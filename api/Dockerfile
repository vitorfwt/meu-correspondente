FROM node:20-alpine

# Install netcat (nc) to check if the database port is open and bash
RUN apk add --no-cache netcat-openbsd bash

WORKDIR /app

# Copy dependency definition files
COPY package*.json ./
COPY prisma ./prisma/

# Install dependencies and generate Prisma client
RUN npm ci
RUN npx prisma generate

# Copy the rest of the application files
COPY . .

# Set permissions for the entrypoint script
RUN sed -i 's/\r$//' docker-entrypoint.sh
RUN chmod +x docker-entrypoint.sh

EXPOSE 3000

# Run entrypoint script
ENTRYPOINT ["./docker-entrypoint.sh"]
