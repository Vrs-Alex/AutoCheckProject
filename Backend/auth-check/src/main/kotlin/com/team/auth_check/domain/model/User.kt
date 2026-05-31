package com.team.auth_check.domain.model

import java.time.Instant

/** Pure domain model — no JPA, no framework dependencies. */
data class User(
    val id: Long = 0,
    val email: String,
    val passwordHash: String,
    val fullName: String,
    val role: UserRole,
    val createdAt: Instant = Instant.now()
)

enum class UserRole { EXPERT, CANDIDATE }
