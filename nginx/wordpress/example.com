# Virtual host configuration for example.com

server {

    listen 127.0.0.1:80;
    listen 127.0.0.1:443 ssl;
    http2 on;

    server_name example.com;

    # SSL
    include /etc/nginx/conf.d/ssl.conf;
    ssl_certificate /etc/letsencrypt/live/example.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/example.com/privkey.pem;

    # Security
    include /etc/nginx/custom.conf.d/block-exploits.conf;
    add_header Strict-Transport-Security $hsts_header always;
    add_header X-Content-Type-Options nosniff;
    add_header X-Frame-Options DENY;
    add_header X-XSS-Protection "1; mode=block";

    # Google Chrome
    add_header Alt-Svc "clear";
    
    # Force SSL
    include /etc/nginx/custom.conf.d/force-ssl.conf;  
 
    root /var/www/vhosts/example.com;
    index index.php

    client_max_body_size 64M;

    # Logging
    access_log /var/log/nginx/example.com/access.log;
    error_log /var/log/nginx/example.com/error.log;

    # Buffering
    proxy_buffer_size 128k;            # Set buffer size for proxied responses
    proxy_buffers 4 256k;              # Number and size of buffers for proxied responses
    proxy_busy_buffers_size 256k;      # Size of busy buffer in case of large responses
    
    # ─── Allow Let's Encrypt challenges ──────────────────────
    location ^~ /.well-known/acme-challenge/ {
        default_type "text/plain";
        alias /var/www/vhosts/example.com/.well-known/acme-challenge/;
        try_files $uri =404;
    }
    # ─────────────────────────────────────────────────────────
    location / {
        try_files $uri $uri/ /index.php?$args;
    }

    location ~ \.php$ {
        include snippets/fastcgi-php.conf;
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