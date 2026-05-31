package com.team.auth_check.infrastructure.persistence.impl

import com.team.auth_check.domain.model.Assignment
import com.team.auth_check.domain.repository.AssignmentRepository
import com.team.auth_check.infrastructure.persistence.AssignmentJpaRepository
import com.team.auth_check.infrastructure.persistence.UserJpaRepository
import com.team.auth_check.infrastructure.persistence.mapper.toDomain
import com.team.auth_check.infrastructure.persistence.mapper.toEntity
import org.springframework.stereotype.Repository

@Repository
class AssignmentRepositoryImpl(
    private val jpa: AssignmentJpaRepository,
    private val userJpa: UserJpaRepository
) : AssignmentRepository {

    override fun findById(id: Long): Assignment? =
        jpa.findById(id).orElse(null)?.toDomain()

    override fun findAllOrderByCreatedAtDesc(): List<Assignment> =
        jpa.findAllByOrderByCreatedAtDesc().map { it.toDomain() }

    override fun save(assignment: Assignment): Assignment {
        // getReferenceById creates a JPA proxy — avoids loading the full entity just for FK
        val createdByEntity = userJpa.getReferenceById(assignment.createdBy.id)
        return jpa.save(assignment.toEntity(createdByEntity)).toDomain()
    }

    override fun existsById(id: Long): Boolean = jpa.existsById(id)

    override fun deleteById(id: Long) = jpa.deleteById(id)
}
