Skewer
======
Rapid sales pitching.

## Development

Firstly you should add app.getskewer.com to your /etc/hosts.
```
127.0.0.1       app.getskewer.com
```

Next, clone the repo and run `start-dev.sh`

The site will then be available at http://app.getskewer.com:3000/

*Ideally* you will configure a local web server (like nginx) to proxy your local https port 443 to port 3000. To do this you will want add/update a block in your `nginx.conf` that looks like this:
```
# localhost (https)
server {
    proxy_buffering off;
    ssl_certificate      4pax.pem; # use any self-signed cert and key here
    ssl_certificate_key  4pax.key;
    client_body_buffer_size 256k;
    client_max_body_size 100m;

    listen 443 default_server ssl;
    server_name  localhost;

    # Main
    location / {
        proxy_pass http://localhost:3000;
        proxy_redirect off;
        proxy_buffering off;
        proxy_set_header Host            $host;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    }
}
```
