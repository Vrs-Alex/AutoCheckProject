package com.team.auth_check.infrastructure.persistence.entity

import com.team.auth_check.domain.model.CheckStatus
import com.team.auth_check.domain.model.CheckerType
import jakarta.persistence.*
import java.time.Instant

/** JPA entity that maps to the "check_results" table. Use CheckResultMapper to convert to/from domain. */
@Entity
@Table(name = "check_results")
class CheckResultEntity(
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    val id: Long = 0,

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "submission_id", nullable = false)
    val submission: SubmissionEntity,

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    val checkerType: CheckerType,

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    var status: CheckStatus = CheckStatus.PENDING,

    @Column(columnDefinition = "numeric(5,2)")
    var score: Double?,

    @Column(columnDefinition = "TEXT")
    var log: String?,

    val startedAt: Instant?,

    var finishedAt: Instant?
)
