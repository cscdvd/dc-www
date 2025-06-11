upstream www-example {
  server unix:/home/example/www/tmp/gunicorn.sock fail_timeout=0;
}

server {

    listen 80;
    server_name www.example.com example.com;

    client_max_body_size 32M;
    access_log /home/example/www/log/access.log;
    error_log /home/example/www/log/error.log;

    location /assets/ {
        alias   /home/example/www/static/assets/;
    }

    location /media/ {
        alias   /home/example/www/static/media/;
    }

    location / {

        proxy_redirect off;
        if (!-f $request_filename) {
            proxy_pass http://www-example;
            break;
        }
    }

    location /admin/ {
        allow 127.0.0.1/32;    # Allow specific IP address
        deny all;               # Deny all other IP addresses
    }

}