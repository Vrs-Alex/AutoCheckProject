package com.team.auth_check.application.dto

import jakarta.validation.constraints.NotBlank
import jakarta.validation.constraints.NotEmpty

data class CreateAssignmentRequest(
    @field:NotBlank(message = "Название задания обязательно")
    val title: String,
    val description: String? = null,
    @field:NotEmpty(message = "Необходимо указать хотя бы один чекер")
    val checkerWeights: Map<String, Int>
)

data class AssignmentDto(
    val id: Long,
    val title: String,
    val description: String?,
    val checkerWeights: Map<String, Int>,
    val createdBy: Long,
    val createdAt: String,
    val updatedAt: String
)
