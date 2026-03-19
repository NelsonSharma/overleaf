# Installation

This guides contains instructions to self-host overleaf on the internet with full latex functionality using nginx reverse proxy 


## (1) Clone Repository 
```sh
git clone https://github.com/NelsonSharma/overleaf.git && cd overleaf
```



#### Directory Structure
```
    bin         binaries
    config      local configuration files (needs to be created)
    data        instance data (mount on overleaf container)
    doc         documentation
    lib         docker compose files
```


## (2) Configuration


Create local configuration, by running:

```sh
bin/init
```

Now check the contents of the `config/` directory

```sh
    overleaf.rc     
    variables.env     
    version
```

These are the three configuration files you will interact with:

- `overleaf.rc` : the main top-level configuration file
    - `OVERLEAF_LISTEN_IP=127.0.0.1`
    - `OVERLEAF_PORT=8080`

- `variables.env` : environment variables loaded into the docker container
    - `OVERLEAF_APP_NAME="MyOverLeaf"`
    - `OVERLEAF_NAV_TITLE=My OverLeaf Instance`
    - `OVERLEAF_ADMIN_EMAIL=admin@gmail.com`
    - (use the same admin-email mentioned here to create first account when the app starts)


- `version` : the version of the (sharelatex) docker images to use
    - `6.1.2`


## (3) Launch and install full latex

After setting the configuration files, launch overleaf:
```sh
bin/up
```

Once the container is up, install latex-full inside it (note the container name is `sharelatex`)
```sh
docker exec -t sharelatex tlmgr update --self && tlmgr install scheme-full
```

You can install latex-full later also (after creating first admin account)


## (4) Create the first admin account

- In a browser, open <http://localhost:8080/launchpad>. You should see a form with email and password fields.
Fill these in with the credentials you want to use as the admin account, then click "Register".

- Then click the link to go to the login page (<http://localhost:8080/login>). Enter the credentials.
Once you are logged in, you will be taken to a welcome page.

- Click the green button at the bottom of the page to start using Overleaf. 

## (5) Stop App
To stop the app use:
```sh
bin/stop
```

At this point the app is ready to be used. 

Rest of the following configurations are optional.

## (6) Email Configuration

If you want to enable sending emails and invite other users to join your instance, set the following in `variables.env` file
```
OVERLEAF_EMAIL_FROM_ADDRESS=admin@gmail.com
OVERLEAF_EMAIL_SMTP_HOST=smtp.gmail.com
OVERLEAF_EMAIL_SMTP_PORT=587
OVERLEAF_EMAIL_SMTP_USER=admin@gmail.com
OVERLEAF_EMAIL_SMTP_PASS=gmail_app_password
OVERLEAF_EMAIL_SMTP_NAME=Admin from example.com
```
This requires having a gmail account and a corresponding app-password (you can use your gmail password directly too but its recomended to create an app-password for security)

## (7) Reverse Proxy

If using nginx reverse proxy for https, set the following in `variables.env` file. It assumes that you have `nginx` running and an SSL certificate issued already which is configured to be used in `/etc/nginx/nginx.conf`.

Make foolowing changes to `variables.env`
```
OVERLEAF_BEHIND_PROXY=true
OVERLEAF_SECURE_COOKIE=true
OVERLEAF_SITE_URL=https://overleaf.example.com
```

Create a config on nginx

```

server {

    listen 443 ssl;
    server_name overleaf.example.com; # Matches OVERLEAF_SITE_URL in variables.env

    # WebSocket upgrades
    map $http_upgrade $connection_upgrade {
        default upgrade;
        ''      close;
    }

    # SSL for HTTPS (use LetsEncrypt to get a certificate)
    ssl_certificate     /etc/letsencrypt/live/example.com/fullchain.pem; 
    ssl_certificate_key /etc/letsencrypt/live/example.com/privkey.pem;
    ssl_session_cache    shared:SSL:50m;
    ssl_session_timeout  1h;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers 'ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305';
    ssl_prefer_server_ciphers on;

    proxy_http_version 1.1;
    proxy_set_header Host              $host;
    proxy_set_header X-Real-IP         $remote_addr;
    proxy_set_header X-Forwarded-For   $proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto $scheme;
    proxy_set_header Upgrade           $http_upgrade;
    proxy_set_header Connection        "upgrade";

    location / {
        proxy_pass http://127.0.0.1:8080; # Matches OVERLEAF_PORT in overleaf.rc

    }
}
```

## (8) Custom Image

If you want to create a custom version of `sharelatex` image with full latex installed in it, use the `dockerfile`:

```dockerfile
FROM sharelatex/sharelatex:6.1.2
RUN tlmgr update --self && tlmgr install scheme-full
```

Build your image using
```sh
docker build -t sharelatex/sharelatex:6.1.2 .
```
If you change the custom image name from `sharelatex/sharelatex:6.1.2` to anything else then make sure to change the same in `overleaf.rc` file as follows: 
```sh
OVERLEAF_IMAGE_NAME=<new_image_name>
```

You can also save a `tar` version of the new image

```sh
docker save sharelatex/sharelatex:6.1.2 > sharelatex-full.tar
```

and load it later using

```sh
docker load -i sharelatex-full.tar
```

## (9) Other Users

If you invite other users to join your server, you can do so from admin dashboard in the app. However, there is no way to check how many users are currently registered on the server. To check this you must query the mongo container directly as follows:

- open a shell in mongo container 
```sh
docker exec -it mongo mongosh
```

- list databases
```sh
show dbs
```

- use sharelatex database
```sh
use sharelatex
```

- check users using one the following commands:

```sh
db.users.find({}, {email:1, first_name:1, last_name:1}).pretty()
db.users.find({}, {email:1, _id:0})
db.users.countDocuments()
```


---


## Updates
For more info and updates, check the original overleaf [github page](https://github.com/overleaf/toolkit)

---
