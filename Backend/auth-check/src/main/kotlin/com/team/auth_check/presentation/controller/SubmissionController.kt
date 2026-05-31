package com.team.auth_check.presentation.controller

import com.team.auth_check.application.dto.*
import com.team.auth_check.application.service.SubmissionService
import com.team.auth_check.domain.model.UserRole
import io.swagger.v3.oas.annotations.Operation
import io.swagger.v3.oas.annotations.security.SecurityRequirement
import io.swagger.v3.oas.annotations.tags.Tag
import org.slf4j.LoggerFactory
import org.springframework.http.HttpStatus
import org.springframework.http.ResponseEntity
import org.springframework.security.core.annotation.AuthenticationPrincipal
import org.springframework.security.core.userdetails.UserDetails
import org.springframework.web.bind.annotation.*
import org.springframework.web.multipart.MultipartFile

@Tag(name = "Submissions", description = "Загрузка решений, статусы, результаты чекеров, вердикт")
@SecurityRequirement(name = "bearerAuth")
@RestController
@RequestMapping("/api/v1/submissions")
class SubmissionController(private val submissionService: SubmissionService) {

    private val log = LoggerFactory.getLogger(javaClass)

    @Operation(summary = "Загрузить решение (ZIP или Git URL)")
    @PostMapping(consumes = ["multipart/form-data"])
    fun submit(
        @RequestPart(required = false) file: MultipartFile?,
        @RequestPart(required = false) gitUrl: String?,
        @RequestPart assignmentId: String,
        @RequestPart(required = false) candidateEmail: String?,
        @RequestPart(required = false) candidateFullName: String?,
        @AuthenticationPrincipal principal: UserDetails
    ): ResponseEntity<ApiResponse<SubmissionDto>> {
        log.info("POST /submissions assignmentId={} caller={}", assignmentId, principal.username)
        val role = resolveRole(principal)
        return ResponseEntity.status(HttpStatus.CREATED).body(
            ApiResponse(data = submissionService.submit(
                assignmentId = assignmentId.toLong(),
                file = file,
                gitUrl = gitUrl,
                callerEmail = principal.username,
                callerRole = role,
                candidateEmail = candidateEmail,
                candidateFullName = candidateFullName
            ))
        )
    }

    @Operation(summary = "Список проверок (EXPERT — все, CANDIDATE — только свои)")
    @GetMapping
    fun list(
        @RequestParam(required = false) assignmentId: Long?,
        @AuthenticationPrincipal principal: UserDetails
    ): ResponseEntity<ApiResponse<List<SubmissionDto>>> {
        log.debug("GET /submissions caller={}", principal.username)
        return ResponseEntity.ok(ApiResponse(data = submissionService.list(principal.username, resolveRole(principal), assignmentId)))
    }

    @Operation(summary = "Проверка по ID")
    @GetMapping("/{id}")
    fun getById(
        @PathVariable id: Long,
        @AuthenticationPrincipal principal: UserDetails
    ): ResponseEntity<ApiResponse<SubmissionDto>> {
        log.debug("GET /submissions/{} caller={}", id, principal.username)
        return ResponseEntity.ok(ApiResponse(data = submissionService.getById(id, principal.username, resolveRole(principal))))
    }

    @Operation(summary = "Текущий статус проверки (для polling)")
    @GetMapping("/{id}/status")
    fun getStatus(@PathVariable id: Long): ResponseEntity<ApiResponse<SubmissionStatusDto>> {
        log.debug("GET /submissions/{}/status", id)
        return ResponseEntity.ok(ApiResponse(data = submissionService.getStatus(id)))
    }

    @Operation(summary = "Детальные результаты всех чекеров")
    @GetMapping("/{id}/results")
    fun getResults(@PathVariable id: Long): ResponseEntity<ApiResponse<List<CheckResultDto>>> {
        log.debug("GET /submissions/{}/results", id)
        return ResponseEntity.ok(ApiResponse(data = submissionService.getResults(id)))
    }

    @Operation(summary = "Повторный запуск проверки — только EXPERT")
    @PostMapping("/{id}/rerun")
    fun rerun(@PathVariable id: Long): ResponseEntity<ApiResponse<SubmissionDto>> {
        log.info("POST /submissions/{}/rerun", id)
        return ResponseEntity.ok(ApiResponse(data = submissionService.rerun(id)))
    }

    @Operation(summary = "Вынести вердикт ACCEPTED/REJECTED — только EXPERT")
    @PutMapping("/{id}/verdict")
    fun verdict(
        @PathVariable id: Long,
        @RequestBody req: VerdictRequest
    ): ResponseEntity<ApiResponse<SubmissionDto>> {
        log.info("PUT /submissions/{}/verdict verdict={}", id, req.verdict)
        return ResponseEntity.ok(ApiResponse(data = submissionService.setVerdict(id, req)))
    }

    @Operation(summary = "JSON-отчёт по проверке")
    @GetMapping("/{id}/report")
    fun report(
        @PathVariable id: Long,
        @AuthenticationPrincipal principal: UserDetails
    ): ResponseEntity<ApiResponse<SubmissionDto>> {
        log.debug("GET /submissions/{}/report", id)
        return ResponseEntity.ok(ApiResponse(data = submissionService.getById(id, principal.username, resolveRole(principal))))
    }

    @Operation(summary = "AI-анализ кода (Sprint-4)")
    @GetMapping("/{id}/ai-review")
    fun aiReview(@PathVariable id: Long): ResponseEntity<ApiResponse<AiReviewDto>> {
        log.debug("GET /submissions/{}/ai-review", id)
        return ResponseEntity.ok(ApiResponse(data = submissionService.getAiReview(id)))
    }

    private fun resolveRole(principal: UserDetails) =
        if (principal.authorities.any { it.authority == "ROLE_EXPERT" }) UserRole.EXPERT
        else UserRole.CANDIDATE
}
