package com.team.auth_check.infrastructure.persistence.entity

import com.team.auth_check.domain.model.SubmissionStatus
import com.team.auth_check.domain.model.Verdict
import jakarta.persistence.*
import java.time.Instant

/** JPA entity that maps to the "submissions" table. Use SubmissionMapper to convert to/from domain. */
@Entity
@Table(name = "submissions")
class SubmissionEntity(
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    val id: Long = 0,

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "assignment_id", nullable = false)
    val assignment: AssignmentEntity,

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "candidate_id", nullable = false)
    val candidate: UserEntity,

    val filePath: String?,

    val gitUrl: String?,

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    var status: SubmissionStatus = SubmissionStatus.PENDING,

    @Column(columnDefinition = "numeric(5,2)")
    var totalScore: Double?,

    @Enumerated(EnumType.STRING)
    var verdict: Verdict?,

    var verdictComment: String?,

    @Column(columnDefinition = "TEXT")
    var aiReview: String?,

    @Column(nullable = false)
    val createdAt: Instant = Instant.now(),

    var completedAt: Instant?
)
