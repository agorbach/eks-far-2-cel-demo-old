# 🚀 הדגמת Amazon EKS  
### Terraform • AWS CloudShell • Kubernetes
1. פתח דפדפן אינטרנט  
2. היכנס לכתובת:  
   https://console.aws.amazon.com
3. התחבר לחשבון ה־AWS שלך  
4. בפינה הימנית העליונה של המסך, בחר Region:
**שם ה־Repository:** eks-far-2-cel-demo-30-12  
**Region:** us-east-1 (N. Virginia)

---

## 🎯 מטרת התרגיל

מסמך זה מציג תהליך מלא, מסודר וברור להקמת **Amazon EKS** באמצעות **Terraform**,  
והרצה של **אפליקציה אמיתית** בתוך Kubernetes – משלב אפס ועד אפליקציה זמינה בדפדפן.

התרגיל מיועד לדמו בכיתה / קורס DevOps / הדרכה, וכולל:

- עבודה אך ורק מתוך **AWS CloudShell** (ללא התקנות מקומיות)
- יצירת **IAM User ייעודי**
- הקמת **VPC**
- הקמת **EKS Cluster**
- Managed Node Group
- חיבור הרשאות **IAM ↔ Kubernetes (RBAC)**
- Build של Docker Image
- Push ל־Amazon ECR
- Deployment + Service ב־Kubernetes
- גישה חיצונית לאפליקציה

---

## 🧱 ארכיטקטורה כללית (High Level)

GitHub (קוד האפליקציה)  
→ Docker Image  
→ Amazon ECR  
→ Amazon EKS  
→ Deployment  
→ Service (LoadBalancer)  
→ כתובת ציבורית בדפדפן

---

## ✅ דרישות מקדימות

### נדרש
- חשבון AWS פעיל  
- הרשאות Administrator (לצורכי דמו / קורס)  
- חשבון GitHub  

### לא נדרש
- AWS CLI מקומי  
- Terraform מקומי  
- Docker מקומי  

> 💡 כל העבודה מתבצעת בענן – באמצעות **AWS CloudShell בלבד**.

---

## 1️⃣ בחירת Region

ב־AWS Console (בחלק העליון הימני):

**Region:** `N. Virginia (us-east-1)`

⚠️ כל השלבים במסמך זה מניחים עבודה ב־Region זה.

---

## 2️⃣ פתיחת AWS CloudShell

1. היכנס ל־AWS Console  
2. לחץ על אייקון **CloudShell (>_)**  
3. ודא ש־CloudShell רץ ב־`us-east-1`  

בדיקה:
```bash
aws sts get-caller-identity
```

---

## 3️⃣ יצירת IAM User ייעודי (שלב חובה)

❗ לא עובדים עם משתמש root בכיתה.  
יוצרים משתמש ברור ומבודד לצורכי לימוד.

### 3.1 יצירת המשתמש

AWS Console → IAM → Users → Create user  

**שם המשתמש:**
```
eks-far-2-cel-demo-user
```

סמן:
- ✔ AWS Management Console access  
- ✔ Programmatic access  

---

### 3.2 הרשאות למשתמש

Attach policies directly:
- **AdministratorAccess**

> 📝 לצורכי קורס בלבד. בפרודקשן יש להשתמש ב־Least Privilege.

---

### 3.3 יצירת Access Keys

במהלך יצירת המשתמש:
- צור **Access Key**
- שמור בצד:
  - Access Key ID  
  - Secret Access Key  

---

## 4️⃣ הגדרת AWS CLI ב־CloudShell

ב־CloudShell:
```bash
aws configure
```

הכנס:
- Access Key ID  
- Secret Access Key  
- Default region: `us-east-1`  
- Output format: `json`  

בדיקה:
```bash
aws sts get-caller-identity
```

פלט צפוי:
```
arn:aws:iam::ACCOUNT_ID:user/eks-far-2-cel-demo-user
```

---

## 5️⃣ התקנת Terraform ב־CloudShell

Terraform **אינו מותקן כברירת מחדל**.

```bash
cd ~
curl -sLo terraform.zip https://releases.hashicorp.com/terraform/1.6.6/terraform_1.6.6_linux_amd64.zip
unzip terraform.zip
sudo mv terraform /usr/local/bin/
rm terraform.zip
terraform -version
```

---

## 6️⃣ טיפול במגבלת דיסק של CloudShell (קריטי)

CloudShell מגיע עם נפח דיסק קטן.  
שלב זה מונע שגיאות מסוג `no space left on device`.

```bash
export TF_PLUGIN_CACHE_DIR=/tmp/terraform-plugin-cache
mkdir -p /tmp/terraform-plugin-cache
```

