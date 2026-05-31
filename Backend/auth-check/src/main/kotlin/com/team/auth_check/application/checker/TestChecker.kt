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
import kotlin.streams.asSequence

/**
 * Runs the project's test suite and parses results.
 *
 * Scoring: passed / total * 100. Bonus -20 if no tests found at all.
 *
 * Sprint-3 upgrade: run in isolated Docker container.
 */
@Component
class TestChecker : IChecker {

    override val type = CheckerType.TESTS

    private val log = LoggerFactory.getLogger(javaClass)

    override fun check(context: CheckContext): CheckerResult {
        log.info("Test check started submissionId={}", context.submissionId)
        return try {
            val codePath = context.codePath

            // Count test files as a quick sanity check
            val testFiles = Files.walk(codePath).asSequence()
                .filter { Files.isRegularFile(it) }
                .filter { f ->
                    val name = f.fileName.toString()
                    name.contains("Test") || name.contains("Spec") ||
                    name.endsWith("_test.dart")
                }
                .toList()

            if (testFiles.isEmpty()) {
                log.warn("No test files found submissionId={}", context.submissionId)
                return CheckerResult(type, CheckStatus.FAILED, 0.0,
                    "Тестовые файлы не найдены. Ожидаются *Test.kt, *Spec.kt или *_test.dart.")
            }

            // Run tests
            val cmd = detectTestCommand(codePath)
                ?: return CheckerResult(type, CheckStatus.ERROR, null,
                    "Система сборки не определена для запуска тестов.")

            val process = ProcessBuilder(cmd)
                .directory(codePath.toFile())
                .redirectErrorStream(true)
                .start()

            val finished = process.waitFor(180L, TimeUnit.SECONDS)
            val output = process.inputStream.bufferedReader().readText()

            if (!finished) {
                process.destroyForcibly()
                return CheckerResult(type, CheckStatus.ERROR, null,
                    "Превышено время выполнения тестов (180с)")
            }

            val exitCode = process.exitValue()
            val (passed, total) = parseTestResults(output)
            val score = if (total > 0) (passed.toDouble() / total * 100).coerceIn(0.0, 100.0) else 0.0
            val status = if (exitCode == 0 && score >= 50) CheckStatus.PASSED else CheckStatus.FAILED

            log.info("Test check done submissionId={} passed={}/{} score={}", context.submissionId, passed, total, score)
            CheckerResult(type, status, score,
                "Тестовых файлов: ${testFiles.size}\nПройдено: $passed/$total\nБалл: $score\n\n${output.take(3000)}")

        } catch (e: Exception) {
            log.error("Test check error submissionId={}", context.submissionId, e)
            CheckerResult(type, CheckStatus.ERROR, null, "Ошибка запуска тестов: ${e.message}")
        }
    }

    private fun detectTestCommand(root: java.nio.file.Path): List<String>? {
        val isWindows = System.getProperty("os.name").lowercase().contains("win")
        return when {
            Files.exists(root.resolve("pubspec.yaml")) ->
                listOf("flutter", "test")
            Files.exists(root.resolve("build.gradle.kts")) ||
            Files.exists(root.resolve("build.gradle")) -> {
                val gradlew = if (isWindows) "./gradlew.bat" else "./gradlew"
                listOf(gradlew, "test", "--no-daemon")
            }
            else -> null
        }
    }

    /** Parse "X tests completed, Y failed" from Gradle output. Returns (passed, total). */
    private fun parseTestResults(output: String): Pair<Int, Int> {
        val totalRegex = Regex("""(\d+) tests?""")
        val failedRegex = Regex("""(\d+) failed""")
        val total = totalRegex.find(output)?.groupValues?.get(1)?.toIntOrNull() ?: 0
        val failed = failedRegex.find(output)?.groupValues?.get(1)?.toIntOrNull() ?: 0
        return (total - failed) to total
    }
}
