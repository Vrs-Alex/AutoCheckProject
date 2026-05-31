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
 * Checks that the project follows a layered architecture.
 *
 * Scoring (each worth 20 points):
 * - domain/  directory exists
 * - presentation/ or ui/ directory exists
 * - data/ or infrastructure/ or repository/ directory exists
 * - No direct DB calls from presentation layer (no "Repository" import in Activity/Fragment/Screen)
 * - README.md or architecture docs present
 */
@Component
class ArchitectureChecker : IChecker {

    override val type = CheckerType.ARCHITECTURE

    private val log = LoggerFactory.getLogger(javaClass)

    override fun check(context: CheckContext): CheckerResult {
        log.info("Architecture check started submissionId={}", context.submissionId)
        return try {
            val allDirs = Files.walk(context.codePath).asSequence()
                .filter { Files.isDirectory(it) }
                .map { it.fileName?.toString()?.lowercase() ?: "" }
                .toSet()

            val allFiles = Files.walk(context.codePath).asSequence()
                .filter { Files.isRegularFile(it) }
                .toList()

            val checks = mutableListOf<Pair<String, Boolean>>()

            // 1. Domain layer
            val hasDomain = allDirs.any { it in setOf("domain", "model", "entity") }
            checks += "domain/ слой существует" to hasDomain

            // 2. Presentation layer
            val hasPresentation = allDirs.any { it in setOf("presentation", "ui", "view", "screen") }
            checks += "presentation/ слой существует" to hasPresentation

            // 3. Data/Infrastructure layer
            val hasData = allDirs.any { it in setOf("data", "infrastructure", "repository", "datasource") }
            checks += "data/ или infrastructure/ слой существует" to hasData

            // 4. No DB calls from UI (heuristic: Repository not imported in Activity/Fragment/Screen files)
            val uiFiles = allFiles.filter { f ->
                val name = f.fileName.toString()
                name.contains("Activity") || name.contains("Fragment") ||
                name.contains("Screen") || name.contains("View")
            }
            val noDirectRepo = uiFiles.none { f ->
                Files.readString(f).contains("Repository(") &&
                !Files.readString(f).contains("ViewModel") &&
                !Files.readString(f).contains("UseCase")
            }
            checks += "UI не обращается к репозиториям напрямую" to noDirectRepo

            // 5. README or docs
            val hasReadme = allFiles.any { it.fileName.toString().lowercase() == "readme.md" }
            checks += "README.md присутствует" to hasReadme

            val passedCount = checks.count { it.second }
            val score = passedCount * 20.0

            val status = if (score >= 60) CheckStatus.PASSED else CheckStatus.FAILED
            val details = checks.joinToString("\n") { (desc, passed) ->
                val mark = if (passed) "✓" else "✗"
                "  [$mark] $desc"
            }
            val summary = "Пройдено: $passedCount/5\nБалл: $score\n\n$details"

            log.info("Architecture check done submissionId={} score={}", context.submissionId, score)
            CheckerResult(type, status, score, summary)

        } catch (e: Exception) {
            log.error("Architecture check error submissionId={}", context.submissionId, e)
            CheckerResult(type, CheckStatus.ERROR, null, "Ошибка проверки: ${e.message}")
        }
    }
}
