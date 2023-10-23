FROM node:latest

WORKDIR /app

COPY /duffy4commish/package.json /app
RUN npm i

COPY /duffy4commish/ /app
#RUN npm run build
#RUN npm prune

EXPOSE 3000
EXPOSE 24678
ENV HOST=0.0.0.0

CMD ["npm", "run", "dev"]