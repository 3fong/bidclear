FROM frolvlad/alpine-java:jre8-slim
LABEL liulei getobjects@sina.com

ENV BASE_DIR="/opt/bidclear" \
    TIME_ZONE="Asia/Shanghai" \
    BASE_CODING="UTF-8" \
    BASE_XMS="-Xms128m" \
    BASE_XMX="-Xmx512m" \
    ACTIVE_PROFILE="test" \
    REDIS_HOST="redis" \
    REDIS_PORT="6379" \
    NACOS_HOST="nacos"

WORKDIR /$BASE_DIR

COPY jar/*.jar jar/
COPY start.sh start.sh
RUN chmod +x start.sh


RUN cp /usr/share/zoneinfo/$TIME_ZONE /etc/localtime && echo "$TIME_ZONE" > /etc/timezone
COPY --from=ochinchina/supervisord:latest /usr/local/bin/supervisord /usr/local/bin/supervisord
COPY supervisor.conf /etc/supervisord.conf
EXPOSE 8099
CMD ["/usr/local/bin/supervisord"]