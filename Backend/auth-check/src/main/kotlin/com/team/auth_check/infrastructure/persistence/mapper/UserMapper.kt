package com.team.auth_check.infrastructure.persistence.mapper

import com.team.auth_check.domain.model.User
import com.team.auth_check.infrastructure.persistence.entity.UserEntity

fun UserEntity.toDomain(): User = User(
    id           = id,
    email        = email,
    passwordHash = passwordHash,
    fullName     = fullName,
    role         = role,
    createdAt    = createdAt
)

fun User.toEntity(): UserEntity = UserEntity(
    id           = id,
    email        = email,
    passwordHash = passwordHash,
    fullName     = fullName,
    role         = role,
    createdAt    = createdAt
)
