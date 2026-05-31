package com.team.auth_check.infrastructure.persistence

import com.team.auth_check.domain.model.CheckerType
import com.team.auth_check.infrastructure.persistence.entity.CheckResultEntity
import org.springframework.data.jpa.repository.JpaRepository
import org.springframework.stereotype.Repository

@Repository
interface CheckResultJpaRepository : JpaRepository<CheckResultEntity, Long> {

    fun findBySubmissionId(submissionId: Long): List<CheckResultEntity>

    fun findBySubmissionIdAndCheckerType(submissionId: Long, checkerType: CheckerType): CheckResultEntity?
}
