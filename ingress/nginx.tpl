log_format default '{{ log_pattern }}';
access_log /dev/fd/1 default;

{% if request_id -%}
proxy_set_header Request-Id $request_id;
add_header Request-Id $request_id;
{% endif %}

server {
    listen 80 default_server;
    server_name _;
    access_log off;

    {% if secure -%}

    return 301 https://$host$request_uri;

    {% else -%}

    location / {
        root /usr/share/nginx/html;
        index index.html;
    }

    {% endif %}
}

{% if secure -%}
server {
    listen 443 ssl default_server;
    server_name _;
    ssl_certificate     {{certificate}};
    ssl_certificate_key {{private_key}};
    access_log off;

    location / {
        root /usr/share/nginx/html;
        index index.html;
    }
}
{% endif %}

{% for entry in entries -%}

server {
    listen {{ entry.insecure_port }};
    server_name {{ entry.host }};

    location / {
        {% if entry.secure -%}
        return 301 https://$host$request_uri;
        {% else -%}
        resolver 127.0.0.11;
        set $upstream {{ entry.service }}:{{ entry.port }}{{ entry.path}};

        proxy_set_header Host              $host;
        proxy_set_header X-Real-IP         $remote_addr;
        proxy_set_header X-Forwarded-For   $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_set_header X-Forwarded-Host  $host;
        proxy_set_header X-Forwarded-Port  $server_port;

        # Mitigate httpoxy attack
        proxy_set_header Proxy "";

        {% for key,value in entry.config.items() -%}
            {{key}} {{value}};
        {% endfor %}

        proxy_pass http://$upstream;

        {% endif -%}
    }
}

{% if entry.secure -%}
server {
    listen {{ entry.secure_port }} ssl;
    server_name {{ entry.host }};
    ssl_certificate {{ entry.certificate }};
    ssl_certificate_key {{ entry.private_key }};

    location / {
        resolver 127.0.0.11;
        set $upstream {{ entry.service }}:{{ entry.port }}{{ entry.path}};
        proxy_set_header Host              $host;
        proxy_set_header Upgrade           $http_upgrade;
        proxy_set_header Connection        "Upgrade";
        proxy_set_header X-Real-IP         $remote_addr;
        proxy_set_header X-Forwarded-For   $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_set_header X-Forwarded-Host  $host;
        proxy_set_header X-Forwarded-Port  $server_port;
        # Mitigate httpoxy attack
        proxy_set_header Proxy "";
        proxy_pass http://$upstream;

        {% for key,value in entry.config.items() -%}
        {{key}} {{value}};
        {% endfor %}

    }
}
{% endif %}

{% endfor %}

