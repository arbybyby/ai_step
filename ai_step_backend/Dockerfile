# ...existing code...
FROM maven:3.9.5-eclipse-temurin-21 AS build
WORKDIR /app

# копируем только то, что нужно для dependency resolution
COPY pom.xml mvnw ./
COPY .mvn .mvn
RUN chmod +x mvnw && mvn -B -e -ntp dependency:go-offline

# копируем исходники и собираем
COPY src ./src
RUN mvn -B clean package -DskipTests

FROM eclipse-temurin:21-jre-jammy
WORKDIR /app
# копируем итоговый JAR (любой JAR в target)
COPY --from=build /app/target/*.jar app.jar

EXPOSE 8080
CMD ["java", "-jar", "app.jar"]
# ...existing code...