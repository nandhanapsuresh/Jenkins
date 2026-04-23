# Jenkins + Terraform + AWS (End-to-End Demo)

## Overview
This project demonstrates how to use Jenkins to trigger Terraform and 
automatically provision AWS infrastructure including VPC, EC2, and S3.

## Architecture

Jenkins → Terraform → AWS (VPC + Subnet + EC2 + S3)

---

## Prerequisites
- Jenkins server (running and accessible)
- AWS Account with IAM user
- GitHub account
- Terraform installed on Jenkins server

---

## IAM Permissions Required

### Step 1: Create IAM User in AWS Console
1. Go to **AWS Console → IAM → Users → Create User**
2. Username: `jenkins-terraform-user`
3. Select: **Programmatic access** (Access Key + Secret Key)

### Step 2: Attach the Following Policies

| Policy | Purpose |
|--------|---------|
| `AmazonEC2FullAccess` | Create/manage EC2 instances, VPC, Subnets |
| `AmazonS3FullAccess` | Create/manage S3 buckets |
| `AmazonVPCFullAccess` | Create/manage VPC and networking |

> **Minimum permissions needed:**
> - `ec2:CreateVpc`, `ec2:CreateSubnet`, `ec2:RunInstances`, `ec2:TerminateInstances`
> - `s3:CreateBucket`, `s3:DeleteBucket`, `s3:PutObject`
> - `sts:GetCallerIdentity` (for verifying AWS credentials)

### Step 3: Save Credentials
After creating the user, save:
- **Access Key ID**
- **Secret Access Key**

These will be used in `aws configure` on the Jenkins server.

---

## Step 1: Install Terraform on Jenkins Server

SSH into your Jenkins server and run:

```bash
# Download Terraform
wget https://releases.hashicorp.com/terraform/1.6.6/terraform_1.6.6_linux_amd64.zip

# Unzip
unzip terraform_1.6.6_linux_amd64.zip

# Move to bin
sudo mv terraform /usr/local/bin/

# Verify installation
terraform -version
```

---

## Step 2: Configure AWS CLI on Jenkins Server

```bash
# Install AWS CLI
sudo apt install awscli -y        # Ubuntu
# sudo yum install aws-cli -y    # Amazon Linux

# Configure credentials
aws configure
```

Enter when prompted:
AWS Access Key ID:     <your-access-key>
AWS Secret Access Key: <your-secret-key>
Default region name:   ap-south-2        # Hyderabad region
Default output format: json

```bash
# Verify configuration
aws sts get-caller-identity
```

Expected output:
```json
{
  "UserId": "XXXXXXXXXXXXX",
  "Account": "99152424XXXX",
  "Arn": "arn:aws:iam::99152424XXXX:user/jenkins-terraform-user"
}
```

---

## Step 3: Create Terraform Code

### Create GitHub Repository
1. Go to GitHub → New Repository
2. Name: `jenkins-terraform-aws`
3. Visibility: Public

### Create `main.tf`

```hcl
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "ap-south-2"    # Hyderabad
}

# S3 Bucket
resource "aws_s3_bucket" "demo_bucket" {
  bucket = "jenkins-terraform-demo-nandhana-12345"
}

# VPC
resource "aws_vpc" "demo_vpc" {
  cidr_block = "10.0.0.0/16"
}

# Subnet
resource "aws_subnet" "public_subnet" {
  vpc_id     = aws_vpc.demo_vpc.id
  cidr_block = "10.0.1.0/24"
}

# EC2 Instance
resource "aws_instance" "ec2" {
  ami           = "ami-0f5ee92e2d63afc18"    # Ubuntu - Hyderabad region
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.public_subnet.id
}
```

### Push to GitHub

```bash
git init
git add main.tf
git commit -m "Add Terraform config for AWS infrastructure"
git remote add origin https://github.com/<your-username>/jenkins-terraform-aws.git
git push -u origin main
```

---

## Step 4: Configure Jenkins Job

1. Go to **Jenkins → New Item**
2. Name: `terraform-job1`
3. Type: **Freestyle Project**
4. Click **OK**

### Source Code Management
- Select **Git**
- Repository URL: `https://github.com/<your-username>/jenkins-terraform-aws.git`
- Branch: `*/main`

---

## Step 5: Add Build Steps

Go to **Build Steps → Add build step → Execute Shell**

Add **3 separate shell steps:**

### Build Step 1 — Terraform Init
```bash
terraform init
```

### Build Step 2 — Terraform Plan
```bash
terraform plan
```

### Build Step 3 — Terraform Apply
```bash
terraform apply -auto-approve
```

Click **Save**

---

## Step 6: Run the Job

1. Click **Build Now**
2. Click on build number → **Console Output**

---

## Verification

### Jenkins Console Output

**Build #1 — terraform init **

Initializing provider plugins...

Installing hashicorp/aws v5.100.0...
Installed hashicorp/aws v5.100.0 (signed by HashiCorp)
Terraform has been successfully initialized!
Finished: SUCCESS

**Build #3 — terraform plan **

Plan: 4 to add, 0 to change, 0 to destroy.
Finished: SUCCESS

**Build #4 — terraform apply **

Apply complete! Resources: 4 added, 0 changed, 0 destroyed.
Finished: SUCCESS

### AWS Console Verification
After successful apply, verify in AWS Console:

| Resource | Name | Status |
|----------|------|--------|
| VPC | demo_vpc | ✅ Created |
| Subnet | public_subnet | ✅ Created |
| EC2 Instance | - | ✅ Running |
| S3 Bucket | jenkins-terraform-demo-nandhana-12345 | ✅ Created |

---

## Cleanup (Terraform Destroy)

To avoid AWS charges, destroy resources after testing:

### Add a Destroy Job in Jenkins
[OAdd build step → Execute Shell:
```bash
terraform destroy -auto-approve
```

**Build #5 — terraform destroy **

aws_s3_bucket.demo_bucket: Destruction complete after 1s
aws_instance.ec2: Destruction complete after 30s
aws_subnet.public_subnet: Destruction complete after 1s
aws_vpc.demo_vpc: Destruction complete after 0s
Destroy complete! Resources: 4 destroyed.
Finished: SUCCESS

---

## Project Structure

jenkins-terraform-aws/
│
├── main.tf                  # Terraform configuration
├── .terraform.lock.hcl      # Provider lock file (auto-generated)
└── README.md

---

## Screenshots

### Terraform Init — Build #1
![Terraform Init](screenshots/terraform-init.png)

### Terraform Plan — Build #3
![Terraform Plan](screenshots/terraform-plan.png)

### Terraform Destroy — Build #5
![Terraform Destroy](screenshots/terraform-destroy.png)

---

## Tools & Services Used

| Tool | Purpose |
|------|---------|
| Jenkins | CI/CD automation |
| Terraform | Infrastructure as Code |
| AWS EC2 | Virtual machine |
| AWS VPC + Subnet | Networking |
| AWS S3 | Object storage |
| GitHub | Source code management |

---

## Region Used
**ap-south-2 — Hyderabad, India**

---

## Author
**nandhanapsuresh**
GitHub: [nandhanapsuresh](https://github.com/nandhanapsuresh)
