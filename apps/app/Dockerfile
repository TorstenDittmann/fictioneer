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

# Build the application
RUN bun run vite:build

# Production stage
FROM joseluisq/static-web-server:2

# Copy built app from builder stage
COPY --from=builder /app/build /public

# Copy Static Web Server configuration
COPY sws.toml /etc/sws.toml

# Expose port 80
EXPOSE 80

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD wget --no-verbose --tries=1 --spider http://localhost:80/ || exit 1

# Start Static Web Server with config file
CMD ["static-web-server", "--config-file", "/etc/sws.toml"]