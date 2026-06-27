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

WORKDIR /build
# Copy root + all workspace manifests so resolution: workspace works.
# (pubspec.lock is gitignored; flutter pub get will use root lock + manifests)
COPY pubspec.yaml pubspec.lock ./
COPY packages/structured_logger/pubspec.yaml packages/structured_logger/
COPY packages/structured_logger_dio_interceptor/pubspec.yaml packages/structured_logger_dio_interceptor/
COPY apps/clef_viewer/server/pubspec.yaml apps/clef_viewer/server/
COPY apps/clef_viewer/ui/pubspec.yaml apps/clef_viewer/ui/

# Copy ui sources
COPY apps/clef_viewer/ui/ apps/clef_viewer/ui/

WORKDIR /build/apps/clef_viewer/ui
RUN flutter pub get

# Same-origin API via nginx reverse proxy (empty CLEF_VIEWER_API).
RUN flutter build web --release --no-wasm-dry-run \
    --dart-define=CLEF_VIEWER_API= \
    --dart-define=CLEF_VIEWER_VERSION=${CLEF_VIEWER_VERSION}

FROM nginx:alpine

COPY --from=build /build/apps/clef_viewer/ui/build/web /usr/share/nginx/html
COPY apps/clef_viewer/ui/nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 80