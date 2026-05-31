package com.team.auth_check.infrastructure.storage

import org.slf4j.LoggerFactory
import org.springframework.beans.factory.annotation.Value
import org.springframework.stereotype.Service
import org.springframework.web.multipart.MultipartFile
import java.nio.file.Files
import java.nio.file.Path
import java.nio.file.Paths
import java.util.UUID
import java.util.zip.ZipFile

/** Handles saving and extracting candidate submission ZIP files to the local filesystem. */
@Service
class FileStorageService(
    @Value("\${app.uploads.dir:/app/uploads}") private val uploadsDir: String
) {

    private val log = LoggerFactory.getLogger(javaClass)

    private val root: Path = Paths.get(uploadsDir).also { Files.createDirectories(it) }

    /**
     * Saves an uploaded ZIP file to disk.
     * Returns the relative path stored in the DB: "submissions/{uuid}/code.zip".
     */
    fun saveZip(file: MultipartFile): String {
        require(file.originalFilename?.endsWith(".zip") == true) {
            "Только ZIP-файлы разрешены"
        }
        val uuid = UUID.randomUUID().toString()
        val dir = root.resolve("submissions/$uuid")
        Files.createDirectories(dir)
        val destination = dir.resolve("code.zip")
        file.transferTo(destination)
        log.info("Saved ZIP submissionUuid={} size={}bytes", uuid, file.size)
        return "submissions/$uuid/code.zip"
    }

    /**
     * Extracts a stored ZIP file into a sibling "extracted/" directory.
     * Returns the absolute path to the extracted directory for the checkers.
     *
     * Zip-slip protection: entries with ".." in path are skipped.
     */
    fun extractZip(relativePath: String): Path {
        val zipPath = root.resolve(relativePath)
        val extractDir = zipPath.parent.resolve("extracted")
        if (Files.exists(extractDir)) return extractDir  // already extracted

        Files.createDirectories(extractDir)
        ZipFile(zipPath.toFile()).use { zip ->
            zip.entries().asSequence()
                .filter { !it.name.contains("..") }   // zip-slip guard
                .forEach { entry ->
                    val target = extractDir.resolve(entry.name)
                    if (entry.isDirectory) {
                        Files.createDirectories(target)
                    } else {
                        Files.createDirectories(target.parent)
                        zip.getInputStream(entry).use { input ->
                            Files.copy(input, target)
                        }
                    }
                }
        }
        log.debug("Extracted ZIP to {}", extractDir)
        return extractDir
    }

    /** Absolute path for a stored file. Used by checkers to locate the code. */
    fun absolutePath(relativePath: String): Path = root.resolve(relativePath)
}
