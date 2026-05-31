package com.team.auth_check.application.checker

import org.slf4j.LoggerFactory
import org.springframework.boot.context.event.ApplicationReadyEvent
import org.springframework.context.annotation.Profile
import org.springframework.context.event.EventListener
import org.springframework.stereotype.Service

/**
 * Queue consumer that runs in the worker process.
 *
 * Activated on profiles "worker" (docker-compose worker service) and "default" (local dev).
 * In production the "api" profile runs the HTTP server and does NOT start this loop.
 *
 * The worker thread blocks on Redis BLPOP to avoid busy-waiting.
 */
@Service
@Profile("worker", "default")
class SubmissionWorkerService(
    private val queue: SubmissionQueueService,
    private val orchestrator: CheckOrchestrator
) {

    private val log = LoggerFactory.getLogger(javaClass)

    @Volatile
    private var running = true

    /** Starts the worker loop as a daemon thread once the application context is ready. */
    @EventListener(ApplicationReadyEvent::class)
    fun start() {
        val thread = Thread(::workerLoop, "submission-worker")
        // Non-daemon: JVM stays alive while this thread runs (critical for worker profile with no HTTP server)
        thread.isDaemon = false
        thread.start()
        log.info("Submission worker started")
    }

    private fun workerLoop() {
        log.info("Worker loop running, waiting for submissions...")
        while (running) {
            try {
                val submissionId = queue.dequeue(timeoutSeconds = 5) ?: continue
                log.info("Dequeued submissionId={}, starting orchestration", submissionId)
                orchestrator.process(submissionId)
            } catch (e: InterruptedException) {
                log.info("Worker thread interrupted — shutting down")
                Thread.currentThread().interrupt()
                break
            } catch (e: Exception) {
                // Log and keep running — one bad submission must not kill the worker
                log.error("Unhandled error in worker loop", e)
            }
        }
    }

    fun stop() {
        running = false
        log.info("Worker loop stop requested")
    }
}
