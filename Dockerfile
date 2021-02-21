FROM morazow/openssl:1.1.1j as BASE_BUILD

ARG NGINX_VERSION=
ARG NGINX_SHA256=
ARG NGINX_PGP_KEY="B0F4253373F8F6F510D42178520A9993A1C052F8"

ARG NGINX_TAR_URL="http://nginx.org/download/nginx-${NGINX_VERSION}.tar.gz"
ARG NGINX_ASC_URL="http://nginx.org/download/nginx-${NGINX_VERSION}.tar.gz.asc"

ARG PCRE_VERSION="8.44"
ARG PCRE_SHA256="aecafd4af3bd0f3935721af77b889d9024b2e01d96b58471bd91a3063fb47728"
ARG PCRE_PGP_KEY="45F68D54BBE23FB3039B46E59766E084FB0F43D8"

ARG PCRE_TAR_URL="https://ftp.pcre.org/pub/pcre/pcre-${PCRE_VERSION}.tar.gz"
ARG PCRE_SIG_URL="https://ftp.pcre.org/pub/pcre/pcre-${PCRE_VERSION}.tar.gz.sig"

ARG ZLIB_VERSION="1.2.11"
ARG ZLIB_SHA256="c3e5e9fdd5004dcb542feda5ee4f0ff0744628baf8ed2dd5d66f8ca1197cb1a1"
ARG ZLIB_PGP_KEY="5ED46A6721D365587791E2AA783FCD8E58BCAFBA"

ARG ZLIB_TAR_URL="https://www.zlib.net/zlib-${ZLIB_VERSION}.tar.gz"
ARG ZLIB_ASC_URL="https://www.zlib.net/zlib-${ZLIB_VERSION}.tar.gz.asc"

ARG CA_CERT_FILE="/etc/ssl/certs/ca-certificates.crt"
ARG ESSENTIAL_PACKAGES="build-essential curl gnupg"

