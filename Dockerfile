# Flutter Web with FORCE UPDATE
FROM debian:bullseye-slim AS build

RUN apt-get update && apt-get install -y curl git unzip
RUN git clone https://github.com/flutter/flutter.git --depth 1 -b stable
ENV PATH="$PATH:/flutter/bin"

WORKDIR /app
COPY . .

RUN flutter pub get
ENV FLUTTER_WEB_USE_SKIA=false
RUN flutter build web --release --no-source-maps

# ====== NUCLEAR CACHE BUSTING ======
RUN BUILD_ID="FORCE_$(date +%s)"
RUN echo "BUILD VERSION: $BUILD_ID"

# 1. Rename ALL asset files with version
RUN find build/web -type f \( -name "*.js" -o -name "*.css" -o -name "*.png" -o -name "*.jpg" -o -name "*.jpeg" -o -name "*.gif" -o -name "*.ico" -o -name "*.svg" \) \
    -exec sh -c 'mv "$1" "${1%.*}_${BUILD_ID}.${1##*.}"' _ {} \;

# 2. Update index.html with new filenames
RUN sed -i "s/main\.dart\.js/main.dart_${BUILD_ID}.js/g" build/web/index.html
RUN sed -i "s/flutter\.js/flutter_${BUILD_ID}.js/g" build/web/index.html
RUN sed -i "s/main\.css/main_${BUILD_ID}.css/g" build/web/index.html

# 3. Delete ALL service worker files
RUN rm -f build/web/*service*.js 2>/dev/null || true
RUN rm -f build/web/*worker*.js 2>/dev/null || true
RUN rm -f build/web/*flutter_service* 2>/dev/null || true

# 4. Create FORCE UPDATE script file
RUN cat > build/web/force-update.js << 'EOF'
// FORCE UPDATE SCRIPT
(function() {
console.log('=== FORCE UPDATE SCRIPT LOADED ===');

// 1. Kill service workers
if ('serviceWorker' in navigator) {
navigator.serviceWorker.getRegistrations().then(function(regs) {
regs.forEach(function(reg) {
reg.unregister().then(function() {
console.log('ServiceWorker unregistered:', reg.scope);
});
});
});
}

// 2. Clear ALL storage
if ('localStorage' in window) localStorage.clear();
if ('sessionStorage' in window) sessionStorage.clear();

// 3. Add no-cache meta tag dynamically
var meta = document.createElement('meta');
meta.httpEquiv = "Cache-Control";
meta.content = "no-store, no-cache, must-revalidate";
document.head.appendChild(meta);

// 4. Force reload if cached
if (window.performance && window.performance.navigation.type === 2) {
window.location.reload(true);
}
})();
EOF

# 5. Inject force-update script into index.html
RUN sed -i '/<head>/a\    <script src="force-update.js"></script>' build/web/index.html

# 6. Create version file
RUN echo "window.FORCE_UPDATE_VERSION = '$BUILD_ID';" > build/web/version.js

FROM nginx:alpine

# Copy built files
COPY --from=build /app/build/web /usr/share/nginx/html

# NUCLEAR nginx config - NO CACHING EVER
RUN cat > /etc/nginx/nginx.conf << 'EOF'
events{}
http {
server {
listen 8080;
root /usr/share/nginx/html;

# KILL ALL CACHING
add_header Cache-Control "no-store, no-cache, must-revalidate, proxy-revalidate, max-age=0";
add_header Pragma "no-cache";
add_header Expires "Thu, 01 Jan 1970 00:00:00 GMT";

# Extra headers to prevent any caching
add_header X-Accel-Expires "0";

location / {
try_files $uri $uri/ /index.html;
# Force immediate reload
add_header Last-Modified $date_gmt;
if_modified_since off;
expires off;
etag off;
}

# Special for index.html - ALWAYS fresh
location = /index.html {
add_header Cache-Control "no-store, no-cache, must-revalidate";
expires -1;
}
}
}
EOF

EXPOSE 8080
CMD ["nginx", "-g", "daemon off;"]