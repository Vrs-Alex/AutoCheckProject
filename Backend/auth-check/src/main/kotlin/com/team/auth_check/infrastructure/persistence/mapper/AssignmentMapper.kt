package com.team.auth_check.infrastructure.persistence.mapper

import com.team.auth_check.domain.model.Assignment
import com.team.auth_check.infrastructure.persistence.entity.AssignmentEntity
import com.team.auth_check.infrastructure.persistence.entity.UserEntity

fun AssignmentEntity.toDomain(): Assignment = Assignment(
    id             = id,
    title          = title,
    description    = description,
    checkerWeights = checkerWeights,
    createdBy      = createdBy.toDomain(),
    createdAt      = createdAt,
    updatedAt      = updatedAt
)

/** [createdByEntity] must be a JPA-managed UserEntity (loaded via UserJpaRepository). */
fun Assignment.toEntity(createdByEntity: UserEntity): AssignmentEntity = AssignmentEntity(
    id             = id,
    title          = title,
    description    = description,
    checkerWeights = checkerWeights,
    createdBy      = createdByEntity,
    createdAt      = createdAt,
    updatedAt      = updatedAt
)
