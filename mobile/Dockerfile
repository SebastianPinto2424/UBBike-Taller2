FROM ghcr.io/cirruslabs/flutter:stable@sha256:00a00f16768db672361fb5b79396b2748b75391c9d3bd9a33fc40b257ee94ef0 AS build

WORKDIR /app

COPY pubspec.* ./
RUN flutter pub get

COPY . .

ARG API_BASE_URL=http://localhost:3000
RUN flutter build web --release --no-web-resources-cdn --dart-define=API_BASE_URL=$API_BASE_URL

FROM nginxinc/nginx-unprivileged:1.27-alpine@sha256:65e3e85dbaed8ba248841d9d58a899b6197106c23cb0ff1a132b7bfe0547e4c0

ARG API_BASE_URL=http://localhost:3000
ARG CSP_CONNECT_SRC
ARG CSP_IMG_SRC
COPY nginx.conf /etc/nginx/conf.d/default.conf
RUN WS_BASE_URL="$(printf '%s' "$API_BASE_URL" | sed -e 's#^http://#ws://#' -e 's#^https://#wss://#')" && \
    CSP_VALUE="${CSP_CONNECT_SRC:-'self' ${API_BASE_URL} ${WS_BASE_URL}}" && \
    IMG_VALUE="${CSP_IMG_SRC:-'self' data: blob: ${API_BASE_URL}}" && \
    sed -i "s#__CSP_CONNECT_SRC__#${CSP_VALUE}#g" /etc/nginx/conf.d/default.conf && \
    sed -i "s#__CSP_IMG_SRC__#${IMG_VALUE}#g" /etc/nginx/conf.d/default.conf
COPY --from=build /app/build/web /usr/share/nginx/html

EXPOSE 8080
