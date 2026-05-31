package com.team.auth_check.application.checker

import org.slf4j.LoggerFactory
import org.springframework.data.redis.core.StringRedisTemplate
import org.springframework.stereotype.Service

/** Pushes submission IDs to Redis queue for asynchronous processing by the worker. */
@Service
class SubmissionQueueService(
    private val redis: StringRedisTemplate
) {

    private val log = LoggerFactory.getLogger(javaClass)

    companion object {
        const val QUEUE_KEY = "autocheck:submission:queue"
    }

    /** Add a submission to the processing queue. Worker will pick it up. */
    fun enqueue(submissionId: Long) {
        redis.opsForList().rightPush(QUEUE_KEY, submissionId.toString())
        log.info("Enqueued submissionId={} queueSize={}", submissionId, queueSize())
    }

    /** Blocking pop — waits up to timeoutSeconds for a new item. Returns null on timeout. */
    fun dequeue(timeoutSeconds: Long = 5): Long? {
        val value = redis.opsForList()
            .leftPop(QUEUE_KEY, java.time.Duration.ofSeconds(timeoutSeconds))
        return value?.toLongOrNull()
    }

    fun queueSize(): Long = redis.opsForList().size(QUEUE_KEY) ?: 0
}
