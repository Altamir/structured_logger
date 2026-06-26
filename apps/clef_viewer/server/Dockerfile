# Build context: repository root (as declared in .github/workflows/clef-viewer-images.yml)
# After monorepo: pub workspaces require ancestor manifests + root lock for resolution.
# See design doc "Docker Build Context" section for rationale.
FROM dart:stable AS build

WORKDIR /build

# 1. Copy only manifests first (better layer cache for pub get)
COPY pubspec.yaml pubspec.lock ./
COPY packages/structured_logger/pubspec.yaml packages/structured_logger/
COPY apps/clef_viewer/server/pubspec.yaml apps/clef_viewer/server/

# 2. Copy full sources (no sub-package pubspec.lock is copied or needed;
#    root lock + workspace resolution provides reproducibility. The
#    **/pubspec.lock !pubspec.lock .gitignore rule from PR 1 ensures this.)
COPY packages/structured_logger/ packages/structured_logger/
COPY apps/clef_viewer/server/ apps/clef_viewer/server/

# 3. Resolve at workspace root (critical for pub workspaces + Melos-style resolution)
RUN dart pub get

# 4. Compile from the server package dir (pub still sees the workspace)
WORKDIR /build/apps/clef_viewer/server
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