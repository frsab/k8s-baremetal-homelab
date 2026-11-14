# 🌐 Atelier 01 : Exposition Réseau Bare-Metal (MetalLB & NGINX Ingress)

## 🎯 Objectif de l'atelier
Résoudre la problématique principale des clusters Kubernetes hébergés sur du matériel physique (Bare-Metal) : l'absence de fournisseur Cloud pour attribuer automatiquement des adresses IP externes aux services de type `LoadBalancer`.

À la fin de cet atelier, une application web hébergée dans le cluster est accessible depuis n'importe quel appareil du réseau local via un nom de domaine personnalisé.

---

## 🏗️ Architecture et Flux Réseau

* **Routeur physique :** TP-Link ER605 (Gestion du réseau local et DHCP).
* **Couche 3/4 (Attribution d'IP) :** **MetalLB** configuré en mode **Layer 2 (L2)**. Il intercepte les demandes `LoadBalancer` et annonce l'IP attribuée sur le réseau local via le protocole ARP.
* **Couche 7 (Routage HTTP) :** **NGINX Ingress Controller**. Il reçoit tout le trafic sur l'IP unique fournie par MetalLB et le redirige vers les bons Pods selon le nom de domaine (Host) demandé.

```text
[Client Réseau Local] ──(http://homelab.local)──► [TP-Link ER605]
                                                               │
                                                (Résolution ARP vers l'IP MetalLB)
                                                               ▼
┌───────────────────────────────────────────────────────────────────────────────┐
│ CLUSTER KUBESPRAY (Optiplex + EliteBooks)                                     │
│                                                                               │
│  [IP Externe MetalLB] ──► [NGINX Ingress Controller] ──► [Service] ──► [Pod]  │
└───────────────────────────────────────────────────────────────────────────────┘
```

---
          ù
## 📋 Prérequis

1. Un cluster Kubernetes fonctionnel (déployé ici via Kubespray).
2. Accès au cluster configuré depuis le poste de travail via `kubectl`.
3. Une plage d'adresses IP libres réservée en dehors de la plage DHCP du routeur TP-Link ER605.

---

## 🚀 Déploiement Pas-à-Pas

### 1. Installation de MetalLB
Déploiement des composants natifs de MetalLB dans le namespace `metallb-system` :
```bash
kubectl apply -f https://githubusercontent.com
```
*Vérifier que tous les pods (`controller` et `speaker`) sont en statut `Running` avant de continuer :*
```bash
kubectl get pods -n metallb-system
```

### 2. Configuration de la plage d'IP (Mode L2)
Application du pool d'adresses IP libres et de l'annonce L2 :
```bash
kubectl apply -f 01-metallb-pool.yaml
```

### 3. Installation de NGINX Ingress Controller
Déploiement du contrôleur d'Ingress qui consommera automatiquement la première IP disponible du pool MetalLB :
```bash
kubectl apply -f https://githubusercontent.com
```
*Vérifier l'attribution de l'adresse IP externe (`EXTERNAL-IP`) :*
```bash
kubectl get svc -n ingress-nginx
```

### 4. Déploiement de l'application de test
Création du Pod, du Service interne et de la règle Ingress associée :
```bash
kubectl apply -f 02-app-test-ingress.yaml
```

---

## 🧪 Validation du fonctionnement

Pour tester l'accès depuis le poste client sans serveur DNS local, ajouter l'entrée suivante dans le fichier `hosts` de votre machine (`C:\Windows\System32\drivers\etc\hosts` sous Windows ou `/etc/hosts` sous Linux/macOS) :

```text
<EXTERNAL-IP-ATTRIBUÉE>   demo.homelab.local
```

Tester ensuite la connexion via le navigateur ou en ligne de commande :
```bash
curl -I http://homelab.local
```
*Résultat attendu : `HTTP/1.1 200 OK`*

---

## 📝 Notes & Ressources
* **Article complet sur Medium :** [Lien vers votre article à ajouter après publication]
* **Choix techniques :** Le mode Layer 2 a été privilégié pour sa compatibilité directe avec le routeur TP-Link ER605 sans configuration complexe. Le routage dynamique BGP sera traité dans un atelier ultérieur.
