FROM node:18 AS webapp-builder

WORKDIR /app

# Copy and build the client/webapp
COPY client/package*.json ./client/
WORKDIR /app/client
RUN npm install

COPY client/ ./
# This builds to ../server/webapp (which is /app/server/webapp)
RUN npm run build

# Build the Go server
FROM docker.io/alpine:latest

LABEL maintainer="Chrystian Huot <chrystian.huot@saubeo.solutions>"

WORKDIR /app

ENV DOCKER=1

# Copy server code
COPY server/. server/.

# Copy built webapp from previous stage - Angular builds to /app/server/webapp
COPY --from=webapp-builder /app/server/webapp ./server/webapp

RUN mkdir -p /app/data && \
    apk --no-cache --no-progress --virtual .build add go && \
    cd server && \
    go build -o ../rdio-scanner && \
    cd .. && \
    rm -fr server /root/.cache /root/go && \
    apk del .build && \
    apk --no-cache --no-progress add ffmpeg mailcap tzdata

VOLUME [ "/app/data" ]
EXPOSE 3000
ENTRYPOINT [ "./rdio-scanner", "-base_dir", "/app/data" ]
