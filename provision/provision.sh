#!/bin/bash
set -ex

dnf install elixir erlang certbot python-certbot-nginx nginx
certbot --nginx -d yagg-game.com
touch /var/spool/cron/root
echo '0 12 * * * /usr/bin/certbot renew --quiet' >> /var/spool/cron/root
mkdir -f /yagg/www
