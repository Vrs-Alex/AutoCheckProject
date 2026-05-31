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
 * Checks documentation quality in source files.
 *
 * Scoring:
 * - 30 pts — README.md exists and is non-trivial (>200 chars)
 * - 40 pts — ≥50% of public classes/functions have KDoc/Javadoc/dartdoc comments
 * - 30 pts — no obvious logging anti-patterns (no raw println in main sources)
 */
@Component
class DocumentationChecker : IChecker {

    override val type = CheckerType.DOCUMENTATION

    private val log = LoggerFactory.getLogger(javaClass)

    override fun check(context: CheckContext): CheckerResult {
        log.info("Documentation check started submissionId={}", context.submissionId)
        return try {
            val root = context.codePath
            var score = 0.0
            val details = StringBuilder()

            // ── 1. README.md ──────────────────────────────────────────────────
            val readme = Files.walk(root).asSequence()
                .filter { it.fileName?.toString()?.lowercase() == "readme.md" }
                .firstOrNull()
            if (readme != null) {
                val content = Files.readString(readme)
                if (content.length > 200) {
                    score += 30.0
                    details.appendLine("✓ README.md найден (${content.length} символов) — +30")
                } else {
                    score += 10.0
                    details.appendLine("⚠ README.md слишком короткий — +10")
                }
            } else {
                details.appendLine("✗ README.md отсутствует — +0")
            }

            // ── 2. KDoc/Javadoc coverage ─────────────────────────────────────
            val sourceFiles = Files.walk(root).asSequence()
                .filter { Files.isRegularFile(it) }
                .filter { p -> p.toString().let { it.endsWith(".kt") || it.endsWith(".java") || it.endsWith(".dart") } }
                .toList()

            if (sourceFiles.isNotEmpty()) {
                var totalDeclarations = 0
                var documentedDeclarations = 0
                val classOrFunRegex = Regex("""^(public\s+|open\s+|data\s+)?(class|fun|interface|object)\s+\w""")
                val docCommentRegex = Regex("""^\s*(/\*\*|///|///)""")

                sourceFiles.forEach { file ->
                    val lines = Files.readAllLines(file)
                    lines.forEachIndexed { idx, line ->
                        if (classOrFunRegex.containsMatchIn(line.trim())) {
                            totalDeclarations++
                            val prevLine = if (idx > 0) lines[idx - 1] else ""
                            if (docCommentRegex.containsMatchIn(prevLine) ||
                                (idx > 1 && docCommentRegex.containsMatchIn(lines[idx - 2]))) {
                                documentedDeclarations++
                            }
                        }
                    }
                }

                val coverage = if (totalDeclarations > 0)
                    documentedDeclarations.toDouble() / totalDeclarations else 0.0
                val docScore = (coverage * 40).coerceIn(0.0, 40.0)
                score += docScore
                details.appendLine(
                    "${if (coverage >= 0.5) "✓" else "✗"} " +
                    "Документировано ${documentedDeclarations}/${totalDeclarations} " +
                    "объявлений (${(coverage * 100).toInt()}%) — +${"%.0f".format(docScore)}"
                )
            }

            // ── 3. Logging usage ─────────────────────────────────────────────
            val hasLogger = sourceFiles.any { f ->
                val content = Files.readString(f)
                content.contains("LoggerFactory") || content.contains("Logger") ||
                content.contains("log.") || content.contains("Timber.")
            }
            if (hasLogger) {
                score += 30.0
                details.appendLine("✓ Логирование используется — +30")
            } else {
                details.appendLine("✗ Логирование не найдено — +0")
            }

            val status = if (score >= 50) CheckStatus.PASSED else CheckStatus.FAILED
            log.info("Documentation check done submissionId={} score={}", context.submissionId, score)
            CheckerResult(type, status, score, "Итог: $score/100\n\n$details")

        } catch (e: Exception) {
            log.error("Documentation check error submissionId={}", context.submissionId, e)
            CheckerResult(type, CheckStatus.ERROR, null, "Ошибка проверки: ${e.message}")
        }
    }
}
