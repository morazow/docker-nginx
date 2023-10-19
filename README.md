# Nginx

[![Docker Image Version](https://img.shields.io/docker/v/morazow/nginx.svg?style=flat-square&logo=docker)](https://hub.docker.com/r/morazow/nginx)
[![Docker Image Size](https://img.shields.io/docker/image-size/morazow/nginx.svg?style=flat-square&logo=docker)](https://hub.docker.com/r/morazow/nginx)
[![Docker Pulls](https://img.shields.io/docker/pulls/morazow/nginx.svg?style=flat-square&logo=docker)](https://hub.docker.com/r/morazow/nginx)

[Nginx](https://nginx.org/) proxy server that runs inside the [Google Distroless](https://github.com/GoogleContainerTools/distroless) static Debian 11 (Buster) image.

## Building

To build the image, run the following command:

```sh
docker build -f Dockerfile -t morazow/nginx:1.24.0 .
```

## License

[MIT License](LICENSE)
