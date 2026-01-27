# 🚀 תרגיל סיום – GKE + Helm + Ingress 

**Repository:** `eks-far-2-cel-demo-30-12`  
**תיקייה ייעודית ב־Repo:** `gke/`  
**Project (GCP):** `gcp-2026`  
**Region/Zone:** `us-central1` / `us-central1-a`  
**Cluster Name:** `far-gke-demo`  


---

## ✅ 0) לפני שמתחילים – מה נדרש

### נדרש ב־GCP Console (חד־פעמי)
1. פתח דפדפן → Google Cloud Console  
2. ודא שיש Billing פעיל לפרויקט  
3. ודא שהפרויקט נקרא: `gcp-2026`  
4. Enable APIs:
   - **Kubernetes Engine API**
   - **Compute Engine API**
   - (מומלץ) **Artifact Registry API**

### עבודה מומלצת
- לעבוד מתוך **Google Cloud Shell** (אין התקנות מקומיות).

---

## 1) פתיחת Cloud Shell והגדרת Project/Region/Zone

ב־GCP Console לחץ: **Activate Cloud Shell**

הרץ:

```bash
gcloud config set project gcp-2026
gcloud config set compute/region us-central1
gcloud config set compute/zone us-central1-a
```

בדיקה:

```bash
gcloud config list
gcloud auth list
```

אם `gcloud auth list` מראה משתמש מחובר – מצוין.

---

## 2) יצירת Cluster ב־GKE (הכי קצר)

הרץ פקודה אחת ליצירת Cluster:

```bash
gcloud container clusters create far-gke-demo \
  --region us-central1 \
  --num-nodes 2 \
  --machine-type e2-medium \
  --enable-ip-alias
```

⏱️ 5–10 דקות.

---

## 3) חיבור kubectl ל־Cluster + בדיקות

חיבור credentials:

```bash
gcloud container clusters get-credentials far-gke-demo --region us-central1
```

בדיקות:

```bash
kubectl cluster-info
kubectl get nodes -o wide
kubectl get ns
```

**תוצאה תקינה:** 2 Nodes במצב `Ready`.

---

## 4) הכנת ה־Repository והמבנה ב־GitHub

### 4.1 Clone ל־Cloud Shell

בתיקיית הבית:

```bash
cd ~
git clone https://github.com/agorbach/eks-far-2-cel-demo-30-12.git
cd eks-far-2-cel-demo-30-12
```

### 4.2 יצירת מבנה תיקיות (אם לא קיים)

ב־root של ה־repo:

```bash
mkdir -p gke/helm
mkdir -p app/far-2-cel
```

מבנה צפוי בסוף:

```
eks-far-2-cel-demo-30-12/
├── app/
│   └── far-2-cel/                 # קוד האפליקציה + Dockerfile
└── gke/
    ├── readme-gke.md              # המסמך הזה
    └── helm/
        └── far-2-cel/             # Helm Chart
```

---

## 5) הבאת קוד האפליקציה far-2-cel לתוך ה־Repo

אם כבר יש אצלך קוד ב־repo – דלג.  
אם לא: נביא אותו מה־repo `test2025`:

```bash
cd ~/eks-far-2-cel-demo-30-12/app
git clone https://github.com/agorbach/test2025.git
rm -rf far-2-cel
cp -r test2025/far-2-cel ./far-2-cel
rm -rf test2025
```

בדיקה:

```bash
ls -la ~/eks-far-2-cel-demo-30-12/app/far-2-cel
```

**חובה לראות:** `main.py` ו־`Dockerfile` (או ליצור בהמשך).

---

## 6) יצירת Dockerfile תקין (במידה וחסר או צריך אחידות)

היכנס לתיקיית האפליקציה:

```bash
cd ~/eks-far-2-cel-demo-30-12/app/far-2-cel
```

צור/ערוך Dockerfile:

```bash
nano Dockerfile
```

הדבק את זה (עובד, קטן, ודטרמיניסטי):

```dockerfile
FROM python:3.11-slim

WORKDIR /app
COPY . /app

RUN pip install --no-cache-dir Flask

EXPOSE 8080
CMD ["python", "/app/main.py"]
```

בדיקה שיש main.py:

```bash
ls -la main.py
```

> אם שם הקובץ אצלך הוא `app.py` במקום `main.py` – שנה את ה־CMD בהתאם.

---

## 7) בחירת Registry ב־GCP (מומלץ Artifact Registry)

### 7.1 יצירת Artifact Registry (חד־פעמי)

