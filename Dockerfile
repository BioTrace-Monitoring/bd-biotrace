FROM mysql:8.0

# copia o script sql para a pasta de exec automática
COPY ./init.sql /docker-entrypoint-initdb.d/
