package com.team.auth_check.infrastructure.persistence.mapper

import com.team.auth_check.domain.model.Submission
import com.team.auth_check.infrastructure.persistence.entity.AssignmentEntity
import com.team.auth_check.infrastructure.persistence.entity.SubmissionEntity
import com.team.auth_check.infrastructure.persistence.entity.UserEntity

fun SubmissionEntity.toDomain(): Submission = Submission(
    id             = id,
    assignment     = assignment.toDomain(),
    candidate      = candidate.toDomain(),
    filePath       = filePath,
    gitUrl         = gitUrl,
    status         = status,
    totalScore     = totalScore,
    verdict        = verdict,
    verdictComment = verdictComment,
    aiReview       = aiReview,
    createdAt      = createdAt,
    completedAt    = completedAt
)

/**
 * For CREATE: pass managed [assignmentEntity] and [candidateEntity] loaded via getReferenceById().
 * For UPDATE: load existing entity and mutate it directly — do NOT use this function.
 */
fun Submission.toNewEntity(
    assignmentEntity: AssignmentEntity,
    candidateEntity: UserEntity
): SubmissionEntity = SubmissionEntity(
    assignment     = assignmentEntity,
    candidate      = candidateEntity,
    filePath       = filePath,
    gitUrl         = gitUrl,
    status         = status,
    totalScore     = totalScore,
    verdict        = verdict,
    verdictComment = verdictComment,
    aiReview       = aiReview,
    createdAt      = createdAt,
    completedAt    = completedAt
)
