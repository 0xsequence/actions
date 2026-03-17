FROM alpine

RUN apk update && \
    apk upgrade && \
    apk add git curl jq rsync gnupg

ADD ./entrypoint.sh /entrypoint.sh

ENTRYPOINT [ "/entrypoint.sh" ]