package com.team.auth_check.infrastructure.security

import jakarta.servlet.FilterChain
import jakarta.servlet.http.HttpServletRequest
import jakarta.servlet.http.HttpServletResponse
import org.slf4j.LoggerFactory
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken
import org.springframework.security.core.context.SecurityContextHolder
import org.springframework.security.web.authentication.WebAuthenticationDetailsSource
import org.springframework.stereotype.Component
import org.springframework.web.filter.OncePerRequestFilter

/**
 * Intercepts every request, extracts the Bearer token from Authorization header,
 * validates it via JwtService and sets the SecurityContext so Spring Security
 * treats the request as authenticated.
 */
@Component
class JwtAuthFilter(
    private val jwtService: JwtService,
    private val userDetailsService: UserDetailsServiceImpl
) : OncePerRequestFilter() {

    private val log = LoggerFactory.getLogger(javaClass)

    override fun doFilterInternal(
        request: HttpServletRequest,
        response: HttpServletResponse,
        chain: FilterChain
    ) {
        val authHeader = request.getHeader("Authorization")

        // Skip if there's no Bearer token
        if (authHeader == null || !authHeader.startsWith("Bearer ")) {
            chain.doFilter(request, response)
            return
        }

        val token = authHeader.removePrefix("Bearer ").trim()

        if (!jwtService.isValid(token)) {
            log.debug("Invalid or expired JWT on {}", request.requestURI)
            chain.doFilter(request, response)
            return
        }

        // Token is valid — build authentication and populate SecurityContext
        val email = jwtService.extractEmail(token)
        if (SecurityContextHolder.getContext().authentication == null) {
            val userDetails = userDetailsService.loadUserByUsername(email)
            val auth = UsernamePasswordAuthenticationToken(
                userDetails, null, userDetails.authorities
            ).also { it.details = WebAuthenticationDetailsSource().buildDetails(request) }
            SecurityContextHolder.getContext().authentication = auth
            log.debug("Authenticated user={} path={}", email, request.requestURI)
        }

        chain.doFilter(request, response)
    }
}
