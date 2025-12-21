# ⚡ Plan de Pruebas No Funcionales - Sistema Ticketero

**Proyecto:** Ticketero - Queue Management System  
**Versión:** 2.0  
**Fecha:** Diciembre 2024  
**Alcance:** Performance, Seguridad, Resiliencia, Usabilidad  

---

## 📑 Contenido

1. [Estrategia General](#1-estrategia-general)
2. [Pruebas de Performance](#2-pruebas-de-performance)
3. [Pruebas de Carga](#3-pruebas-de-carga)
4. [Pruebas de Seguridad](#4-pruebas-de-seguridad)
5. [Pruebas de Resiliencia](#5-pruebas-de-resiliencia)
6. [Pruebas de Escalabilidad](#6-pruebas-de-escalabilidad)
7. [Pruebas de Compatibilidad](#7-pruebas-de-compatibilidad)
8. [Monitoreo y Métricas](#8-monitoreo-y-métricas)
9. [Herramientas y Automatización](#9-herramientas-y-automatización)

---

## 1. Estrategia General

### 1.1 Objetivos

- ✅ **Performance:** Validar tiempos de respuesta bajo carga normal
- ✅ **Escalabilidad:** Determinar límites del sistema
- ✅ **Seguridad:** Identificar vulnerabilidades básicas
- ✅ **Resiliencia:** Verificar comportamiento ante fallos
- ✅ **Usabilidad:** Confirmar facilidad de uso de APIs

### 1.2 Criterios de Aceptación

| Aspecto | Métrica | Objetivo | Crítico |
|---------|---------|----------|---------|
| **Latencia API** | P95 response time | < 500ms | < 1000ms |
| **Throughput** | Requests/second | > 100 RPS | > 50 RPS |
| **Disponibilidad** | Uptime | > 99.5% | > 99% |
| **Memoria** | Heap usage | < 80% | < 90% |
| **CPU** | CPU utilization | < 70% | < 85% |
| **Notificaciones** | Delivery rate | > 95% | > 90% |

### 1.3 Entorno de Pruebas

```yaml
# Configuración del entorno
Hardware:
  CPU: 4 cores
  RAM: 8GB
  Storage: SSD 100GB
  
Software:
  OS: Ubuntu 22.04 LTS
  Java: OpenJDK 21
  PostgreSQL: 16
  RabbitMQ: 3.13
  
Network:
  Bandwidth: 1Gbps
  Latency: < 1ms (local)
```

---

## 2. Pruebas de Performance

### 2.1 Pruebas de Latencia

#### PN-001: Latencia de Creación de Tickets
**Objetivo:** Verificar tiempo de respuesta para crear tickets  
**Herramienta:** JMeter / Artillery  
**Duración:** 10 minutos  

**Configuración:**
- **Usuarios concurrentes:** 10
- **Ramp-up:** 30 segundos
- **Requests por usuario:** 100

**Script JMeter:**
```xml
<HTTPSamplerProxy>
  <elementProp name="HTTPsampler.Arguments">
    <collectionProp name="Arguments.arguments">
      <elementProp name="" elementType="HTTPArgument">
        <boolProp name="HTTPArgument.always_encode">false</boolProp>
        <stringProp name="Argument.value">{
          "nationalId": "${__Random(10000000,99999999)}",
          "telefono": "98765${__Random(1000,9999)}",
          "branchOffice": "Sucursal Test",
          "queueType": "PERSONAL"
        }</stringProp>
      </elementProp>
    </collectionProp>
  </elementProp>
  <stringProp name="HTTPSampler.domain">localhost</stringProp>
  <stringProp name="HTTPSampler.port">8080</stringProp>
  <stringProp name="HTTPSampler.path">/api/tickets</stringProp>
  <stringProp name="HTTPSampler.method">POST</stringProp>
</HTTPSamplerProxy>
```

**Criterios de Éxito:**
- P50 < 200ms
- P95 < 500ms
- P99 < 1000ms
- Error rate < 1%

#### PN-002: Latencia de Consultas
**Objetivo:** Verificar tiempo de respuesta para consultas  

**Endpoints a probar:**
- GET /api/tickets/{uuid}
- GET /api/tickets/{numero}/position
- GET /api/admin/dashboard

**Criterios de Éxito:**
- P95 < 300ms para consultas simples
- P95 < 800ms para dashboard (más complejo)

### 2.2 Pruebas de Throughput

#### PN-003: Capacidad Máxima de Creación
**Objetivo:** Determinar máximo RPS sostenible  
**Método:** Incremento gradual de carga  

```bash
# Script Artillery
config:
  target: 'http://localhost:8080'
  phases:
    - duration: 60
      arrivalRate: 10
    - duration: 60
      arrivalRate: 25
    - duration: 60
      arrivalRate: 50
    - duration: 60
      arrivalRate: 100
    - duration: 60
      arrivalRate: 150

scenarios:
  - name: "Create Ticket"
    weight: 100
    flow:
      - post:
          url: "/api/tickets"
          json:
            nationalId: "{{ $randomInt(10000000, 99999999) }}"
            telefono: "987654321"
            branchOffice: "Sucursal Test"
            queueType: "PERSONAL"
```

**Métricas a capturar:**
- Requests per second
- Response time percentiles
- Error rate
- Resource utilization

---

## 3. Pruebas de Carga

### 3.1 Carga Sostenida

#### PN-004: Operación Normal Extendida
**Objetivo:** Verificar estabilidad bajo carga normal prolongada  
**Duración:** 2 horas  
**Carga:** 50 RPS constante  

**Escenarios:**
- 70% Creación de tickets
- 20% Consultas de estado
- 10% Operaciones administrativas

**Monitoreo:**
- Memory leaks
- Connection pool exhaustion
- Database performance
- Message queue backlog

#### PN-005: Picos de Carga
**Objetivo:** Simular horas pico de sucursal bancaria  
**Patrón:** Carga variable que simula horarios reales  

```yaml
# Patrón de carga diaria
08:00-09:00: 20 RPS  # Apertura
09:00-11:00: 80 RPS  # Pico matutino
11:00-13:00: 40 RPS  # Media mañana
13:00-14:00: 100 RPS # Hora de almuerzo (pico)
14:00-16:00: 60 RPS  # Tarde
16:00-17:00: 90 RPS  # Pico vespertino
17:00-18:00: 30 RPS  # Cierre
```

### 3.2 Carga de Estrés

#### PN-006: Límites del Sistema
**Objetivo:** Encontrar punto de quiebre del sistema  
**Método:** Incremento agresivo hasta fallo  

**Fases:**
1. **Baseline:** 50 RPS por 5 minutos
2. **Incremento:** +25 RPS cada 2 minutos
3. **Sostenimiento:** Mantener carga máxima por 10 minutos
4. **Recuperación:** Reducir a baseline

**Criterios de Fallo:**
- Error rate > 5%
- Response time P95 > 2 segundos
- CPU > 95% por más de 2 minutos
- Memory > 95%

---

## 4. Pruebas de Seguridad

### 4.1 Vulnerabilidades de API

#### PN-007: Inyección SQL
**Objetivo:** Verificar protección contra SQL injection  
**Herramienta:** OWASP ZAP / Burp Suite  

**Casos de prueba:**
```bash
# Payloads maliciosos en parámetros
POST /api/tickets
{
  "nationalId": "12345678'; DROP TABLE ticket; --",
  "telefono": "987654321",
  "branchOffice": "Test",
  "queueType": "PERSONAL"
}

# Inyección en path parameters
GET /api/tickets/uuid'; SELECT * FROM ticket; --
```

**Resultado esperado:** Requests rechazadas con error 400

#### PN-008: Validación de Entrada
**Objetivo:** Verificar validaciones robustas  

**Casos maliciosos:**
```json
{
  "nationalId": "<script>alert('xss')</script>",
  "telefono": "../../../../etc/passwd",
  "branchOffice": "A".repeat(1000),
  "queueType": "INVALID_QUEUE"
}
```

#### PN-009: Rate Limiting
**Objetivo:** Verificar protección contra ataques de fuerza bruta  

**Test:**
- Enviar 1000 requests desde misma IP en 1 minuto
- Verificar que se aplique rate limiting
- Confirmar que requests legítimas no se afecten

### 4.2 Seguridad de Datos

#### PN-010: Exposición de Información Sensible
**Objetivo:** Verificar que no se exponga información confidencial  

**Verificaciones:**
- Logs no contienen datos sensibles completos
- Respuestas de error no revelan estructura interna
- Headers no exponen versiones de software
- Stack traces no se muestran en producción

```bash
# Verificar sanitización en logs
curl -X POST http://localhost:8080/api/tickets \
  -H "Content-Type: application/json" \
  -d '{"nationalId":"12345678","telefono":"987654321"}'

# Verificar que en logs aparece: 123****78
grep "123\*\*\*\*78" application.log
```

---

## 5. Pruebas de Resiliencia

### 5.1 Tolerancia a Fallos

#### PN-011: Fallo de Base de Datos
**Objetivo:** Verificar comportamiento ante fallo de PostgreSQL  

**Escenario:**
1. Sistema operando normalmente
2. Detener PostgreSQL
3. Enviar requests
4. Verificar respuestas de error apropiadas
5. Reiniciar PostgreSQL
6. Verificar recuperación automática

**Resultado esperado:**
- HTTP 500 con mensaje genérico
- No pérdida de datos
- Recuperación automática sin restart

#### PN-012: Fallo de RabbitMQ
**Objetivo:** Verificar patrón Outbox ante fallo de mensajería  

**Escenario:**
1. Detener RabbitMQ
2. Crear tickets (deben guardarse en outbox)
3. Reiniciar RabbitMQ
4. Verificar procesamiento de mensajes pendientes

#### PN-013: Fallo de Telegram
**Objetivo:** Verificar resiliencia ante fallo de servicio externo  

**Escenario:**
1. Configurar token inválido de Telegram
2. Crear tickets con teléfono
3. Verificar que tickets se crean correctamente
4. Confirmar logs de error apropiados
5. Restaurar configuración
6. Verificar reintento de notificaciones

### 5.2 Recuperación ante Fallos

#### PN-014: Reinicio del Sistema
**Objetivo:** Verificar recuperación completa tras reinicio  

**Pasos:**
1. Sistema con carga normal
2. Reinicio abrupto (kill -9)
3. Restart del sistema
4. Verificar:
   - Conexiones de BD restauradas
   - Cola RabbitMQ reconectada
   - Procesamiento de mensajes pendientes
   - Métricas restablecidas

---

## 6. Pruebas de Escalabilidad

### 6.1 Escalamiento Horizontal

#### PN-015: Múltiples Instancias
**Objetivo:** Verificar comportamiento con múltiples instancias  

**Configuración:**
```yaml
# docker-compose-scale.yml
version: '3.8'
services:
  api:
    image: ticketero:latest
    deploy:
      replicas: 3
    ports:
      - "8080-8082:8080"
  
  nginx:
    image: nginx:alpine
    ports:
      - "80:80"
    volumes:
      - ./nginx.conf:/etc/nginx/nginx.conf
```

**Pruebas:**
- Load balancing entre instancias
- Consistencia de datos
- Procesamiento distribuido de colas

#### PN-016: Escalamiento de Base de Datos
**Objetivo:** Verificar límites de conexiones PostgreSQL  

**Test:**
- Incrementar pool de conexiones gradualmente
- Monitorear performance de queries
- Identificar punto de saturación

### 6.2 Escalamiento Vertical

#### PN-017: Límites de Recursos
**Objetivo:** Determinar requerimientos mínimos y óptimos  

**Configuraciones a probar:**
```yaml
Configuración Mínima:
  CPU: 1 core
  RAM: 2GB
  
Configuración Recomendada:
  CPU: 2 cores
  RAM: 4GB
  
Configuración Óptima:
  CPU: 4 cores
  RAM: 8GB
```

---

## 7. Pruebas de Compatibilidad

### 7.1 Compatibilidad de Navegadores

#### PN-018: APIs REST desde Diferentes Clientes
**Objetivo:** Verificar compatibilidad con diferentes clientes HTTP  

**Clientes a probar:**
- curl
- Postman
- JavaScript fetch()
- Java RestTemplate
- Python requests

### 7.2 Compatibilidad de Versiones

#### PN-019: Versiones de Java
**Objetivo:** Verificar compatibilidad con diferentes versiones JVM  

**Versiones a probar:**
- OpenJDK 21 (principal)
- Oracle JDK 21
- GraalVM 21

#### PN-020: Versiones de Base de Datos
**Objetivo:** Verificar compatibilidad PostgreSQL  

**Versiones a probar:**
- PostgreSQL 14
- PostgreSQL 15
- PostgreSQL 16 (principal)

---

## 8. Monitoreo y Métricas

### 8.1 Métricas de Sistema

#### Métricas JVM
```bash
# Heap memory usage
jvm_memory_used_bytes{area="heap"}

# Garbage collection
jvm_gc_collection_seconds_count
jvm_gc_collection_seconds_sum

# Thread count
jvm_threads_current
```

#### Métricas de Aplicación
```bash
# Custom metrics
tickets_created_total{queue_type="PERSONAL"}
notification_delivery_rate
api_request_duration_seconds

# Database metrics
hikari_connections_active
hikari_connections_pending
```

### 8.2 Alertas y Umbrales

```yaml
# Prometheus alerts
groups:
  - name: ticketero-alerts
    rules:
      - alert: HighResponseTime
        expr: histogram_quantile(0.95, http_request_duration_seconds_bucket) > 0.5
        for: 2m
        labels:
          severity: warning
        annotations:
          summary: "High response time detected"
      
      - alert: HighErrorRate
        expr: rate(http_requests_total{status=~"5.."}[5m]) > 0.05
        for: 1m
        labels:
          severity: critical
        annotations:
          summary: "High error rate detected"
```

---

## 9. Herramientas y Automatización

### 9.1 Herramientas de Testing

| Herramienta | Propósito | Configuración |
|-------------|-----------|---------------|
| **JMeter** | Load testing | GUI + CLI scripts |
| **Artillery** | Modern load testing | YAML config |
| **OWASP ZAP** | Security testing | Automated scans |
| **k6** | Performance testing | JavaScript scripts |
| **Gatling** | High-performance testing | Scala DSL |

### 9.2 Scripts de Automatización

#### Script de Carga Básica
```bash
#!/bin/bash
# load-test.sh

echo "🚀 Iniciando pruebas de carga..."

# Configuración
TARGET_URL="http://localhost:8080"
DURATION="300s"
RATE="50"

# Ejecutar Artillery
artillery quick \
  --duration $DURATION \
  --rate $RATE \
  --output report.json \
  $TARGET_URL/api/tickets

# Generar reporte HTML
artillery report report.json

echo "✅ Pruebas completadas. Ver report.json.html"
```

#### Script de Monitoreo
```bash
#!/bin/bash
# monitor.sh

echo "📊 Iniciando monitoreo del sistema..."

# Métricas de sistema
while true; do
  echo "$(date): CPU=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | cut -d'%' -f1)"
  echo "$(date): MEM=$(free | grep Mem | awk '{printf("%.2f%%", $3/$2 * 100.0)}')"
  echo "$(date): DISK=$(df -h / | awk 'NR==2{printf "%s", $5}')"
  
  # Métricas de aplicación
  curl -s http://localhost:8080/actuator/metrics/jvm.memory.used | jq '.measurements[0].value'
  
  sleep 30
done
```

### 9.3 Pipeline de Pruebas No Funcionales

```yaml
# .github/workflows/performance-tests.yml
name: Performance Tests

on:
  schedule:
    - cron: '0 2 * * *'  # Diario a las 2 AM
  workflow_dispatch:

jobs:
  performance-tests:
    runs-on: ubuntu-latest
    
    steps:
      - uses: actions/checkout@v4
      
      - name: Setup Environment
        run: |
          docker-compose up -d
          sleep 30  # Wait for services
      
      - name: Install Artillery
        run: npm install -g artillery
      
      - name: Run Load Tests
        run: |
          artillery run tests/performance/load-test.yml
          artillery run tests/performance/stress-test.yml
      
      - name: Security Scan
        run: |
          docker run -t owasp/zap2docker-stable zap-baseline.py \
            -t http://localhost:8080
      
      - name: Generate Report
        run: |
          artillery report results.json
      
      - name: Upload Results
        uses: actions/upload-artifact@v3
        with:
          name: performance-results
          path: |
            results.json.html
            zap-report.html
```

---

## 10. Casos de Prueba Específicos

### 10.1 Escenarios Realistas

#### PN-021: Día Típico de Sucursal
**Objetivo:** Simular operación real de sucursal bancaria  
**Duración:** 8 horas (simuladas en 1 hora)  

**Perfil de carga:**
```yaml
# Simulación de día completo
scenarios:
  - name: "Morning Rush"
    duration: 10m
    arrivalRate: 80
    
  - name: "Mid Morning"
    duration: 15m
    arrivalRate: 40
    
  - name: "Lunch Peak"
    duration: 10m
    arrivalRate: 120
    
  - name: "Afternoon"
    duration: 15m
    arrivalRate: 60
    
  - name: "Evening Rush"
    duration: 10m
    arrivalRate: 100
```

#### PN-022: Black Friday Bancario
**Objetivo:** Simular día de máxima demanda  
**Características:**
- 5x carga normal
- Picos súbitos
- Sostenimiento prolongado

### 10.2 Casos Límite

#### PN-023: Ticket con Datos Máximos
**Objetivo:** Verificar manejo de datos en límites superiores  

```json
{
  "nationalId": "999999999999",
  "telefono": "999999999999999",
  "branchOffice": "A".repeat(100),
  "queueType": "GERENCIA"
}
```

#### PN-024: Concurrencia Extrema
**Objetivo:** Probar condiciones de carrera  
**Escenario:** 1000 usuarios creando tickets simultáneamente en misma cola

---

## 11. Reportes y Análisis

### 11.1 Formato de Reportes

```markdown
# Reporte de Pruebas de Performance
**Fecha:** 2024-12-01
**Duración:** 2 horas
**Configuración:** 4 cores, 8GB RAM

## Resumen Ejecutivo
- ✅ Objetivos de latencia cumplidos
- ⚠️ Throughput máximo: 85 RPS (objetivo: 100 RPS)
- ✅ Estabilidad bajo carga sostenida
- ❌ Memory leak detectado tras 4 horas

## Métricas Detalladas
| Métrica | Objetivo | Resultado | Estado |
|---------|----------|-----------|--------|
| P95 Latency | < 500ms | 420ms | ✅ |
| Throughput | > 100 RPS | 85 RPS | ⚠️ |
| Error Rate | < 1% | 0.3% | ✅ |

## Recomendaciones
1. Optimizar queries de dashboard (bottleneck identificado)
2. Implementar connection pooling para RabbitMQ
3. Investigar memory leak en NotificationService
```

### 11.2 Métricas de Tendencia

```bash
# Tracking de performance en el tiempo
Date,P95_Latency,Throughput,Error_Rate,Memory_Usage
2024-12-01,420ms,85,0.3%,65%
2024-12-02,380ms,92,0.2%,68%
2024-12-03,450ms,88,0.4%,72%
```

---

## 12. Checklist de Ejecución

### Pre-ejecución
- [ ] Entorno de pruebas configurado
- [ ] Base de datos con datos de prueba
- [ ] Servicios externos (Telegram) configurados
- [ ] Herramientas de monitoreo activas
- [ ] Scripts de prueba validados

### Durante ejecución
- [ ] Monitorear métricas en tiempo real
- [ ] Documentar anomalías observadas
- [ ] Capturar logs relevantes
- [ ] Verificar estabilidad del entorno

### Post-ejecución
- [ ] Generar reportes automáticos
- [ ] Analizar resultados vs objetivos
- [ ] Identificar bottlenecks
- [ ] Documentar recomendaciones
- [ ] Limpiar entorno de pruebas

---

**Documento preparado por:** Performance Team  
**Revisado por:** Tech Lead & DevOps  
**Aprobado por:** Architecture Team  

**Última actualización:** Diciembre 2024  
**Próxima revisión:** Enero 2025