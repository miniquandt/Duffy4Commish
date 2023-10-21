FROM node:latest

WORKDIR /app

COPY package.json ./
RUN npm i
COPY ./website .
RUN npm run build

ENV HOST=0.0.0.0
EXPOSE 3000

EXPOSE 24678

CMD ["node"]