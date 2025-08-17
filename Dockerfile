FROM curlimages/curl:8.15.0 AS builder
ARG TARGETPLATFORM
ARG UPSTREAM_VERSION=v0.6.5
RUN DOCKER_ARCH=$(case ${TARGETPLATFORM:-linux/amd64} in \
  "linux/amd64")   echo "amd64"  ;; \
  "linux/arm/v7")  echo "arm64"   ;; \
  "linux/arm64")   echo "arm64" ;; \
  *)               echo ""        ;; esac) \
  && echo "DOCKER_ARCH=$DOCKER_ARCH" \
  && curl --fail -L https://github.com/mautrix/gmessages/releases/download/${UPSTREAM_VERSION}/mautrix-gmessages-${DOCKER_ARCH} > /tmp/mautrix-gmessages
RUN chmod 0755 /tmp/mautrix-gmessages
# just test the download
RUN /tmp/mautrix-gmessages --help

FROM debian:trixie-slim AS runtime
# renovate: suite=trixie depName=ca-certificates
ENV CA_CERTIFICATES_VERSION="20250419"
# renovate: suite=trixie depName=libasprintf0v5
ENV LIBASPRINTF_VERSION="0.23.1-2"
# renovate: suite=trixie depName=gettext-base
ENV GETTEXT_BASE_VERSION="0.23.1-2"

RUN apt-get update && apt-get install -y \
  ca-certificates="${CA_CERTIFICATES_VERSION}" \
  libasprintf0v5=${LIBASPRINTF_VERSION} \
  gettext-base=${GETTEXT_BASE_VERSION} \
  && rm -rf /var/lib/apt/lists/*
COPY --from=mwader/static-ffmpeg:7.1.1 /ffmpeg /usr/local/bin/
COPY --from=mwader/static-ffmpeg:7.1.1 /ffprobe /usr/local/bin/
COPY --from=builder /tmp/mautrix-gmessages /usr/bin/mautrix-gmessages
USER 1337
ENTRYPOINT ["/usr/bin/mautrix-gmessages"]
