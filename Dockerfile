FROM node:20-alpine AS builder
RUN apk add --no-cache git
WORKDIR /src
RUN git clone https://github.com/thelastoutpostworkshop/ESPConnect?ref=v1.0.1 .

RUN npm install
RUN npm run build

WORKDIR /src/src

RUN npm init -y

RUN npm install express

RUN echo "const express = require('express'); \
const path = require('path'); \
const app = express(); \
app.use(express.static(path.join(__dirname, 'dist'))); \
app.listen(3000, () => console.log('Server running on port 3000'));" > server.js

COPY --from=builder /src/dist /production/dist
FROM gcr.io/distroless/nodejs20-debian12
WORKDIR /app

COPY --from=builder /production /app

EXPOSE 3000

CMD ["server.js"]
