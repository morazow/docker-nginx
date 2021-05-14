# Nginx

[![Docker Image Version][version-badge]][hub-link]
[![Docker Image Size][size-badge]][hub-link]
[![Docker Pulls][pulls-badge]][hub-link]

[Nginx][nginx] proxy server that runs inside the [Google Distroless][distroless]
base Debian 10 (Buster) image.

## Building

Build with a version and corresponding tar [`sha256sum`][tars]:

```sh
VERSION="1.19.7" && \
SHA256SUM="7ae4dd020c41d3a5e1e6a8578fcc60e508e3e27e7668e845ddc87a05a775b50e" && \
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
