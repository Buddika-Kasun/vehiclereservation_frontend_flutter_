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

RUN echo 'window.config = {' > build/web/config.js
RUN echo '  apiUrl: "${API_URL:-https://api.example.com}",' >> build/web/config.js
RUN echo '  wsUrl: "${WS_URL:-wss://ws.example.com}",' >> build/web/config.js
RUN echo '};' >> build/web/config.js

FROM nginx:alpine
COPY --from=build /app/build/web /usr/share/nginx/html

# Optimized nginx config
RUN echo 'events{}' > /etc/nginx/nginx.conf
RUN echo 'http{' >> /etc/nginx/nginx.conf
RUN echo '  gzip on; gzip_vary on; gzip_min_length 256; gzip_types text/plain text/css text/xml text/javascript application/javascript application/json;' >> /etc/nginx/nginx.conf
RUN echo '  server{' >> /etc/nginx/nginx.conf
RUN echo '    listen 8080;' >> /etc/nginx/nginx.conf
RUN echo '    root /usr/share/nginx/html;' >> /etc/nginx/nginx.conf
# RUN echo '    location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg)$ { expires 1y; add_header Cache-Control "public, immutable"; }' >> /etc/nginx/nginx.conf
RUN echo '    location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg)$ { expires 1h; }' >> /etc/nginx/nginx.conf
RUN echo '    location / { try_files $uri $uri/ /index.html; }' >> /etc/nginx/nginx.conf
RUN echo '  }' >> /etc/nginx/nginx.conf
RUN echo '}' >> /etc/nginx/nginx.conf

EXPOSE 8080
CMD ["nginx", "-g", "daemon off;"]