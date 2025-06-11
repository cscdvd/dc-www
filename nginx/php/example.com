# Virtual Host configuration for example.com

server {

    listen 127.0.0.1:80;
    listen 127.0.0.1:443 ssl;

    http2 on;

    server_name example.com www.example.com;

    # Let's Encrypt SSL
    include /etc/nginx/conf.d/ssl.conf;
    ssl_certificate /etc/letsencrypt/live/example.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/example.com/privkey.pem;

    # Block Exploits
    include /etc/nginx/custom.conf.d/block-exploits.conf;

    # Security Headers
    add_header Strict-Transport-Security $hsts_header always;
    add_header X-Content-Type-Options nosniff;
    add_header X-Frame-Options DENY;
    add_header X-XSS-Protection "1; mode=block";

    # Google Chrome
    add_header Alt-Svc "clear";

    # Force SSL
    include /etc/nginx/custom.conf.d/force-ssl.conf;
    
    root /var/www/vhosts/example.com/httpdocs;		
    index  index.php index.html index.htm;

    #logs
    rewrite_log on;
    access_log /var/log/nginx/example.com/access.log;
    error_log /var/log/nginx/example.com/error.log;
    
    error_page 404 https://example.com/404.php;
    error_page 500 /500.php;

    client_body_buffer_size     24M;
    client_max_body_size        24M;
	
    proxy_buffer_size 128k;            # Set buffer size for proxied responses
    proxy_buffers 4 256k;              # Number and size of buffers for proxied responses
    proxy_busy_buffers_size 256k;      # Size of busy buffer in case of large responses

    keepalive_timeout 60;
    
    location / {
        rewrite ^/([A-Za-z0-9\-]+)$ /index.php?load=$1;
            rewrite ^/([A-Za-z0-9\-]+)/$ /index.php?load=$1;
            try_files $uri $uri/ =404;
    }

    location ~ [^/]\.php(/|$) {
        fastcgi_split_path_info ^(.+?\.php)(/.*)$;
        if (!-f $document_root$fastcgi_script_name) {
            return 404;
        }
        fastcgi_read_timeout 60;
	    fastcgi_send_timeout 60;
        proxy_read_timeout 60;
	    proxy_send_timeout 60;

        # Mitigate https://httpoxy.org/ vulnerabilities
        fastcgi_param HTTP_PROXY "";

        fastcgi_pass unix:/var/run/php/example.com.sock;
        fastcgi_index index.php;

        # include the fastcgi_param setting
        include fastcgi_params;
        fastcgi_param  SCRIPT_FILENAME   $document_root$fastcgi_script_name;
    }

    # Handle static files caching
    location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf)$ {
        expires 1d;
        access_log off;
    }

    location ~ /\.ht {
        allow 10.0.0.0/8;
	    deny all;
    }
}