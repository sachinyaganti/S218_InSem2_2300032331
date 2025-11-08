# Stage 1: Build with Maven and Java 17
FROM maven:3.9.6-eclipse-temurin-17 AS build

WORKDIR /app

# Copy the entire backend source
COPY . .

# Build the application
RUN mvn clean package -DskipTests

# Stage 2: Run with Tomcat
FROM tomcat:9.0-jdk17-temurin

# Remove default apps
RUN rm -rf /usr/local/tomcat/webapps/*

# Copy backend WAR to Tomcat
COPY --from=build /app/target/*.war /usr/local/tomcat/webapps/back2.war

EXPOSE 8080
CMD ["catalina.sh", "run"]    