#!/bin/bash

# Configuration
INGRESS_IP="192.168.25.76"
DOMAIN="k8s-test.local"
NB_REQUESTS=5

echo "=== Vérification de l'état des Pods ==="
kubectl get pods -l app=web-test
echo ""

echo "=== Lancement des tests curl vers l'Ingress ==="
for i in $(seq 1 $NB_REQUESTS)
do
  echo -n "Requête #$i: "
  # --resolve permet de forcer la résolution du domaine vers l'IP de l'Ingress
  HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" --resolve "$DOMAIN:80:$INGRESS_IP" http://$DOMAIN/)
  
  if [ "$HTTP_STATUS" -eq 200 ]; then
    echo "Succès (HTTP 200 OK)"
  else
    echo "Échec (HTTP $HTTP_STATUS)"
  fi
  sleep 1
done
