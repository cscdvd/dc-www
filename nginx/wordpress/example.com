# Virtual host configuration for example.com

server {
    listen 80;
    server_name example.com www.example.com;

    root /var/www/vhosts/example.com;
    index index.php

    client_max_body_size 64M;

    # Logging
    access_log /var/log/nginx/example.com/access.log;
    error_log /var/log/nginx/example.com/error.log;

    location / {
        try_files $uri $uri/ /index.php?$args;
    }

    location ~ \.php$ {
        include fastcgi.conf;
        fastcgi_index index.php;
        fastcgi_intercept_errors on;
        fastcgi_pass unix:/run/php/example.com.sock;
    }

    location ~* \.(css|js|jpg|jpeg|png|gif|ico|svg)$ {
        expires max;
        log_not_found off;
    }

    location = /favicon.ico {
    log_not_found off;
    access_log off;
    }

    location = /robots.txt {
        allow all;
        log_not_found off;
        access_log off;
    }

    # Deny all attempts to access hidden files such as .htaccess, .htpasswd, .DS_Store (Mac).
    location ~ /\. {
        deny all;
    }

    # Deny access to any files with a .php extension in the uploads directory
    location ~* /(?:uploads|files)/.*\.php$ {
        deny all;
    }
}