הרץ:

```bash
gcloud services enable artifactregistry.googleapis.com
gcloud artifacts repositories create demo-repo \
  --repository-format=docker \
  --location=us-central1 \
  --description="Docker repo for GKE demo"
```

### 7.2 Login לדוקר

```bash
gcloud auth configure-docker us-central1-docker.pkg.dev
```

### 7.3 בניית Image + Push

הגדר משתנים:

```bash
PROJECT_ID=gcp-2026
REGION=us-central1
REPO=demo-repo
IMAGE=far-2-cel
TAG=1.0
```

Build:

```bash
cd ~/eks-far-2-cel-demo-30-12/app/far-2-cel
docker build -t us-central1-docker.pkg.dev/$PROJECT_ID/$REPO/$IMAGE:$TAG .
```

Push:

```bash
docker push us-central1-docker.pkg.dev/$PROJECT_ID/$REPO/$IMAGE:$TAG
```

בדיקה:

```bash
gcloud artifacts docker images list us-central1-docker.pkg.dev/$PROJECT_ID/$REPO --include-tags
```

---

## 8) התקנת Helm

```bash
curl -sSL https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
helm version
```

---

## 9) התקנת Ingress Controller (NGINX) ל־GKE

ניצור namespace ונפרוס NGINX Ingress:

```bash
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.9.5/deploy/static/provider/cloud/deploy.yaml
```

להמתין עד שהפודים Ready:

```bash
kubectl get pods -n ingress-nginx -w
```

כשהכול Ready, עצור עם Ctrl+C.

קבלת External IP של ה־Ingress Controller:

```bash
kubectl get svc -n ingress-nginx
```

שמור את ה־EXTERNAL-IP של `ingress-nginx-controller` (לדוגמה: `34.xx.xx.xx`).

---

## 10) יצירת Helm Chart לאפליקציה

### 10.1 יצירת Chart

```bash
cd ~/eks-far-2-cel-demo-30-12/gke/helm
helm create far-2-cel
cd far-2-cel
```

מבנה בסיסי:

```
gke/helm/far-2-cel/
├── Chart.yaml
├── values.yaml
└── templates/
    ├── deployment.yaml
    ├── service.yaml
    ├── ingress.yaml
    └── ...
```

### 10.2 עריכת values.yaml (חובה)

```bash
nano values.yaml
```

החלף את התוכן ל־(מינימום ברור):

```yaml
replicaCount: 3

image:
  repository: us-central1-docker.pkg.dev/gcp-2026/demo-repo/far-2-cel
  tag: "1.0"
  pullPolicy: IfNotPresent

service:
  type: ClusterIP
  port: 80
  targetPort: 8080

ingress:
  enabled: true
  className: nginx
  annotations: {}
  hosts:
    - host: ""
      paths:
        - path: /
          pathType: Prefix
  tls: []
```

### 10.3 עדכון templates/deployment.yaml

פתח:

```bash
nano templates/deployment.yaml
```

וודא ש־containerPort מתאים (8080) ושימוש ב־Values:

חפש את `containerPort:` ועדכן ל־8080:

```yaml
ports:
  - name: http
    containerPort: 8080
    protocol: TCP
```

(שאר התבנית נשארת כפי ש־helm create יצר.)

### 10.4 עדכון templates/service.yaml

פתח:

```bash
nano templates/service.yaml
```

וודא שיש mapping נכון ל־targetPort 8080 (ברוב תבניות Helm זה מגיע מה־values).  
אם יש `targetPort: http` זה תקין כל עוד ה־port name ב־deployment הוא `http`.  
אם אין – תגדיר:

```yaml
ports:
  - port: {{ .Values.service.port }}
    targetPort: 8080
    protocol: TCP
    name: http
```

### 10.5 עדכון templates/ingress.yaml

פתח:

```bash
nano templates/ingress.yaml
```

וודא שהוא משתמש ב־ingress.className: nginx ושה־backend מצביע ל־service של chart.

---

## 11) Deploy ראשון עם Helm + בדיקות

### 11.1 התקנה (Install)

מתיקיית ה־chart:

```bash
cd ~/eks-far-2-cel-demo-30-12/gke/helm/far-2-cel
helm install far-demo .
```

בדיקות:

```bash
helm list
kubectl get deploy,rs,pods
kubectl get svc
kubectl get ingress
```

### 11.2 בדיקת גישה בדפדפן

קח את ה־Ingress External IP (של ingress-nginx-controller) והיכנס:

