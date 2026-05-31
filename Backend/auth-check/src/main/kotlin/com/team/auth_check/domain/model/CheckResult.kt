package com.team.auth_check.domain.model

import java.time.Instant

/** Pure domain model for a single checker's result within a submission. */
data class CheckResult(
    val id: Long = 0,
    /** Back-reference stored as ID to avoid circular domain dependency. */
    val submissionId: Long,
    val checkerType: CheckerType,
    val status: CheckStatus,
    val score: Double?,
    val log: String?,
    val startedAt: Instant?,
    val finishedAt: Instant?
)

enum class CheckerType {
    STATIC_ANALYSIS, ARCHITECTURE, BUILD, TESTS, DOCUMENTATION, GIT_PRACTICES
}

enum class CheckStatus { PENDING, RUNNING, PASSED, FAILED, ERROR }
