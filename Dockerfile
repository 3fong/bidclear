FROM anapsix/alpine-java:8_server-jre
LABEL liulei getobjects@sina.com

ENV TIME_ZONE="Asia/Shanghai" 

RUN echo "$TIME_ZONE" > /etc/timezone
COPY --from=ochinchina/supervisord:latest /usr/local/bin/supervisord /usr/local/bin/supervisord
COPY supervisor.conf /etc/supervisord.conf
EXPOSE 8099
CMD ["/usr/local/bin/supervisord"]
