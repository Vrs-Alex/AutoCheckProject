package com.team.auth_check.domain.repository

import com.team.auth_check.domain.model.Submission
import java.time.Instant

interface SubmissionRepository {
    fun findById(id: Long): Submission?
    fun findAll(limit: Int = 200): List<Submission>
    fun findByCandidateId(candidateId: Long): List<Submission>
    fun findByAssignmentId(assignmentId: Long): List<Submission>
    fun save(submission: Submission): Submission
    fun countByCandidateId(candidateId: Long): Int
    fun findBestScoreByCandidateId(candidateId: Long): Double?
    /** Returns list of (date string, count) for stats chart. */
    fun countByDay(from: Instant): List<Pair<String, Int>>
}
