package com.team.auth_check.application.dto


data class CheckResultDto(
    val id: Long,
    val checkerType: String,
    val status: String,
    val score: Double?,
    val log: String?,
    val startedAt: String?,
    val finishedAt: String?
)
