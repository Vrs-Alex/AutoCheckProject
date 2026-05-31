package com.team.auth_check.infrastructure.config

import org.springframework.boot.context.properties.ConfigurationProperties
import org.springframework.boot.context.properties.EnableConfigurationProperties
import org.springframework.context.annotation.Configuration

@ConfigurationProperties(prefix = "app.jwt")
data class JwtProperties(
    val secret: String,
    val expirationMs: Long = 259200000
)

@ConfigurationProperties(prefix = "app.ai")
data class AiProperties(
    val apiKey: String = "",
    val baseUrl: String = "https://api.openai.com"
)

@Configuration
@EnableConfigurationProperties(JwtProperties::class, AiProperties::class)
class AppConfig
