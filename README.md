# VLE-8: Blue-Green Deployment using DevOps Tools

Blue-Green deployment with **Terraform, Ansible, Docker, Kubernetes (Minikube), Jenkins and Git** on AWS EC2.

- **Blue** = current live version (`myapp:v1`)
- **Green** = new version (`myapp:v2`)
- Traffic is switched Blue → Green by changing the Kubernetes Service selector, and rolled back the same way.

## Repository layout

```
terraform/main.tf           Step 1 – provisions the EC2 instance (ap-south-1)
ansible/inventory.ini       Step 2 – Ansible inventory (Terraform output IP)
ansible/jenkins_setup.yml   Step 2 – installs Docker on the instance
app/Dockerfile              Step 3 – nginx image serving index.html
app/index.html              Step 3 – app page (v2 = green; v1 = same page in blue)
app/deployment-blue.yaml    Step 4 – Blue deployment (myapp:v1)
app/deployment-green.yaml   Step 4 – Green deployment (myapp:v2)
app/service.yaml            Step 4 – Service, initially selects color=blue
app/Jenkinsfile             Step 7 – Build → Deploy Green → (approve) Switch Traffic
```

## Steps

```bash
# Step 1 – Provision infrastructure
cd terraform
terraform init
terraform apply

# Step 2 – Configure with Ansible (put the Terraform public_ip in inventory.ini)
cd ../ansible
ansible-playbook -i inventory.ini jenkins_setup.yml

# Step 3 – Build images (v1 = blue page, v2 = green page) and load into Minikube
cd ../app
docker build -t myapp:v1 .     # with the blue index.html
docker build -t myapp:v2 .     # with the green index.html
minikube image load myapp:v1
minikube image load myapp:v2

# Step 5 – Deploy Blue
kubectl apply -f deployment-blue.yaml
kubectl apply -f service.yaml

# Step 6 – Deploy Green (runs in parallel, no traffic yet)
kubectl apply -f deployment-green.yaml

# Step 7 – Jenkins pipeline job "vle8-blue-green" (Pipeline script from SCM → this repo's app/Jenkinsfile)

# Step 8 – Switch traffic Blue → Green
kubectl patch service myapp-service \
  -p '{"spec":{"selector":{"app":"myapp","color":"green"}}}'

# Step 9 – Rollback Green → Blue
kubectl patch service myapp-service \
  -p '{"spec":{"selector":{"app":"myapp","color":"blue"}}}'
```

## Environment used

- Control node: AWS EC2 t3.large, Ubuntu 24.04 (us-east-1) with Terraform 1.17, Ansible 2.16, Docker, Minikube 1.39 (Kubernetes 1.37), Jenkins 2.580 (Java 21)
- Terraform-provisioned node: EC2 t3.micro, Ubuntu 24.04 (ap-south-1), Docker installed by Ansible
- Terraform credentials came from an IAM role attached to the control node (no keys in this repo)

## Result

- Two environments (Blue and Green) running simultaneously
- Jenkins pipeline built v2, deployed Green, and after approval switched traffic to Green
- No downtime during the switch
- One-command rollback to Blue
