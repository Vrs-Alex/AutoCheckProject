package com.team.auth_check.infrastructure.persistence

import com.team.auth_check.domain.model.UserRole
import com.team.auth_check.infrastructure.persistence.entity.UserEntity
import org.springframework.data.jpa.repository.JpaRepository
import org.springframework.stereotype.Repository
import java.util.Optional

@Repository
interface UserJpaRepository : JpaRepository<UserEntity, Long> {

    fun findByEmail(email: String): Optional<UserEntity>

    fun existsByEmail(email: String): Boolean

    fun findAllByRole(role: UserRole): List<UserEntity>
}
