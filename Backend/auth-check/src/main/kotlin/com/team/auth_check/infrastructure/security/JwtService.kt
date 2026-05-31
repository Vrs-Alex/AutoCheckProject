package com.team.auth_check.infrastructure.security

import com.team.auth_check.infrastructure.config.JwtProperties
import io.jsonwebtoken.JwtException
import io.jsonwebtoken.Jwts
import io.jsonwebtoken.security.Keys
import org.slf4j.LoggerFactory
import org.springframework.data.redis.core.StringRedisTemplate
import org.springframework.stereotype.Service
import java.util.Date
import java.util.concurrent.TimeUnit
import javax.crypto.SecretKey

/** Generates, validates and revokes JWT tokens. Revoked tokens are stored in Redis. */
@Service
class JwtService(
    private val jwtProps: JwtProperties,
    private val redis: StringRedisTemplate
) {

    private val log = LoggerFactory.getLogger(javaClass)

    // Derived from the configured secret — evaluated once at startup
    private val signingKey: SecretKey by lazy {
        Keys.hmacShaKeyFor(jwtProps.secret.toByteArray(Charsets.UTF_8))
    }

    private val blacklistPrefix = "jwt:blacklist:"

    /** Generate a signed JWT containing the user email as subject. */
    fun generateToken(email: String): String {
        val now = Date()
        val expiry = Date(now.time + jwtProps.expirationMs)
        log.debug("Generating token for {} exp={}", email, expiry)
        return Jwts.builder()
            .subject(email)
            .issuedAt(now)
            .expiration(expiry)
            .signWith(signingKey)
            .compact()
    }

    /** Extract email (subject) from a valid token. Throws JwtException if invalid. */
    fun extractEmail(token: String): String =
        parseClaims(token).subject

    /** Extract expiry date from token (used when blacklisting on logout). */
    fun extractExpiry(token: String): Date =
        parseClaims(token).expiration

    /**
     * Returns true if the token is:
     * 1. Cryptographically valid (correct signature, not expired)
     * 2. NOT in the Redis blacklist (i.e. not logged out)
     */
    fun isValid(token: String): Boolean {
        return try {
            parseClaims(token) // throws on invalid/expired
            !isBlacklisted(token)
        } catch (e: JwtException) {
            log.debug("Invalid token: {}", e.message)
            false
        } catch (e: Exception) {
            log.error("Token validation error", e)
            false
        }
    }

    /**
     * Blacklist a token until its natural expiry so that logout takes immediate effect.
     * Redis TTL is set to the remaining lifetime of the token.
     */
    fun revoke(token: String) {
        val ttlMs = extractExpiry(token).time - System.currentTimeMillis()
        if (ttlMs > 0) {
            redis.opsForValue().set(
                "$blacklistPrefix$token",
                "1",
                ttlMs,
                TimeUnit.MILLISECONDS
            )
            log.info("Token revoked, TTL={}ms", ttlMs)
        }
    }

    // ── Internal helpers ────────────────────────────────────────────────────────

    private fun parseClaims(token: String) =
        Jwts.parser()
            .verifyWith(signingKey)
            .build()
            .parseSignedClaims(token)
            .payload

    private fun isBlacklisted(token: String): Boolean =
        redis.hasKey("$blacklistPrefix$token") == true
}
