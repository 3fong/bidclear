FROM adoptopenjdk/openjdk8-openj9:alpine-jre
LABEL liulei getobjects@sina.com

ENV BASE_DIR="/opt/bidclear" \
    BASE_CODING="UTF-8" \
    BASE_XMS="-Xms128m" \
    BASE_XMX="-Xmx512m" \
    ACTIVE_PROFILE="test" \
    REDIS_HOST="redis" \
    REDIS_PORT="6379" \
    NACOS_HOST="nacos"

WORKDIR /$BASE_DIR

COPY ./jar/*.jar ./jar/
COPY ./start.sh ./start.sh
RUN chmod +x ./start.sh

EXPOSE 9961
ENTRYPOINT ["/opt/bidclear/start.sh"]
