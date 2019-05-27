FROM nginx
ADD nginx-stats.conf /etc/nginx/conf.d/default.conf
ADD goaccess-generate.sh /etc/nginx/conf.d/generate.sh