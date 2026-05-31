package com.team.auth_check.application.service

import com.team.auth_check.application.dto.*
import com.team.auth_check.domain.model.User
import com.team.auth_check.domain.model.UserRole
import com.team.auth_check.domain.repository.UserRepository
import com.team.auth_check.infrastructure.security.JwtService
import org.slf4j.LoggerFactory
import org.springframework.security.authentication.AuthenticationManager
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken
import org.springframework.security.crypto.password.PasswordEncoder
import org.springframework.stereotype.Service
import org.springframework.transaction.annotation.Transactional

@Service
class AuthService(
    private val userRepository: UserRepository,
    private val jwtService: JwtService,
    private val passwordEncoder: PasswordEncoder,
    private val authManager: AuthenticationManager
) {

    private val log = LoggerFactory.getLogger(javaClass)

    @Transactional
    fun register(req: RegisterRequest): TokenResponse {
        log.info("Register attempt email={} role={}", req.email, req.role)
        if (userRepository.existsByEmail(req.email)) {
            throw IllegalArgumentException("Email уже зарегистрирован")
        }
        val role = runCatching { UserRole.valueOf(req.role.uppercase()) }
            .getOrElse { throw IllegalArgumentException("Роль должна быть EXPERT или CANDIDATE") }

        val user = User(
            email        = req.email,
            passwordHash = passwordEncoder.encode(req.password),
            fullName     = req.fullName,
            role         = role
        )
        userRepository.save(user)
        log.info("User registered email={}", user.email)
        return buildTokenResponse(user.email)
    }

    fun login(req: LoginRequest): TokenResponse {
        log.info("Login attempt email={}", req.email)
        authManager.authenticate(UsernamePasswordAuthenticationToken(req.email, req.password))
        log.info("Login successful email={}", req.email)
        return buildTokenResponse(req.email)
    }

    fun logout(token: String) {
        jwtService.revoke(token)
        log.info("Token revoked on logout")
    }

    @Transactional(readOnly = true)
    fun getProfile(email: String): UserProfileDto {
        val user = userRepository.findByEmail(email)
            ?: throw NoSuchElementException("Пользователь не найден")
        return UserProfileDto(user.id, user.email, user.fullName, user.role.name)
    }

    @Transactional(readOnly = true)
    fun findByEmail(email: String): User =
        userRepository.findByEmail(email)
            ?: throw NoSuchElementException("Пользователь не найден: $email")

    private fun buildTokenResponse(email: String): TokenResponse {
        val token = jwtService.generateToken(email)
        return TokenResponse(token, jwtService.extractExpiry(token).time - System.currentTimeMillis())
    }
}
