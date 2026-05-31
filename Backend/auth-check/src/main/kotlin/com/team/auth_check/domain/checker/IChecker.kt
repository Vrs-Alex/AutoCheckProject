package com.team.auth_check.domain.checker

import com.team.auth_check.domain.model.CheckerType
import com.team.auth_check.domain.model.CheckStatus
import java.nio.file.Path

/**
 * Contract for every code checker.
 *
 * Design follows Open/Closed principle:
 * - Adding a new checker = new IChecker implementation.
 * - CheckOrchestrator never needs to change when a new checker is added.
 */
interface IChecker {

    /** Identifies this checker — maps to CheckerType enum and DB column. */
    val type: CheckerType

    /**
     * Run analysis on the candidate's code and return a result.
     * Must not throw — catch all exceptions internally and return CheckerResult with status=ERROR.
     *
     * Sprint-3 note: each implementation will run in an isolated Docker container.
     * Currently implemented as direct analysis without Docker isolation.
     *
     * @param context input data: code path, submission id, assignment id
     */
    fun check(context: CheckContext): CheckerResult
}

/** Input data passed to every checker. */
data class CheckContext(
    val submissionId: Long,
    val assignmentId: Long,
    /** Absolute path to the extracted code directory. */
    val codePath: Path
)

/** Output from a checker. */
data class CheckerResult(
    val type: CheckerType,
    val status: CheckStatus,
    /** Score 0–100. Null only on ERROR status. */
    val score: Double?,
    /** Human-readable or JSON log for the expert dashboard. */
    val log: String
)
