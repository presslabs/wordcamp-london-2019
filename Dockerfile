FROM quay.io/presslabs/wordpress-runtime:5.1-latest as builder
RUN rm -rf /var/www/html
COPY --chown=www-data:www-data . /var/www
WORKDIR /var/www
RUN composer install -n --no-ansi --no-dev --prefer-dist 
RUN rm -rf .composer

FROM quay.io/presslabs/wordpress-runtime:5.1-latest
ENV DOCUMENT_ROOT=/var/www/web
RUN rm -rf /var/www/html
COPY --from=builder /var/www /var/www