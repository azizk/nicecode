FROM ubuntu:20.04 AS builder

LABEL maintainer="Aziz Köksal <aziz.koeksal@gmail.com>"
LABEL license="MIT"

ARG DEBIAN_FRONTEND=noninteractive TZ=Europe/London

RUN apt update -y \
    && apt install -y \
           curl gcc cmake openssl perl g++ clang libsasl2-dev pkg-config libssl-dev

WORKDIR /src

ARG VSN=0.18.1
COPY vector-v${VSN}.tar.gz .
RUN (\
      cat vector-v${VSN}.tar.gz \
      || curl -L https://github.com/vectordotdev/vector/archive/refs/tags/v${VSN}.tar.gz \
    ) \
    | tar -xz \
    && cd vector-${VSN} \
    && ( \
      curl -sSf https://sh.rustup.rs \
      | sh -s -- -y --default-toolchain $(grep -oP '\d+\.\d+\.\d+' rust-toolchain.toml) \
      && cp $HOME/.cargo/bin/* /usr/bin \
    ) \
    && cargo check --release
    # && cargo build --release --no-default-features --features syslog,sinks-loki
