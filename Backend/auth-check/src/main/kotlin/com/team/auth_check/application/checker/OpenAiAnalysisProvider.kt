package com.team.auth_check.application.checker

import com.fasterxml.jackson.annotation.JsonIgnoreProperties
import com.fasterxml.jackson.module.kotlin.jacksonObjectMapper
import com.fasterxml.jackson.module.kotlin.readValue
import com.team.auth_check.application.dto.AiReviewDto
import com.team.auth_check.domain.checker.IAnalysisProvider
import com.team.auth_check.infrastructure.config.AiProperties
import org.slf4j.LoggerFactory
import org.springframework.stereotype.Service
import java.net.URI
import java.net.http.HttpClient
import java.net.http.HttpRequest
import java.net.http.HttpResponse
import java.nio.file.Files
import java.nio.file.Path
import java.time.Duration

/**
 * OpenAI-compatible AI code reviewer. Works with Groq, OpenAI, Ollama, or any compatible provider.
 * Swappable via IAnalysisProvider without changing orchestrator (Sprint-4 SOLID requirement).
 */
@Service
class OpenAiAnalysisProvider(
    private val aiProperties: AiProperties
) : IAnalysisProvider {

    private val log = LoggerFactory.getLogger(javaClass)
    private val jackson = jacksonObjectMapper()
    private val http = HttpClient.newBuilder().connectTimeout(Duration.ofSeconds(10)).build()

    companion object {
        private const val MODEL = "meta-llama/llama-3.2-3b-instruct:free"
        private const val MAX_CODE_CHARS = 4000
    }

    override fun analyze(codePath: Path): AiReviewDto {
        if (aiProperties.apiKey.isBlank()) {
            log.debug("AI_API_KEY not set — skipping AI review")
            return AiReviewDto(available = false)
        }

        return try {
            val codeSnippet = collectCode(codePath)
            val response = callApi(codeSnippet)
            parseResponse(response)
        } catch (e: Exception) {
            log.error("AI review failed", e)
            AiReviewDto(available = false)
        }
    }

    private fun collectCode(codePath: Path): String {
        val sb = StringBuilder()
        val extensions = setOf("kt", "java", "dart", "swift")

        // README first
        val readme = codePath.resolve("README.md")
        if (Files.exists(readme)) {
            sb.appendLine("=== README.md ===")
            sb.appendLine(Files.readString(readme).take(1000))
            sb.appendLine()
        }

        // Source files
        Files.walk(codePath)
            .filter { Files.isRegularFile(it) }
            .filter { it.toString().substringAfterLast('.') in extensions }
            .filter { !it.toString().contains("build/") && !it.toString().contains(".gradle/") }
            .limit(10)
            .forEach { file ->
                if (sb.length < MAX_CODE_CHARS) {
                    sb.appendLine("=== ${codePath.relativize(file)} ===")
                    sb.appendLine(Files.readString(file).take(600))
                    sb.appendLine()
                }
            }

        return sb.toString().take(MAX_CODE_CHARS)
    }

    private fun callApi(code: String): String {
        val systemPrompt = """
            Ты — Senior Mobile Developer, проверяющий тестовое задание кандидата.
            Проанализируй предоставленный код и ответь ТОЛЬКО валидным JSON без markdown, строго в формате:
            {
              "summary": "краткая общая оценка (2-3 предложения)",
              "strengths": ["плюс 1", "плюс 2", "плюс 3"],
              "weaknesses": ["минус 1", "минус 2"],
              "recommendations": ["рекомендация 1", "рекомендация 2"]
            }
        """.trimIndent()

        val body = jackson.writeValueAsString(mapOf(
            "model" to MODEL,
            "messages" to listOf(
                mapOf("role" to "system", "content" to systemPrompt),
                mapOf("role" to "user", "content" to "Проверь этот код:\n\n$code")
            ),
            "temperature" to 0.3,
            "max_tokens" to 800
        ))

        val request = HttpRequest.newBuilder()
            .uri(URI.create("${aiProperties.baseUrl}/v1/chat/completions"))
            .header("Content-Type", "application/json")
            .header("Authorization", "Bearer ${aiProperties.apiKey}")
            .timeout(Duration.ofSeconds(30))
            .POST(HttpRequest.BodyPublishers.ofString(body))
            .build()

        log.info("Calling AI provider model={} url={}", MODEL, aiProperties.baseUrl)

        // Retry up to 3 times on 429 rate limit
        repeat(3) { attempt ->
            val response = http.send(request, HttpResponse.BodyHandlers.ofString())
            if (response.statusCode() == 200) return response.body()
            if (response.statusCode() == 429) {
                log.warn("AI rate limited attempt={} — retrying in 3s", attempt + 1)
                Thread.sleep(3000)
            } else {
                log.error("AI API error status={} body={}", response.statusCode(), response.body().take(200))
                throw RuntimeException("AI API returned ${response.statusCode()}")
            }
        }
        throw RuntimeException("AI API rate limited after 3 attempts")
    }

    private fun parseResponse(apiResponse: String): AiReviewDto {
        val root = jackson.readValue<ChatCompletionResponse>(apiResponse)
        val content = root.choices.firstOrNull()?.message?.content
            ?: return AiReviewDto(available = false)

        return try {
            // Strip possible markdown fences
            val json = content.trim()
                .removePrefix("```json").removePrefix("```")
                .removeSuffix("```").trim()

            val parsed = jackson.readValue<AiOutput>(json)
            AiReviewDto(
                available       = true,
                summary         = parsed.summary,
                strengths       = parsed.strengths,
                weaknesses      = parsed.weaknesses,
                recommendations = parsed.recommendations
            )
        } catch (e: Exception) {
            log.warn("Could not parse AI JSON response, using raw text")
            AiReviewDto(available = true, summary = content.take(1000))
        }
    }

    @JsonIgnoreProperties(ignoreUnknown = true)
    data class ChatCompletionResponse(val choices: List<Choice> = emptyList())

    @JsonIgnoreProperties(ignoreUnknown = true)
    data class Choice(val message: Message = Message())

    @JsonIgnoreProperties(ignoreUnknown = true)
    data class Message(val content: String = "")

    @JsonIgnoreProperties(ignoreUnknown = true)
    data class AiOutput(
        val summary: String? = null,
        val strengths: List<String>? = null,
        val weaknesses: List<String>? = null,
        val recommendations: List<String>? = null
    )
}
