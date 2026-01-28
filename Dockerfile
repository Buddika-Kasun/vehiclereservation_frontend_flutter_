# Use pre-built Flutter image (FASTER)
FROM cirrusci/flutter:stable AS builder

WORKDIR /app

# Copy pubspec first for caching
COPY pubspec.yaml pubspec.lock ./
RUN flutter pub get

# Copy rest of app
COPY . .

# Build with cache busting
ENV FLUTTER_WEB_USE_SKIA=false
RUN flutter build web --release --no-source-maps

# Add version to files
RUN BUILD_ID=$(date +%s) && \
    sed -i "s/main\.dart\.js/main.dart.js?v=$BUILD_ID/g" build/web/index.html && \
    sed -i "s/flutter\.js/flutter.js?v=$BUILD_ID/g" build/web/index.html

# Production
FROM nginx:alpine
COPY --from=builder /app/build/web /usr/share/nginx/html

# Simple nginx config - line by line (no errors)
RUN echo 'events{}' > /etc/nginx/nginx.conf
RUN echo 'http {' >> /etc/nginx/nginx.conf
RUN echo '  server {' >> /etc/nginx/nginx.conf
RUN echo '    listen 8080;' >> /etc/nginx/nginx.conf
RUN echo '    root /usr/share/nginx/html;' >> /etc/nginx/nginx.conf
RUN echo '    # NO CACHE' >> /etc/nginx/nginx.conf
RUN echo '    add_header Cache-Control "no-store, no-cache, must-revalidate";' >> /etc/nginx/nginx.conf
RUN echo '    location / {' >> /etc/nginx/nginx.conf
RUN echo '      try_files $uri $uri/ /index.html;' >> /etc/nginx/nginx.conf
RUN echo '    }' >> /etc/nginx/nginx.conf
RUN echo '  }' >> /etc/nginx/nginx.conf
RUN echo '}' >> /etc/nginx/nginx.conf

EXPOSE 8080
CMD ["nginx", "-g", "daemon off;"]