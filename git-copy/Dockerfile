FROM alpine

RUN apk update && \
    apk upgrade && \
    apk add git curl jq

ADD ./entrypoint.sh /entrypoint.sh

ENTRYPOINT [ "/entrypoint.sh" ]