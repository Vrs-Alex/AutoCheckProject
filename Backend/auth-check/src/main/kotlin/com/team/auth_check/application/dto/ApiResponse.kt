package com.team.auth_check.application.dto

/** Universal API envelope: success → data field present, error → error field present. */
data class ApiResponse<T>(
    val data: T? = null,
    val error: ApiError? = null,
    val meta: Map<String, Any>? = null
)

data class ApiError(
    val code: String,
    val message: String,
    val details: Map<String, String>? = null
)
