FROM nginx:alpine

# Create config.js with Railway environment variables
RUN echo 'window.config = {' > /usr/share/nginx/html/config.js
RUN echo '  apiUrl: "${API_URL:-https://api.example.com}",' >> /usr/share/nginx/html/config.js
RUN echo '  wsUrl: "${WS_URL:-wss://ws.example.com}"' >> /usr/share/nginx/html/config.js
RUN echo '};' >> /usr/share/nginx/html/config.js

# Copy Flutter web build
COPY build/web /usr/share/nginx/html

EXPOSE 8080
CMD ["nginx", "-g", "daemon off;"]