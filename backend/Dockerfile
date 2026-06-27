FROM node:20-slim

WORKDIR /app

# better-sqlite3 is a native module; these let npm fall back to compiling
# from source if a prebuilt binary isn't available for the build platform.
RUN apt-get update && apt-get install -y --no-install-recommends python3 make g++ \
    && rm -rf /var/lib/apt/lists/*

COPY package*.json ./
RUN npm ci --omit=dev

COPY src ./src

ENV PORT=4000
ENV DATA_DIR=/data

EXPOSE 4000

CMD ["node", "src/server.js"]
