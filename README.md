# Nginx

[![Docker Image Version][version-badge]][hub-link]
[![Docker Image Size][size-badge]][hub-link]
[![Docker Pulls][pulls-badge]][hub-link]

[Nginx][nginx] proxy server that runs inside the [Google Distroless][distroless]
base Debian 10 image.

## Building

Build with a version and corresponding tar [`sha256sum`][tars]:

```sh
VERSION="1.18.0" && \
SHA256SUM="4c373e7ab5bf91d34a4f11a0c9496561061ba5eee6020db272a17a7228d35f99" && \
docker build --build-arg NGINX_VERSION="$VERSION" \
    --build-arg NGINX_SHA256="$SHA256SUM" \
    -f Dockerfile \
    -t "morazow/nginx:$VERSION" \
    .
```

## License

[MIT License](LICENSE)

[nginx]: https://nginx.org/
[tars]: https://nginx.org/en/download.html
[distroless]: https://github.com/GoogleContainerTools/distroless
[pulls-badge]: https://img.shields.io/docker/pulls/morazow/nginx.svg?style=flat-square&logo=docker
[size-badge]: https://img.shields.io/docker/image-size/morazow/nginx.svg?style=flat-square&logo=docker
[version-badge]: https://img.shields.io/docker/v/morazow/nginx.svg?style=flat-square&logo=docker
[hub-link]: https://hub.docker.com/r/morazow/nginx
