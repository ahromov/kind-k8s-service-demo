FROM amazoncorretto:21-alpine
WORKDIR /service
RUN adduser -D appuser && \
    chown -R appuser:appuser /service
COPY target/*.jar service.jar
EXPOSE 8080 8081
ENTRYPOINT ["sh", "-c", "exec java -server -XX:TieredStopAtLevel=1 -XX:MaxRAMPercentage=75.0 -XX:InitialRAMPercentage=50.0 -XX:+UseG1GC -XX:+ExitOnOutOfMemoryError $JAVA_OPTS $JAVA_TOOL_OPTIONS -jar service.jar"]
