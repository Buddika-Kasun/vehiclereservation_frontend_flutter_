# Two-stage build for optimized Flutter web
FROM debian:bullseye-slim AS build

# Install dependencies
RUN apt-get update && apt-get install -y curl git unzip

# Install specific Flutter version that has optimizations (3.13.0+)
RUN git clone https://github.com/flutter/flutter.git --depth 1 -b 3.16.0
ENV PATH="$PATH:/flutter/bin"

# Enable web and verify
RUN flutter config --enable-web
RUN flutter --version

WORKDIR /app
COPY . .

# Create missing assets
RUN mkdir -p assets && touch assets/.env

# Get dependencies
RUN flutter pub get

# OPTIMIZED BUILD for fast loading
RUN flutter build web --release \
    --dart-define=FLUTTER_WEB_USE_SKIA=false \
    --no-source-maps \
    --pwa-strategy offline-first

# Create config.js with placeholders
RUN echo 'window.config = {' > build/web/config.js
RUN echo '  apiUrl: "${API_URL:-https://api.example.com}",' >> build/web/config.js
RUN echo '  wsUrl: "${WS_URL:-wss://ws.example.com}",' >> build/web/config.js
RUN echo '};' >> build/web/config.js

# Stage 2: Optimized nginx server
FROM nginx:alpine

# Install brotli for better compression (optional)
RUN apk add --no-cache brotli

# Copy built app
COPY --from=build /app/build/web /usr/share/nginx/html

# Create OPTIMIZED nginx config for fast loading
RUN echo 'events { worker_connections 1024; }' > /etc/nginx/nginx.conf
RUN echo 'http {' >> /etc/nginx/nginx.conf
RUN echo '  # Gzip compression' >> /etc/nginx/nginx.conf
RUN echo '  gzip on;' >> /etc/nginx/nginx.conf
RUN echo '  gzip_vary on;' >> /etc/nginx/nginx.conf
RUN echo '  gzip_min_length 256;' >> /etc/nginx/nginx.conf
RUN echo '  gzip_comp_level 5;' >> /etc/nginx/nginx.conf
RUN echo '  gzip_types' >> /etc/nginx/nginx.conf
RUN echo '    text/plain' >> /etc/nginx/nginx.conf
RUN echo '    text/css' >> /etc/nginx/nginx.conf
RUN echo '    text/xml' >> /etc/nginx/nginx.conf
RUN echo '    text/javascript' >> /etc/nginx/nginx.conf
RUN echo '    application/javascript' >> /etc/nginx/nginx.conf
RUN echo '    application/xml+rss' >> /etc/nginx/nginx.conf
RUN echo '    application/json' >> /etc/nginx/nginx.conf
RUN echo '    image/svg+xml;' >> /etc/nginx/nginx.conf
RUN echo '' >> /etc/nginx/nginx.conf
RUN echo '  # Brotli compression (better than gzip)' >> /etc/nginx/nginx.conf
RUN echo '  brotli on;' >> /etc/nginx/nginx.conf
RUN echo '  brotli_comp_level 6;' >> /etc/nginx/nginx.conf
RUN echo '  brotli_types' >> /etc/nginx/nginx.conf
RUN echo '    text/plain' >> /etc/nginx/nginx.conf
RUN echo '    text/css' >> /etc/nginx/nginx.conf
RUN echo '    text/xml' >> /etc/nginx/nginx.conf
RUN echo '    text/javascript' >> /etc/nginx/nginx.conf
RUN echo '    application/javascript' >> /etc/nginx/nginx.conf
RUN echo '    application/xml+rss' >> /etc/nginx/nginx.conf
RUN echo '    application/json' >> /etc/nginx/nginx.conf
RUN echo '    image/svg+xml;' >> /etc/nginx/nginx.conf
RUN echo '' >> /etc/nginx/nginx.conf
RUN echo '  server {' >> /etc/nginx/nginx.conf
RUN echo '    listen 8080;' >> /etc/nginx/nginx.conf
RUN echo '    root /usr/share/nginx/html;' >> /etc/nginx/nginx.conf
RUN echo '    index index.html;' >> /etc/nginx/nginx.conf
RUN echo '' >> /etc/nginx/nginx.conf
RUN echo '    # Cache static assets aggressively' >> /etc/nginx/nginx.conf
RUN echo '    location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot|wasm)$ {' >> /etc/nginx/nginx.conf
RUN echo '      expires 1y;' >> /etc/nginx/nginx.conf
RUN echo '      add_header Cache-Control "public, immutable";' >> /etc/nginx/nginx.conf
RUN echo '      access_log off;' >> /etc/nginx/nginx.conf
RUN echo '    }' >> /etc/nginx/nginx.conf
RUN echo '' >> /etc/nginx/nginx.conf
RUN echo '    # Main Dart bundle - shorter cache' >> /etc/nginx/nginx.conf
RUN echo '    location ~* main\.dart\.js$ {' >> /etc/nginx/nginx.conf
RUN echo '      expires 7d;' >> /etc/nginx/nginx.conf
RUN echo '      add_header Cache-Control "public";' >> /etc/nginx/nginx.conf
RUN echo '    }' >> /etc/nginx/nginx.conf
RUN echo '' >> /etc/nginx/nginx.conf
RUN echo '    # Service worker - no cache' >> /etc/nginx/nginx.conf
RUN echo '    location ~* /flutter_service_worker\.js$ {' >> /etc/nginx/nginx.conf
RUN echo '      add_header Cache-Control "no-cache";' >> /etc/nginx/nginx.conf
RUN echo '      add_header Service-Worker-Allowed "/";' >> /etc/nginx/nginx.conf
RUN echo '    }' >> /etc/nginx/nginx.conf
RUN echo '' >> /etc/nginx/nginx.conf
RUN echo '    # HTML files - no cache' >> /etc/nginx/nginx.conf
RUN echo '    location ~* \.html$ {' >> /etc/nginx/nginx.conf
RUN echo '      expires -1;' >> /etc/nginx/nginx.conf
RUN echo '      add_header Cache-Control "no-cache, no-store, must-revalidate";' >> /etc/nginx/nginx.conf
RUN echo '    }' >> /etc/nginx/nginx.conf
RUN echo '' >> /etc/nginx/nginx.conf
RUN echo '    location / {' >> /etc/nginx/nginx.conf
RUN echo '      try_files $uri $uri/ /index.html;' >> /etc/nginx/nginx.conf
RUN echo '    }' >> /etc/nginx/nginx.conf
RUN echo '  }' >> /etc/nginx/nginx.conf
RUN echo '}' >> /etc/nginx/nginx.conf

EXPOSE 8080
CMD ["nginx", "-g", "daemon off;"]