FROM node:20-alpine
WORKDIR /app

COPY package*.json ./
RUN npm ci --legacy-peer-deps

COPY . .
RUN npm run build -- --configuration production

EXPOSE 80 8080 3000

CMD ["sh", "-c", "npx serve -s dist/vision-medical-system-front/browser -l ${PORT:-80}"]
