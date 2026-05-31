package com.team.auth_check.domain.repository

import com.team.auth_check.domain.model.CheckResult
import com.team.auth_check.domain.model.CheckerType

interface CheckResultRepository {
    fun findBySubmissionId(submissionId: Long): List<CheckResult>
    fun findBySubmissionIdAndCheckerType(submissionId: Long, checkerType: CheckerType): CheckResult?
    fun save(checkResult: CheckResult): CheckResult
}
