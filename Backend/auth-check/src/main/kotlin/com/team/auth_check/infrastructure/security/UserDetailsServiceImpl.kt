package com.team.auth_check.infrastructure.security

import com.team.auth_check.domain.repository.UserRepository
import org.slf4j.LoggerFactory
import org.springframework.security.core.authority.SimpleGrantedAuthority
import org.springframework.security.core.userdetails.User
import org.springframework.security.core.userdetails.UserDetails
import org.springframework.security.core.userdetails.UserDetailsService
import org.springframework.security.core.userdetails.UsernameNotFoundException
import org.springframework.stereotype.Service

/** Loads the user from the domain repository for Spring Security authentication. Username = email. */
@Service
class UserDetailsServiceImpl(
    private val userRepository: UserRepository
) : UserDetailsService {

    private val log = LoggerFactory.getLogger(javaClass)

    override fun loadUserByUsername(email: String): UserDetails {
        log.debug("Loading user by email={}", email)
        val user = userRepository.findByEmail(email)
            ?: throw UsernameNotFoundException("Пользователь не найден: $email")

        return User.builder()
            .username(user.email)
            .password(user.passwordHash)
            .authorities(SimpleGrantedAuthority("ROLE_${user.role.name}"))
            .build()
    }
}
