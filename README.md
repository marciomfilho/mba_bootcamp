1. Visão geral
Este repositório provisiona a infraestrutura da TrackNow na AWS utilizando Terraform, atendendo aos requisitos de alta disponibilidade, escalabilidade, segurança, DevOps/IaC e observabilidade definidos no case TrackNow.
​

Principais componentes:

VPC com sub-redes públicas e privadas (3 AZs)

NAT Gateways e Internet Gateway

Cluster ECS Fargate (microserviços) + Application Load Balancer

RDS Aurora PostgreSQL Multi-AZ

S3 + CloudFront para estáticos

Integração com práticas de CI/CD e GitOps (via pipelines externos).
​

2. Estrutura de diretórios
text
tracknow-infra/
  ├─ envs/
  │   ├─ dev/
  │   │   ├─ main.tf
  │   │   ├─ variables.tf
  │   │   └─ backend.tf
  │   ├─ staging/
  │   └─ prod/
  │
  ├─ modules/
  │   ├─ vpc/
  │   │   ├─ main.tf
  │   │   ├─ variables.tf
  │   │   └─ outputs.tf
  │   ├─ ecs_app/
  │   ├─ rds/
  │   └─ s3_cloudfront/
  │
  └─ README.md
envs/*: definição de cada ambiente (dev, staging, prod).

modules/*: módulos reutilizáveis para VPC, ECS, RDS e S3/CloudFront.
​

3. Pré-requisitos
Conta AWS com permissões para VPC, ECS, RDS, S3, CloudFront, IAM etc.

Terraform >= 1.6.0 instalado.

AWS CLI configurado (aws configure).

Bucket S3 e tabela DynamoDB para remote state criados previamente:

bash
aws s3api create-bucket --bucket tracknow-terraform-state --region sa-east-1
aws dynamodb create-table \
  --table-name tracknow-terraform-lock \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST
Esses recursos garantem controle de concorrência e segurança do estado, reduzindo o risco operacional descrito como “gestão artesanal” no case.
​

4. Variáveis sensíveis
No diretório do ambiente (envs/prod, por exemplo), defina um arquivo terraform.tfvars com:

text
db_master_password = "SENHA_FORTE_AQUI"
Ou use variáveis de ambiente:

bash
export TF_VAR_db_master_password="SENHA_FORTE_AQUI"
Senhas não devem ser commitadas em repositório, em linha com boas práticas de segurança e DevSecOps.
​

5. Fluxo de uso local
Exemplo para o ambiente prod:

bash
cd envs/prod

# 1. Inicializar o backend remoto e providers
terraform init

# 2. Verificar sintaxe
terraform validate

# 3. Visualizar o plano de mudanças
terraform plan -out=plan.tfplan

# 4. Aplicar mudanças (com confirmação)
terraform apply plan.tfplan
Para destruir recursos (apenas em ambientes de teste):

bash
terraform destroy
6. Integração com CI/CD
Em um pipeline de CI/CD (ex.: GitHub Actions), o fluxo recomendado é:

terraform fmt -check

terraform validate

terraform plan (comentado no PR)

terraform apply somente em merges para main ou tags de release, com aprovação manual.

Isto substitui o processo de deploy manual citado no case e implementa de fato Infraestrutura como Código + DevOps.
​

7. Extensões futuras
Adicionar módulos para:

WAF + regras gerenciadas

CloudWatch alarms, log groups e dashboards

Secrets Manager e KMS

Integrar com repositório de aplicações (tracknow-services) e registry ECR, permitindo que o pipeline de aplicação faça deploy automático para o ECS provisionado por este IaC.
