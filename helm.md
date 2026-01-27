# 🚀 GKE + Helm + Ingress – מדריך והסברים (readme-gke.md)

 
---

## 🎯 מטרת המסמך

מסמך זה מיועד לשיעור מתקדם על:
- Helm Package Manager  
- Ingress Controller  
- עבודה על Google Kubernetes Engine (GKE)  
- תרגול Deploy, Upgrade, Rollback ו‑Debug  

המטרה הפדגוגית:
> להפוך את הסטודנט מ־"מריץ YAML" ל־**מנהל מערכת Kubernetes**.

---

## 🧠 חלק 1 – מה זה Helm?

### למה בכלל Helm?

בלי Helm, כל פריסה דורשת:
- deployment.yaml  
- service.yaml  
- ingress.yaml  
- configmap.yaml  

בעיות:
- הרבה קבצים  
- שכפול קוד  
- אין ניהול גרסאות לפריסה  
- אין Rollback  

### מה Helm פותר?

Helm הוא:
- Package Manager ל‑Kubernetes  
- מאפשר לארוז אפליקציה כ‑Chart  
- מאפשר:
  - Install  
  - Upgrade  
  - Rollback  
  - Environments (dev/prod)  

### מושגים חשובים

| מושג | הסבר |
|-----|------|
| Chart | חבילת Helm (תבנית של אפליקציה) |
| Values | קובץ קונפיגורציה |
| Template | YAML דינמי עם משתנים |
| Release | פריסה בפועל בקלאסטר |
| Revision | גרסה של פריסה |

### פקודות ליבה

```bash
helm install far-demo .
helm upgrade far-demo .
helm history far-demo
helm rollback far-demo 1
```

משפט זהב לכיתה:
> YAML זה קובץ.  
> Helm זה מערכת פריסה.

---

## 🧠 חלק 2 – מה זה Ingress?

### למה Ingress?

בלי Ingress:
- כל Service = LoadBalancer  
- הרבה כתובות IP  
- יקר  
- לא סקיילבילי  

Ingress מאפשר:
- כתובת אחת  
- Routing לפי Path / Host  
- TLS במקום אחד  

### ארכיטקטורה

Client  
→ LoadBalancer  
→ Ingress Controller (NGINX)  
→ Ingress Rules  
→ Service  
→ Pod  

### דוגמת Ingress

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: far-ingress
spec:
  rules:
  - http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: far-2-cel
            port:
              number: 80
```

משפט זהב:
> Ingress לא מפנה ל‑Pod.  
> Ingress מפנה ל‑Service.

---

## 🧪 חלק 3 – תרגילי Deploy לשיעור

### תרגיל 1 – Install ראשון

```bash
helm install far-demo .
kubectl get pods
kubectl get svc
kubectl get ingress
```

שאלות:
- מה נוצר בפועל?
- כמה אובייקטים Kubernetes נוצרו?

---

### תרגיל 2 – Scaling דרך Helm

```bash
# values.yaml
replicaCount: 1

helm upgrade far-demo .
kubectl get pods
```

שאלות:
- למה Helm שולט במספר ה‑Pods?
- מי עושה את ה‑Scheduling?

---

### תרגיל 3 – Upgrade גרסה

```bash
docker build -t gcr.io/gcp-2026/far-2-cel:2.0 .
docker push gcr.io/gcp-2026/far-2-cel:2.0
```

```bash
# values.yaml
tag: "2.0"

helm upgrade far-demo .
kubectl rollout status deployment far-demo
```

שאלות:
- למה אין Downtime?
- מה זה Rolling Update?

---

### תרגיל 4 – Rollback

```bash
helm history far-demo
helm rollback far-demo 1
```

שאלות:
- מה חזר אחורה?
- למה זה חשוב בפרודקשן?

---

### תרגיל 5 – שבירה מכוונת

```bash
# values.yaml
tag: "does-not-exist"

helm upgrade far-demo .
kubectl get pods
```

ואז:

```bash
helm rollback far-demo 1
```

מטרה:
- ללמד Debug אמיתי.

---

## 🧠 חלק 4 – מה מדגימים על חיבור ל‑GitHub?

### תרחיש מומלץ לדמו

1. אתה משנה קוד ב‑GitHub (main.py / index.html)  
2. Build Image חדש  
3. Push ל‑Registry  
4. helm upgrade  
5. הסטודנטים רואים שינוי חי בדפדפן  

### Flow פדגוגי

GitHub  
→ Docker Build  
→ Registry  
→ Helm Upgrade  
→ Kubernetes Rolling Update  
→ Browser  

משפט זהב:
> Kubernetes לא מריץ קוד.  
> הוא מריץ Images שמגיעים מ‑CI.

---

## 🔗 חיבור GitHub אוטומטי (רמה מתקדמת)

אם תרצה להראות CI/CD:

אפשר להדגים:

- GitHub Actions  
- Pipeline בסיסי:
  - on push  
  - docker build  
  - docker push  
  - helm upgrade  

רעיון לשקף:

> Commit ב‑GitHub → שינוי באתר תוך 2 דקות.

---

## 📁 מבנה מומלץ ל‑Repository

```
eks-far-2-cel-demo-30-12/
├── app/
│   └── far-2-cel/
├── helm/
│   └── far-2-cel/
├── gke/
│   ├── readme-gke.md   <-- המסמך הזה
│   └── commands.txt
└── README.md
```

---

## 🎯 סיכום פדגוגי

ביחידה זו כיסית:

| נושא | כוסה |
|------|------|
| Managed Kubernetes (GKE) | ✔ |
| Helm Concepts | ✔ |
| Helm CLI | ✔ |
| Ingress | ✔ |
| Upgrade / Rollback | ✔ |
| CI/CD Flow | ✔ |
| Debugging | ✔ |

משפט סיום לשיעור:

> מי שמבין Helm ו‑Ingress –  
> כבר עובד ברמת Production.

---

סוף המסמך.
