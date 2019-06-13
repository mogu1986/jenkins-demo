FROM maven:3-jdk-8-alpine as builder
ADD . /app
WORKDIR /app
RUN ls && mvn package

FROM tomcat
WORKDIR /app
COPY --from=builder /app/target/demo.war /usr/local/tomcat/webapps/demo.war