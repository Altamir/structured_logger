# Build context: repository root (structured_logger/)
FROM dart:stable AS build

WORKDIR /build/apps/clef_viewer/server
COPY apps/clef_viewer/server/pubspec.yaml apps/clef_viewer/server/pubspec.lock ./

COPY apps/clef_viewer/server/ ./
RUN dart pub get
RUN dart compile exe bin/server.dart -o /server

FROM debian:bookworm-slim

ARG CLEF_VIEWER_VERSION=dev

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
      libsqlite3-0 \
      ca-certificates \
      curl \
    && sqlite_so="$(find /usr/lib -name 'libsqlite3.so.0' | head -1)" \
    && ln -sf "$sqlite_so" "${sqlite_so%.0}" \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app
COPY --from=build /server /app/server

ENV PORT=5341
ENV DB_PATH=/data/clef_viewer.db
ENV STATIC_PATH=/nonexistent
ENV CLEF_VIEWER_VERSION=$CLEF_VIEWER_VERSION

EXPOSE 5341
VOLUME ["/data"]

ENTRYPOINT ["/app/server"]