```
http://<INGRESS-EXTERNAL-IP>/?celsius=78
```

---

## 12) Troubleshooting מהיר (כשלא עובד)

### 12.1 Ingress לא נותן תשובה?

בדוק ingress:

```bash
kubectl describe ingress far-demo-far-2-cel
```

בדוק service endpoints:

```bash
kubectl get endpoints
kubectl describe svc far-demo-far-2-cel
```

בדוק logs של האפליקציה:

```bash
kubectl logs deploy/far-demo-far-2-cel --tail=100
```

### 12.2 Pod לא עולה?

```bash
kubectl describe pod <POD_NAME>
kubectl get events --sort-by=.metadata.creationTimestamp | tail -n 30
```

---

# 🧪 תרגילי סיום (שעה–שעתיים)

## תרגיל A – Scaling דרך Helm

1. ערוך `values.yaml`:
   - `replicaCount: 1`
2. הרץ:

```bash
helm upgrade far-demo .
kubectl get pods
```

**בדיקה:** מספר הפודים יורד.

---

## תרגיל B – Upgrade גרסה (שינוי קוד → Image חדש → Helm upgrade)

1. ערוך את האפליקציה (לדוגמה צבעים/כותרת ב־HTML)
2. בנה Image חדש:

```bash
TAG=2.0
docker build -t us-central1-docker.pkg.dev/$PROJECT_ID/$REPO/$IMAGE:$TAG .
docker push us-central1-docker.pkg.dev/$PROJECT_ID/$REPO/$IMAGE:$TAG
```

3. עדכן `values.yaml`:

```yaml
image:
  tag: "2.0"
```

4. בצע Upgrade:

```bash
helm upgrade far-demo .
kubectl rollout status deploy/far-demo-far-2-cel
```

**בדיקה:** רואים שינוי בדפדפן.

---

## תרגיל C – Rollback

```bash
helm history far-demo
helm rollback far-demo 1
```

**בדיקה:** האפליקציה חוזרת לגרסה קודמת.

---

## תרגיל D – שבירה מכוונת + Debug

1. שנה `values.yaml` לתג שלא קיים: `tag: "999"`
2. הרץ:

```bash
helm upgrade far-demo .
kubectl get pods
kubectl describe pod <POD_NAME>
```

3. תתקן חזרה ל־`2.0` ותעשה Upgrade.

מטרה: לחוות ImagePullBackOff ולהבין Debug.

---

## תרגיל E – הוספת NGINX Service נוסף + Path Routing

מטרה: להראות Ingress מפצל תעבורה לשני Services.

1. פרוס nginx רגיל:

```bash
kubectl create deployment web-nginx --image=nginx
kubectl expose deployment web-nginx --port 80 --type ClusterIP
```

2. ערוך את `templates/ingress.yaml` והוסף נתיב נוסף:

- `/` → far-2-cel
- `/nginx` → web-nginx

(דוגמה קונספטואלית — תתאים לתבנית שלך)

3. Upgrade:

```bash
helm upgrade far-demo .
kubectl get ingress
```

בדיקה:

- `http://<INGRESS-IP>/`
- `http://<INGRESS-IP>/nginx`

---

## תרגיל F – Observability קצר (Logs + Describe + Events)

להראות סט כלים קבוע:

```bash
kubectl get all
kubectl describe ingress
kubectl logs deploy/far-demo-far-2-cel --tail=50
kubectl get events --sort-by=.metadata.creationTimestamp | tail -n 20
```

---

## תרגיל G – Cleanup מלא (סיום שיעור)

מחיקת Release:

```bash
helm uninstall far-demo
```

מחיקת nginx demo:

```bash
kubectl delete svc web-nginx
kubectl delete deploy web-nginx
```

מחיקת Ingress Controller (אופציונלי):

```bash
kubectl delete -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.9.5/deploy/static/provider/cloud/deploy.yaml
```

מחיקת Cluster:

```bash
gcloud container clusters delete far-gke-demo --region us-central1
```

---

## ✅ בדיקות סופיות (Checklist למרצה)

לפני שמסיימים, ודא:

- [ ] `kubectl get nodes` → Ready  
- [ ] `helm list` → far-demo קיים  
- [ ] `kubectl get ingress` → יש ADDRESS  
- [ ] הדפדפן פותח `/?celsius=78` ומחזיר תשובה  
- [ ] עשית Upgrade + Rollback בהצלחה  
- [ ] הדגמת Path Routing (`/nginx`)  

---

סוף המסמך.
