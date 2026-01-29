# ============================================
# PRODUCTION FLUTTER WEB WITH VERSIONING
# ============================================

# Stage 1: Build
FROM ubuntu:22.04 AS builder

# Install dependencies
RUN apt-get update && apt-get install -y \
    curl \
    git \
    unzip \
    xz-utils \
    && rm -rf /var/lib/apt/lists/*

# Install Flutter
RUN git clone https://github.com/flutter/flutter.git -b stable /flutter
ENV PATH="$PATH:/flutter/bin"

WORKDIR /app

# Copy pubspec for dependency caching
COPY pubspec.yaml pubspec.lock ./
RUN flutter pub get

# Copy app code
COPY . .

# Fix: Create required assets directory
RUN mkdir -p assets && touch assets/.env

# Build web app
ENV FLUTTER_WEB_USE_SKIA=false
RUN flutter build web --release --no-source-maps --no-wasm-dry-run

# ====== VERSIONING & CACHE BUSTING ======
# Generate content-based hash for true versioning
RUN find . -type f -name "*.dart" -o -name "*.yaml" -o -name "*.json" | \
    sort | xargs cat | sha256sum | cut -d' ' -f1 > /tmp/build.hash

RUN BUILD_HASH=$(cat /tmp/build.hash) && \
    BUILD_TIME=$(date +%s) && \
    VERSION="${BUILD_HASH:0:8}-${BUILD_TIME}" && \
    echo "VERSION=$VERSION" > /tmp/version.env && \
    echo "BUILD_TIME=$BUILD_TIME" >> /tmp/version.env && \
    echo "BUILD_HASH=$BUILD_HASH" >> /tmp/version.env

# Create versioned file names
RUN source /tmp/version.env && \
    # 1. Create versioned copies
    cp build/web/main.dart.js build/web/main.$VERSION.js && \
    cp build/web/flutter.js build/web/flutter.$VERSION.js && \
    cp build/web/main.dart.js.map build/web/main.$VERSION.js.map 2>/dev/null || true && \
    # 2. Update index.html to use versioned files
    sed -i "s/main\.dart\.js/main.$VERSION.js/g" build/web/index.html && \
    sed -i "s/flutter\.js/flutter.$VERSION.js/g" build/web/index.html && \
    # 3. Create version manifest
    echo "{\"version\":\"$VERSION\",\"built\":\"$(date)\",\"hash\":\"$BUILD_HASH\"}" > build/web/version.json

# Remove service workers to prevent caching issues
RUN rm -f build/web/flutter_service_worker.js 2>/dev/null || true
RUN rm -f build/web/service-worker.js 2>/dev/null || true

# Add version info to window object
RUN echo "window.APP_VERSION = '$(cat /tmp/version.env | grep VERSION | cut -d= -f2)';" > build/web/version.js

# Stage 2: Production
FROM nginx:alpine

# Copy built files
COPY --from=builder /app/build/web /usr/share/nginx/html

# Create nginx config with proper cache control
RUN cat > /etc/nginx/nginx.conf << 'EOF'
events {
worker_connections 1024;
}

http {
# Gzip compression
gzip on;
gzip_vary on;
gzip_min_length 1024;
gzip_types text/plain text/css text/xml text/javascript 
application/javascript application/json application/xml+rss;

# Cache settings
map $sent_http_content_type $expires {
default                    off;
text/html                  1h;           # HTML - 1 hour
text/css                   max;
application/javascript     max;
~image/                    max;
~font/                     max;
}

server {
listen 8080;
root /usr/share/nginx/html;
index index.html;

# Security headers
add_header X-Frame-Options "SAMEORIGIN" always;
add_header X-Content-Type-Options "nosniff" always;
add_header Referrer-Policy "strict-origin-when-cross-origin" always;

# ====== CACHE CONTROL RULES ======

# 1. Versioned assets (with hash in filename) - cache forever
location ~* \.[0-9a-f]{8,}-[0-9]+\.(js|css|map)$ {
expires max;
add_header Cache-Control "public, immutable, max-age=31536000";
access_log off;
}

# 2. Static assets without version - cache for 1 week
location ~* \.(?:ico|css|js|gif|jpe?g|png|svg|woff2?|eot|ttf|otf)$ {
expires 7d;
add_header Cache-Control "public, max-age=604800";
access_log off;
}

# 3. HTML files - cache for 1 hour (or no-cache for development)
location ~* \.html$ {
expires 1h;
add_header Cache-Control "public, max-age=3600, must-revalidate";
}

# 4. Special rule for index.html - shorter cache
location = /index.html {
expires 1h;
add_header Cache-Control "public, max-age=3600, must-revalidate";
}

# 5. Version manifest - no cache
location = /version.json {
expires -1;
add_header Cache-Control "no-store, no-cache, must-revalidate";
}

# 6. Main SPA routing
location / {
try_files $uri $uri/ /index.html;
# Moderate cache for API responses etc
expires 5m;
add_header Cache-Control "public, max-age=300";
}

# 7. Disable logs for favicon
location = /favicon.ico {
log_not_found off;
access_log off;
}
}
}
EOF

# Create health check endpoint
RUN echo '{"status":"healthy","service":"flutter-web","timestamp":"'$(date -Iseconds)'"}' > /usr/share/nginx/html/health

EXPOSE 8080
CMD ["nginx", "-g", "daemon off;"]