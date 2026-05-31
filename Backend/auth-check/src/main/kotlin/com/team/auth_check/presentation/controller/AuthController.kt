package com.team.auth_check.presentation.controller

import com.team.auth_check.application.dto.ApiResponse
import com.team.auth_check.application.dto.LoginRequest
import com.team.auth_check.application.dto.RegisterRequest
import com.team.auth_check.application.dto.TokenResponse
import com.team.auth_check.application.dto.UserProfileDto
import com.team.auth_check.application.service.AuthService
import io.swagger.v3.oas.annotations.Operation
import io.swagger.v3.oas.annotations.security.SecurityRequirement
import io.swagger.v3.oas.annotations.tags.Tag
import jakarta.servlet.http.HttpServletRequest
import jakarta.validation.Valid
import org.slf4j.LoggerFactory
import org.springframework.http.HttpStatus
import org.springframework.http.ResponseEntity
import org.springframework.security.core.annotation.AuthenticationPrincipal
import org.springframework.security.core.userdetails.UserDetails
import org.springframework.web.bind.annotation.*

@Tag(name = "Auth", description = "Регистрация, вход, выход и профиль")
@RestController
@RequestMapping("/api/v1/auth")
class AuthController(private val authService: AuthService) {

    private val log = LoggerFactory.getLogger(javaClass)

    @Operation(summary = "Вход в систему", description = "Возвращает JWT Bearer-токен")
    @PostMapping("/login")
    fun login(@Valid @RequestBody req: LoginRequest): ResponseEntity<ApiResponse<TokenResponse>> {
        log.info("POST /auth/login email={}", req.email)
        return ResponseEntity.ok(ApiResponse(data = authService.login(req)))
    }

    @Operation(summary = "Регистрация нового пользователя")
    @PostMapping("/register")
    fun register(@Valid @RequestBody req: RegisterRequest): ResponseEntity<ApiResponse<TokenResponse>> {
        log.info("POST /auth/register email={}", req.email)
        return ResponseEntity.status(HttpStatus.CREATED).body(ApiResponse(data = authService.register(req)))
    }

    @Operation(summary = "Выход — токен инвалидируется в Redis")
    @SecurityRequirement(name = "bearerAuth")
    @PostMapping("/logout")
    fun logout(request: HttpServletRequest): ResponseEntity<ApiResponse<Nothing>> {
        val token = request.getHeader("Authorization")?.removePrefix("Bearer ")?.trim() ?: ""
        authService.logout(token)
        log.info("POST /auth/logout — token revoked")
        return ResponseEntity.ok(ApiResponse())
    }

    @Operation(summary = "Профиль текущего пользователя")
    @SecurityRequirement(name = "bearerAuth")
    @GetMapping("/profile")
    fun profile(@AuthenticationPrincipal principal: UserDetails): ResponseEntity<ApiResponse<UserProfileDto>> {
        log.debug("GET /auth/profile user={}", principal.username)
        return ResponseEntity.ok(ApiResponse(data = authService.getProfile(principal.username)))
    }
}
