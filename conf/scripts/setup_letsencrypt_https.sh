#!/bin/bash
# Solicita un certificado de Let's Encrypt y lo configura en Apache
set -ex

cd "$(dirname "$0")"
source .env

apt update
apt install -y certbot python3-certbot-apache

certbot --apache \
  -m "$CERTBOT_EMAIL" \
  --agree-tos \
  --no-eff-email \
  --non-interactive \
  --redirect \
  -d "$DOMAIN"
