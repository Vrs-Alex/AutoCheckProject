package com.team.auth_check.domain.repository

import com.team.auth_check.domain.model.Assignment

interface AssignmentRepository {
    fun findById(id: Long): Assignment?
    fun findAllOrderByCreatedAtDesc(): List<Assignment>
    fun save(assignment: Assignment): Assignment
    fun existsById(id: Long): Boolean
    fun deleteById(id: Long)
}
