# Simpler optimized version
FROM debian:bullseye-slim AS build

RUN apt-get update && apt-get install -y curl git unzip
RUN git clone https://github.com/flutter/flutter.git --depth 1 -b stable
ENV PATH="$PATH:/flutter/bin"

WORKDIR /app
COPY . .

RUN mkdir -p assets && touch assets/.env
RUN flutter pub get

# Force HTML renderer via environment (works with older Flutter)
ENV FLUTTER_WEB_USE_SKIA=false
RUN flutter build web --release --no-source-maps

# ====== ADD CACHE BUSTING HERE ======
# Generate unique build ID
RUN BUILD_ID=$(date +%s) && \
    # Add version to all asset URLs in index.html
    sed -i "s/\"main\.dart\.js\"/\"main.dart.js?v=$BUILD_ID\"/g" build/web/index.html && \
    sed -i "s/\"flutter\.js\"/\"flutter.js?v=$BUILD_ID\"/g" build/web/index.html && \
    sed -i "s/\"main\.css\"/\"main.css?v=$BUILD_ID\"/g" build/web/index.html && \
    # Also update manifest.json if exists
    if [ -f build/web/manifest.json ]; then \
    sed -i "s/\.png/\.png?v=$BUILD_ID/g" build/web/manifest.json; \
    fi

# Create config.js with version
RUN BUILD_ID=$(date +%s) && \
    echo "window.appVersion = '$BUILD_ID';" > build/web/version.js && \
    echo 'window.config = {' >> build/web/version.js && \
    echo '  apiUrl: "${API_URL:-https://api.example.com}",' >> build/web/version.js && \
    echo '  wsUrl: "${WS_URL:-wss://ws.example.com}",' >> build/web/version.js && \
    echo '};' >> build/web/version.js

FROM nginx:alpine
COPY --from=build /app/build/web /usr/share/nginx/html

# Optimized nginx config with cache busting support
RUN echo 'events{}' > /etc/nginx/nginx.conf
RUN echo 'http{' >> /etc/nginx/nginx.conf
RUN echo '  gzip on; gzip_vary on; gzip_min_length 256; gzip_types text/plain text/css text/xml text/javascript application/javascript application/json;' >> /etc/nginx/nginx.conf
RUN echo '  server{' >> /etc/nginx/nginx.conf
RUN echo '    listen 8080;' >> /etc/nginx/nginx.conf
RUN echo '    root /usr/share/nginx/html;' >> /etc/nginx/nginx.conf
RUN echo '    # Versioned files - cache forever (with ?v= parameter)' >> /etc/nginx/nginx.conf
RUN echo '    location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg)(\?v=[0-9]+)?$ {' >> /etc/nginx/nginx.conf
RUN echo '      expires 1y;' >> /etc/nginx/nginx.conf
RUN echo '      add_header Cache-Control "public, immutable";' >> /etc/nginx/nginx.conf
RUN echo '    }' >> /etc/nginx/nginx.conf
RUN echo '    # HTML files - NEVER cache' >> /etc/nginx/nginx.conf
RUN echo '    location ~* \.html$ {' >> /etc/nginx/nginx.conf
RUN echo '      expires -1;' >> /etc/nginx/nginx.conf
RUN echo '      add_header Cache-Control "no-store, no-cache, must-revalidate";' >> /etc/nginx/nginx.conf
RUN echo '    }' >> /etc/nginx/nginx.conf
RUN echo '    # Force no-cache for index.html specifically' >> /etc/nginx/nginx.conf
RUN echo '    location = /index.html {' >> /etc/nginx/nginx.conf
RUN echo '      expires -1;' >> /etc/nginx/nginx.conf
RUN echo '      add_header Cache-Control "no-store, no-cache, must-revalidate, max-age=0";' >> /etc/nginx/nginx.conf
RUN echo '      add_header Pragma "no-cache";' >> /etc/nginx/nginx.conf
RUN echo '    }' >> /etc/nginx/nginx.conf
RUN echo '    # Main route - serve index.html for SPA' >> /etc/nginx/nginx.conf
RUN echo '    location / {' >> /etc/nginx/nginx.conf
RUN echo '      try_files $uri $uri/ /index.html;' >> /etc/nginx/nginx.conf
RUN echo '      add_header Cache-Control "no-store, no-cache, must-revalidate";' >> /etc/nginx/nginx.conf
RUN echo '    }' >> /etc/nginx/nginx.conf
RUN echo '  }' >> /etc/nginx/nginx.conf
RUN echo '}' >> /etc/nginx/nginx.conf

EXPOSE 8080
CMD ["nginx", "-g", "daemon off;"]