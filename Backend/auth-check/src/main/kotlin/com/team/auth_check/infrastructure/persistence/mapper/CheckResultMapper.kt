package com.team.auth_check.infrastructure.persistence.mapper

import com.team.auth_check.domain.model.CheckResult
import com.team.auth_check.infrastructure.persistence.entity.CheckResultEntity
import com.team.auth_check.infrastructure.persistence.entity.SubmissionEntity

fun CheckResultEntity.toDomain(): CheckResult = CheckResult(
    id          = id,
    submissionId = submission.id,
    checkerType = checkerType,
    status      = status,
    score       = score,
    log         = log,
    startedAt   = startedAt,
    finishedAt  = finishedAt
)

/** [submissionEntity] must be a JPA-managed SubmissionEntity. */
fun CheckResult.toNewEntity(submissionEntity: SubmissionEntity): CheckResultEntity = CheckResultEntity(
    submission  = submissionEntity,
    checkerType = checkerType,
    status      = status,
    score       = score,
    log         = log,
    startedAt   = startedAt,
    finishedAt  = finishedAt
)
