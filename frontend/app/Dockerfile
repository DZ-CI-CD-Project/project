FROM node:18-alpine
WORKDIR /app

# Install dependencies
COPY package.json package-lock.json ./
# 네트워크 문제를 우회하기 위해 재시도 로직 추가
RUN for i in 1 2 3 4 5; do \
        echo "npm install 시도 $i..." && \
        npm install --omit=dev --no-audit --no-fund && break || \
        (echo "npm install 시도 $i 실패, 15초 후 재시도..." && sleep 15); \
    done || (echo "npm install 최종 실패" && exit 1)

# Copy app sources
COPY . .

ENV NODE_ENV=production
ENV PORT=3000
EXPOSE 3000

CMD ["node", "server.js"]



