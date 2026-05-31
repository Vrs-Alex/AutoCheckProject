package com.team.auth_check.domain.model

import java.time.Instant

/** Pure domain model — JSON checkerWeights stored as string, parsed at service layer. */
data class Assignment(
    val id: Long = 0,
    val title: String,
    val description: String?,
    /** JSON: {"STATIC_ANALYSIS":20,"BUILD":20,"TESTS":20,"ARCHITECTURE":15,"DOCUMENTATION":15,"GIT_PRACTICES":10} */
    val checkerWeights: String,
    val createdBy: User,
    val createdAt: Instant,
    val updatedAt: Instant
)
