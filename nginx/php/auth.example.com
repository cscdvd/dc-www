# Virtual Host configuration for example.com

server {

    listen 80;
    
    server_name example.com;

    # Turn on authentication:
    auth_basic           "Restricted Area";
    # Point to your htpasswd file:
    auth_basic_user_file /etc/nginx/auth/.htpasswd;

    # Block Exploits
    include /etc/nginx/custom.conf.d/block-exploits.conf;
    
    root /var/www/vhosts/example.com;		
    index  index.html;

    # Logging

    access_log /var/log/nginx/example.com/access.log;
    error_log /var/log/nginx/example.com/error.log;
    
    client_body_buffer_size     64M;
    client_max_body_size        64M;

    keepalive_timeout 60;
    
    location / {
        try_files $uri $uri/ =404;
    }

    # Handle static files caching
    location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf)$ {
        expires 1d;
        access_log off;
    }

    location ~ /\.ht {
	    deny all;
    }
}