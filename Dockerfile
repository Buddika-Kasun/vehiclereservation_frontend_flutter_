FROM debian:bullseye-slim AS build

RUN apt-get update && apt-get install -y curl git unzip
RUN git clone https://github.com/flutter/flutter.git --depth 1 -b stable
ENV PATH="$PATH:/flutter/bin"

WORKDIR /app
COPY . .

RUN mkdir -p assets && touch assets/.env
RUN flutter pub get

RUN flutter build web --release --no-source-maps --pwa-strategy=none

RUN BUILD_ID=$(date +%s) && \
    echo "window.APP_VERSION='$BUILD_ID';" > build/web/version.js && \
    echo 'window.config = {' > build/web/config.js && \
    echo '  apiUrl: "'"${API_URL:-https://api.example.com}"'",' >> build/web/config.js && \
    echo '  wsUrl: "'"${WS_URL:-wss://ws.example.com}"'",' >> build/web/config.js && \
    echo '};' >> build/web/config.js && \
    sed -i "s/main.dart.js/main.dart.js?v=$BUILD_ID/g" build/web/index.html && \
    sed -i "s/flutter_bootstrap.js/flutter_bootstrap.js?v=$BUILD_ID/g" build/web/index.html

FROM nginx:alpine

COPY --from=build /app/build/web /usr/share/nginx/html

RUN rm /etc/nginx/conf.d/default.conf

RUN printf '%s\n' \
    'server {' \
    '  listen 0.0.0.0:$PORT;' \
    '  root /usr/share/nginx/html;' \
    '  index index.html;' \
    '  gzip on;' \
    '  gzip_types text/plain text/css application/javascript application/json;' \
    '  location = /index.html {' \
    '    add_header Cache-Control "no-store, no-cache, must-revalidate, max-age=0";' \
    '  }' \
    '  location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg)$ {' \
    '    expires 1y;' \
    '    add_header Cache-Control "public, immutable";' \
    '  }' \
    '  location / {' \
    '    try_files $uri $uri/ /index.html;' \
    '    add_header Cache-Control "no-store";' \
    '  }' \
    '}' \
    > /etc/nginx/conf.d/app.conf

CMD ["sh", "-c", "envsubst '$PORT' < /etc/nginx/conf.d/app.conf > /etc/nginx/conf.d/default.conf && nginx -g 'daemon off;'"]
