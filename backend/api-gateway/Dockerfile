FROM maven:3.9.9-eclipse-temurin-17-alpine AS build
WORKDIR /build
COPY backend ./backend
RUN cd backend && mvn -q -pl api-gateway -am package -DskipTests

FROM eclipse-temurin:17-jre-alpine
WORKDIR /app
RUN addgroup -S spring && adduser -S spring -G spring
COPY --from=build /build/backend/api-gateway/target/api-gateway-*.jar /app/app.jar
USER spring:spring
EXPOSE 8080
ENV JAVA_OPTS="-XX:MaxRAMPercentage=75.0"
ENTRYPOINT ["sh", "-c", "java $JAVA_OPTS -jar /app/app.jar"]
