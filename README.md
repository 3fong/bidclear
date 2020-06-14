### 微服务单容器部署 ###

最近在看容器,跟同事沟通,他想把微服务放到单个容器里部署,以实现环境不变.这个只能是测试自己玩一下,生产环境中单容器部署微服务容易出现,容器运行正常,但是部分服务不可用的情况,应用的管理也很麻烦,这里简单做个记录吧


实际启动服务有三部分:   

1. nacos注册中心    
2. redis缓存服务,实际后端服务还有mysql,这里它没有容器化   
3. 多个springboot服务   

这三部分各自运行在自己的容器中



#### 方案一: ####
这里的运行方案主要是想模拟单机运行环境,就是把docker当成虚拟机来用,最直接的方式是通过dockerfile直接执行多个服务启动,但是docker因为需要一个前台进程来判断服务是否存活,所以最后一个服务不能加"&"后台运行标识,这也就造成如果最后一个服务挂掉,整个容器就会退出,造成所有服务退出.

tag:v1.0 版本


Dockerfile:

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


服务启动脚本 start.sh


    #!/bin/sh
    
    echo 'task start---------------------------------------------------------------- ' 
    JAVA_OPT="-Dfile-encoding=${BASE_CODING}"
    #JAVA_OPT="${JAVA_OPT} ${BASE_XMS}"
    #JAVA_OPT="${JAVA_OPT} ${BASE_XMX}"
    
    PRO_OPT="--spring.profiles.active=${ACTIVE_PROFILE}"
    PRO_OPT="${PRO_OPT} --spring.redis.host=${REDIS_HOST}"
    PRO_OPT="${PRO_OPT} --spring.redis.port=${REDIS_PORT}"
    PRO_OPT="${PRO_OPT} --nacos.server-addr=${NACOS_HOST}"
    
    echo 'param-----------------${PRO_OPT}----------------------------------------------- ' 
    
    nohup java ${JAVA_OPT} -jar ${BASE_DIR}/jar/bidding-clearing-report-service-1.0.0.jar ${PRO_OPT} > ${BASE_DIR}/log/nohup-report.log 2>&1 &
    nohup java ${JAVA_OPT} -jar ${BASE_DIR}/jar/bidding-clearing-user-service-1.0.0.jar ${PRO_OPT} > ${BASE_DIR}/log/nohup-user.log 2>&1 &
    nohup java ${JAVA_OPT} -jar ${BASE_DIR}/jar/bidding-clearing-service-1.0.0.jar ${PRO_OPT} > ${BASE_DIR}/log/nohup-bidclear.log 2>&1 &
    nohup java ${JAVA_OPT} -jar ${BASE_DIR}/jar/bidding-clearing-gateway-service-1.0.0.jar ${PRO_OPT} > ${BASE_DIR}/log/nohup-gateway.log 2>&1 &
    nohup java ${JAVA_OPT} -jar ${BASE_DIR}/jar/bidding-clearing-log-service-1.0.0.jar ${PRO_OPT} > ${BASE_DIR}/log/nohup-log.log 2>&1 &
    nohup java ${JAVA_OPT} -jar ${BASE_DIR}/jar/bidding-clearing-message-service-1.0.0.jar ${PRO_OPT} > ${BASE_DIR}/log/nohup-message.log 2>&1
    

#### 方案二: ####
tag:v2.0   

通过supervisor来管理服务,负责和docker交互,这样既可以解决docker前台进程问题,又便于服务管理.

dockerfile:

    FROM anapsix/alpine-java:8_server-jre
    LABEL liulei getobjects@sina.com
    
    ENV BASE_DIR="/opt/bidclear" \
    TIME_ZONE="Asia/Shanghai" 
    
    WORKDIR /${BASE_DIR}
    
    COPY start.sh start.sh
    RUN chmod +x start.sh
    
    RUN echo "$TIME_ZONE" > /etc/timezone
    COPY --from=ochinchina/supervisord:latest /usr/local/bin/supervisord /usr/local/bin/supervisord
    COPY supervisor.conf /etc/supervisord.conf
    EXPOSE 8099
    CMD ["/usr/local/bin/supervisord"]


通过每个服务一个program,这样也可以更好的划分服务范围,同时通过volumes挂载执行jar包的方式,通过supervisor来实现服务热更新.缺点是容器如果挂了就全挂了,这一点可以通过docker-compose的restart来解决.     
supervisor.conf

    [program:gateway]
    command = java -Dfile-encoding=UTF-8 -Xms128m -Xmx256m -jar /opt/bidclear/jar/bidding-clearing-gateway-service-1.0.0.jar --spring.profiles.active=test --spring.redis.host=redis --spring.redis.port=6379 --nacos.server-addr=nacos
    stdout_logfile=/opt/bidclear/log/nohup-gateway.log
    redirect_stderr=true
    
    [program:report]
    command = java -Dfile-encoding=UTF-8 -Xms128m -Xmx256m -jar /opt/bidclear/jar/bidding-clearing-report-service-1.0.0.jar --spring.profiles.active=test --spring.redis.host=redis --spring.redis.port=6379 --nacos.server-addr=nacos
    stdout_logfile=/opt/bidclear/log/nohup-report.log
    redirect_stderr=true
    
    [program:user]
    command = java -Dfile-encoding=UTF-8 -Xms128m -Xmx256m -jar /opt/bidclear/jar/bidding-clearing-user-service-1.0.0.jar --spring.profiles.active=test --spring.redis.host=redis --spring.redis.port=6379 --nacos.server-addr=nacos
    stdout_logfile=/opt/bidclear/log/nohup-user.log
    redirect_stderr=true
    
    [program:bidclear]
    command = java -Dfile-encoding=UTF-8 -Xms128m -Xmx256m -jar /opt/bidclear/jar/bidding-clearing-service-1.0.0.jar --spring.profiles.active=test --spring.redis.host=redis --spring.redis.port=6379 --nacos.server-addr=nacos
    stdout_logfile=/opt/bidclear/log/nohup-bidclear.log
    redirect_stderr=true
    
    [program:log]
    command = java -Dfile-encoding=UTF-8 -Xms128m -Xmx256m -jar /opt/bidclear/jar/bidding-clearing-log-service-1.0.0.jar --spring.profiles.active=test --spring.redis.host=redis --spring.redis.port=6379 --nacos.server-addr=nacos
    stdout_logfile=/opt/bidclear/log/nohup-log.log
    redirect_stderr=true
    
    [program:message]
    command = java -Dfile-encoding=UTF-8 -Xms128m -Xmx256m -jar /opt/bidclear/jar/bidding-clearing-message-service-1.0.0.jar --spring.profiles.active=test --spring.redis.host=redis --spring.redis.port=6379 --nacos.server-addr=nacos
    stdout_logfile=/opt/bidclear/log/nohup-message.log
    redirect_stderr=true
    
    [supervisord]
    logfile=/opt/bidclear/log/supervisord.log
    
    [inet_http_server]
    port = :8099
    


服务启动:

    docker-compose up -d


问题:

nacos服务进行服务注册时会占用大量cpu,可能存在服务挂掉的情况

服务器配置:2核4g,1m带宽的阿里云服务器


