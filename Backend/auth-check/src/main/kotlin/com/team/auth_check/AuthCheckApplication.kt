package com.team.auth_check

import org.springframework.boot.autoconfigure.SpringBootApplication
import org.springframework.boot.runApplication
import org.springframework.data.jpa.repository.config.EnableJpaRepositories
import org.springframework.scheduling.annotation.EnableAsync

@SpringBootApplication
@EnableAsync
@EnableJpaRepositories(basePackages = ["com.team.auth_check.infrastructure.persistence"])
class AuthCheckApplication

fun main(args: Array<String>) {
    runApplication<AuthCheckApplication>(*args)
}
