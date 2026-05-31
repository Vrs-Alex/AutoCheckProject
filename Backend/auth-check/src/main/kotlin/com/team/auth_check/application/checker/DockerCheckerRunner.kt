package com.team.auth_check.application.checker

import com.fasterxml.jackson.annotation.JsonIgnoreProperties
import com.fasterxml.jackson.module.kotlin.jacksonObjectMapper
import com.fasterxml.jackson.module.kotlin.readValue
import com.team.auth_check.domain.checker.CheckerResult
import com.team.auth_check.domain.model.CheckStatus
import com.team.auth_check.domain.model.CheckerType
import org.slf4j.LoggerFactory
import org.springframework.beans.factory.annotation.Value
import org.springframework.stereotype.Service
import java.nio.file.Path
import java.nio.file.Paths
import java.util.concurrent.TimeUnit

/**
 * Runs each checker in an isolated Docker container via the mounted Docker socket.
 *
 * Each container:
 * - Mounts the uploads volume (read-only access to candidate's code)
 * - Has no access to the internal autocheck-net network
 * - Is limited to 512 MB RAM and 1 CPU
 * - Is forcibly killed after 3 minutes
 * - Is removed automatically after exit (--rm)
 *
 * The container writes a single JSON line to stdout:
 *   {"status": "passed|failed|error", "score": 85.0, "log": "..."}
 */
@Service
class DockerCheckerRunner(
    @Value("\${app.uploads.dir:/app/uploads}") uploadsDir: String,
    @Value("\${app.docker.uploads-volume:auth-check_uploads_data}") private val uploadsVolume: String,
    @Value("\${app.docker.checker-image:autocheck-checker:latest}") private val checkerImage: String
) {
    private val log = LoggerFactory.getLogger(javaClass)
    private val jackson = jacksonObjectMapper()
    private val uploadsRoot: Path = Paths.get(uploadsDir)

    companion object {
        private const val TIMEOUT_SECONDS = 180L
    }

    fun run(checkerType: CheckerType, codePath: Path): CheckerResult {
        val relPath = uploadsRoot.relativize(codePath).toString()
        val containerName = "checker-${checkerType.name.lowercase()}-${System.currentTimeMillis()}"

        val cmd = listOf(
            "docker", "run", "--rm",
            "--name", containerName,
            "-v", "$uploadsVolume:/app/uploads:ro",
            "--memory=512m",
            "--cpus=1",
            checkerImage,
            checkerType.name,
            relPath
        )

        log.info("Starting checker container type={} relPath={}", checkerType, relPath)

        return try {
            val process = ProcessBuilder(cmd)
                .redirectErrorStream(false)
                .start()

            val finished = process.waitFor(TIMEOUT_SECONDS, TimeUnit.SECONDS)
            val stdout = process.inputStream.bufferedReader().readText().trim()
            val stderr = process.errorStream.bufferedReader().readText().trim()

            if (!finished) {
                process.destroyForcibly()
                runCatching {
                    ProcessBuilder("docker", "stop", containerName)
                        .start().waitFor(10, TimeUnit.SECONDS)
                }
                log.warn("Checker timeout type={} containerName={}", checkerType, containerName)
                return CheckerResult(
                    checkerType, CheckStatus.ERROR, null,
                    "Превышено время выполнения (${TIMEOUT_SECONDS}с)"
                )
            }

            if (stdout.isBlank()) {
                log.error("Empty stdout from checker type={} stderr={}", checkerType, stderr.take(200))
                return CheckerResult(
                    checkerType, CheckStatus.ERROR, null,
                    "Контейнер не вернул результат. stderr: ${stderr.take(500)}"
                )
            }

            val output = jackson.readValue<DockerCheckerOutput>(stdout)
            val status = when (output.status) {
                "passed" -> CheckStatus.PASSED
                "failed" -> CheckStatus.FAILED
                else     -> CheckStatus.ERROR
            }

            log.info("Checker done type={} status={} score={}", checkerType, status, output.score)
            CheckerResult(checkerType, status, output.score, output.log)

        } catch (e: Exception) {
            log.error("Docker runner error type={}", checkerType, e)
            CheckerResult(checkerType, CheckStatus.ERROR, null, "Ошибка запуска контейнера: ${e.message}")
        }
    }

    @JsonIgnoreProperties(ignoreUnknown = true)
    data class DockerCheckerOutput(
        val status: String = "error",
        val score: Double? = null,
        val log: String = ""
    )
}
