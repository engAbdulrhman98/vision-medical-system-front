FROM node:20-alpine
WORKDIR /app

COPY package*.json ./
RUN npm install --legacy-peer-deps
RUN npm install -g serve

COPY . .
RUN npm run build -- --configuration production

EXPOSE 80 8080 3000

CMD ["sh", "-c", "serve -s dist/vision-medical-system-front/browser -l ${PORT:-80}"]

