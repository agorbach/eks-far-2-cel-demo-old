EKS Demo – Terraform + AWS CloudShell + far-2-cel
🎯 מטרת הפרויקט

דוגמה מלאה, נקייה ולימודית להקמת Amazon EKS באמצעות Terraform,
הרצה אך ורק בענן (AWS CloudShell), ופריסה של אפליקציית הדוגמה far-2-cel.

הפרויקט מיועד ל:

דמו בכיתה

קורס DevOps / Cloud

הדגמה למנהלים / צוותים

סביבת לימוד שחוזרת על עצמה בלי תלות במחשב מקומי

🧱 ארכיטקטורה (High Level)
AWS CloudShell
   |
   |-- Terraform
   |      |-- VPC
   |      |-- EKS Cluster
   |      |-- Managed Node Group
   |
   |-- ECR
   |      |-- Docker image (far-2-cel)
   |
   |-- Kubernetes
          |-- Deployment
          |-- Service (LoadBalancer)

✅ דרישות מקדימות

חשבון AWS פעיל

הרשאות Administrator (או הרשאות מלאות ל-EKS/VPC/IAM)

GitHub account

לא נדרש:

AWS CLI מקומי

Docker מקומי

Terraform מקומי

👉 הכול רץ מתוך AWS CloudShell

🖥️ שלב 1 – פתיחת AWS CloudShell

היכנס ל-AWS Console

בחר Region (מומלץ): eu-central-1

לחץ על אייקון CloudShell (>_)

המתן לפתיחת הטרמינל

בדיקה:

aws sts get-caller-identity

🔧 שלב 2 – התקנת Terraform ב-CloudShell (חובה)

Terraform לא מותקן כברירת מחדל ב-CloudShell

cd ~
curl -sLo terraform.zip https://releases.hashicorp.com/terraform/1.6.6/terraform_1.6.6_linux_amd64.zip
unzip terraform.zip
sudo mv terraform /usr/local/bin/
rm terraform.zip
terraform -version

💾 שלב 3 – טיפול במגבלת דיסק של CloudShell (קריטי)

CloudShell מגיע עם נפח דיסק קטן.
כדי למנוע שגיאות no space left on device:

export TF_PLUGIN_CACHE_DIR=/tmp/terraform-plugin-cache
mkdir -p /tmp/terraform-plugin-cache

📦 שלב 4 – Clone של ה-Repository
cd ~
git clone https://github.com/agorbach/eks-far-2-cel-demo-old.git
cd eks-far-2-cel-demo-old


מבנה הפרויקט:

infra/   # Terraform (EKS + VPC)
k8s/     # Kubernetes manifests
app/     # Application source (far-2-cel)

🧱 שלב 5 – Terraform (EKS + VPC)
📁 infra/versions.tf
terraform {
  required_version = ">= 1.6.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.30"
    }
  }
}


⚠️ חשוב:
AWS provider 6.x לא תואם למודול EKS 20.x

📁 infra/provider.tf
provider "aws" {
  region = "eu-central-1"
}

📁 infra/main.tf
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.1.2"

  name = "eks-demo-vpc"
  cidr = "10.0.0.0/16"

  azs             = ["eu-central-1a", "eu-central-1b"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24"]

  enable_nat_gateway = true
  single_nat_gateway = true
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "20.24.3"

  cluster_name    = "eks-far-2-cel"
  cluster_version = "1.29"

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  eks_managed_node_groups = {
    default = {
      instance_types = ["t3.medium"]
      desired_size   = 2
      min_size       = 1
      max_size       = 3
    }
  }
}

▶️ שלב 6 – Terraform Init / Apply
cd infra
rm -rf .terraform .terraform.lock.hcl
terraform init -upgrade
terraform apply


אשר עם:

yes


⏱️ זמן הקמה: ~10–15 דקות

🔗 שלב 7 – חיבור kubectl ל-EKS
aws eks update-kubeconfig \
  --region eu-central-1 \
  --name eks-far-2-cel


בדיקה:

kubectl get nodes

📦 שלב 8 – Build & Push ל-ECR
יצירת Repository
aws ecr create-repository --repository-name far-2-cel

Login
aws ecr get-login-password | docker login \
  --username AWS \
  --password-stdin <ACCOUNT_ID>.dkr.ecr.eu-central-1.amazonaws.com

Build & Push
cd app/far-2-cel
docker build -t far-2-cel:1.0 .
docker tag far-2-cel:1.0 <ACCOUNT_ID>.dkr.ecr.eu-central-1.amazonaws.com/far-2-cel:1.0
docker push <ACCOUNT_ID>.dkr.ecr.eu-central-1.amazonaws.com/far-2-cel:1.0

☸️ שלב 9 – Kubernetes Deployment
📁 k8s/deployment.yaml
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
          image: <ACCOUNT_ID>.dkr.ecr.eu-central-1.amazonaws.com/far-2-cel:1.0
          ports:
            - containerPort: 5000

📁 k8s/service.yaml
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


Apply:

kubectl apply -f k8s/
kubectl get svc

🌍 שלב 10 – גישה לאפליקציה

כשתופיע כתובת:

EXTERNAL-IP


פתח בדפדפן:

http://<EXTERNAL-IP>

🧹 ניקוי משאבים (בסיום דמו)
kubectl delete -f k8s/
cd infra
terraform destroy

⚠️ תקלות נפוצות ופתרונות
❌ no space left on device

➡️ Restart ל-CloudShell + שימוש ב-/tmp ל-Terraform cache

❌ Unsupported block type

➡️ AWS provider 6.x
➡️ פתרון: pin ל-~> 5.30

❌ Duplicate module / provider

➡️ מחיקה ויצירה מחדש של הקובץ

✅ סטטוס הפרויקט

✔️ EKS נבנה בהצלחה
✔️ Terraform רץ בענן בלבד
✔️ מתאים לקורס / דמו / הדרכה
