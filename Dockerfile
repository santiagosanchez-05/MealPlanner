FROM nginx:alpine

# Elimina configuración por defecto
RUN rm -rf /usr/share/nginx/html/*

# Copia Flutter build al servidor web
COPY build/web /usr/share/nginx/html

# Expone el puerto 80
EXPOSE 80

# Inicia Nginx
CMD ["nginx", "-g", "daemon off;"]
