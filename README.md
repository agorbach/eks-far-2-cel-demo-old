# 🚀 הדגמת Amazon EKS  
### Terraform • AWS CloudShell • Kubernetes

**Region:** us-east-1 (N. Virginia)  
**שם ה־Repository:** eks-far-2-cel-demo-30-12  

---

## 🔍 הערות מקדימות חשובות (קריטי לקריאה)

### ✏️ למה משתמשים ב־nano?
ב־AWS CloudShell **אין עורך גרפי**.  
לכן כל יצירת/עריכת קבצים נעשית באמצעות עורך טקסט בטרמינל.

העורך המומלץ והפשוט ביותר:
```bash
nano
```

✔ קיים כברירת מחדל  
✔ נוח ללימוד בכיתה  
✔ ללא קיצורי מקשים מסובכים  

📌 כל קובץ במדריך נוצר כך:
```bash
nano filename.tf
```
שמירה: `Ctrl + O` → Enter  
יציאה: `Ctrl + X`

---

### 🧠 האם נכון להשתמש ב־EKS גרסה 1.29?

❌ **לא.**  
נכון להיום (2026), גרסה **1.29 נחשבת מיושנת**.

AWS תומכת רק ב־3 גרסאות אחרונות של Kubernetes.

### ✅ הגרסה המומלצת כיום:
```
Kubernetes 1.30
```
(יציבה, נתמכת, ומתאימה לכל הכלים)

📌 כל הכלים במדריך זה **מותאמים לגרסה 1.30**:
- Terraform AWS Provider  
- terraform-aws-eks module  
- kubectl  
- EKS Managed Node Groups  

---

## 🎯 מטרת התרגיל

תרגיל כיתתי **מקצה לקצה**:

- הקמת Amazon EKS באמצעות Terraform  
- עבודה מלאה מתוך AWS CloudShell  
- חיבור IAM ↔ Kubernetes  
- פריסת אפליקציית Flask אמיתית  
- תרגול מעשי של Pods / Nodes / LoadBalancer  

⏱️ משך: כ־2–2.5 שעות

---

## 🧱 ארכיטקטורה (High Level)

Terraform  
→ Amazon VPC  
→ Amazon EKS (1.30)  
→ Managed Node Group  
→ Amazon ECR  
→ Kubernetes Deployment  
→ Service (LoadBalancer)  
→ גישה ציבורית בדפדפן  

---

## ✅ דרישות מקדימות

### נדרש
- חשבון AWS פעיל  
- משתמש IAM עם הרשאות Administrator (לקורס בלבד)  
- חשבון GitHub  

### לא נדרש
- התקנות מקומיות  
- Docker מקומי  
- Terraform מקומי  

> 💡 הכל מתבצע ב־AWS CloudShell.

---

## 1️⃣ בחירת Region

AWS Console → Region:

```
us-east-1 (N. Virginia)
```

---

## 2️⃣ פתיחת AWS CloudShell

בדיקה:
```bash
aws sts get-caller-identity
```

---

## 3️⃣ יצירת IAM User ייעודי

**שם:**
```
eks-far-2-cel-demo-user
```

### הרשאות (Attach directly):
- AdministratorAccess  
- AdministratorAccess-Amplify  
- AdministratorAccess-AWSElasticBeanstalk  
- AWSAuditManagerAdministratorAccess  
- AWSManagementConsoleAdministratorAccess  
- IAMUserChangePassword  

⚠️ לקורס בלבד.

---

## 4️⃣ הגדרת AWS CLI

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
terraform -version
```

✔ Terraform 1.7.x תואם לחלוטין ל־EKS 1.30

---

## 6️⃣ טיפול במגבלת דיסק של CloudShell

```bash
export TF_PLUGIN_CACHE_DIR=/tmp/terraform-plugin-cache
mkdir -p /tmp/terraform-plugin-cache
```

---

## 7️⃣ יצירת קבצי Terraform (ללא infra)

📌 כל הקבצים נוצרים בתיקייה הראשית של ה־Repository.

### 7.1 יצירת versions.tf

```bash
nano versions.tf
```

```hcl
terraform {
  required_version = ">= 1.7.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.40"
    }
  }
}
```

---

### 7.2 יצירת provider.tf

```bash
nano provider.tf
```

```hcl
provider "aws" {
  region = "us-east-1"
}
```

---

### 7.3 יצירת main.tf

```bash
nano main.tf
```

⚠️ חובה להחליף `ACCOUNT_ID`

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

## 8️⃣ יצירת ה־EKS

```bash
rm -rf .terraform .terraform.lock.hcl
terraform init -upgrade
terraform apply
```

אישור:
```
yes
```

⏱️ 10–15 דקות.

---

## 9️⃣ חיבור kubectl

```bash
aws eks update-kubeconfig   --region us-east-1   --name eks-far-2-cel-demo-30-12

kubectl get nodes
```

---

## 🔟 תרגול מתקדם (חלק כיתתי)

✔ Pods  
✔ Nodes  
✔ Self-Healing  
✔ Scale  
✔ LoadBalancer  
✔ Logs  

(כפי שנלמד בשיעור)

---

## 1️⃣1️⃣ ניקוי משאבים

```bash
terraform destroy
```

---

## ✅ סיכום

- שימוש בגרסאות עדכניות בלבד  
- עבודה נכונה עם nano  
- EKS יציב ונתמך  
- מסמך מוכן לקורס אמיתי  

---
