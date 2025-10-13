FROM openjdk:21-jdk-slim

WORKDIR /app

RUN apt-get update && apt-get install -y maven

COPY . .

RUN mvn clean package

EXPOSE 3000

CMD ["java", "-jar", "ai-step-backend-0.0.1-SNAPSHOT.jar"]
