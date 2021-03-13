user  nginx;
worker_processes  1;

error_log /dev/fd/2 warn;
pid /run/nginx.pid;

events {
    worker_connections  1024;
}

http {
    include /etc/nginx/mime.types;
    default_type application/octet-stream;

    log_format default '{{ log_pattern }}';
    access_log /dev/fd/1 default;

    sendfile on;
    keepalive_timeout 65;

    {% if request_id -%}
    proxy_set_header Request-Id $request_id;
    add_header Request-Id $request_id;
    {% endif %}

    server {
        listen 80;
        server_name localhost 127.0.0.1;
        access_log off;

        location / {
            root /usr/share/nginx/html;
            index index.html;
        }
    }

    {% for entry in entries -%}
    server {
        listen 80;
        server_name {{ entry.host }};

        location / {
            resolver 127.0.0.11;
            set $upstream {{ entry.service }}:{{ entry.port }}{{ entry.path}};
            proxy_set_header Host              $host;
            proxy_set_header Upgrade $http_upgrade;
            proxy_set_header Connection "Upgrade";
            proxy_set_header X-Real-IP         $remote_addr;
            proxy_set_header X-Forwarded-For   $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
            proxy_set_header X-Forwarded-Host  $host;
            proxy_set_header X-Forwarded-Port  $server_port;
            proxy_pass http://$upstream;
        }
    }
    {% endfor %}
}
