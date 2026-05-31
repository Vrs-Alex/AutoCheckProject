package com.team.auth_check.presentation.advice

// Replaced by ApiError inside ApiResponse — kept for compile compatibility during transition.
@Deprecated("Use ApiResponse(error = ApiError(...)) instead")
typealias ErrorResponse = com.team.auth_check.application.dto.ApiError
