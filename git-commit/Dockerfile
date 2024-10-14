FROM alpine

RUN apk update && \
    apk upgrade && \
    apk add git curl tar

ADD ./entrypoint.sh /entrypoint.sh

ENTRYPOINT [ "/entrypoint.sh" ]