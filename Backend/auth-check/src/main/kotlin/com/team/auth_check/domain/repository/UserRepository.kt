package com.team.auth_check.domain.repository

import com.team.auth_check.domain.model.User
import com.team.auth_check.domain.model.UserRole

/** Pure domain contract — no JPA, no Spring, no framework dependencies. */
interface UserRepository {
    fun findByEmail(email: String): User?
    fun findById(id: Long): User?
    fun findAllByRole(role: UserRole): List<User>
    fun save(user: User): User
    fun existsByEmail(email: String): Boolean
}
