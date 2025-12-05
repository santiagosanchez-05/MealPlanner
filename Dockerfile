FROM nginx:alpine

# Limpia contenido por defecto de Nginx
RUN rm -rf /usr/share/nginx/html/*

# Copia el build de Flutter Web
COPY build/web /usr/share/nginx/html

# Expone el puerto 80
EXPOSE 80

# Inicia Nginx
CMD ["nginx", "-g", "daemon off;"]


