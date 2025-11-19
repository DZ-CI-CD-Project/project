# /home/kevin/gb-deploy/src/backend/Dockerfile
FROM node:18-alpine
WORKDIR /backend

# bcryptjs와 mongoose는 순수 JavaScript이므로 네이티브 빌드 도구 불필요
# 만약 나중에 네이티브 모듈이 필요하면 아래 주석을 해제하세요
# RUN apk add --no-cache python3 make g++

# Copy package files first for better caching
COPY package*.json ./

# Install dependencies with retry logic
# 네트워크 문제를 우회하기 위해 재시도 로직 추가
RUN for i in 1 2 3 4 5; do \
        echo "npm install 시도 $i..." && \
        npm install --omit=dev --no-audit --no-fund && break || \
        (echo "npm install 시도 $i 실패, 15초 후 재시도..." && sleep 15); \
    done || (echo "npm install 최종 실패" && exit 1)

# Copy the rest of the application
COPY . .

# Environment variables
ENV NODE_ENV=production \
    PORT=8000 \
    MONGO_URI=mongodb://mongodb:27017/jobsdb \
    JWT_SECRET=your_jwt_secret_key

EXPOSE 8000

CMD ["node", "app.js"]

