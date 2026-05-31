package com.team.auth_check.presentation.controller

import com.team.auth_check.application.dto.ApiResponse
import com.team.auth_check.application.dto.StatsDto
import com.team.auth_check.application.service.ReportService
import io.swagger.v3.oas.annotations.Operation
import io.swagger.v3.oas.annotations.security.SecurityRequirement
import io.swagger.v3.oas.annotations.tags.Tag
import org.slf4j.LoggerFactory
import org.springframework.http.ResponseEntity
import org.springframework.web.bind.annotation.GetMapping
import org.springframework.web.bind.annotation.RequestMapping
import org.springframework.web.bind.annotation.RestController

@Tag(name = "Reports", description = "Статистика платформы — только EXPERT")
@SecurityRequirement(name = "bearerAuth")
@RestController
@RequestMapping("/api/v1/reports")
class ReportController(private val reportService: ReportService) {

    private val log = LoggerFactory.getLogger(javaClass)

    @Operation(summary = "Агрегированная статистика")
    @GetMapping("/stats")
    fun stats(): ResponseEntity<ApiResponse<StatsDto>> {
        log.debug("GET /reports/stats")
        return ResponseEntity.ok(ApiResponse(data = reportService.getStats()))
    }
}
