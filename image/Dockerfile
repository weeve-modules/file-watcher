FROM golang:alpine AS builder
COPY ./image/src .
RUN unset GOPATH && go build -o watcher main.go

###
FROM alpine:edge
# Oh yes, you need bash!
RUN apk add --no-cache bash
SHELL ["/bin/bash", "-c"]
COPY --from=builder /go/watcher ./
COPY ./image/entrypoint.sh /entrypoint.sh

RUN ["chmod", "+x", "/entrypoint.sh"]

ENTRYPOINT ["/entrypoint.sh"]
###