package com.team.auth_check.application.dto

import io.swagger.v3.oas.annotations.media.Schema
import jakarta.validation.constraints.Email
import jakarta.validation.constraints.NotBlank
import jakarta.validation.constraints.Size

data class LoginRequest(
    @field:Email(message = "Некорректный email")
    @Schema(example = "expert@company.com")
    val email: String,

    @field:NotBlank(message = "Пароль не может быть пустым")
    @Schema(example = "secret123")
    val password: String
)

data class RegisterRequest(
    @field:Email(message = "Некорректный email")
    val email: String,

    @field:NotBlank
    @field:Size(min = 6, message = "Минимум 6 символов")
    val password: String,

    @field:NotBlank(message = "ФИО обязательно")
    val fullName: String,

    @Schema(example = "CANDIDATE", allowableValues = ["EXPERT", "CANDIDATE"])
    val role: String = "CANDIDATE"
)

data class TokenResponse(
    val token: String,
    @Schema(description = "Срок действия токена в миллисекундах")
    val expiresIn: Long
)

data class UserProfileDto(
    val id: Long,
    val email: String,
    val fullName: String,
    val role: String
)
