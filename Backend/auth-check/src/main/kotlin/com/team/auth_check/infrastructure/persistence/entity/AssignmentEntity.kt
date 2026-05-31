package com.team.auth_check.infrastructure.persistence.entity

import jakarta.persistence.*
import java.time.Instant

/** JPA entity that maps to the "assignments" table. Use AssignmentMapper to convert to/from domain. */
@Entity
@Table(name = "assignments")
class AssignmentEntity(
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    val id: Long = 0,

    @Column(nullable = false)
    val title: String,

    @Column(columnDefinition = "TEXT")
    val description: String?,

    @Column(nullable = false, columnDefinition = "TEXT")
    val checkerWeights: String,

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "created_by", nullable = false)
    val createdBy: UserEntity,

    @Column(nullable = false)
    val createdAt: Instant = Instant.now(),

    @Column(nullable = false)
    var updatedAt: Instant = Instant.now()
)
