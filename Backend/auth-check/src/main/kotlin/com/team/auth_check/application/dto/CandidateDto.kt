package com.team.auth_check.application.dto


data class CandidateDto(
    val id: Long,
    val email: String,
    val fullName: String,
    val submissionsCount: Int,
    val bestScore: Double?
)
