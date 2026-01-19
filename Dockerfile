# Two-stage build with specific Flutter version
FROM debian:bullseye-slim AS build

# Install dependencies
RUN apt-get update && apt-get install -y curl git unzip xz-utils

# Install specific Flutter version (use stable channel)
RUN git clone https://github.com/flutter/flutter.git --depth 1 -b stable
ENV PATH="$PATH:/flutter/bin"

# Verify Flutter installation
RUN flutter --version

WORKDIR /app
COPY . .

# Create missing assets if they don't exist
RUN mkdir -p assets && touch assets/.env

# Build Flutter web
RUN flutter pub get
RUN flutter build web --release

# Create config.js template (Railway will inject vars)
RUN echo 'window.config = {' > build/web/config.js
RUN echo '  apiUrl: "${API_URL:-https://api.example.com}",' >> build/web/config.js
RUN echo '  wsUrl: "${WS_URL:-wss://ws.example.com}"' >> build/web/config.js
RUN echo '};' >> build/web/config.js

# Stage 2: Serve with nginx
FROM nginx:alpine

# Copy built Flutter web app
COPY --from=build /app/build/web /usr/share/nginx/html

# Update nginx to listen on Railway's PORT
RUN echo 'events { worker_connections 1024; }' > /etc/nginx/nginx.conf
RUN echo 'http {' >> /etc/nginx/nginx.conf
RUN echo '  server {' >> /etc/nginx/nginx.conf
RUN echo '    listen ${PORT:-8080};' >> /etc/nginx/nginx.conf
RUN echo '    root /usr/share/nginx/html;' >> /etc/nginx/nginx.conf
RUN echo '    index index.html;' >> /etc/nginx/nginx.conf
RUN echo '    location / { try_files $uri $uri/ /index.html; }' >> /etc/nginx/nginx.conf
RUN echo '  }' >> /etc/nginx/nginx.conf
RUN echo '}' >> /etc/nginx/nginx.conf

EXPOSE 8080
CMD ["nginx", "-g", "daemon off;"]