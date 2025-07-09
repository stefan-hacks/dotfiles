### Comprehensive Lab Setup: VirtualBox & Debian for Sysadmin Project  
In this lab, you'll create a Debian-based VM to complete all `sys_tasks.md` objectives while integrating Ansible, cloud platforms, containerization, databases, and networking.  

---

#### **Lab Architecture**  
**Host Machine**: Your local OS (Windows/macOS/Linux) running VirtualBox.  
**VM**: Debian 12 Bookworm (64-bit) with the following specs:  
- **CPU**: 4 cores  
- **RAM**: 8 GB  
- **Storage**: 80 GB (dynamically allocated)  
- **Network**:  
  - **Adapter 1**: NAT (for internet access)  
  - **Adapter 2**: Host-Only Network (for static IP management)  

---

### **Phase 1: Debian VM Setup**  
#### **Step 1: Install Debian in VirtualBox**  
1. Download [Debian 12 ISO](https://www.debian.org/download).  
2. Create a new VirtualBox VM:  
   - Type: **Linux**  
   - Version: **Debian (64-bit)**  
   - Allocate resources (CPU/RAM/storage as above).  
3. Start VM and install Debian:  
   - **Partitioning**: Use entire disk (LVM, ext4).  
   - **Software Selection**: Install SSH server and standard system utilities.  
   - **User**: Create non-root user `sysadmin` with sudo privileges.  

#### **Step 2: Configure Networking**  
```bash  
# Configure static IP for Host-Only adapter  
sudo nano /etc/network/interfaces.d/hostonly  
# Add:  
auto enp0s8  
iface enp0s8 inet static  
    address 192.168.56.10  
    netmask 255.255.255.0  

sudo systemctl restart networking  
```

---

### **Phase 2: Complete sys_tasks.md Objectives**  
#### **Task 1: Web Server (NGINX/Apache) + Secured Wiki**  
**Option A: NGINX**  
```bash  
sudo apt install nginx certbot python3-certbot-nginx -y  
sudo ufw allow 'Nginx Full' && sudo ufw enable  

# Install MediaWiki  
sudo apt install php-fpm php-mysql php-xml mariadb-server -y  
sudo mysql_secure_installation  

# Configure MediaWiki  
wget https://releases.wikimedia.org/mediawiki/1.39/mediawiki-1.39.1.tar.gz  
tar -xzf mediawiki-*.tar.gz  
sudo mv mediawiki-1.39.1 /var/www/html/wiki  

# SSL with Let's Encrypt  
sudo certbot --nginx -d wiki.yourdomain.com  
```

**Option B: Apache**  
```bash  
sudo apt install apache2 certbot python3-certbot-apache -y  
# Repeat MediaWiki steps, use /var/www/html  
```

---

#### **Task 2: Postfix Email Server**  
```bash  
sudo apt install postfix dovecot-core dovecot-imapd -y  
# During Postfix install: Select "Internet Site" and set domain  
sudo nano /etc/postfix/main.cf  # Configure TLS, SASL  
sudo nano /etc/dovecot/dovecot.conf  # Enable SSL  
sudo systemctl restart postfix dovecot  
```

---

#### **Task 3: Rebuild with Ansible**  
1. **Directory Structure**:  
   ```  
   sysadmin-project/  
   ├── ansible/  
   │   ├── playbooks/  
   │   │   ├── webserver.yml  
   │   │   ├── postfix.yml  
   │   │   └── wiki.yml  
   │   ├── roles/  
   │   └── inventory  
   ```  

2. **Example Playbook (`webserver.yml`)**  
   ```yaml  
   - hosts: localhost  
     become: true  
     tasks:  
       - name: Install NGINX  
         apt:  
           name: nginx  
           state: present  
       - name: Enable UFW rules  
         ufw:  
           rule: allow  
           name: 'Nginx Full'  
   ```  

3. **Run Playbooks**:  
   ```bash  
   ansible-playbook -i inventory playbooks/webserver.yml  
   ```

---

#### **Task 4: Automated Backups to AWS S3**  
1. **Terraform Setup (create S3 bucket)**  
   ```hcl  
   # main.tf  
   provider "aws" { region = "us-east-1" }  
   resource "aws_s3_bucket" "backups" {  
     bucket = "sysadmin-backups-123"  
     acl    = "private"  
     server_side_encryption_configuration { rule { apply_server_side_encryption_by_default { sse_algorithm = "AES256" } } }  
   }  
   ```  
   Run: `terraform init && terraform apply`  

2. **Backup Script (`backup.sh`)**  
   ```bash  
   #!/bin/bash  
   tar -czf /tmp/wiki-backup-$(date +%F).tar.gz /var/www/html/wiki  
   aws s3 cp /tmp/wiki-backup-*.tar.gz s3://sysadmin-backups-123/  
   ```  

3. **Schedule with Cron**:  
   ```bash  
   crontab -e  
   # Add: 0 3 * * * /path/to/backup.sh  
   ```

---

#### **Task 5: Publish to GitHub**  
```bash  
cd sysadmin-project  
git init  
git add .  
git commit -m "Full sysadmin project"  
git remote add origin https://github.com/yourusername/sysadmin-project.git  
git push -u origin main  
```

---

### **Phase 3: Integrate Advanced Tools**  
#### **Docker & Kubernetes**  
1. **Containerize MediaWiki**:  
   ```dockerfile  
   # Dockerfile  
   FROM ubuntu:22.04  
   RUN apt update && apt install -y apache2 php mysql-client  
   COPY mediawiki /var/www/html  
   EXPOSE 80  
   ```  
   Build: `docker build -t my-wiki .`  

2. **Kubernetes Deployment**:  
   ```yaml  
   # wiki-deployment.yaml  
   apiVersion: apps/v1  
   kind: Deployment  
   metadata: { name: mediawiki }  
   spec:  
     replicas: 1  
     template:  
       spec:  
         containers:  
         - name: wiki  
           image: my-wiki  
           ports: [ { containerPort: 80 } ]  
   ```  
   Apply: `kubectl apply -f wiki-deployment.yaml`  

---

#### **Multi-Cloud Integration**  
1. **Deploy S3 Bucket via Pulumi (Python)**:  
   ```python  
   import pulumi_aws as aws  
   bucket = aws.s3.Bucket("backups", server_side_encryption_configuration={ "rule": { "applyServerSideEncryptionByDefault": { "sseAlgorithm": "AES256" } } })  
   ```  

2. **Provision VM on AWS/Azure/GCP with Terraform**:  
   ```hcl  
   # AWS EC2 instance  
   resource "aws_instance" "wiki_server" {  
     ami           = "ami-0c55b159cbfafe1f0"  
     instance_type = "t2.micro"  
   }  
   ```

---

#### **Database & Big Data**  
1. **MySQL Secure Setup**:  
   ```bash  
   sudo mysql_secure_installation  
   mysql -u root -p -e "CREATE DATABASE wikidb; CREATE USER 'wiki'@'localhost' IDENTIFIED BY 'password';"  
   ```  

2. **Spark/Hadoop Integration**:  
   - Use Hadoop HDFS for backup storage:  
     ```bash  
     hdfs dfs -put /tmp/wiki-backup*.tar.gz /backups/  
     ```  
   - Process logs with PySpark:  
     ```python  
     from pyspark.sql import SparkSession  
     spark = SparkSession.builder.appName("LogAnalysis").getOrCreate()  
     logs = spark.read.text("/var/log/nginx/access.log")  
     ```

---

### **Validation & Testing**  
1. **Verify Services**:  
   - Access wiki at `https://<VM_IP>`  
   - Test email: `telnet <VM_IP> 25`  
2. **Check Backups**:  
   ```bash  
   aws s3 ls s3://sysadmin-backups-123/  
   ```  
3. **Audit Security**:  
   - Run `lynis audit system`  
   - Check SSL: `sslyze --regular wiki.yourdomain.com`  

---

### **Final GitHub Repo Structure**  
```  
sysadmin-project/  
├── ansible/          # All playbooks and roles  
├── terraform/        # S3, EC2, and cloud configs  
├── pulumi/           # Multi-cloud S3 code  
├── docker/           # Dockerfiles for services  
├── kubernetes/       # K8s manifests  
├── scripts/          # backup.sh, cron jobs  
├── docs/             # Wiki content/documentation  
└── README.md         # Project summary  
```

---

This lab provides end-to-end exposure to critical sysadmin tools and workflows. Adjust cloud credentials and domains for your environment. Time commitment: **20-30 hours** for full implementation.
