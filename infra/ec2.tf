data "aws_ami" "amazon-linux-2" {
  most_recent = true
  filter {
    name   = "owner-alias"
    values = ["amazon"]
  }
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm*"]
  }
}
resource "aws_network_interface" "interface" {
  subnet_id       = local.subnet
  security_groups = [aws_security_group.allow_tls.id]
  

}
resource "aws_instance" "ec2" {
  depends_on           = [aws_network_interface.interface]
  ami                  = data.aws_ami.amazon-linux-2.id
  instance_type        = local.instance_type
  user_data            = <<EOF
        #!/bin/bash
    #############[Docker]#############
    sudo yum install docker -y
    sudo systemctl start docker 
    #############[Kind]#############
    [ $(uname -m) = x86_64 ] && curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.20.0/kind-linux-amd64 
    chmod +x ./kind
    sudo mv ./kind /usr/local/bin/kind
    #############[Kubectl]#############
    curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
    sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
    chmod +x kubectl
    mkdir -p ~/.local/bin
    mv ./kubectl ~/.local/bin/kubectl
    #############[Helm]#############
    curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
    chmod 700 get_helm.sh
    ./get_helm.sh
    #############[Jenkins + Git]#############
    sudo yum update –y
    sudo wget -O /etc/yum.repos.d/jenkins.repo \
    https://pkg.jenkins.io/redhat-stable/jenkins.repo
    sudo rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io-2023.key
    sudo yum upgrade
    amazon-linux-extras install java-openjdk11 -y
    yum install jenkins git jq docker -y
    sudo yum install jenkins -y
    sudo systemctl enable jenkins
    sudo systemctl start jenkins
    #############[Git + Append group]#############
    sudo yum install git -y
    sudo usermod -aG docker jenkins
    sudo usermod -aG docker ec2-user
    #############[kind.yaml]#############
    aws s3 cp s3://kind-storage-s3/kind.yaml /var/lib/jenkins/

    kind create cluster --config=/var/lib/jenkins/kind.yaml
    sudo mkdir -p /var/lib/jenkins/.kube/
    kind get kubeconfig --name=kind > /var/lib/jenkins/.kube/config
    chown -R jenkins: /var/lib/jenkins/.kube
    kubectl create secret docker-registry regcred --docker-server=750126809429.dkr.ecr.eu-central-1.amazonaws.com --docker-username=AWS --docker-password=$(aws ecr get-login-password --region eu-central-1)
EOF
  iam_instance_profile = aws_iam_instance_profile.profile.name
  network_interface {
    network_interface_id = aws_network_interface.interface.id
    device_index = 0
  }
  tags = {
    Name = "Jenkins"
  }
}
