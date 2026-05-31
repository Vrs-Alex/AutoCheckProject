package com.team.auth_check.application.checker

import com.fasterxml.jackson.module.kotlin.jacksonObjectMapper
import com.fasterxml.jackson.module.kotlin.readValue
import com.team.auth_check.domain.checker.IAnalysisProvider
import com.team.auth_check.domain.model.CheckStatus
import com.team.auth_check.domain.model.SubmissionStatus
import com.team.auth_check.domain.repository.CheckResultRepository
import com.team.auth_check.domain.repository.SubmissionRepository
import com.team.auth_check.infrastructure.storage.FileStorageService
import org.slf4j.LoggerFactory
import org.springframework.beans.factory.annotation.Value
import org.springframework.stereotype.Service
import java.nio.file.Files
import java.nio.file.Path
import java.time.Instant
import java.util.concurrent.TimeUnit

/**
 * Orchestrates all checkers for one submission.
 *
 * Open/Closed: depends on DockerCheckerRunner — adding a new checker script requires no change here.
 * Sprint-3: each checker runs in an isolated Docker container via [DockerCheckerRunner].
 */
@Service
class CheckOrchestrator(
    private val dockerRunner: DockerCheckerRunner,
    private val analysisProvider: IAnalysisProvider,
    private val submissionRepository: SubmissionRepository,
    private val checkResultRepository: CheckResultRepository,
    private val fileStorage: FileStorageService,
    @Value("\${app.uploads.dir:/app/uploads}") private val uploadsDir: String
) {

    private val log = LoggerFactory.getLogger(javaClass)
    private val jackson = jacksonObjectMapper()

    fun process(submissionId: Long) {
        log.info("Orchestrator starting submissionId={}", submissionId)

        val submission = submissionRepository.findById(submissionId) ?: run {
            log.error("Submission not found submissionId={}", submissionId)
            return
        }

        submissionRepository.save(submission.copy(status = SubmissionStatus.RUNNING))

        val weights: Map<String, Int> = try {
            jackson.readValue(submission.assignment.checkerWeights)
        } catch (e: Exception) {
            log.error("Cannot parse checkerWeights submissionId={}", submissionId, e)
            submissionRepository.save(submission.copy(status = SubmissionStatus.ERROR))
            return
        }

        val codePath: Path = try {
            if (submission.filePath != null)
                fileStorage.extractZip(submission.filePath)
            else
                cloneGitRepo(submission.gitUrl!!, submissionId)
        } catch (e: Exception) {
            log.error("Failed to prepare code submissionId={}", submissionId, e)
            submissionRepository.save(submission.copy(status = SubmissionStatus.ERROR))
            return
        }

        var weightedSum = 0.0
        var totalWeight = 0

        // Each checker runs in an isolated Docker container — failure in one does NOT stop others
        checkResultRepository.findBySubmissionId(submissionId).forEach { checkResult ->
            val type   = checkResult.checkerType
            val weight = weights[type.name] ?: 0
            if (weight == 0) return@forEach

            checkResultRepository.save(checkResult.copy(status = CheckStatus.RUNNING, startedAt = Instant.now()))

            log.info("Dispatching checker={} to Docker container submissionId={}", type, submissionId)
            val result = dockerRunner.run(type, codePath)

            checkResultRepository.save(
                checkResult.copy(
                    status     = result.status,
                    score      = result.score,
                    log        = result.log,
                    finishedAt = Instant.now()
                )
            )
            log.info("Checker={} container finished status={} score={}", type, result.status, result.score)

            if (result.score != null) {
                weightedSum += result.score * weight
                totalWeight += weight
            }
        }

        val totalScore = if (totalWeight > 0) weightedSum / totalWeight else null

        // AI review runs after all checkers — result saved to submission.aiReview
        log.info("Running AI review submissionId={}", submissionId)
        val aiReview = try {
            val dto = analysisProvider.analyze(codePath)
            if (dto.available) jackson.writeValueAsString(dto) else null
        } catch (e: Exception) {
            log.error("AI review error submissionId={}", submissionId, e)
            null
        }

        submissionRepository.save(
            submission.copy(
                status      = SubmissionStatus.DONE,
                totalScore  = totalScore,
                aiReview    = aiReview,
                completedAt = Instant.now()
            )
        )
        log.info("Orchestrator done submissionId={} totalScore={}", submissionId, totalScore)
    }

    /** Clone git repo into the uploads volume so Docker sibling containers can access it. */
    private fun cloneGitRepo(gitUrl: String, submissionId: Long): Path {
        val relPath = "submissions/git-$submissionId/extracted"
        val dir = fileStorage.absolutePath(relPath)
        if (Files.exists(dir)) return dir

        Files.createDirectories(dir)
        log.debug("Cloning {} into {}", gitUrl, dir)
        val process = ProcessBuilder("git", "clone", "--depth=1", gitUrl, dir.toString())
            .redirectErrorStream(true).start()
        val ok = process.waitFor(120, TimeUnit.SECONDS)
        if (!ok || process.exitValue() != 0) {
            val out = process.inputStream.bufferedReader().readText()
            throw RuntimeException("git clone failed: $out")
        }
        return dir
    }
}
