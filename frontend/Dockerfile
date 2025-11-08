# Stage 1: Build stage (Node.js for React/Vite)
FROM node:18 AS build-stage
WORKDIR /app

# Install git to allow repo cloning
RUN apt-get update && apt-get install -y git

# Clone the Event Management System frontend repo
RUN git clone https://github.com/suneethabulla/Event-Management-System.git temp && \
    mv temp/frontend/* . && \
    rm -rf temp

# Install dependencies and build
RUN npm install
RUN npm run build

# Stage 2: Runtime stage (Nginx for serving)
FROM nginx:alpine

# Copy React build output to Nginx
COPY --from=build-stage /app/dist /usr/share/nginx/html

# Copy custom nginx configuration
COPY nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
