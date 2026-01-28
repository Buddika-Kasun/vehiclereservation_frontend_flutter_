# Stage 1: Install latest Flutter with proper Dart SDK
FROM ubuntu:22.04 AS builder

# Install dependencies
RUN apt-get update && apt-get install -y \
    curl \
    git \
    unzip \
    xz-utils \
    libglu1-mesa \
    && rm -rf /var/lib/apt/lists/*

# Install latest Flutter (has Dart 3.3+)
RUN git clone https://github.com/flutter/flutter.git -b stable /flutter
ENV PATH="$PATH:/flutter/bin"

# Verify installation
RUN flutter --version

WORKDIR /app

# Copy pubspec first for caching
COPY pubspec.yaml pubspec.lock ./
RUN flutter pub get

# Copy rest of app
COPY . .

# Build
ENV FLUTTER_WEB_USE_SKIA=false
RUN flutter build web --release --no-source-maps

# ====== NUCLEAR CACHE BUSTING ======
# 1. Generate unique version
RUN BUILD_VERSION="v$(date +%Y%m%d%H%M%S)"

# 2. Rename main files
RUN mv build/web/main.dart.js build/web/main.dart.$BUILD_VERSION.js
RUN mv build/web/flutter.js build/web/flutter.$BUILD_VERSION.js

# 3. Update index.html
RUN sed -i "s/main\.dart\.js/main.dart.$BUILD_VERSION.js/g" build/web/index.html
RUN sed -i "s/flutter\.js/flutter.$BUILD_VERSION.js/g" build/web/index.html

# 4. Delete ALL service workers
RUN rm -f build/web/flutter_service_worker.js 2>/dev/null || true
RUN rm -f build/web/service-worker.js 2>/dev/null || true

# 5. Add force update script directly into index.html
RUN sed -i '/<head>/a\
    <script>\
    (function() {\
    console.log("🚀 FORCE UPDATE SCRIPT LOADED");\
    \
    // 1. Kill ALL service workers\
    if ("serviceWorker" in navigator) {\
    navigator.serviceWorker.getRegistrations().then(function(regs) {\
    regs.forEach(function(reg) {\
    reg.unregister().then(function(success) {\
    console.log("✅ ServiceWorker unregistered:", reg.scope);\
    });\
    });\
    });\
    }\
    \
    // 2. Clear ALL caches\
    if ("caches" in window) {\
    caches.keys().then(function(cacheNames) {\
    cacheNames.forEach(function(cacheName) {\
    caches.delete(cacheName).then(function(success) {\
    console.log("✅ Cache deleted:", cacheName);\
    });\
    });\
    });\
    }\
    \
    // 3. Clear localStorage\
    if ("localStorage" in window) {\
    localStorage.clear();\
    console.log("✅ localStorage cleared");\
    }\
    \
    // 4. Force reload if page was cached\
    window.addEventListener("pageshow", function(event) {\
    if (event.persisted) {\
    console.log("🔄 Page loaded from cache, forcing reload");\
    window.location.reload();\
    }\
    });\
    })();\
    </script>' build/web/index.html

# Stage 2: Production
FROM nginx:alpine

# Copy built files
COPY --from=builder /app/build/web /usr/share/nginx/html

# Nginx config: NO CACHING AT ALL
RUN cat > /etc/nginx/nginx.conf << 'EOF'
events {
worker_connections 1024;
}
http {
server {
listen 8080;
server_name _;
root /usr/share/nginx/html;

# DISABLE ALL CACHING
add_header Cache-Control "no-store, no-cache, must-revalidate, proxy-revalidate, max-age=0";
add_header Pragma "no-cache";
add_header Expires "Thu, 01 Jan 1970 00:00:00 GMT";

# Disable etag
etag off;

# Don't send last-modified
if_modified_since off;

location / {
try_files $uri $uri/ /index.html;
}

# Special rule for index.html - ALWAYS fresh
location = /index.html {
add_header Cache-Control "no-store, no-cache, must-revalidate";
expires -1;
}
}
}
EOF

EXPOSE 8080
CMD ["nginx", "-g", "daemon off;"]