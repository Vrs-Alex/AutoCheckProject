package com.team.auth_check.infrastructure.persistence.impl

import com.team.auth_check.domain.model.User
import com.team.auth_check.domain.model.UserRole
import com.team.auth_check.domain.repository.UserRepository
import com.team.auth_check.infrastructure.persistence.UserJpaRepository
import com.team.auth_check.infrastructure.persistence.mapper.toDomain
import com.team.auth_check.infrastructure.persistence.mapper.toEntity
import org.springframework.stereotype.Repository

@Repository
class UserRepositoryImpl(
    private val jpa: UserJpaRepository
) : UserRepository {

    override fun findByEmail(email: String): User? =
        jpa.findByEmail(email).orElse(null)?.toDomain()

    override fun findById(id: Long): User? =
        jpa.findById(id).orElse(null)?.toDomain()

    override fun findAllByRole(role: UserRole): List<User> =
        jpa.findAllByRole(role).map { it.toDomain() }

    override fun save(user: User): User =
        jpa.save(user.toEntity()).toDomain()

    override fun existsByEmail(email: String): Boolean =
        jpa.existsByEmail(email)
}