RUN set -e -x && \
    \
    echo "==> Install essential build dependencies" && \
    apt-get update -y && \
    apt-get install -y --no-install-recommends ${ESSENTIAL_PACKAGES} && \
    \
    ## PCRE Build
    echo "Download pcre-${PCRE_VERSION}.tar.gz" && \
    cd /tmp/ && \
    curl --cacert ${CA_CERT_FILE} ${PCRE_TAR_URL} -o /tmp/pcre.tar.gz && \
    curl --cacert ${CA_CERT_FILE} ${PCRE_SIG_URL} -o /tmp/pcre.tar.gz.sig && \
    \
    echo "${PCRE_SHA256} /tmp/pcre.tar.gz" | sha256sum -c - && \
    GNUPGHOME="$(mktemp -d)" && \
    export GNUPGHOME && \
    ( gpg --no-tty --keyserver ipv4.pool.sks-keyservers.net --recv-keys "$PCRE_PGP_KEY" \
    || gpg --no-tty --keyserver ha.pool.sks-keyservers.net --recv-keys "$PCRE_PGP_KEY" ) && \
    gpg --batch --verify /tmp/pcre.tar.gz.sig /tmp/pcre.tar.gz && \
    tar -C /tmp -xf /tmp/pcre.tar.gz && \
    rm -rf $GNUPGHOME /tmp/pcre.tar.gz /tmp/pcre.tar.gz.sig && \
    \
    echo "==> Configure and install pcre-${PCRE_VERSION}" && \
    cd /tmp/pcre-${PCRE_VERSION} && \
    ./configure && \
    make && \
    make install && \
    \
    ## ZLIB Build
    echo "Download zlib-${ZLIB_VERSION}.tar.gz" && \
    curl --cacert ${CA_CERT_FILE} ${ZLIB_TAR_URL} -o /tmp/zlib.tar.gz && \
    curl --cacert ${CA_CERT_FILE} ${ZLIB_ASC_URL} -o /tmp/zlib.tar.gz.asc && \
    \
    echo "${ZLIB_SHA256} /tmp/zlib.tar.gz" | sha256sum -c - && \
    GNUPGHOME="$(mktemp -d)" && \
    export GNUPGHOME && \
    ( gpg --no-tty --keyserver ipv4.pool.sks-keyservers.net --recv-keys "$ZLIB_PGP_KEY" \
    || gpg --no-tty --keyserver ha.pool.sks-keyservers.net --recv-keys "$ZLIB_PGP_KEY" ) && \
    gpg --batch --verify /tmp/zlib.tar.gz.asc /tmp/zlib.tar.gz && \
    tar -C /tmp -xf /tmp/zlib.tar.gz && \
    rm -rf $GNUPGHOME /tmp/zlib.tar.gz /tmp/zlib.tar.gz.asc && \
    \
    echo "==> Configure and install zlib-${ZLIB_VERSION}" && \
    cd /tmp/zlib-${ZLIB_VERSION} && \
    ./configure && \
    make && \
    make install && \
    \
    ## NGINX Build
    echo "Download, verify and untar the nginx-${NGINX_VERSION}.tar.gz" && \
    curl --cacert ${CA_CERT_FILE} ${NGINX_TAR_URL} -o /tmp/nginx.tar.gz && \
    curl --cacert ${CA_CERT_FILE} ${NGINX_ASC_URL} -o /tmp/nginx.tar.gz.asc && \
    \
    echo "${NGINX_SHA256} /tmp/nginx.tar.gz" | sha256sum -c - && \
    export GNUPGHOME="$(mktemp -d)" && \
    ( gpg --no-tty --keyserver ipv4.pool.sks-keyservers.net --recv-keys "$NGINX_PGP_KEY" \
    || gpg --no-tty --keyserver ha.pool.sks-keyservers.net --recv-keys "$NGINX_PGP_KEY" ) && \
    gpg --batch --verify /tmp/nginx.tar.gz.asc /tmp/nginx.tar.gz && \
    tar -C /tmp -xf /tmp/nginx.tar.gz && \
    rm -rf $GNUPGHOME /tmp/nginx.tar.gz /tmp/nginx.tar.gz.asc && \
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
        --with-http_auth_request_module \
        --with-http_ssl_module \
        --with-http_v2_module \
        --with-stream \
        --with-stream_ssl_module \
        --with-stream_ssl_preread_module \
        --with-cc-opt=-I/usr/local/include \
        --with-ld-opt=-L/usr/local/lib \
        --with-pcre=../pcre-${PCRE_VERSION} \
        --with-zlib=../zlib-${ZLIB_VERSION} && \
    make && \
    make install && \
    \
    strip -s /usr/local/nginx/sbin/nginx && \
    \
    echo "==> Cleaning up" && \
    apt-get clean && \
    apt-get purge -y --auto-remove ${ESSENTIAL_PACKAGES} && \
    apt-get autoremove -y && \
    rm -rf \
        /tmp/* \
        /var/tmp/* \
        /var/lib/apt/lists/*

FROM gcr.io/distroless/base-debian10
COPY --from=BASE_BUILD /usr/local/nginx/sbin/nginx /sbin/nginx
COPY --from=BASE_BUILD /etc/group /etc/group
COPY --from=BASE_BUILD /etc/passwd /etc/passwd
COPY --from=BASE_BUILD /etc/nginx/mime.types /etc/nginx/mime.types
COPY --from=BASE_BUILD /etc/nginx/nginx.conf /etc/nginx/nginx.conf
COPY --from=BASE_BUILD /usr/local/lib/libcrypto.so.1.1 /lib/x86_64-linux-gnu/
COPY --from=BASE_BUILD /usr/local/lib/libssl.so.1.1 /lib/x86_64-linux-gnu/
COPY --from=BASE_BUILD /usr/local/lib/libjemalloc.so.2 /lib/x86_64-linux-gnu/
COPY --from=BASE_BUILD /usr/lib/x86_64-linux-gnu/libstdc++.so.6 /lib/x86_64-linux-gnu/
COPY --from=BASE_BUILD /lib/x86_64-linux-gnu/libgcc_s.so.1 /lib/x86_64-linux-gnu/

EXPOSE 80 443

ENTRYPOINT ["/sbin/nginx"]
CMD ["-g", "daemon off;"]
