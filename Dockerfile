FROM debian:bullseye-slim

# Install Flutter and build
RUN apt-get update && apt-get install -y curl git unzip
RUN git clone https://github.com/flutter/flutter.git --depth 1
ENV PATH="$PATH:/flutter/bin"

WORKDIR /app
COPY . .

# Build
RUN flutter pub get
RUN flutter build web --release

# Create config
RUN echo 'window.config = {' > build/web/config.js
RUN echo '  apiUrl: "${API_URL:-https://api.example.com}",' >> build/web/config.js
RUN echo '  wsUrl: "${WS_URL:-wss://ws.example.com}"' >> build/web/config.js
RUN echo '};' >> build/web/config.js

# Serve
RUN apt-get install -y nodejs npm
RUN npm install -g serve

EXPOSE 8080
CMD ["serve", "-s", "build/web", "-l", "8080"]