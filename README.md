# 🚀 הדגמת Amazon EKS  
### Terraform • AWS CloudShell • Kubernetes

**Region:** us-east-1 (N. Virginia)  
**שם ה־Repository:** eks-far-2-cel-demo-30-12  

---

## 🎯 מטרת התרגיל

מסמך זה מציג תהליך **מלא, מדויק ומעודכן** להקמת **Amazon EKS** באמצעות **Terraform**,  
והרצה של **אפליקציית Flask אמיתית** בתוך Kubernetes – משלב אפס ועד תרגול כיתתי מתקדם.

⏱️ משך כולל: כ־2–2.5 שעות  
🎓 מיועד לקורס / דמו / סדנה מעשית

---

## 🧱 ארכיטקטורה כללית (High Level)

Terraform  
→ Amazon VPC  
→ Amazon EKS (Kubernetes 1.30)  
→ Managed Node Group  
→ Amazon ECR  
→ Deployment  
→ Service (LoadBalancer)  
→ כתובת ציבורית בדפדפן  

---

## ✅ דרישות מקדימות

### נדרש
- חשבון AWS פעיל  
- משתמש IAM עם הרשאות Administrator (לצורכי קורס בלבד)  
- חשבון GitHub  

### לא נדרש
- התקנות מקומיות  
- Docker מקומי  
- Terraform מקומי  

> 💡 כל העבודה מתבצעת בענן – באמצעות **AWS CloudShell בלבד**.

---


## 1️⃣ כניסה ל-AWS Console ובחירת Region

1. פתח דפדפן  
2. היכנס לכתובת: https://console.aws.amazon.com  
3. התחבר לחשבון ה-AWS שלך  
4. בפינה הימנית העליונה בחר Region: 


**N. Virginia (us-east-1)**

---

## 2️⃣ פתיחת AWS CloudShell

בדיקה:
```bash
aws sts get-caller-identity
```

---

## 3️⃣ יצירת IAM User ייעודי (שלב חובה)

❗ לא עובדים עם root בכיתה.

**שם המשתמש:**
```
eks-far-2-cel-demo-user
```

### הרשאות (Attach policies directly):
- AdministratorAccess  
- AdministratorAccess-Amplify  
- AdministratorAccess-AWSElasticBeanstalk  
- AWSAuditManagerAdministratorAccess  
- AWSManagementConsoleAdministratorAccess  
- IAMUserChangePassword  

---

## 4️⃣ הגדרת AWS CLI ב־CloudShell

```bash
aws configure
```

בדיקה:
```bash
aws sts get-caller-identity
```

---

## 5️⃣ התקנת Terraform (גרסה עדכנית)

```bash
cd ~
curl -sLo terraform.zip https://releases.hashicorp.com/terraform/1.7.5/terraform_1.7.5_linux_amd64.zip
unzip terraform.zip
sudo mv terraform /usr/local/bin/
rm terraform.zip
terraform version
```

---

## 6️⃣ טיפול במגבלת דיסק של CloudShell

```bash
export TF_PLUGIN_CACHE_DIR=/tmp/terraform-plugin-cache
mkdir -p /tmp/terraform-plugin-cache
```

---

## 7️⃣ Clone של ה־Repository (שלב חובה)

📌 זהו השלב שבו נוצרת סביבת העבודה בפועל.

```bash
cd ~
git clone https://github.com/agorbach/eks-far-2-cel-demo-30-12.git
cd eks-far-2-cel-demo-30-12
```

מבנה צפוי:
```
README.md

```

---

## 8️⃣ יצירת קבצי Terraform (ללא תיקיית infra)

> כל הקבצים נמצאים **בתיקייה הראשית של ה־Repository**.

---

### 8.1 יצירת versions.tf

```bash
nano versions.tf
```

```hcl
terraform {
  required_version = ">= 1.6.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 6.0.0"
    }
  }
}


```

---

### 8.2 יצירת provider.tf

```bash
nano provider.tf
```

```hcl
provider "aws" {
  region = "us-east-1"
}
```

---

### 8.3 יצירת main.tf (קובץ מלא)

```bash
nano main.tf
```

⚠️ **חובה להחליף `ACCOUNT_ID` במספר החשבון שלכם.**

```hcl
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.5.1"

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
  version = "21.0.0"

  cluster_name    = "eks-far-2-cel-demo-30-12"
  cluster_version = "1.30"

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

kubectl get nodes
```

---

## 1️⃣1️⃣ המשך תרגול Kubernetes בכיתה



# 🧠 חלק ב׳ – תרגול מעשי (כשעה)

## תרגיל 1 – Pods ו־Nodes

```bash
kubectl get pods -o wide
kubectl get nodes -o wide
```

שאלות:
- כמה Pods רצים?
- על איזה Node כל Pod?

---

## תרגיל 2 – מחיקת Pod

```bash
kubectl delete pod <POD_NAME>
kubectl get pods
```

❓ למה ה־Pod חוזר לבד?

---

## תרגיל 3 – שינוי replicas

```bash
kubectl scale deployment far-2-cel --replicas=5
kubectl get pods
```

---

## תרגיל 4 – מחיקת Service

```bash
kubectl delete svc far-2-cel
kubectl get svc
```

❓ למה האפליקציה נופלת למרות שה־Pods רצים?

---

## תרגיל 5 – החזרת Service

```bash
kubectl apply -f service.yaml
kubectl get svc far-2-cel
```

---

## תרגיל 6 – Logs

```bash
kubectl logs <POD_NAME>
```

---

## תרגיל 7 – מחיקת Deployment

```bash
kubectl delete deployment far-2-cel
kubectl get pods
```

---

## תרגיל 8 – ניקוי מלא

```bash
kubectl delete svc far-2-cel
kubectl delete deployment far-2-cel
```

---

## 1️⃣2️⃣ ניקוי משאבים

```bash
terraform destroy
```

---

## ✅ סיכום

✔ תהליך מלא, רציף וללא חורים  
✔ כולל Clone, Terraform, EKS ו־Kubernetes  
✔ מותאם לגרסאות עדכניות  
✔ מוכן לעבודה בכיתה  

---
