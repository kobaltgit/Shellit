# Build stage
FROM dart:stable AS build

WORKDIR /app
COPY pubspec.* ./
RUN dart pub get

COPY . .
RUN dart pub get --offline
RUN dart compile exe bin/server.dart -o bin/server

# Production minimal runtime stage
FROM debian:bookworm-slim

# Install sqlite3 runtime library and certificates
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    libsqlite3-0 \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app
COPY --from=build /app/bin/server /app/server

# Directory for sqlite database storage
RUN mkdir -p /data
VOLUME /data

ENV PORT=8080
ENV HOST=0.0.0.0
ENV DATA_PATH=/data/shellit-sync.db
ENV REGISTRATION_TOKEN=""

EXPOSE 8080

ENTRYPOINT ["/app/server"]
