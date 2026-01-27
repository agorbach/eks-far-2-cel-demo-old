# 🚀 GKE + Helm – מדריך פרקטי מלא (readme-gke.md).

---

## 1️⃣ דרישות מקדימות

נדרש:

- חשבון Google Cloud פעיל  
- Project קיים או חדש  

נבחר Project:

```
PROJECT_ID=gcp-2026
REGION=us-central1
ZONE=us-central1-a
CLUSTER_NAME=far-gke-demo
```

---

## 2️⃣ התקנת והגדרת gcloud

אם עובדים מ־Cloud Shell (מומלץ):

```bash
gcloud config set project gcp-2026
gcloud config set compute/region us-central1
gcloud config set compute/zone us-central1-a
```

בדיקה:

```bash
gcloud auth list
gcloud config list
```

---

## 3️⃣ יצירת Cluster ב-GKE (הכי קצר)

```bash
gcloud container clusters create far-gke-demo   --num-nodes=2   --machine-type=e2-medium   --enable-ip-alias   --region us-central1
```

חיבור kubectl:

```bash
gcloud container clusters get-credentials far-gke-demo --region us-central1
kubectl get nodes
```

פלט תקין: 2 Nodes במצב Ready.

---

## 4️⃣ התקנת Helm

```bash
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
helm version
```

---

## 5️⃣ יצירת Chart Helm לאפליקציה far-2-cel

בתוך ה־Repository:

```bash
cd eks-far-2-cel-demo-30-12
mkdir -p gke/helm
cd gke/helm
helm create far-2-cel
cd far-2-cel
```

מבנה חשוב:

```
far-2-cel/
├── Chart.yaml
├── values.yaml
└── templates/
    ├── deployment.yaml
    ├── service.yaml
    └── ingress.yaml
```

---

## 6️⃣ עדכון values.yaml

פתח עם nano:

```bash
nano values.yaml
```

ערכים מינימליים:

```yaml
replicaCount: 2

image:
  repository: gcr.io/gcp-2026/far-2-cel
  tag: "1.0"
  pullPolicy: IfNotPresent

service:
  type: ClusterIP
  port: 80

ingress:
  enabled: true
  className: nginx
  hosts:
    - host: ""
      paths:
        - path: /
          pathType: Prefix
```

---

## 7️⃣ בניית Image ודחיפה ל-Google Container Registry

מתיקיית האפליקציה:

```bash
cd ~/eks-far-2-cel-demo-30-12/app/far-2-cel
```

```bash
docker build -t gcr.io/gcp-2026/far-2-cel:1.0 .
docker push gcr.io/gcp-2026/far-2-cel:1.0
```

---

## 8️⃣ התקנת Ingress Controller (NGINX)

```bash
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.9.5/deploy/static/provider/cloud/deploy.yaml
```

המתן:

```bash
kubectl get pods -n ingress-nginx
kubectl get svc -n ingress-nginx
```

שמור את ה־EXTERNAL-IP של ingress-nginx-controller.

---

## 9️⃣ פריסה ראשונה עם Helm

מתיקיית ה־Chart:

```bash
cd ~/eks-far-2-cel-demo-30-12/gke/helm/far-2-cel
helm install far-demo .
```

בדיקות:

```bash
kubectl get pods
kubectl get svc
kubectl get ingress
```

---

## 🔟 בדיקת גישה בדפדפן

קח את ה־EXTERNAL-IP של Ingress Controller:

```bash
kubectl get svc -n ingress-nginx
```

פתח בדפדפן:

```
http://<INGRESS-EXTERNAL-IP>/
```

האפליקציה far-2-cel אמורה להופיע.

---

## 1️⃣1️⃣ תרגיל 1 – Scaling דרך Helm

```bash
nano values.yaml
# שנה replicaCount ל-5
```

```bash
helm upgrade far-demo .
kubectl get pods
```

---

## 1️⃣2️⃣ תרגיל 2 – Upgrade גרסה

בנה Image חדש:

```bash
docker build -t gcr.io/gcp-2026/far-2-cel:2.0 .
docker push gcr.io/gcp-2026/far-2-cel:2.0
```

עדכן values.yaml:

```yaml
tag: "2.0"
```

```bash
helm upgrade far-demo .
kubectl rollout status deployment far-demo
```

---

## 1️⃣3️⃣ תרגיל 3 – Rollback

```bash
helm history far-demo
helm rollback far-demo 1
```

---

## 1️⃣4️⃣ תרגיל 4 – Ingress Routing מתקדם

הוסף שירות נוסף (nginx) ונתיב:

```yaml
- path: /nginx
  pathType: Prefix
  backend:
    service:
      name: nginx
      port:
        number: 80
```

בדוק:

```
http://<INGRESS-IP>/
http://<INGRESS-IP>/nginx
```

---

## 1️⃣5️⃣ ניקוי משאבים

```bash
helm uninstall far-demo
gcloud container clusters delete far-gke-demo --region us-central1
```

---

## ✅ סיום

במסמך זה ביצעת:

- יצירת Cluster ב-GKE  
- התקנת Helm  
- יצירת Chart  
- פריסה עם Helm  
- Ingress  
- Scaling  
- Upgrade  
- Rollback  

זהו תרגיל Production מלא לשיעור מסכם.

סוף המסמך.
