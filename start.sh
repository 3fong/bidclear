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

java ${JAVA_OPT} -jar ${BASE_DIR}/jar/bidding-clearing-report-service-1.0.0.jar ${PRO_OPT} > ${BASE_DIR}/log/nohup-report.log 2>&1 &
java ${JAVA_OPT} -jar ${BASE_DIR}/jar/bidding-clearing-user-service-1.0.0.jar ${PRO_OPT} > ${BASE_DIR}/log/nohup-user.log 2>&1 &
java ${JAVA_OPT} -jar ${BASE_DIR}/jar/bidding-clearing-service-1.0.0.jar ${PRO_OPT} > ${BASE_DIR}/log/nohup-bidclear.log 2>&1 &
java ${JAVA_OPT} -jar ${BASE_DIR}/jar/bidding-clearing-gateway-service-1.0.0.jar ${PRO_OPT} > ${BASE_DIR}/log/nohup-gateway.log 2>&1 &
java ${JAVA_OPT} -jar ${BASE_DIR}/jar/bidding-clearing-log-service-1.0.0.jar ${PRO_OPT} > ${BASE_DIR}/log/nohup-log.log 2>&1 &
java ${JAVA_OPT} -jar ${BASE_DIR}/jar/bidding-clearing-message-service-1.0.0.jar ${PRO_OPT} > ${BASE_DIR}/log/nohup-message.log 2>&1
