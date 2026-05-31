package com.team.auth_check.application.dto


data class SubmissionDto(
    val id: Long,
    val assignmentId: Long,
    val assignmentTitle: String,
    val candidateId: Long,
    val candidateFullName: String,
    val status: String,
    val totalScore: Double?,
    val verdict: String?,
    val verdictComment: String?,
    val createdAt: String,
    val completedAt: String?
)

data class SubmissionStatusDto(
    val id: Long,
    val status: String,
    val totalScore: Double?
)

data class VerdictRequest(
    val verdict: String,
    val comment: String? = null
)

data class AiReviewDto(
    val available: Boolean,
    val summary: String? = null,
    val strengths: List<String>? = null,
    val weaknesses: List<String>? = null,
    val recommendations: List<String>? = null
)
