package com.team.auth_check.application.checker

import com.team.auth_check.domain.checker.CheckContext
import com.team.auth_check.domain.checker.CheckerResult
import com.team.auth_check.domain.checker.IChecker
import com.team.auth_check.domain.model.CheckStatus
import com.team.auth_check.domain.model.CheckerType
import org.slf4j.LoggerFactory
import org.springframework.stereotype.Component
import java.nio.file.Files

/**
 * Analyses Git history quality in the submitted repository.
 *
 * Scoring (each criterion worth 20 points):
 * 1. .git directory present (git repo, not just a ZIP dump)
 * 2. ≥5 commits (not a single "initial commit" dump)
 * 3. Commit messages are descriptive (avg length ≥ 20 chars)
 * 4. Evidence of feature branches (non-main branch names in refs)
 * 5. No merge commits with conflict markers left in code
 */
@Component
class GitPracticesChecker : IChecker {

    override val type = CheckerType.GIT_PRACTICES

    private val log = LoggerFactory.getLogger(javaClass)

    override fun check(context: CheckContext): CheckerResult {
        log.info("GitPractices check started submissionId={}", context.submissionId)
        return try {
            val root = context.codePath
            val gitDir = root.resolve(".git")

            if (!Files.exists(gitDir)) {
                return CheckerResult(type, CheckStatus.FAILED, 0.0,
                    ".git директория не найдена. Решение должно быть Git-репозиторием.")
            }

            val checks = mutableListOf<Pair<String, Boolean>>()

            // 1. Git repo exists
            checks += ".git директория присутствует" to true

            // 2. Commit count
            val commitLog = runGit(root, "git", "log", "--oneline")
            val commitCount = commitLog.lines().count { it.isNotBlank() }
            checks += "≥5 коммитов ($commitCount)" to (commitCount >= 5)

            // 3. Commit message quality
            val messages = runGit(root, "git", "log", "--format=%s").lines().filter { it.isNotBlank() }
            val avgLen = if (messages.isNotEmpty()) messages.sumOf { it.length } / messages.size else 0
            checks += "Среднее длина сообщений ≥20 символов ($avgLen)" to (avgLen >= 20)

            // 4. Feature branches
            val branches = runGit(root, "git", "branch", "-a")
            val hasFeatureBranches = branches.lines().any { line ->
                val b = line.trim().removePrefix("* ").removePrefix("remotes/origin/")
                b.isNotBlank() && b !in setOf("main", "master", "HEAD")
            }
            checks += "Присутствуют feature-ветки" to hasFeatureBranches

            // 5. No conflict markers
            val hasConflicts = Files.walk(root).anyMatch { f ->
                Files.isRegularFile(f) && !f.startsWith(gitDir) &&
                f.fileName.toString().let { n ->
                    n.endsWith(".kt") || n.endsWith(".dart") || n.endsWith(".java")
                } &&
                Files.readString(f).contains("<<<<<<< ")
            }
            checks += "Нет незакрытых конфликтов слияния" to !hasConflicts

            val passedCount = checks.count { it.second }
            val score = passedCount * 20.0
            val status = if (score >= 60) CheckStatus.PASSED else CheckStatus.FAILED
            val details = checks.joinToString("\n") { (desc, ok) ->
                "  [${if (ok) "✓" else "✗"}] $desc"
            }
            val summary = buildString {
                appendLine("Коммитов: $commitCount")
                appendLine("Пройдено: $passedCount/5, Балл: $score")
                appendLine()
                appendLine(details)
            }

            log.info("GitPractices done submissionId={} score={}", context.submissionId, score)
            CheckerResult(type, status, score, summary)

        } catch (e: Exception) {
            log.error("GitPractices error submissionId={}", context.submissionId, e)
            CheckerResult(type, CheckStatus.ERROR, null, "Ошибка проверки Git: ${e.message}")
        }
    }

    private fun runGit(root: java.nio.file.Path, vararg cmd: String): String {
        val process = ProcessBuilder(*cmd)
            .directory(root.toFile())
            .redirectErrorStream(true)
            .start()
        process.waitFor(30, java.util.concurrent.TimeUnit.SECONDS)
        return process.inputStream.bufferedReader().readText()
    }
}
