package com.team.auth_check.infrastructure.persistence.entity

import com.team.auth_check.domain.model.UserRole
import jakarta.persistence.*
import java.time.Instant

/** JPA entity that maps to the "users" table. Use UserMapper to convert to/from domain User. */
@Entity
@Table(name = "users")
class UserEntity(
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    val id: Long = 0,

    @Column(nullable = false, unique = true)
    val email: String,

    @Column(nullable = false)
    var passwordHash: String,

    @Column(nullable = false)
    val fullName: String,

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    val role: UserRole,

    @Column(nullable = false)
    val createdAt: Instant = Instant.now()
)
