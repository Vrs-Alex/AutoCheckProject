package com.team.auth_check.application.dto


data class StatsDto(
    val totalSubmissions: Int,
    val averageScore: Double,
    val passRate: Double,
    val dailyCounts: List<DailyCountDto>,
    val topCandidates: List<TopCandidateDto>
)

data class DailyCountDto(
    val date: String,
    val count: Int
)

data class TopCandidateDto(
    val candidateId: Long,
    val fullName: String,
    val bestScore: Double
)
