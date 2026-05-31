package com.team.auth_check.domain.checker

import com.team.auth_check.application.dto.AiReviewDto
import java.nio.file.Path

/** Abstraction for AI code analysis — provider is swappable without changing orchestrator. */
interface IAnalysisProvider {
    fun analyze(codePath: Path): AiReviewDto
}
