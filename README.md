# TP final Cloud

## 1. Objectif du TP

L’objectif de ce TP est de mettre en pratique les concepts fondamentaux du cloud computing, incluant :
- Déploiement d’une application conteneurisée
- Gestion d’un registry Docker privé
- Déploiement sur Kubernetes (GKE)
- Gestion des droits via IAM
- Infrastructure as Code avec Terraform
- Pipeline CI/CD automatisé
- Rédaction d’une documentation claire et structurée

---

## 2. Architecture du projet


- **Docker** : containerisation de l’application Flask
- **Artifact Registry** : stockage du container Docker privé
- **GKE** : cluster Kubernetes managé
- **Terraform** : provisionnement de l’infrastructure
- **Cloud Build** : pipeline CI/CD automatique
- **IAM** : gestion des permissions avec un Service Account dédié

---

## 3. Application

- Langage : Python 3.11
- Framework : Flask
- Fonction : retourne un message simple sur `/` pour vérifier le fonctionnement

**Code principal (app.py)**

python
from flask import Flask

app = Flask(__name__)

@app.route("/")
def hello():
    return "TP Cloud GCP - Application Kubernetes OK"

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=8080)
Dockerfile utilisé pour la containerisation :

## 4. Docker & Artifact Registry
Construction de l’image Docker :

docker history tp-cloud-app
>>
IMAGE          CREATED        CREATED BY                                      SIZE      COMMENT
87ad99c1318e   3 hours ago    CMD ["python" "app.py"]                         0B        buildkit.dockerfile.v0
<missing>      3 hours ago    COPY app.py . # buildkit                        12.3kB    buildkit.dockerfile.v0
<missing>      3 hours ago    RUN /bin/sh -c pip install -r requirements.t…   19.6MB    buildkit.dockerfile.v0
<missing>      3 hours ago    COPY requirements.txt . # buildkit              12.3kB    buildkit.dockerfile.v0
<missing>      22 hours ago   WORKDIR /app                                    8.19kB    buildkit.dockerfile.v0
<missing>      7 days ago     CMD ["python3"]                                 0B        buildkit.dockerfile.v0
<missing>      7 days ago     RUN /bin/sh -c set -eux;  for src in idle3 p…   16.4kB    buildkit.dockerfile.v0
<missing>      7 days ago     RUN /bin/sh -c set -eux;   savedAptMark="$(a…   48.4MB    buildkit.dockerfile.v0
<missing>      7 days ago     ENV PYTHON_SHA256=8d3ed8ec5c88c1c95f5e558612…   0B        buildkit.dockerfile.v0
<missing>      7 days ago     ENV PYTHON_VERSION=3.11.14                      0B        buildkit.dockerfile.v0
<missing>      7 days ago     ENV GPG_KEY=A035C8C19219BA821ECEA86B64E628F8…   0B        buildkit.dockerfile.v0
<missing>      7 days ago     RUN /bin/sh -c set -eux;  apt-get update;  a…   4.94MB    buildkit.dockerfile.v0
<missing>      7 days ago     ENV LANG=C.UTF-8                                0B        buildkit.dockerfile.v0
<missing>      7 days ago     ENV PATH=/usr/local/bin:/usr/local/sbin:/usr…   0B        buildkit.dockerfile.v0
<missing>      8 days ago     # debian.sh --arch 'amd64' out/ 'trixie' '@1…   87.4MB    debuerreotype 0.16


## 5. Kubernetes (GKE)
Cluster créé via la console GCP ou Terraform

Exemple de déploiement Kubernetes (deployment.yaml) :



apiVersion: apps/v1
kind: Deployment
metadata:
  name: tp-cloud-app
spec:
  replicas: 2
  selector:
    matchLabels:
      app: tp-cloud
  template:
    metadata:
      labels:
        app: tp-cloud
    spec:
      containers:
      - name: app
        image: europe-west1-docker.pkg.dev/tp-cloud-gke-nolan/tp-docker-repo/app:v1
        ports:
        - containerPort: 8080
Service Kubernetes exposé via LoadBalancer :



apiVersion: v1
kind: Service
metadata:
  name: tp-cloud-service
spec:
  type: LoadBalancer
  selector:
    app: tp-cloud
  ports:
  - port: 80
    targetPort: 8080


## 6. IAM & sécurité
Création d’un Service Account pour la CI/CD :

gcloud iam service-accounts create cicd-sa
Attribution des rôles nécessaires :

gcloud projects add-iam-policy-binding tp-cloud-gke-nolan \
  --member="serviceAccount:cicd-sa@tp-cloud-gke-nolan.iam.gserviceaccount.com" \
  --role="roles/container.developer"

gcloud projects add-iam-policy-binding tp-cloud-gke-nolan \
  --member="serviceAccount:cicd-sa@tp-cloud-gke-nolan.iam.gserviceaccount.com" \
  --role="roles/artifactregistry.writer"
Principe : moindre privilège, le service account a uniquement les droits nécessaires.


## 7. Infrastructure as Code (Terraform)
Fichier main.tf utilisé :

hcl

terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

provider "google" {
  project = "tp-cloud-gke-nolan"
  region  = "europe-west1"
  zone    = "europe-west1-b"
}

resource "google_container_cluster" "gke" {
  name     = "tp-gke-cluster-tf"
  location = "europe-west1-b"
  initial_node_count = 2

  node_config {
    machine_type = "e2-medium"
  }
}

Commandes principales :

terraform init    # Initialisation de Terraform
terraform plan    # Vérification de ce qui sera créé
