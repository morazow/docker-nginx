FROM debian:bookworm-slim as BASE_BUILD

LABEL org.opencontainers.image.source=https://github.com/morazow/docker-nginx
LABEL org.opencontainers.image.description="Statically build Nginx for distroless image"
LABEL org.opencontainers.image.licenses=MIT

ARG NGINX_VERSION="1.24.0"
ARG NGINX_SHA256="77a2541637b92a621e3ee76776c8b7b40cf6d707e69ba53a940283e30ff2f55d"
# https://nginx.org/en/pgp_keys.html
ARG NGINX_PGP_KEY="13C82A63B603576156E30A4EA0EA981B66B0D967"

ARG NGINX_TAR_URL="http://nginx.org/download/nginx-${NGINX_VERSION}.tar.gz"
ARG NGINX_ASC_URL="http://nginx.org/download/nginx-${NGINX_VERSION}.tar.gz.asc"

ARG OPENSSL_VERSION="openssl-3.1.3"
ARG OPENSSL_URL="https://github.com/openssl/openssl.git"

ARG PCRE_VERSION="10.42"
ARG PCRE_SHA256="c33b418e3b936ee3153de2c61cc638e7e4fe3156022a5c77d0711bcbb9d64f1f"
ARG PCRE_PGP_KEY="45F68D54BBE23FB3039B46E59766E084FB0F43D8"

ARG PCRE_TAR_URL="https://github.com/PCRE2Project/pcre2/releases/download/pcre2-${PCRE_VERSION}/pcre2-${PCRE_VERSION}.tar.gz"
ARG PCRE_SIG_URL="https://github.com/PCRE2Project/pcre2/releases/download/pcre2-${PCRE_VERSION}/pcre2-${PCRE_VERSION}.tar.gz.sig"

ARG ZLIB_URL="https://github.com/cloudflare/zlib.git"

ARG ESSENTIAL_PACKAGES="build-essential ca-certificates curl git gnupg2"

RUN set -e -x && \
  \
  echo "==> Install essential build dependencies" && \
  apt-get update -y && \
  apt-get install -y --no-install-recommends ${ESSENTIAL_PACKAGES}

# Prepare OpenSSL

RUN set -e -x && \
  \
  echo "==> Git clone OpenSSL and checkout ${OPENSSL_VERSION} branch" && \
  git clone --branch ${OPENSSL_VERSION} --depth 1 --recursive ${OPENSSL_URL} /tmp/openssl && \
  cd /tmp/openssl

## Prepare PCRE

