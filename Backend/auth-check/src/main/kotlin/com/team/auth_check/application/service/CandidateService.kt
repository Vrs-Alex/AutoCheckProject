package com.team.auth_check.application.service

import com.team.auth_check.application.dto.CandidateDto
import com.team.auth_check.domain.model.UserRole
import com.team.auth_check.domain.repository.SubmissionRepository
import com.team.auth_check.domain.repository.UserRepository
import org.slf4j.LoggerFactory
import org.springframework.security.access.prepost.PreAuthorize
import org.springframework.stereotype.Service
import org.springframework.transaction.annotation.Transactional

@Service
class CandidateService(
    private val userRepository: UserRepository,
    private val submissionRepository: SubmissionRepository
) {

    private val log = LoggerFactory.getLogger(javaClass)

    @Transactional(readOnly = true)
    @PreAuthorize("hasRole('EXPERT')")
    fun list(): List<CandidateDto> {
        log.debug("Fetching all candidates")
        return userRepository.findAllByRole(UserRole.CANDIDATE).map { user ->
            CandidateDto(
                id               = user.id,
                email            = user.email,
                fullName         = user.fullName,
                submissionsCount = submissionRepository.countByCandidateId(user.id),
                bestScore        = submissionRepository.findBestScoreByCandidateId(user.id)
            )
        }
    }

    @Transactional(readOnly = true)
    @PreAuthorize("hasRole('EXPERT')")
    fun getById(id: Long): CandidateDto {
        log.debug("Fetching candidate id={}", id)
        val user = userRepository.findById(id)?.takeIf { it.role == UserRole.CANDIDATE }
            ?: throw NoSuchElementException("Кандидат $id не найден")
        return CandidateDto(
            id               = user.id,
            email            = user.email,
            fullName         = user.fullName,
            submissionsCount = submissionRepository.countByCandidateId(user.id),
            bestScore        = submissionRepository.findBestScoreByCandidateId(user.id)
        )
    }
}
