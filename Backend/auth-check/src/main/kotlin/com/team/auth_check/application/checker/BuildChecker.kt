package com.team.auth_check.application.checker

import com.team.auth_check.domain.checker.CheckContext
import com.team.auth_check.domain.checker.CheckerResult
import com.team.auth_check.domain.checker.IChecker
import com.team.auth_check.domain.model.CheckStatus
import com.team.auth_check.domain.model.CheckerType
import org.slf4j.LoggerFactory
import org.springframework.stereotype.Component
import java.nio.file.Files
import java.util.concurrent.TimeUnit

/**
 * Attempts to build the candidate's project.
 * Score: 100 on success, 0 on failure.
 *
 * Detects build system: Gradle (build.gradle / build.gradle.kts), pubspec.yaml (Flutter),
 * Maven (pom.xml). Runs the appropriate build command with a 3-minute timeout.
 *
 * Sprint-3 upgrade: run inside isolated Docker container with pre-installed SDK.
 */
@Component
class BuildChecker : IChecker {

    override val type = CheckerType.BUILD

    private val log = LoggerFactory.getLogger(javaClass)

    private val timeoutSeconds = 180L

    override fun check(context: CheckContext): CheckerResult {
        log.info("Build check started submissionId={}", context.submissionId)
        return try {
            val codePath = context.codePath
            val (cmd, buildSystem) = detectBuildCommand(codePath)
                ?: return CheckerResult(
                    type, CheckStatus.ERROR, null,
                    "Система сборки не определена. Ожидается Gradle, Flutter или Maven."
                )

            log.debug("Build system={} cmd={}", buildSystem, cmd)
            val process = ProcessBuilder(cmd)
                .directory(codePath.toFile())
                .redirectErrorStream(true)
                .start()

            val finished = process.waitFor(timeoutSeconds, TimeUnit.SECONDS)
            val output = process.inputStream.bufferedReader().readText()

            if (!finished) {
                process.destroyForcibly()
                log.warn("Build timeout submissionId={}", context.submissionId)
                return CheckerResult(type, CheckStatus.ERROR, null,
                    "Превышено время сборки (${timeoutSeconds}с)")
            }

            val exitCode = process.exitValue()
            val status = if (exitCode == 0) CheckStatus.PASSED else CheckStatus.FAILED
            val score = if (exitCode == 0) 100.0 else 0.0

            log.info("Build done submissionId={} exitCode={} score={}", context.submissionId, exitCode, score)
            CheckerResult(type, status, score,
                "Система сборки: $buildSystem\nКод завершения: $exitCode\n\n$output".take(4000))

        } catch (e: Exception) {
            log.error("Build check error submissionId={}", context.submissionId, e)
            CheckerResult(type, CheckStatus.ERROR, null, "Ошибка запуска сборки: ${e.message}")
        }
    }

    private fun detectBuildCommand(root: java.nio.file.Path): Pair<List<String>, String>? {
        val isWindows = System.getProperty("os.name").lowercase().contains("win")
        return when {
            Files.exists(root.resolve("pubspec.yaml")) ->
                listOf("flutter", "build", "apk", "--debug") to "Flutter"
            Files.exists(root.resolve("build.gradle.kts")) ||
            Files.exists(root.resolve("build.gradle")) -> {
                val gradlew = if (isWindows) "./gradlew.bat" else "./gradlew"
                listOf(gradlew, "build", "-x", "test", "--no-daemon") to "Gradle"
            }
            Files.exists(root.resolve("pom.xml")) ->
                listOf("mvn", "package", "-DskipTests", "-q") to "Maven"
            else -> null
        }
    }
}
