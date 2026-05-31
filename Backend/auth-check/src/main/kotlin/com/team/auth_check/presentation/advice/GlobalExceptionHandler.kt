package com.team.auth_check.presentation.advice

import com.team.auth_check.application.dto.ApiError
import com.team.auth_check.application.dto.ApiResponse
import org.slf4j.LoggerFactory
import org.springframework.dao.DataIntegrityViolationException
import org.springframework.http.HttpStatus
import org.springframework.http.ResponseEntity
import org.springframework.http.converter.HttpMessageNotReadableException
import org.springframework.security.access.AccessDeniedException
import org.springframework.security.core.AuthenticationException
import org.springframework.validation.FieldError
import org.springframework.web.bind.MethodArgumentNotValidException
import org.springframework.web.bind.annotation.ExceptionHandler
import org.springframework.web.bind.annotation.RestControllerAdvice

/**
 * Centralized error handler — all exceptions pass through here.
 * Returns [ApiResponse] with error field populated, data is null (omitted by NON_NULL Jackson).
 */
@RestControllerAdvice
class GlobalExceptionHandler {

    private val log = LoggerFactory.getLogger(javaClass)

    private fun err(code: String, message: String, details: Map<String, String>? = null) =
        ApiResponse<Nothing>(error = ApiError(code, message, details))

    /** 422 — validation failed on @Valid fields */
    @ExceptionHandler(MethodArgumentNotValidException::class)
    fun handleValidation(ex: MethodArgumentNotValidException): ResponseEntity<ApiResponse<Nothing>> {
        val details = ex.bindingResult.allErrors.associate { e ->
            (e as FieldError).field to (e.defaultMessage ?: "invalid")
        }
        log.debug("Validation failed: {}", details)
        return ResponseEntity
            .status(HttpStatus.UNPROCESSABLE_ENTITY)
            .body(err("VALIDATION_ERROR", "Ошибка валидации", details))
    }

    /** 400 — malformed JSON body or missing required field */
    @ExceptionHandler(HttpMessageNotReadableException::class)
    fun handleNotReadable(ex: HttpMessageNotReadableException): ResponseEntity<ApiResponse<Nothing>> {
        log.debug("Unreadable request body: {}", ex.message)
        return ResponseEntity
            .status(HttpStatus.BAD_REQUEST)
            .body(err("BAD_REQUEST", "Некорректное тело запроса"))
    }

    /** 400 — bad request (missing file/gitUrl, invalid argument, weights sum ≠ 100, etc.) */
    @ExceptionHandler(IllegalArgumentException::class)
    fun handleBadRequest(ex: IllegalArgumentException): ResponseEntity<ApiResponse<Nothing>> {
        log.debug("Bad request: {}", ex.message)
        return ResponseEntity
            .status(HttpStatus.BAD_REQUEST)
            .body(err("BAD_REQUEST", ex.message ?: "Некорректный запрос"))
    }

    /** 409 — FK constraint: e.g. deleting assignment that has submissions */
    @ExceptionHandler(DataIntegrityViolationException::class)
    fun handleDataIntegrity(ex: DataIntegrityViolationException): ResponseEntity<ApiResponse<Nothing>> {
        log.debug("Data integrity violation: {}", ex.message)
        return ResponseEntity
            .status(HttpStatus.CONFLICT)
            .body(err("CONFLICT", "Операция нарушает целостность данных"))
    }

    /** 401 — authentication error from Spring Security */
    @ExceptionHandler(AuthenticationException::class)
    fun handleAuth(ex: AuthenticationException): ResponseEntity<ApiResponse<Nothing>> {
        log.debug("Auth error: {}", ex.message)
        return ResponseEntity
            .status(HttpStatus.UNAUTHORIZED)
            .body(err("UNAUTHORIZED", ex.message ?: "Не авторизован"))
    }

    /** 403 — authenticated but missing permission */
    @ExceptionHandler(AccessDeniedException::class)
    fun handleAccess(ex: AccessDeniedException): ResponseEntity<ApiResponse<Nothing>> {
        log.debug("Access denied: {}", ex.message)
        return ResponseEntity
            .status(HttpStatus.FORBIDDEN)
            .body(err("FORBIDDEN", "Нет прав доступа"))
    }

    /** 404 — resource not found */
    @ExceptionHandler(NoSuchElementException::class)
    fun handleNotFound(ex: NoSuchElementException): ResponseEntity<ApiResponse<Nothing>> {
        log.debug("Not found: {}", ex.message)
        return ResponseEntity
            .status(HttpStatus.NOT_FOUND)
            .body(err("NOT_FOUND", ex.message ?: "Не найдено"))
    }

    /** 500 — unexpected server error */
    @ExceptionHandler(Exception::class)
    fun handleGeneric(ex: Exception): ResponseEntity<ApiResponse<Nothing>> {
        log.error("Unexpected error", ex)
        return ResponseEntity
            .status(HttpStatus.INTERNAL_SERVER_ERROR)
            .body(err("INTERNAL_ERROR", "Внутренняя ошибка сервера"))
    }
}
