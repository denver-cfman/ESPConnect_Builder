# -----------------------------------------------------------------------------
# Stage 1: Builder
# Clones the repo, installs dependencies, and builds the Vue.js static assets.
# -----------------------------------------------------------------------------
FROM node:20-alpine AS builder

# Install git so we can clone the repository
RUN apk add --no-cache git

WORKDIR /src

# 1. Clone the specific repository
# We clone into the current directory (.)
RUN git clone https://github.com/thelastoutpostworkshop/ESPConnect?ref=v1.0.1 .

# 2. Install dependencies and build the project
RUN npm install
RUN npm run build

# -----------------------------------------------------------------------------
# Stage 2: Server Preparation
# Prepares a minimal production folder with a lightweight web server.
# This is necessary because Distroless images don't have Nginx or Apache.
# -----------------------------------------------------------------------------
WORKDIR /production

# Initialize a new package.json for the production server
RUN npm init -y

# Install a lightweight HTTP server (Express) to serve the static files
RUN npm install express

# Create a minimal server.js script
# This script serves files from the 'dist' directory on port 3000
RUN echo "const express = require('express'); \
const path = require('path'); \
const app = express(); \
app.use(express.static(path.join(__dirname, 'dist'))); \
app.listen(3000, () => console.log('Server running on port 3000'));" > server.js

# Copy the built static assets from Stage 1 into this new environment
COPY --from=builder /src/dist /production/dist

# -----------------------------------------------------------------------------
# Stage 3: Final Distroless Image
# The actual runtime image. It contains only Node.js, our server script,
# and the static assets. No shell, no package manager, no bloat.
# -----------------------------------------------------------------------------
FROM gcr.io/distroless/nodejs20-debian12

WORKDIR /app

# Copy the prepared production folder from Stage 2
COPY --from=builder /production /app

# Expose the port our Express server is listening on
EXPOSE 3000

# Start the server
CMD ["server.js"]
