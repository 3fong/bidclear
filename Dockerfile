FROM anapsix/alpine-java:8_server-jre
LABEL liulei getobjects@sina.com

ENV BASE_DIR="/opt/bidclear" \
    TIME_ZONE="Asia/Shanghai" \
    BASE_CODING="UTF-8" \
    ACTIVE_PROFILE="test" \
    REDIS_PORT="6379" 

WORKDIR /${BASE_DIR}

COPY start.sh start.sh
RUN chmod +x start.sh

RUN echo "$TIME_ZONE" > /etc/timezone
COPY --from=ochinchina/supervisord:latest /usr/local/bin/supervisord /usr/local/bin/supervisord
COPY supervisor.conf /etc/supervisord.conf
EXPOSE 8099
CMD ["/usr/local/bin/supervisord"]
