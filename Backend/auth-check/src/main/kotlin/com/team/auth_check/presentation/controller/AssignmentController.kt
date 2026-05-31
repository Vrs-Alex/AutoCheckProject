package com.team.auth_check.presentation.controller

import com.team.auth_check.application.dto.ApiResponse
import com.team.auth_check.application.dto.AssignmentDto
import com.team.auth_check.application.dto.CreateAssignmentRequest
import com.team.auth_check.application.service.AssignmentService
import io.swagger.v3.oas.annotations.Operation
import io.swagger.v3.oas.annotations.security.SecurityRequirement
import io.swagger.v3.oas.annotations.tags.Tag
import jakarta.validation.Valid
import org.slf4j.LoggerFactory
import org.springframework.http.HttpStatus
import org.springframework.http.ResponseEntity
import org.springframework.security.core.annotation.AuthenticationPrincipal
import org.springframework.security.core.userdetails.UserDetails
import org.springframework.web.bind.annotation.*

@Tag(name = "Assignments", description = "CRUD тестовых заданий")
@SecurityRequirement(name = "bearerAuth")
@RestController
@RequestMapping("/api/v1/assignments")
class AssignmentController(private val assignmentService: AssignmentService) {

    private val log = LoggerFactory.getLogger(javaClass)

    @Operation(summary = "Список всех тестовых заданий")
    @GetMapping
    fun list(): ResponseEntity<ApiResponse<List<AssignmentDto>>> {
        log.debug("GET /assignments")
        return ResponseEntity.ok(ApiResponse(data = assignmentService.list()))
    }

    @Operation(summary = "Создать задание — только EXPERT")
    @PostMapping
    fun create(
        @Valid @RequestBody req: CreateAssignmentRequest,
        @AuthenticationPrincipal principal: UserDetails
    ): ResponseEntity<ApiResponse<AssignmentDto>> {
        log.info("POST /assignments title='{}' expert={}", req.title, principal.username)
        return ResponseEntity.status(HttpStatus.CREATED)
            .body(ApiResponse(data = assignmentService.create(req, principal.username)))
    }

    @Operation(summary = "Задание по ID")
    @GetMapping("/{id}")
    fun getById(@PathVariable id: Long): ResponseEntity<ApiResponse<AssignmentDto>> {
        log.debug("GET /assignments/{}", id)
        return ResponseEntity.ok(ApiResponse(data = assignmentService.getById(id)))
    }

    @Operation(summary = "Редактировать задание — только EXPERT")
    @PutMapping("/{id}")
    fun update(
        @PathVariable id: Long,
        @Valid @RequestBody req: CreateAssignmentRequest
    ): ResponseEntity<ApiResponse<AssignmentDto>> {
        log.info("PUT /assignments/{}", id)
        return ResponseEntity.ok(ApiResponse(data = assignmentService.update(id, req)))
    }

    @Operation(summary = "Удалить задание — только EXPERT")
    @DeleteMapping("/{id}")
    fun delete(@PathVariable id: Long): ResponseEntity<ApiResponse<Nothing>> {
        log.info("DELETE /assignments/{}", id)
        assignmentService.delete(id)
        return ResponseEntity.ok(ApiResponse())
    }
}
