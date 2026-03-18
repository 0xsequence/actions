FROM alpine

RUN apk update && \
    apk upgrade && \
    apk add git curl jq openssh gnupg

ADD ./entrypoint.sh /entrypoint.sh

ENTRYPOINT [ "/entrypoint.sh" ]