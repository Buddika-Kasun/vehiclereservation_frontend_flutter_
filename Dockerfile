# Stage 1: Base Flutter installation (cached)
FROM debian:bullseye-slim AS flutter-base

RUN apt-get update && apt-get install -y curl git unzip \
    && git clone https://github.com/flutter/flutter.git --depth 1 -b stable \
    && rm -rf /var/lib/apt/lists/*

ENV PATH="/flutter/bin:${PATH}"

# Stage 2: Build dependencies (cached separately)
FROM flutter-base AS dependencies

WORKDIR /app

# Copy pubspec files first for better caching
COPY pubspec.yaml pubspec.lock ./

# Get packages (cached unless pubspec changes)
RUN flutter pub get

# Stage 3: Build the app
FROM dependencies AS builder

# Copy rest of the app
COPY . .

# Build with force update
ENV FLUTTER_WEB_USE_SKIA=false

# Generate unique build ID for cache busting
ARG BUILD_ID
RUN if [ -z "$BUILD_ID" ]; then BUILD_ID=$(date +%s); fi && \
    echo "BUILD_ID=$BUILD_ID" > /tmp/build.env && \
    flutter build web --release --no-source-maps

# ====== FORCE UPDATE ======
RUN source /tmp/build.env && \
    # 1. Add version to ALL files
    sed -i "s/main\.dart\.js/main.dart.js?v=$BUILD_ID/g" build/web/index.html && \
    sed -i "s/flutter\.js/flutter.js?v=$BUILD_ID/g" build/web/index.html && \
    sed -i "s/main\.css/main.css?v=$BUILD_ID/g" build/web/index.html && \
    # 2. Remove service worker
    rm -f build/web/flutter_service_worker.js && \
    # 3. Add cache busting script
    echo '<script>if("serviceWorker"in navigator){navigator.serviceWorker.getRegistrations().then(r=>r.forEach(s=>s.unregister()))}</script>' > /tmp/cache-buster.html && \
    sed -i '/<head>/r /tmp/cache-buster.html' build/web/index.html

# Stage 4: Production
FROM nginx:alpine

# Copy built files
COPY --from=builder /app/build/web /usr/share/nginx/html

# NO CACHE config
RUN echo 'events{}
http {
server {
listen 8080;
root /usr/share/nginx/html;

# NO CACHE - FORCE UPDATE
add_header Cache-Control "no-store, no-cache, must-revalidate";
add_header Pragma "no-cache";
add_header Expires "0";

location / {
try_files $uri $uri/ /index.html;
}
}
}' > /etc/nginx/nginx.conf

EXPOSE 8080
CMD ["nginx", "-g", "daemon off;"]