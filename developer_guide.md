# Developer Guide

## GCC Optimization Options When Building From Source

We are building the `nginx` from source using GCC options for optimization and security.

### References

- [The GNU Linker](https://linux.die.net/man/1/ld)
- [The GNU C and C++ Compiler](https://linux.die.net/man/1/gcc)
- [Build Options to Improve Performance and Security of Nginx](https://www.unixteacher.org/blog/build-options-to-improve-the-performance-and-security-of-nginx/)

## Statically Building Nginx

We are building `nginx` executable statically to be used in a `static` Distroless container. However, `nginx` still depends on the shared (dynamic) libraries at runtime to open files such as `/etc/passwd`.

Warning from `make`:

```
/usr/bin/ld: objs/src/core/nginx.o: in function `ngx_load_module':
/tmp/nginx-1.22.1/src/core/nginx.c:1557: warning: Using 'dlopen' in statically linked applications requires at runtime the shared libraries from the glibc version used for linking

/usr/bin/ld: objs/src/os/unix/ngx_process_cycle.o: in function `ngx_worker_process_init':
/tmp/nginx-1.22.1/src/os/unix/ngx_process_cycle.c:807: warning: Using 'initgroups' in statically linked applications requires at runtime the shared libraries from the glibc version used for linking

/usr/bin/ld: objs/src/core/nginx.o: in function `ngx_core_module_init_conf':
/tmp/nginx-1.22.1/src/core/nginx.c:1152: warning: Using 'getgrnam' in statically linked applications requires at runtime the shared libraries from the glibc version used for linking
/usr/bin/ld: /tmp/nginx-1.22.1/src/core/nginx.c:1141: warning: Using 'getpwnam' in statically linked applications requires at runtime the shared libraries from the glibc version used for linking

/usr/bin/ld: objs/src/core/ngx_inet.o: in function `ngx_inet_resolve_host':
/tmp/nginx-1.22.1/src/core/ngx_inet.c:1137: warning: Using 'getaddrinfo' in statically linked applications requires at runtime the shared libraries from the glibc version used for linking
```

To fix these issues, we should also add the required shared libraries to the Distroless container. Required shared libraries:

- `ld`
- `libc`
- `libnss_files`
- `libnss_dns`

For example, `getpwnam` is used to open the `/etc/passwd` file, which requires `libnss_files` shared library. This uses `nsswitch`, you can check its configuration file on `/etc/nsswitch.conf`.

Therefore, we also copy these required shared object (`.so`) to final Distroless image.

### References

- [Stackoverflow comment on `getpwnam` error](https://unix.stackexchange.com/questions/386548/nginx-wont-start-getpwnamnginx-failed-in-etc-nginx-nginx-conf5#comment687896_386548)