---

## 7️⃣ Clone של ה־Repository

```bash
cd ~
git clone https://github.com/agorbach/eks-far-2-cel-demo-30-12.git
cd eks-far-2-cel-demo-30-12
```

מבנה צפוי:
```
infra/
k8s/
app/
```

---

## 8️⃣ קבצי Terraform

### 8.1 infra/versions.tf

```hcl
terraform {
  required_version = ">= 1.6.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.30"
    }
  }
}
```

⚠️ חשוב:  
לא להשתמש ב־AWS provider 6.x – אינו תואם למודול EKS שבשימוש.

---

### 8.2 infra/provider.tf

```hcl
provider "aws" {
  region = "us-east-1"
}
```

---

### 8.3 infra/main.tf (קובץ מלא)

⚠️ **חובה להחליף את `ACCOUNT_ID` במספר החשבון שלכם.**

```hcl
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.1.2"

  name = "eks-far-2-cel-demo-30-12-vpc"
  cidr = "10.0.0.0/16"

  azs             = ["us-east-1a", "us-east-1b"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24"]

  enable_nat_gateway = true
  single_nat_gateway = true
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "20.24.3"

  cluster_name    = "eks-far-2-cel-demo-30-12"
  cluster_version = "1.29"

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  access_entries = {
    admin = {
      principal_arn = "arn:aws:iam::ACCOUNT_ID:user/eks-far-2-cel-demo-user"

      policy_associations = {
        admin = {
          policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
          access_scope = {
            type = "cluster"
          }
        }
      }
    }
  }

  eks_managed_node_groups = {
    default = {
      instance_types = ["t3.medium"]
      desired_size   = 2
      min_size       = 1
      max_size       = 3
    }
  }
}
```

---

## 9️⃣ יצירת ה־EKS באמצעות Terraform

```bash
cd infra
rm -rf .terraform .terraform.lock.hcl
terraform init -upgrade
terraform apply
```

אשר עם:
```
yes
```

⏱️ זמן הקמה משוער: 10–15 דקות.

---

## 🔟 חיבור kubectl ל־EKS

```bash
aws eks update-kubeconfig   --region us-east-1   --name eks-far-2-cel-demo-30-12
```

בדיקה:
```bash
kubectl get nodes
```

---

## 1️⃣1️⃣ הרצת אפליקציית far-2-cel בתוך Kubernetes

### 11.1 הורדת קוד האפליקציה

```bash
cd ~/eks-far-2-cel-demo-30-12
mkdir -p app
cd app
git clone https://github.com/agorbach/test2025.git
cd test2025/far-2-cel
```

---

### 11.2 Dockerfile (אם לא קיים)

```dockerfile
FROM python:3.11-slim
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY . .
EXPOSE 5000
CMD ["python", "app.py"]
```

---

### 11.3 יצירת ECR Repository

```bash
aws ecr create-repository   --repository-name far-2-cel   --region us-east-1
```

---

### 11.4 התחברות ל־ECR

⚠️ **חובה להחליף ACCOUNT_ID**

```bash
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com
```

---

### 11.5 Build ו־Push של האימג׳

```bash
docker build -t far-2-cel:1.0 .
docker tag far-2-cel:1.0 ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com/far-2-cel:1.0
docker push ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com/far-2-cel:1.0
```

---

### 11.6 Deployment ו־Service ב־Kubernetes

**deployment.yaml**
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: far-2-cel
spec:
  replicas: 2
  selector:
    matchLabels:
      app: far-2-cel
  template:
    metadata:
      labels:
        app: far-2-cel
    spec:
      containers:
        - name: far-2-cel
          image: ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com/far-2-cel:1.0
          ports:
            - containerPort: 5000
```

**service.yaml**
```yaml
apiVersion: v1
kind: Service
metadata:
  name: far-2-cel
spec:
  type: LoadBalancer
  selector:
    app: far-2-cel
  ports:
    - port: 80
      targetPort: 5000
```

```bash
kubectl apply -f deployment.yaml
kubectl apply -f service.yaml
kubectl get svc far-2-cel
```

פתח בדפדפן:
```
http://<EXTERNAL-IP>
```

🎉 זהו רגע ה־WOW בכיתה.

---

## 1️⃣2️⃣ ניקוי משאבים (בסיום שיעור)

```bash
cd infra
terraform destroy
```

---

## ✅ סיכום

✔ EKS הוקם בהצלחה  
✔ IAM מחובר ל־Kubernetes  
✔ אפליקציה אמיתית רצה ב־Cluster  
✔ מדריך מלא, ברור ומוכן לכיתה  

---

סוף המסמך.
