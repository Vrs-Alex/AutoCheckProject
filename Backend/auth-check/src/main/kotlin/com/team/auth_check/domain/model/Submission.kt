package com.team.auth_check.domain.model

import java.time.Instant

/** Pure domain model for a candidate's submitted solution. */
data class Submission(
    val id: Long = 0,
    val assignment: Assignment,
    val candidate: User,
    val filePath: String?,
    val gitUrl: String?,
    val status: SubmissionStatus,
    val totalScore: Double?,
    val verdict: Verdict?,
    val verdictComment: String?,
    val aiReview: String?,
    val createdAt: Instant,
    val completedAt: Instant?
)

enum class SubmissionStatus { PENDING, RUNNING, DONE, ERROR }
enum class Verdict { ACCEPTED, REJECTED }
