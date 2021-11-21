FROM alpine AS builder

LABEL maintainer="Aziz Köksal <aziz.koeksal@gmail.com>"
LABEL license="MIT"

RUN apk add --update --no-cache \
  autoconf \
  automake \
  bash \
  build-base \
  cmake \
  curl \
  elfutils-dev \
  libbpf-dev \
  libelf-static \
  libmnl-dev \
  libtool \
  libuv-dev \
  logrotate \
  openssl-dev \
  pkgconf \
  protobuf-dev \
  python3 \
  util-linux-dev \
  zlib-dev

ARG VSN=1.31.0

WORKDIR /src

# Download, extract, build and install.
COPY netdata-v${VSN}.tar.gz .
RUN (\
    cat netdata-v${VSN}.tar.gz \
    || curl -L https://github.com/netdata/netdata/releases/download/v${VSN}/netdata-v${VSN}.tar.gz \
  ) \
  | tar -xz \
  && cd netdata-v${VSN} \
  && chown -R root: . \
  && mkdir /opt/netdata \
  && ./netdata-installer.sh --dont-wait --dont-start-it --disable-telemetry --install /opt



FROM alpine

RUN apk add python3 logrotate libuuid libuv libmnl

COPY --from=builder /opt/netdata /opt/netdata

RUN ln -s /opt/netdata/usr/sbin/* /usr/sbin

ARG USER_ID=201
ARG USER_NAME=netdata

RUN addgroup -g ${USER_ID} -S ${USER_NAME} \
    && adduser -S -H -h /opt/netdata/etc/netdata -u ${USER_ID} -G ${USER_NAME} ${USER_NAME}

RUN cd /opt/netdata \
    # NB: Netdata's UI doesn't start when the web/index.html is owned by root.
    && chown -R netdata: usr/share/netdata \
    && chown -R netdata:root \
      usr/lib/netdata \
      var/cache/netdata \
      var/lib/netdata \
      var/log/netdata

USER $USER_NAME

EXPOSE 19999
CMD netdata -D
