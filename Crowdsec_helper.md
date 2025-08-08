# enroll security engine by execing into the crowdsec container

docker exec crowdsec cscli console enroll -e context <YOUR-CODE>
 
# add bouncer

docker exec crowdsec cscli bouncers add traefik-bouncer
 
# list notifications

docker exec crowdsec cscli notifications list
 
# test a notification channel

docker exec crowdsec cscli notifications test http_default

docker exec crowdsec cscli notifications test email_default
 
# inspect logs

# change directory where your crowdsec compose file resists

cd /opt/traefik

docker compose logs -f | grep -i "performed\|ban on Ip"
 
# inspect metrics

docker exec crowdsec cscli metrics
 
# manually ban an ip address

docker exec crowdsec cscli decisions add --ip <IP>
 
# manually unban an ip address

docker exec crowdsec cscli decisions remove --ip <IP>
 
# https://blog.lrvt.de/configuring-crowdsec-with-traefik/
Configuring CrowdSec with Traefik
Utilizing CrowdSec and its Cyber Threat Intelligence (CTI) to ban malicious threat actors probing our exposed HTTP services in a collaborative manner.
 