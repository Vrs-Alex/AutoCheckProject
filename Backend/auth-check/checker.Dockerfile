FROM eclipse-temurin:21-jdk-alpine

RUN apk add --no-cache git bash python3 curl

WORKDIR /checker-scripts
COPY checker-scripts/ .

ENTRYPOINT ["/bin/bash", "/checker-scripts/run.sh"]
