package com.team.auth_check.application.service

import com.fasterxml.jackson.module.kotlin.jacksonObjectMapper
import com.team.auth_check.application.dto.AssignmentDto
import com.team.auth_check.application.dto.CreateAssignmentRequest
import com.team.auth_check.domain.model.Assignment
import com.team.auth_check.domain.repository.AssignmentRepository
import com.team.auth_check.domain.repository.UserRepository
import org.slf4j.LoggerFactory
import org.springframework.security.access.prepost.PreAuthorize
import org.springframework.stereotype.Service
import org.springframework.transaction.annotation.Transactional
import java.time.Instant

@Service
class AssignmentService(
    private val assignmentRepository: AssignmentRepository,
    private val userRepository: UserRepository
) {

    private val log = LoggerFactory.getLogger(javaClass)
    private val jackson = jacksonObjectMapper()

    @Transactional(readOnly = true)
    fun list(): List<AssignmentDto> {
        log.debug("Fetching all assignments")
        return assignmentRepository.findAllOrderByCreatedAtDesc().map { it.toDto() }
    }

    @Transactional(readOnly = true)
    fun getById(id: Long): AssignmentDto {
        log.debug("Fetching assignment id={}", id)
        return findOrThrow(id).toDto()
    }

    @Transactional
    @PreAuthorize("hasRole('EXPERT')")
    fun create(req: CreateAssignmentRequest, expertEmail: String): AssignmentDto {
        log.info("Creating assignment title='{}' expert={}", req.title, expertEmail)
        validateWeights(req.checkerWeights)
        val expert = userRepository.findByEmail(expertEmail)
            ?: throw NoSuchElementException("Эксперт не найден")

        val assignment = Assignment(
            title          = req.title,
            description    = req.description,
            checkerWeights = jackson.writeValueAsString(req.checkerWeights),
            createdBy      = expert,
            createdAt      = Instant.now(),
            updatedAt      = Instant.now()
        )
        return assignmentRepository.save(assignment).toDto().also {
            log.info("Assignment created id={}", it.id)
        }
    }

    @Transactional
    @PreAuthorize("hasRole('EXPERT')")
    fun update(id: Long, req: CreateAssignmentRequest): AssignmentDto {
        log.info("Updating assignment id={}", id)
        validateWeights(req.checkerWeights)
        val existing = findOrThrow(id)
        val updated = existing.copy(
            title          = req.title,
            description    = req.description,
            checkerWeights = jackson.writeValueAsString(req.checkerWeights),
            updatedAt      = Instant.now()
        )
        return assignmentRepository.save(updated).toDto()
    }

    @Transactional
    @PreAuthorize("hasRole('EXPERT')")
    fun delete(id: Long) {
        log.info("Deleting assignment id={}", id)
        if (!assignmentRepository.existsById(id)) throw NoSuchElementException("Задание $id не найдено")
        assignmentRepository.deleteById(id)
    }

    private fun findOrThrow(id: Long) =
        assignmentRepository.findById(id) ?: throw NoSuchElementException("Задание $id не найдено")

    private fun validateWeights(weights: Map<String, Int>) {
        val sum = weights.values.sum()
        if (sum != 100) throw IllegalArgumentException("Сумма весов должна быть 100, получено $sum")
    }

    @Suppress("UNCHECKED_CAST")
    private fun Assignment.toDto(): AssignmentDto {
        val weights = jackson.readValue(checkerWeights, Map::class.java) as Map<String, Int>
        return AssignmentDto(id, title, description, weights, createdBy.id, createdAt.toString(), updatedAt.toString())
    }
}
