# 🚀 הדגמת Amazon EKS  
### Terraform • AWS CloudShell • Kubernetes

1. פתח דפדפן אינטרנט  
2. היכנס לכתובת: https://console.aws.amazon.com  
3. התחבר לחשבון ה־AWS שלך  
4. בפינה הימנית העליונה של המסך, בחר Region  

**Region:** us-east-1 (N. Virginia)  
**שם ה־Repository:** eks-far-2-cel-demo-30-12  

---

## 🎯 מטרת התרגיל

מסמך זה מציג תהליך **מלא ומעמיק** להקמת **Amazon EKS** באמצעות **Terraform**  
והרצת **אפליקציית Flask אמיתית** בתוך Kubernetes – משלב אפס ועד תרגול מתקדם.

המסמך מיועד לדמו בכיתה / קורס DevOps  
ומכיל גם **תרגול מעשי של כשעתיים** לאחר שהאפליקציה רצה.

---

## 🧱 ארכיטקטורה כללית (High Level)

GitHub (קוד)  
→ Terraform  
→ Amazon VPC  
→ Amazon EKS  
→ Node Group  
→ Docker Image  
→ Amazon ECR  
→ Deployment  
→ Service (LoadBalancer)  
→ כתובת ציבורית בדפדפן  

---

## ✅ דרישות מקדימות

### נדרש
- חשבון AWS פעיל  
- הרשאות Administrator (לצורכי קורס)  
- חשבון GitHub  

### לא נדרש
- התקנות מקומיות  
- Docker מקומי  
- Terraform מקומי  

> 💡 כל העבודה מתבצעת בענן – באמצעות **AWS CloudShell בלבד**.

---

## 1️⃣ בחירת Region

**Region:** `N. Virginia (us-east-1)`  
⚠️ כל השלבים במסמך זה מניחים עבודה ב־Region זה.

---

## 2️⃣ פתיחת AWS CloudShell

```bash
aws sts get-caller-identity
```

---

## 3️⃣ יצירת IAM User ייעודי

**שם המשתמש:**
```
eks-far-2-cel-demo-user
```

יש להוסיף למשתמש את ההרשאות:
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

## 5️⃣ התקנת Terraform ב־CloudShell

```bash
cd ~
curl -sLo terraform.zip https://releases.hashicorp.com/terraform/1.6.6/terraform_1.6.6_linux_amd64.zip
unzip terraform.zip
sudo mv terraform /usr/local/bin/
terraform -version
```

---

## 6️⃣ טיפול במגבלת דיסק של CloudShell

```bash
export TF_PLUGIN_CACHE_DIR=/tmp/terraform-plugin-cache
mkdir -p /tmp/terraform-plugin-cache
```

---

## 7️⃣ יצירת קבצי Terraform (ללא תיקיית infra)

> כל הקבצים נוצרים **בתיקייה הראשית של ה־Repository**.

---

### 7.1 versions.tf

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
אין להשתמש ב־AWS provider 6.x.

---

### 7.2 provider.tf

```hcl
provider "aws" {
  region = "us-east-1"
}
```

---

### 7.3 main.tf (קובץ מלא)

⚠️ חובה להחליף `ACCOUNT_ID` במספר החשבון שלכם.

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

## 8️⃣ יצירת EKS באמצעות Terraform

```bash
rm -rf .terraform .terraform.lock.hcl
terraform init -upgrade
terraform apply
```

אשר:
```
yes
```

⏱️ זמן הקמה משוער: 10–15 דקות.

---

## 9️⃣ חיבור kubectl ל־EKS

```bash
aws eks update-kubeconfig   --region us-east-1   --name eks-far-2-cel-demo-30-12

kubectl get nodes
```

---

## 🔟 הרצת אפליקציית far-2-cel

(כפי שמופיע בשלבים הבאים – Docker, ECR, Deployment, Service)

---

## 1️⃣1️⃣ תרגול מעשי (כשעה)

- מחיקת Pod ו־Self Healing  
- שינוי replicas  
- מחיקת Service והחזרתו  
- בדיקת Logs  
- הבנת LoadBalancer ו־Nodes  

---

## 1️⃣2️⃣ ניקוי משאבים

```bash
terraform destroy
```

---

## ✅ סיכום

✔ הקמת EKS מלאה מאפס  
✔ עבודה ללא תיקיית infra  
✔ שילוב Terraform + Kubernetes  
✔ מסמך מלא ומוכן לכיתה  

---
