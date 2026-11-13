# Stage 1: Build the React Web Frontend
FROM node:20-slim AS web-builder
WORKDIR /src/traccar-web
# Copy the web submodule files (assumes repo was cloned with --recursive)
COPY traccar-web/package*.json ./
RUN npm ci
COPY traccar-web/ ./
RUN npm run build

# Stage 2: Build the Java Backend Server
FROM eclipse-temurin:21-jdk AS backend-builder
WORKDIR /src
COPY . .
RUN chmod +x gradlew && ./gradlew assemble

# Stage 3: Final Production Runtime Image
FROM eclipse-temurin:21-jre
WORKDIR /opt/traccar

# Copy compiled Java server, dependencies, schema, and templates
COPY --from=backend-builder /src/target/tracker-server.jar ./
COPY --from=backend-builder /src/target/lib ./lib
COPY --from=backend-builder /src/schema ./schema
COPY --from=backend-builder /src/templates ./templates
COPY --from=backend-builder /src/setup/traccar.xml ./conf/traccar.xml

# Copy compiled React web app into the web directory
COPY --from=web-builder /src/traccar-web/build ./web

# Expose Web UI (8082) and default GPS device protocol ports (5000-5250)
EXPOSE 8082
EXPOSE 5000-5250/tcp
EXPOSE 5000-5250/udp

ENTRYPOINT ["java", "-Xms512m", "-Xmx512m", "-Djava.net.preferIPv4Stack=true"]
CMD ["-jar", "tracker-server.jar", "conf/traccar.xml"]
