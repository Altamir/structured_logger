# Build context: repository root (as declared in .github/workflows/clef-viewer-images.yml)
# After monorepo: pub workspaces require ancestor manifests (for all members listed in root)
# + root lock for resolution. Sub-locks are gitignored. See design doc for rationale.
FROM dart:stable AS build

WORKDIR /build

# 1. Copy only manifests first (better layer cache for pub get)
# Note: all workspace members' pubspec.yaml are required because root pubspec.yaml
# declares the full workspace list. For server build (dart only), temporarily
# remove the flutter ui member so dart pub get succeeds without Flutter SDK.
COPY pubspec.yaml pubspec.lock ./
RUN sed -i '/- apps\/clef_viewer\/ui/d' pubspec.yaml
COPY packages/structured_logger/pubspec.yaml packages/structured_logger/
COPY packages/structured_logger_dio_interceptor/pubspec.yaml packages/structured_logger_dio_interceptor/
COPY apps/clef_viewer/server/pubspec.yaml apps/clef_viewer/server/

# 2. Copy full sources for the packages we actually build.
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