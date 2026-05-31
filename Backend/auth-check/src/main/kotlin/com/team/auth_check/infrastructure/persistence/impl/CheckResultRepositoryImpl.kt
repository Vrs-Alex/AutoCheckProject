package com.team.auth_check.infrastructure.persistence.impl

import com.team.auth_check.domain.model.CheckResult
import com.team.auth_check.domain.model.CheckerType
import com.team.auth_check.domain.repository.CheckResultRepository
import com.team.auth_check.infrastructure.persistence.CheckResultJpaRepository
import com.team.auth_check.infrastructure.persistence.SubmissionJpaRepository
import com.team.auth_check.infrastructure.persistence.mapper.toDomain
import com.team.auth_check.infrastructure.persistence.mapper.toNewEntity
import org.springframework.stereotype.Repository

@Repository
class CheckResultRepositoryImpl(
    private val jpa: CheckResultJpaRepository,
    private val submissionJpa: SubmissionJpaRepository
) : CheckResultRepository {

    override fun findBySubmissionId(submissionId: Long): List<CheckResult> =
        jpa.findBySubmissionId(submissionId).map { it.toDomain() }

    override fun findBySubmissionIdAndCheckerType(submissionId: Long, checkerType: CheckerType): CheckResult? =
        jpa.findBySubmissionIdAndCheckerType(submissionId, checkerType)?.toDomain()

    override fun save(checkResult: CheckResult): CheckResult {
        val entity = if (checkResult.id == 0L) {
            checkResult.toNewEntity(submissionJpa.getReferenceById(checkResult.submissionId))
        } else {
            jpa.findById(checkResult.id).orElseThrow().also { e ->
                e.status     = checkResult.status
                e.score      = checkResult.score
                e.log        = checkResult.log
                e.finishedAt = checkResult.finishedAt
            }
        }
        return jpa.save(entity).toDomain()
    }
}
