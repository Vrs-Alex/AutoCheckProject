package com.team.auth_check.presentation.controller

import com.team.auth_check.application.dto.ApiResponse
import com.team.auth_check.application.dto.CandidateDto
import com.team.auth_check.application.service.CandidateService
import io.swagger.v3.oas.annotations.Operation
import io.swagger.v3.oas.annotations.security.SecurityRequirement
import io.swagger.v3.oas.annotations.tags.Tag
import org.slf4j.LoggerFactory
import org.springframework.http.ResponseEntity
import org.springframework.web.bind.annotation.*

@Tag(name = "Candidates", description = "Список кандидатов — только EXPERT")
@SecurityRequirement(name = "bearerAuth")
@RestController
@RequestMapping("/api/v1/candidates")
class CandidateController(private val candidateService: CandidateService) {

    private val log = LoggerFactory.getLogger(javaClass)

    @Operation(summary = "Список всех кандидатов")
    @GetMapping
    fun list(): ResponseEntity<ApiResponse<List<CandidateDto>>> {
        log.debug("GET /candidates")
        return ResponseEntity.ok(ApiResponse(data = candidateService.list()))
    }

    @Operation(summary = "Кандидат по ID")
    @GetMapping("/{id}")
    fun getById(@PathVariable id: Long): ResponseEntity<ApiResponse<CandidateDto>> {
        log.debug("GET /candidates/{}", id)
        return ResponseEntity.ok(ApiResponse(data = candidateService.getById(id)))
    }
}
