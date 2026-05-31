# ─── Stage 1: Build ──────────────────────────────────────────────────────────
FROM eclipse-temurin:21-jdk-alpine AS builder

WORKDIR /app

# Copy Gradle wrapper and dependency descriptors first (layer cache)
COPY gradlew settings.gradle.kts build.gradle.kts ./
COPY gradle ./gradle

# Pre-fetch dependencies so subsequent builds use the cache layer
RUN ./gradlew dependencies --no-daemon --quiet || true

# Copy sources and build the fat JAR
COPY src ./src
RUN ./gradlew bootJar --no-daemon -x test

# ─── Stage 2: Runtime ─────────────────────────────────────────────────────────
FROM eclipse-temurin:21-jre-alpine

WORKDIR /app

# Non-root user for security
RUN addgroup -S spring && adduser -S spring -G spring

# Upload directory for candidate ZIP files
RUN mkdir -p /app/uploads && chown spring:spring /app/uploads

COPY --from=builder /app/build/libs/*.jar app.jar

USER spring

EXPOSE 8080

ENTRYPOINT ["java", "-Djava.security.egd=file:/dev/./urandom", "-jar", "app.jar"]
