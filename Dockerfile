# ============================================
# WORKING FLUTTER WEB DOCKERFILE
# ============================================

# Stage 1: Build
FROM ubuntu:22.04 AS builder

# Install Flutter
RUN apt-get update && apt-get install -y curl git unzip xz-utils
RUN git clone https://github.com/flutter/flutter.git -b stable /flutter
ENV PATH="$PATH:/flutter/bin"

WORKDIR /app
COPY pubspec.yaml pubspec.lock ./
RUN flutter pub get
COPY . .
RUN mkdir -p assets && touch assets/.env
RUN flutter build web --release --no-source-maps

# Simple query string versioning
RUN VERSION=$(date +%s) && \
    sed -i "s/main\.dart\.js/main.dart.js?v=$VERSION/g" build/web/index.html && \
    sed -i "s/flutter\.js/flutter.js?v=$VERSION/g" build/web/index.html

# Stage 2: Production
FROM nginx:alpine

# Copy built files
COPY --from=builder /app/build/web /usr/share/nginx/html

# SIMPLE nginx config - NO COMPLEX REGEX
RUN cat > /etc/nginx/nginx.conf << 'EOF'
events {
worker_connections 1024;
}

http {
# Remove default nginx config
include /etc/nginx/mime.types;
default_type application/octet-stream;

# Simple logging
access_log /var/log/nginx/access.log;
error_log /var/log/nginx/error.log;

# Gzip
gzip on;
gzip_vary on;
gzip_min_length 1024;
gzip_types text/plain text/css text/xml text/javascript 
application/javascript application/json;

server {
listen 8080;
server_name _;
root /usr/share/nginx/html;

# Security headers
add_header X-Frame-Options "SAMEORIGIN" always;
add_header X-Content-Type-Options "nosniff" always;

# ====== SIMPLE CACHE CONTROL ======

# JavaScript and CSS files - with or without version query
location ~* \.(js|css)$ {
# Check if has version query parameter
if ($args ~* "v=") {
add_header Cache-Control "public, immutable, max-age=31536000";
expires max;
}
# No version - cache for 1 week
if ($args !~* "v=") {
add_header Cache-Control "public, max-age=604800";
expires 7d;
}
}

# Images and fonts - cache for 1 month
location ~* \.(png|jpg|jpeg|gif|ico|svg|woff|woff2|eot|ttf|otf)$ {
add_header Cache-Control "public, max-age=2592000";
expires 30d;
}

# HTML files - cache for 1 hour
location ~* \.html$ {
add_header Cache-Control "public, max-age=3600, must-revalidate";
expires 1h;
}

# Main SPA routing
location / {
try_files $uri $uri/ /index.html;
add_header Cache-Control "public, max-age=300";
expires 5m;
}
}
}
EOF

EXPOSE 8080
CMD ["nginx", "-g", "daemon off;"]