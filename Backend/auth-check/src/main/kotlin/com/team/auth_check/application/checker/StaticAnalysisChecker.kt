package com.team.auth_check.application.checker

import com.team.auth_check.domain.checker.CheckContext
import com.team.auth_check.domain.checker.CheckerResult
import com.team.auth_check.domain.checker.IChecker
import com.team.auth_check.domain.model.CheckStatus
import com.team.auth_check.domain.model.CheckerType
import org.slf4j.LoggerFactory
import org.springframework.stereotype.Component
import java.nio.file.Files
import kotlin.streams.asSequence

/**
 * Analyses source code for static quality issues.
 *
 * Scoring: score = 100 - (errors * 5) - (warnings * 1), min 0.
 * Detects: TODO/FIXME, print statements, very long lines (>200 chars), empty catch blocks.
 *
 * Sprint-3 upgrade: replace with Detekt / ktlint running in Docker container.
 */
@Component
class StaticAnalysisChecker : IChecker {

    override val type = CheckerType.STATIC_ANALYSIS

    private val log = LoggerFactory.getLogger(javaClass)

    override fun check(context: CheckContext): CheckerResult {
        log.info("StaticAnalysis started submissionId={}", context.submissionId)
        return try {
            val sourceFiles = collectSourceFiles(context.codePath)
            if (sourceFiles.isEmpty()) {
                return CheckerResult(type, CheckStatus.ERROR, null, "Исходные файлы не найдены")
            }

            var errors = 0
            var warnings = 0
            val details = StringBuilder()

            sourceFiles.forEach { file ->
                val lines = Files.readAllLines(file)
                lines.forEachIndexed { idx, line ->
                    val lineNum = idx + 1
                    val trimmed = line.trim()

                    if (trimmed.contains("TODO") || trimmed.contains("FIXME")) {
                        warnings++
                        details.appendLine("  [WARN] ${file.fileName}:$lineNum — TODO/FIXME найден")
                    }
                    if (trimmed.startsWith("println(") || trimmed.startsWith("print(") ||
                        trimmed.startsWith("System.out") || trimmed.startsWith("Log.d(")) {
                        warnings++
                        details.appendLine("  [WARN] ${file.fileName}:$lineNum — print-statement (используйте Logger)")
                    }
                    if (line.length > 200) {
                        warnings++
                        details.appendLine("  [WARN] ${file.fileName}:$lineNum — строка слишком длинная (${line.length} символов)")
                    }
                    // Empty catch block: "catch" followed by "{ }" on same line
                    if (trimmed.matches(Regex("""catch\s*\(.*\)\s*\{\s*\}"""))) {
                        errors++
                        details.appendLine("  [ERROR] ${file.fileName}:$lineNum — пустой catch-блок")
                    }
                }
            }

            val score = maxOf(0.0, 100.0 - errors * 5.0 - warnings * 1.0)
            val status = if (score >= 50) CheckStatus.PASSED else CheckStatus.FAILED
            val summary = buildString {
                appendLine("Проверено файлов: ${sourceFiles.size}")
                appendLine("Ошибки: $errors, Предупреждения: $warnings")
                appendLine("Итоговый балл: $score")
                if (details.isNotEmpty()) appendLine("\nДетали:").append(details)
            }

            log.info("StaticAnalysis done submissionId={} score={}", context.submissionId, score)
            CheckerResult(type, status, score, summary)

        } catch (e: Exception) {
            log.error("StaticAnalysis error submissionId={}", context.submissionId, e)
            CheckerResult(type, CheckStatus.ERROR, null, "Ошибка анализа: ${e.message}")
        }
    }

    private fun collectSourceFiles(root: java.nio.file.Path) =
        Files.walk(root).asSequence()
            .filter { Files.isRegularFile(it) }
            .filter { it.toString().endsWith(".kt") || it.toString().endsWith(".java") ||
                      it.toString().endsWith(".dart") }
            .toList()
}
