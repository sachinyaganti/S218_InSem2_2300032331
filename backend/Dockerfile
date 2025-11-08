# Stage 1: Build with Maven and Java 17
FROM maven:3.9.6-eclipse-temurin-17 AS build

WORKDIR /app

# Install git to allow repo cloning
RUN apt-get update && apt-get install -y git

# Clone the Event Management System backend repo
RUN git clone https://github.com/suneethabulla/Event-Management-System.git temp && \
    mv temp/backend/* . && \
    rm -rf temp

# Build the application
RUN mvn clean package -DskipTests

# Stage 2: Run with Tomcat
FROM tomcat:9.0-jdk17-temurin

# Remove default Tomcat apps
RUN rm -rf /usr/local/tomcat/webapps/*

# Copy backend WAR to Tomcat
COPY --from=build /app/target/*.war /usr/local/tomcat/webapps/eventmanagement.war

EXPOSE 8080
CMD ["catalina.sh", "run"]
