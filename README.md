# File Watcher
|                      |                                                            |
| -------------------- | ---------------------------------------------------------- |
| name                 | File Watcher Ingress                                       |
| type                 | ingress                                                    |
| version              | v0.0.1                                                     |
| docker image         | [weevenetwork/weeve-boilerplate](https://linktodockerhub/) |
| tags                 | Docker, Weeve, MVP                                         |
| authors              | Marcus Jones                                               |
| module specification | v1.0.0                                                     |
| url convention       | 2                                                          |

# Description
This module and project demonstrates a docker container mounting a volume from the host and generating an event stream on file changes.

# Features

# Technical implementation

# Developer

## Host machine source code development

Run a listener, defaulting to port 8080;
`docker run -p 8080:8080 -e LOG_HTTP_BODY=true jmalloc/echo-server -p 8080`

Run the main module in the current folder;
`export MODULE_NAME=file-watch; export EGRESS_URL="http://localhost:8080/handler"; go run main.go -f .`

Change any file in the directory;
`touch hello.txt`

## Dockerized

### Build the container
make build; docker run -it \
    -e MODULE_NAME=dev-random \
    -e MODULE_TYPE=INGRESS \
    -e EGRESS_URL=http://NextContainer:9001/handler \
    weevenetwork/file-watcher /bin/bash

make build; docker run -it \
    --entrypoint /bin/bash \
    -e MODULE_NAME=dev-random \
    -e MODULE_TYPE=INGRESS \
    -e EGRESS_URL=http://NextContainer:9001/handler \
    weevenetwork/file-watcher

### Integration test - manual
Create a volume; `docker volume create foo`

And a network for a simulated dataservice;
`docker network create dtestnet`

**Terminal 1 - file watcher container**

Run the module and mount the volume into the container;
```bash
make build
docker run --rm \
    -v foo:/data \
    --network=dtestnet \
    -e MODULE_NAME=file-watcher \
    -e MODULE_TYPE=INGRESS \
    -e EGRESS_URL=http://echo:9001 \
    weevenetwork/file-watcher -f /data
```

**Terminal 2 - echo**

Use the echo server to simulate a customer endpoint;
```bash
docker run --rm --network=dtestnet -e PORT=9001 -e LOG_HTTP_BODY=true -e LOG_HTTP_HEADERS=true --name echo jmalloc/echo-server
```

**Terminal 3 - modify the volume to trigger the watch**
The volume exists on the file system, but is not designed to be directly accessed. Volumes can be inspected;
```bash
docker volume inspect foo --format '{{.Mountpoint}}'
docker volume inspect foo
```

Run a second container which mounts the same volume, and modifies a file inside the volume;
```bash
docker run --rm -v foo:/test alpine:latest touch /test/file1
```



## Ingress module description