RUN set -e -x && \
  \
  echo "Download pcre-${PCRE_VERSION}.tar.gz" && \
  cd /tmp/ && \
  curl -L ${PCRE_TAR_URL} -o /tmp/pcre.tar.gz && \
  curl -L ${PCRE_SIG_URL} -o /tmp/pcre.tar.gz.sig && \
  \
  echo "${PCRE_SHA256} /tmp/pcre.tar.gz" | sha256sum -c - && \
  GNUPGHOME="$(mktemp -d)" && \
  export GNUPGHOME && \
  (gpg2 --no-tty --keyserver hkps://keyserver.ubuntu.com --recv-keys "$PCRE_PGP_KEY" \
  || gpg2 --no-tty --keyserver hkps://keys.openpgp.org --recv-keys "$PCRE_PGP_KEY") && \
  gpg2 --batch --verify /tmp/pcre.tar.gz.sig /tmp/pcre.tar.gz && \
  tar -C /tmp -xf /tmp/pcre.tar.gz && \
  rm -rf $GNUPGHOME /tmp/pcre.tar.gz /tmp/pcre.tar.gz.sig

## Prepare ZLIB

RUN set -e -x && \
  \
  echo "Git clone and configure Cloudflare Zlib" && \
  git clone --depth 1 --recursive ${ZLIB_URL} /tmp/zlib && \
  cd /tmp/zlib && \
  ./configure

## Prepare Nginx Set Misc Module

RUN set -e -x && \
  \
  echo "Git clone set-misc-nginx-module" && \
  git clone --depth 1 --recursive https://github.com/openresty/set-misc-nginx-module.git /tmp/set-misc-nginx-module && \
  git clone --depth 1 --recursive https://github.com/vision5/ngx_devel_kit.git /tmp/ngx-devel-kit

## Build NGINX

RUN set -e -x && \
  \
  echo "Download, verify and untar the nginx-${NGINX_VERSION}.tar.gz" && \
  curl ${NGINX_TAR_URL} -o /tmp/nginx.tar.gz && \
  curl ${NGINX_ASC_URL} -o /tmp/nginx.tar.gz.asc && \
  \
  echo "${NGINX_SHA256} /tmp/nginx.tar.gz" | sha256sum -c - && \
  export GNUPGHOME="$(mktemp -d)" && \
  (gpg2 --no-tty --keyserver hkps://keyserver.ubuntu.com --recv-keys "$NGINX_PGP_KEY" \
  || gpg2 --no-tty --keyserver hkps://keys.openpgp.org --recv-keys "$NGINX_PGP_KEY") && \
  gpg2 --batch --verify /tmp/nginx.tar.gz.asc /tmp/nginx.tar.gz && \
  tar -C /tmp -xf /tmp/nginx.tar.gz && \
  rm -rf $GNUPGHOME /tmp/nginx.tar.gz /tmp/nginx.tar.gz.asc

RUN set -e -x && \
  \
  echo "==> Configure and install nginx" && \
  cd /tmp/nginx-${NGINX_VERSION} && \
  ./configure \
  --conf-path=/etc/nginx/nginx.conf \
  --error-log-path=/var/log/nginx/error.log \
  --http-log-path=/var/log/nginx/access.log \
  --pid-path=/var/run/nginx.pid \
  --lock-path=/var/run/nginx.lock \
  --http-client-body-temp-path=/var/cache/nginx/client_temp \
  --http-proxy-temp-path=/var/cache/nginx/proxy_temp \
  --http-fastcgi-temp-path=/var/cache/nginx/fastcgi_temp \
  --http-uwsgi-temp-path=/var/cache/nginx/uwsgi_temp \
  --http-scgi-temp-path=/var/cache/nginx/scgi_temp \
  --with-threads \
  --with-file-aio \
  --with-http_auth_request_module \
  --with-http_realip_module \
  --with-http_slice_module \
  --with-http_ssl_module \
  --with-http_v2_module \
  --with-stream \
  --with-stream_ssl_module \
  --with-stream_ssl_preread_module \
  --with-ld-opt="-static" \
  --with-cc-opt="-static -static-libgcc -O3 \
  -Wl,--gc-sections -ffunction-sections -fdata-sections \
  -flto -funsafe-math-optimizations -fstack-protector-all \
  -Wformat -Werror=format-security \
  -D_FORTIFY_SOURCE=2" \
  --with-pcre-jit \
  --with-pcre=../pcre2-${PCRE_VERSION} \
  --with-zlib=../zlib \
  --add-module=/tmp/ngx-devel-kit \
  --add-module=/tmp/set-misc-nginx-module \
  \
  #
  # From https://github.com/trimstray/nginx-admins-handbook/blob/master/doc/SSL_TLS_BASICS.md#tls-versions
  #
  # | PROTOCOL | RFC        | PUBLISHED   | STATUS                        |
  # |:--------:|:----------:|:-----------:|:-----------------------------:|
  # | SSL 1.0  |            | Unpublished | Unpublished                   |
  # | SSL 2.0  |            | 1995        | Deprecated in 2011 [RFC 6176] |
  # | SSL 3.0  |            | 1996        | Deprecated in 2015 [RFC 7568] |
  # | TLS 1.0  | [RFC 2246] | 1999        | Deprecation in 2020           |
  # | TLS 1.1  | [RFC 4346] | 2006        | Deprecation in 2020           |
  # | TLS 1.2  | [RFC 5246] | 2008        | Still secure                  |
  # | TLS 1.3  | [RFC 8446] | 2018        | Still secure                  |
  # |:--------:|:----------:|:-----------:|:-----------------------------:|
  #
  # Thus, only use TLS1.2 and TLS1.3 and strong ssl ciphers.
  #
  # Disable TLS1.0 and TLS1.1.
  --with-openssl=../openssl \
  --with-openssl-opt="no-tls1 no-tls1-method no-tls1_1 no-tls1_1-method \
  no-ssl2 no-ssl3 no-weak-ssl-ciphers \
  no-dtls no-dtls1-method no-dtls1_2-method \
  no-deprecated no-nextprotoneg no-tests \
  enable-ktls enable-ec_nistp_64_gcc_128 \
  -fPIE -fPIC -Wl,-flto -fdata-sections -ffunction-sections \
  -fstack-clash-protection -fstack-protector-strong \
  -s -D_FORTIFY_SOURCE=2" && \
  \
  make -j$(nproc) && \
  make install

RUN set -e -x && \
  \
  echo "==> Stripping nginx static executable" && \
  strip -s /usr/local/nginx/sbin/nginx

RUN set -e -x && \
  \
  echo "==> Cleaning up" && \
  apt-get clean && \
  apt-get purge -y --auto-remove ${ESSENTIAL_PACKAGES} && \
  apt-get autoremove -y && \
  rm -rf \
  /tmp/* \
  /var/tmp/* \
  /var/lib/apt/lists/*

FROM gcr.io/distroless/static-debian12:nonroot
COPY --from=BASE_BUILD /etc/nginx /etc/nginx
COPY --from=BASE_BUILD /usr/local/nginx/sbin/nginx /sbin/nginx
COPY --from=BASE_BUILD /lib/x86_64-linux-gnu/ld*so* /lib/x86_64-linux-gnu/
COPY --from=BASE_BUILD /lib/x86_64-linux-gnu/libc-*so* /lib/x86_64-linux-gnu/
COPY --from=BASE_BUILD /lib/x86_64-linux-gnu/libc.so* /lib/x86_64-linux-gnu/
COPY --from=BASE_BUILD /lib/x86_64-linux-gnu/libnss_files*so* /lib/x86_64-linux-gnu/
COPY --from=BASE_BUILD /lib/x86_64-linux-gnu/libnss_compat*so* /lib/x86_64-linux-gnu/

USER root

EXPOSE 80/tcp 443/tcp

ENTRYPOINT ["/sbin/nginx"]
CMD ["-g", "daemon off;"]
