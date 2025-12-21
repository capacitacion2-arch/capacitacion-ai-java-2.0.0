# Ticketero Infrastructure - AWS CDK

Infraestructura como código para el sistema Ticketero usando AWS CDK con Java.

## 🏗️ Arquitectura

```
                        ┌─────────────────────────────────────────────┐
                         │              VPC 10.0.0.0/16                │
                         │                                             │
    Internet ────────────┤  ┌─────────────┐     ┌─────────────┐       │
         │               │  │  Public     │     │  Public     │       │
         ▼               │  │  Subnet A   │     │  Subnet B   │       │
    ┌─────────┐          │  │ 10.0.1.0/24 │     │ 10.0.2.0/24 │       │
    │   ALB   │──────────┤  └──────┬──────┘     └──────┬──────┘       │
    └─────────┘          │         │ NAT               │              │
         │               │         ▼                   ▼              │
         ▼               │  ┌─────────────┐     ┌─────────────┐       │
    ┌─────────┐          │  │  Private    │     │  Private    │       │
    │   ECS   │◄─────────┤  │  Subnet A   │     │  Subnet B   │       │
    │ Fargate │          │  │ 10.0.11.0/24│     │ 10.0.12.0/24│       │
    └─────────┘          │  └─────────────┘     └─────────────┘       │
         │               │         │                   │              │
    ┌────┴────┐          │         ▼                   ▼              │
    ▼         ▼          │  ┌───────────┐       ┌───────────┐         │
┌──────┐  ┌──────┐       │  │    RDS    │       │ Amazon MQ │         │
│Secrets│  │ ECR  │       │  │ PostgreSQL│       │ RabbitMQ  │         │
│Manager│  │      │       │  └───────────┘       └───────────┘         │
└──────┘  └──────┘       └─────────────────────────────────────────────┘
```

## 📦 Recursos AWS

### Networking
- **VPC** con CIDR 10.0.0.0/16
- **2 subnets públicas** (para ALB)
- **2 subnets privadas** (para ECS, RDS, MQ)
- **NAT Gateway** (1 para dev, 2 para prod)
- **Security Groups** con principio de mínimo privilegio

### Base de Datos
- **RDS PostgreSQL 16**
- Instancia: t3.micro (dev), t3.small (prod)
- Multi-AZ solo en producción
- Automated backups 7 días
- Credentials en Secrets Manager (auto-generado)

### Mensajería
- **Amazon MQ (RabbitMQ)**
- Instancia: mq.t3.micro
- Credentials en Secrets Manager

### Aplicación
- **ECR repository** para imágenes Docker
- **ECS Cluster** con Fargate
- Task Definition: 512 CPU, 1024 MB
- Fargate Service con desired=2
- Auto-scaling: min=1, max=4, target CPU 70%

### Load Balancer
- **Application Load Balancer**
- Health check a `/actuator/health`
- HTTP listener (puerto 80)

### Seguridad
- **Secrets Manager** para TELEGRAM_BOT_TOKEN
- IAM roles automáticos (CDK los genera)
- Security groups con referencias cruzadas

### Monitoreo
- **CloudWatch Log Group** (retención 14 días)
- **CloudWatch Alarms** para CPU > 80%
- **Dashboard** básico

## 🚀 Uso

### Prerrequisitos

- Java 21
- Maven 3.9+
- AWS CDK >= 2.100.0
- AWS CLI configurado

### Instalación

```bash
# Clonar y navegar al directorio
cd ticketero-infra

# Compilar proyecto
mvn clean compile

# Verificar CDK
cdk --version
```

### Comandos CDK

```bash
# Listar stacks
cdk ls

# Ver CloudFormation template
cdk synth ticketero-dev

# Ver diferencias
cdk diff ticketero-dev

# Bootstrap (primera vez)
cdk bootstrap

# Deploy desarrollo
cdk deploy ticketero-dev

# Deploy producción
cdk deploy ticketero-prod

# Destruir stack
cdk destroy ticketero-dev
```

### Tests

```bash
# Ejecutar tests unitarios
mvn test

# Ver cobertura
mvn test jacoco:report
```

## 🏷️ Configuración por Ambiente

### Desarrollo
- 1 NAT Gateway
- RDS t3.micro (no Multi-AZ)
- ECS: 1 task (min=1, max=2)
- Sin alarms
- Costo estimado: ~$110/mes

### Producción
- 2 NAT Gateways (HA)
- RDS t3.small (Multi-AZ)
- ECS: 2 tasks (min=2, max=4)
- 4 CloudWatch Alarms + Dashboard
- Costo estimado: ~$210/mes

## 📊 Outputs

Cada stack exporta:

- `LoadBalancerDNS`: DNS del ALB
- `EcrRepositoryUri`: URI del repositorio ECR
- `DatabaseEndpoint`: Endpoint de RDS
- `MQEndpoint`: Endpoint de Amazon MQ

## 🔒 Seguridad

- Usuario no-root en contenedores
- Security Groups con mínimo privilegio
- Secrets Manager para credenciales
- Deletion protection en producción
- Encrypted storage (RDS)

## 📝 Estructura del Proyecto

```
ticketero-infra/
├── src/main/java/com/example/infra/
│   ├── TicketeroApp.java              # Entry point
│   ├── TicketeroStack.java            # Stack principal
│   ├── constructs/
│   │   ├── NetworkingConstruct.java   # VPC, subnets, SGs
│   │   ├── DatabaseConstruct.java     # RDS PostgreSQL
│   │   ├── MessagingConstruct.java    # Amazon MQ + Secrets
│   │   ├── ContainerConstruct.java    # ECR, ECS, Fargate
│   │   └── MonitoringConstruct.java   # CloudWatch
│   └── config/
│       └── EnvironmentConfig.java     # Configuración por ambiente
├── src/test/java/com/example/infra/
│   └── TicketeroStackTest.java        # Tests de infraestructura
├── cdk.json
└── pom.xml
```

## 🔧 Troubleshooting

### Error: "CDK_DEFAULT_ACCOUNT not set"

```bash
export CDK_DEFAULT_ACCOUNT=$(aws sts get-caller-identity --query Account --output text)
export CDK_DEFAULT_REGION=us-east-1
```

### Error: "Bootstrap required"

```bash
cdk bootstrap aws://$CDK_DEFAULT_ACCOUNT/$CDK_DEFAULT_REGION
```

### Ver logs de ECS

```bash
aws logs tail /ecs/ticketero-dev-api --follow
```

## 📚 Referencias

- [AWS CDK Documentation](https://docs.aws.amazon.com/cdk/)
- [CDK Java Reference](https://docs.aws.amazon.com/cdk/api/v2/java/)
- [AWS Best Practices](https://aws.amazon.com/architecture/well-architected/)

## 🏷️ Tags

Todos los recursos se etiquetan automáticamente con:

- `Environment`: dev/prod
- `Project`: Ticketero
- `ManagedBy`: CDK
- `CostCenter`: ticketero-{env}