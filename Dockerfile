# Stage 1: Build Angular production app
FROM node:20-alpine AS build
WORKDIR /app

COPY package*.json ./
RUN npm ci --legacy-peer-deps

COPY . .
RUN npm run build -- --configuration production

# Stage 2: Serve using Nginx
FROM nginx:alpine
COPY --from=build /app/dist/vision-medical-system-front/browser /usr/share/nginx/html
COPY nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 80 8080
CMD ["sh", "-c", "sed -i 's/PORT_HOLDER/'\"${PORT:-80}\"'/g' /etc/nginx/conf.d/default.conf && nginx -g 'daemon off;'"]
