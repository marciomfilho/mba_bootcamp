# TrackNow Infra – Terraform na AWS

## 1. Visão geral

Este repositório provisiona a infraestrutura da **TrackNow Logística** na AWS utilizando **Terraform**, alinhado aos requisitos de alta disponibilidade, escalabilidade, segurança e DevOps/IaC definidos no case do MBA [file:1].  

Principais componentes atualmente modelados:

- VPC com sub-redes públicas e privadas em **3 AZs** (alta disponibilidade) [file:1].  
- Internet Gateway e NAT Gateways para saída controlada à internet.  
- Camada de aplicação em **EC2 Auto Scaling Group** atrás de um **Application Load Balancer** (monolito escalável).  
- **RDS Aurora PostgreSQL Multi‑AZ** como banco de dados transacional.  
- **S3 + CloudFront** para arquivos estáticos e distribuição de conteúdo.  
- Integração prevista com pipelines de **CI/CD** (GitHub Actions) para automatizar `plan/apply`.

> Foco: modernizar a **infraestrutura** mantendo a aplicação monolítica, removendo o servidor único on‑premises e habilitando crescimento seguro na nuvem [file:1].

---

## 2. Estrutura de diretórios

```text
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
  │   ├─ ec2_app/          # ASG + ALB para o monolito
  │   ├─ rds/              # Aurora PostgreSQL
  │   └─ s3_cloudfront/    # S3 + CDN
  │
  └─ README.md
