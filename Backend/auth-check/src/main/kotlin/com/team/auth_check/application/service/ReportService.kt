package com.team.auth_check.application.service

import com.team.auth_check.application.dto.*
import com.team.auth_check.domain.model.UserRole
import com.team.auth_check.domain.model.Verdict
import com.team.auth_check.domain.repository.SubmissionRepository
import com.team.auth_check.domain.repository.UserRepository
import org.slf4j.LoggerFactory
import org.springframework.security.access.prepost.PreAuthorize
import org.springframework.stereotype.Service
import org.springframework.transaction.annotation.Transactional
import java.time.Instant
import java.time.temporal.ChronoUnit

@Service
class ReportService(
    private val submissionRepository: SubmissionRepository,
    private val userRepository: UserRepository
) {

    private val log = LoggerFactory.getLogger(javaClass)

    @Transactional(readOnly = true)
    @PreAuthorize("hasRole('EXPERT')")
    fun getStats(): StatsDto {
        log.debug("Computing stats")
        val all      = submissionRepository.findAll()
        val total    = all.size
        val scored   = all.filter { it.totalScore != null }
        val accepted = all.count { it.verdict == Verdict.ACCEPTED }

        val averageScore = if (scored.isNotEmpty()) scored.sumOf { it.totalScore!! } / scored.size else 0.0
        val passRate     = if (total > 0) accepted.toDouble() / total * 100 else 0.0

        val dailyCounts = submissionRepository
            .countByDay(Instant.now().minus(30, ChronoUnit.DAYS))
            .map { (date, count) -> DailyCountDto(date, count) }

        val topCandidates = userRepository.findAllByRole(UserRole.CANDIDATE)
            .mapNotNull { user ->
                val best = submissionRepository.findBestScoreByCandidateId(user.id) ?: return@mapNotNull null
                TopCandidateDto(user.id, user.fullName, best)
            }
            .sortedByDescending { it.bestScore }
            .take(10)

        log.debug("Stats: total={} avgScore={}", total, averageScore)
        return StatsDto(total, averageScore, passRate, dailyCounts, topCandidates)
    }
}
