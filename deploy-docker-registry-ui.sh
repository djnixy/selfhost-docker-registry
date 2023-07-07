#!/bin/sh
# https://www.digitalocean.com/community/tutorials/how-to-set-up-a-private-docker-registry-on-ubuntu-22-04
# Deploy docker registry and UI
# the ui is based on nginx
# it's recommended to add extra subdomain for the registry rather than without TLS.
set -e

sudo apt install apache2-utils -y

mkdir /docker-registry
mkdir /docker-registry/data
mkdir /docker-registry/auth

cd /docker-registry/auth
#htpasswd -Bc registry.password username
echo "Please enter Admin User Name: "
read adminUser
htpasswd -Bc registry.password $adminUser
# Enter a password when prompted. The combination of credentials will be appended to /docker-registry/auth/registry.password.

# Note: To add more users, re-run the previous command without -c:
# htpasswd -B registry.password username

cd /docker-registry
tee docker-compose.yml > /dev/null << EOT
version: '3'
services:
  registry-ui:
    image: joxit/docker-registry-ui:main
    restart: always
    ports:
      - 4999:80
    environment:
      - SINGLE_REGISTRY=true
      - REGISTRY_TITLE=Docker Registry UI - Geekseat
      - DELETE_IMAGES=true
      - SHOW_CONTENT_DIGEST=true
      - NGINX_PROXY_PASS_URL=http://registry-server:5000
      - SHOW_CATALOG_NB_TAGS=true
      - CATALOG_MIN_BRANCHES=1
      - CATALOG_MAX_BRANCHES=1
      - TAGLIST_PAGE_SIZE=100
      - REGISTRY_SECURED=yes
      - CATALOG_ELEMENTS_LIMIT=1000

  registry-server:
    image: registry:latest
    restart: always
    ports:
    - 5000:5000
    environment:
      REGISTRY_AUTH: htpasswd
      REGISTRY_AUTH_HTPASSWD_REALM: Registry
      REGISTRY_AUTH_HTPASSWD_PATH: /auth/registry.password
      REGISTRY_STORAGE_FILESYSTEM_ROOTDIRECTORY: /data

      REGISTRY_HTTP_HEADERS_Access-Control-Allow-Origin: '[https://ui.registry.nixy.vip]'
      REGISTRY_HTTP_HEADERS_Access-Control-Allow-Methods: '[HEAD,GET,OPTIONS,DELETE]'
      REGISTRY_HTTP_HEADERS_Access-Control-Allow-Credentials: '[true]'
      REGISTRY_HTTP_HEADERS_Access-Control-Allow-Headers: '[Authorization,Accept,Cache-Control]'
      REGISTRY_HTTP_HEADERS_Access-Control-Expose-Headers: '[Docker-Content-Digest]'
      REGISTRY_STORAGE_DELETE_ENABLED: 'true'
    volumes:
      - ./auth:/auth
      - ./data:/data
EOT

docker compose up -d
