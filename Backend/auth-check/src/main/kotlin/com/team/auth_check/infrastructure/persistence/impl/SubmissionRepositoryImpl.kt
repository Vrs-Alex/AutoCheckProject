package com.team.auth_check.infrastructure.persistence.impl

import com.team.auth_check.domain.model.Submission
import com.team.auth_check.domain.repository.SubmissionRepository
import com.team.auth_check.infrastructure.persistence.AssignmentJpaRepository
import com.team.auth_check.infrastructure.persistence.SubmissionJpaRepository
import com.team.auth_check.infrastructure.persistence.UserJpaRepository
import com.team.auth_check.infrastructure.persistence.mapper.toDomain
import com.team.auth_check.infrastructure.persistence.mapper.toNewEntity
import org.springframework.data.domain.PageRequest
import org.springframework.stereotype.Repository
import java.time.Instant

@Repository
class SubmissionRepositoryImpl(
    private val jpa: SubmissionJpaRepository,
    private val assignmentJpa: AssignmentJpaRepository,
    private val userJpa: UserJpaRepository
) : SubmissionRepository {

    override fun findById(id: Long): Submission? =
        jpa.findById(id).orElse(null)?.toDomain()

    override fun findAll(limit: Int): List<Submission> =
        jpa.findAllByOrderByCreatedAtDesc(PageRequest.of(0, limit)).map { it.toDomain() }

    override fun findByCandidateId(candidateId: Long): List<Submission> =
        jpa.findByCandidateIdOrderByCreatedAtDesc(candidateId).map { it.toDomain() }

    override fun findByAssignmentId(assignmentId: Long): List<Submission> =
        jpa.findByAssignmentIdOrderByCreatedAtDesc(assignmentId).map { it.toDomain() }

    override fun save(submission: Submission): Submission {
        val entity = if (submission.id == 0L) {
            // New submission — use JPA proxies for FK references
            submission.toNewEntity(
                assignmentEntity = assignmentJpa.getReferenceById(submission.assignment.id),
                candidateEntity  = userJpa.getReferenceById(submission.candidate.id)
            )
        } else {
            // Update — load existing entity and mutate its mutable fields
            jpa.findById(submission.id).orElseThrow().also { e ->
                e.status         = submission.status
                e.totalScore     = submission.totalScore
                e.verdict        = submission.verdict
                e.verdictComment = submission.verdictComment
                e.aiReview       = submission.aiReview
                e.completedAt    = submission.completedAt
            }
        }
        return jpa.save(entity).toDomain()
    }

    override fun countByCandidateId(candidateId: Long): Int =
        jpa.countByCandidateId(candidateId)

    override fun findBestScoreByCandidateId(candidateId: Long): Double? =
        jpa.findBestScoreByCandidateId(candidateId)

    override fun countByDay(from: Instant): List<Pair<String, Int>> =
        jpa.countByDay(from).map { row -> row[0].toString() to (row[1] as Long).toInt() }
}
