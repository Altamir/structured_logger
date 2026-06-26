# Build context: repository root (structured_logger/)
# Uses Debian + Flutter SDK (no ghcr.io — avoids docker-credential-desktop issues on ghcr).
# Note: no ui/pubspec.lock is copied (gitignored in monorepo); flutter pub get resolves it.

FROM debian:bookworm-slim AS flutter-base

RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    git \
    unzip \
    xz-utils \
    && rm -rf /var/lib/apt/lists/*

ENV FLUTTER_HOME=/opt/flutter
ENV PATH="${FLUTTER_HOME}/bin:${PATH}"

RUN git clone --depth 1 -b stable https://github.com/flutter/flutter.git "${FLUTTER_HOME}" \
    && flutter config --no-analytics \
    && flutter precache --web

FROM flutter-base AS build

ARG CLEF_VIEWER_VERSION=dev

WORKDIR /app
# Copy only pubspec.yaml (pubspec.lock is gitignored in monorepo; flutter pub get will resolve)
COPY apps/clef_viewer/ui/pubspec.yaml ./
RUN flutter pub get

COPY apps/clef_viewer/ui .
# Same-origin API via nginx reverse proxy (empty CLEF_VIEWER_API).
RUN flutter build web --release --no-wasm-dry-run \
    --dart-define=CLEF_VIEWER_API= \
    --dart-define=CLEF_VIEWER_VERSION=${CLEF_VIEWER_VERSION}

FROM nginx:alpine

COPY --from=build /app/build/web /usr/share/nginx/html
COPY apps/clef_viewer/ui/nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 80