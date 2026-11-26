
# Since we install abseil-dev, the version that the alpine has
#  needs to match what protobuf expects because the developers
# don't care about stability
ARG ALPINE_VERSION=3.22.8

FROM alpine:${ALPINE_VERSION} AS protoc_base
RUN apk add --no-cache build-base curl cmake autoconf libtool git zlib-dev linux-headers abseil-cpp-dev && \
    mkdir -p /out

FROM protoc_base AS protoc_builder
ARG PROTOC_VERSION=29.5
RUN apk add --no-cache ninja abseil-cpp-dev upx automake ninja && \
    curl -sSLO https://github.com/protocolbuffers/protobuf/archive/refs/tags/v${PROTOC_VERSION}.tar.gz && \
    tar -zxf v${PROTOC_VERSION}.tar.gz && \
    cd protobuf-${PROTOC_VERSION} && \
    cmake -Dprotobuf_BUILD_TESTS=OFF -Dprotobuf_ABSL_PROVIDER=package . && \
    cmake --build . -- -j8 && \
    cmake --install . --prefix /out/usr

RUN upx --lzma $(find /out/usr/bin/ \
        -type f -name 'protoc-gen-*' \
        )

FROM alpine:${ALPINE_VERSION} 
# we choose the packages by hand. There is probably a better way.
RUN apk add --no-cache \
  abseil-cpp \
  abseil-cpp-base \
  abseil-cpp-hash \
  abseil-cpp-str-format-internal \
  abseil-cpp-log-internal-format \
  abseil-cpp-base \
  abseil-cpp-hash \
  abseil-cpp-raw-hash-set \
  abseil-cpp-log-internal-message \
  abseil-cpp-log-initialize \
  abseil-cpp-die-if-null \
  abseil-cpp-statusor \
  abseil-cpp-flags-marshalling \
  abseil-cpp-log-internal-nullguard \
  abseil-cpp-log-internal-check-op \
  abseil-cpp-log-internal-conditions \
  abseil-cpp-throw-delegate
COPY --from=protoc_builder /out/ /

ENTRYPOINT [ "/usr/bin/protoc"] 
