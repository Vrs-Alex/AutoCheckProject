package com.team.auth_check.application.service

import com.fasterxml.jackson.module.kotlin.jacksonObjectMapper
import com.fasterxml.jackson.module.kotlin.readValue
import com.team.auth_check.application.checker.SubmissionQueueService
import com.team.auth_check.application.dto.*
import com.team.auth_check.domain.model.*
import com.team.auth_check.domain.repository.AssignmentRepository
import com.team.auth_check.domain.repository.CheckResultRepository
import com.team.auth_check.domain.repository.SubmissionRepository
import com.team.auth_check.domain.repository.UserRepository
import com.team.auth_check.infrastructure.storage.FileStorageService
import org.slf4j.LoggerFactory
import org.springframework.security.access.AccessDeniedException
import org.springframework.security.access.prepost.PreAuthorize
import org.springframework.stereotype.Service
import org.springframework.transaction.annotation.Transactional
import org.springframework.transaction.support.TransactionSynchronization
import org.springframework.transaction.support.TransactionSynchronizationManager
import org.springframework.web.multipart.MultipartFile
import java.time.Instant

@Service
class SubmissionService(
    private val submissionRepository: SubmissionRepository,
    private val assignmentRepository: AssignmentRepository,
    private val userRepository: UserRepository,
    private val checkResultRepository: CheckResultRepository,
    private val fileStorage: FileStorageService,
    private val queue: SubmissionQueueService
) {

    private val log = LoggerFactory.getLogger(javaClass)
    private val jackson = jacksonObjectMapper()

    @Transactional
    fun submit(
        assignmentId: Long,
        file: MultipartFile?,
        gitUrl: String?,
        callerEmail: String,
        callerRole: UserRole,
        candidateEmail: String? = null,
        candidateFullName: String? = null
    ): SubmissionDto {
        require(file != null || !gitUrl.isNullOrBlank()) {
            "Необходимо предоставить ZIP-файл или Git URL"
        }
        log.info("New submission assignmentId={} caller={}", assignmentId, callerEmail)

        val assignment = assignmentRepository.findById(assignmentId)
            ?: throw NoSuchElementException("Задание $assignmentId не найдено")

        val candidate: User = when (callerRole) {
            UserRole.EXPERT -> {
                requireNotNull(candidateEmail) { "Эксперт должен указать email кандидата" }
                userRepository.findByEmail(candidateEmail) ?: run {
                    val name = candidateFullName ?: candidateEmail.substringBefore("@")
                    userRepository.save(User(email = candidateEmail, passwordHash = "", fullName = name, role = UserRole.CANDIDATE))
                }
            }
            UserRole.CANDIDATE -> userRepository.findByEmail(callerEmail)
                ?: throw NoSuchElementException("Пользователь не найден")
        }

        val filePath = file?.let { fileStorage.saveZip(it) }
        val submission = Submission(
            assignment     = assignment,
            candidate      = candidate,
            filePath       = filePath,
            gitUrl         = gitUrl?.takeIf { it.isNotBlank() },
            status         = SubmissionStatus.PENDING,
            totalScore     = null,
            verdict        = null,
            verdictComment = null,
            aiReview       = null,
            createdAt      = Instant.now(),
            completedAt    = null
        )
        val saved = submissionRepository.save(submission)

        val weights: Map<String, Int> = jackson.readValue(assignment.checkerWeights)
        weights.filter { it.value > 0 }.forEach { (name, _) ->
            runCatching { CheckerType.valueOf(name) }.getOrNull()?.let { type ->
                checkResultRepository.save(CheckResult(
                    submissionId = saved.id,
                    checkerType  = type,
                    status       = CheckStatus.PENDING,
                    score        = null,
                    log          = null,
                    startedAt    = Instant.now(),
                    finishedAt   = null
                ))
            }
        }

        // Enqueue AFTER commit — worker must not dequeue before the row is visible in DB
        val submissionId = saved.id
        TransactionSynchronizationManager.registerSynchronization(object : TransactionSynchronization {
            override fun afterCommit() {
                queue.enqueue(submissionId)
                log.info("Submission id={} enqueued after commit", submissionId)
            }
        })
        return saved.toDto()
    }

    @Transactional(readOnly = true)
    fun list(callerEmail: String, callerRole: UserRole, assignmentId: Long? = null): List<SubmissionDto> {
        log.debug("Listing submissions caller={}", callerEmail)
        return when (callerRole) {
            UserRole.EXPERT -> if (assignmentId != null)
                submissionRepository.findByAssignmentId(assignmentId)
            else
                submissionRepository.findAll()
            UserRole.CANDIDATE -> {
                val candidate = userRepository.findByEmail(callerEmail)
                    ?: throw NoSuchElementException("Пользователь не найден")
                submissionRepository.findByCandidateId(candidate.id)
            }
        }.map { it.toDto() }
    }

    @Transactional(readOnly = true)
    fun getById(id: Long, callerEmail: String, callerRole: UserRole): SubmissionDto {
        val submission = findOrThrow(id)
        if (callerRole == UserRole.CANDIDATE && submission.candidate.email != callerEmail) {
            throw AccessDeniedException("Доступ запрещён")
        }
        return submission.toDto()
    }

    @Transactional(readOnly = true)
    fun getStatus(id: Long): SubmissionStatusDto {
        val s = findOrThrow(id)
        return SubmissionStatusDto(s.id, s.status.name, s.totalScore)
    }

    @Transactional(readOnly = true)
    fun getResults(id: Long): List<CheckResultDto> {
        findOrThrow(id)
        return checkResultRepository.findBySubmissionId(id).map { it.toDto() }
    }

    @Transactional
    @PreAuthorize("hasRole('EXPERT')")
    fun rerun(id: Long): SubmissionDto {
        log.info("Rerun submissionId={}", id)
        val submission = findOrThrow(id)
        val reset = submission.copy(status = SubmissionStatus.PENDING, totalScore = null, completedAt = null)
        submissionRepository.save(reset)

        checkResultRepository.findBySubmissionId(id).forEach { cr ->
            checkResultRepository.save(cr.copy(status = CheckStatus.PENDING, score = null, log = null, finishedAt = null))
        }

        TransactionSynchronizationManager.registerSynchronization(object : TransactionSynchronization {
            override fun afterCommit() { queue.enqueue(id) }
        })
        return reset.toDto()
    }

    @Transactional
    @PreAuthorize("hasRole('EXPERT')")
    fun setVerdict(id: Long, req: VerdictRequest): SubmissionDto {
        log.info("Setting verdict submissionId={} verdict={}", id, req.verdict)
        val verdict = runCatching { Verdict.valueOf(req.verdict.uppercase()) }
            .getOrElse { throw IllegalArgumentException("Вердикт должен быть ACCEPTED или REJECTED") }

        val submission = findOrThrow(id)
        val updated = submission.copy(verdict = verdict, verdictComment = req.comment)
        return submissionRepository.save(updated).toDto()
    }

    @Transactional(readOnly = true)
    fun getAiReview(id: Long): AiReviewDto {
        val s = findOrThrow(id)
        if (s.aiReview.isNullOrBlank()) return AiReviewDto(available = false)
        return try {
            jackson.readValue(s.aiReview, AiReviewDto::class.java)
        } catch (e: Exception) {
            AiReviewDto(available = true, summary = s.aiReview)
        }
    }

    private fun findOrThrow(id: Long) =
        submissionRepository.findById(id) ?: throw NoSuchElementException("Проверка $id не найдена")

    private fun Submission.toDto() = SubmissionDto(
        id                = id,
        assignmentId      = assignment.id,
        assignmentTitle   = assignment.title,
        candidateId       = candidate.id,
        candidateFullName = candidate.fullName,
        status            = status.name,
        totalScore        = totalScore,
        verdict           = verdict?.name,
        verdictComment    = verdictComment,
        createdAt         = createdAt.toString(),
        completedAt       = completedAt?.toString()
    )

    private fun CheckResult.toDto() = CheckResultDto(
        id          = id,
        checkerType = checkerType.name,
        status      = status.name,
        score       = score,
        log         = log,
        startedAt   = startedAt?.toString(),
        finishedAt  = finishedAt?.toString()
    )
}
