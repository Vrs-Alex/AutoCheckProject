package com.team.auth_check.infrastructure.persistence

import com.team.auth_check.infrastructure.persistence.entity.SubmissionEntity
import org.springframework.data.domain.Pageable
import org.springframework.data.jpa.repository.JpaRepository
import org.springframework.data.jpa.repository.Query
import org.springframework.stereotype.Repository

@Repository
interface SubmissionJpaRepository : JpaRepository<SubmissionEntity, Long> {

    fun findAllByOrderByCreatedAtDesc(pageable: Pageable): List<SubmissionEntity>

    fun findByCandidateIdOrderByCreatedAtDesc(candidateId: Long): List<SubmissionEntity>

    fun findByAssignmentIdOrderByCreatedAtDesc(assignmentId: Long): List<SubmissionEntity>

    fun countByCandidateId(candidateId: Long): Int

    @Query("SELECT MAX(s.totalScore) FROM SubmissionEntity s WHERE s.candidate.id = :candidateId AND s.totalScore IS NOT NULL")
    fun findBestScoreByCandidateId(candidateId: Long): Double?

    @Query("""
        SELECT CAST(s.createdAt AS date), COUNT(s)
        FROM SubmissionEntity s
        WHERE s.createdAt >= :from
        GROUP BY CAST(s.createdAt AS date)
        ORDER BY CAST(s.createdAt AS date)
    """)
    fun countByDay(from: java.time.Instant): List<Array<Any>>
}
