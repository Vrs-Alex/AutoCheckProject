package com.team.auth_check.infrastructure.persistence

import com.team.auth_check.infrastructure.persistence.entity.AssignmentEntity
import org.springframework.data.jpa.repository.JpaRepository
import org.springframework.stereotype.Repository

@Repository
interface AssignmentJpaRepository : JpaRepository<AssignmentEntity, Long> {

    fun findAllByOrderByCreatedAtDesc(): List<AssignmentEntity>
}
