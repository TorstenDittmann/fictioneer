# Multi-stage build for SvelteKit app with Static Web Server

# Build stage
FROM oven/bun:1 AS builder

WORKDIR /app

# Copy package files
COPY package.json bun.lockb* ./

# Install dependencies
RUN bun install --frozen-lockfile

# Copy source code
COPY . .

# Set build-time environment variable
ARG PUBLIC_INTELLIGENCE_SERVER_URL
ENV PUBLIC_INTELLIGENCE_SERVER_URL=$PUBLIC_INTELLIGENCE_SERVER_URL
ARG PUBLIC_CLERK_PUBLISHABLE_KEY
ENV PUBLIC_CLERK_PUBLISHABLE_KEY=$PUBLIC_CLERK_PUBLISHABLE_KEY

# Build the application
RUN bun run vite:build

# Production stage
FROM ghcr.io/static-web-server/static-web-server:2

# Copy built app from builder stage
COPY --from=builder /app/build ./build

# Copy Static Web Server configuration
COPY sws.toml /etc/sws.toml

# Expose port 80
EXPOSE 80

# Start Static Web Server with config file
CMD ["--config-file", "/etc/sws.toml"]