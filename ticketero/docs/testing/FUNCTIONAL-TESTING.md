# 🧪 Plan de Pruebas Funcionales - Sistema Ticketero

**Proyecto:** Ticketero - Queue Management System  
**Versión:** 2.0  
**Fecha:** Diciembre 2024  
**Tipo:** Pruebas End-to-End y de Integración  

---

## 📑 Contenido

1. [Estrategia de Pruebas](#1-estrategia-de-pruebas)
2. [Casos de Prueba por Módulo](#2-casos-de-prueba-por-módulo)
3. [Pruebas de Integración](#3-pruebas-de-integración)
4. [Pruebas de API](#4-pruebas-de-api)
5. [Pruebas de Notificaciones](#5-pruebas-de-notificaciones)
6. [Pruebas de Dashboard](#6-pruebas-de-dashboard)
7. [Escenarios de Error](#7-escenarios-de-error)
8. [Datos de Prueba](#8-datos-de-prueba)
9. [Automatización](#9-automatización)

---

## 1. Estrategia de Pruebas

### 1.1 Objetivos

- ✅ Validar funcionalidad end-to-end del sistema
- ✅ Verificar integración con servicios externos (Telegram, PostgreSQL, RabbitMQ)
- ✅ Confirmar flujos de negocio completos
- ✅ Validar manejo de errores y casos límite

### 1.2 Alcance

**✅ Incluido:**
- Todos los endpoints REST
- Flujo completo de notificaciones Telegram
- Gestión de colas y posicionamiento
- Dashboard administrativo
- Integración con RabbitMQ
- Patrón Outbox

**❌ Excluido:**
- Pruebas de carga (ver documento de pruebas no funcionales)
- Pruebas de seguridad avanzadas
- Pruebas de UI (no existe interfaz web)

### 1.3 Herramientas

| Herramienta | Propósito | Versión |
|-------------|-----------|---------|
| **Postman** | Pruebas manuales de API | Latest |
| **JUnit 5** | Framework de testing | 5.10+ |
| **TestContainers** | Contenedores para testing | 1.19+ |
| **WireMock** | Mock de servicios externos | 3.0+ |
| **RestAssured** | Testing de API REST | 5.3+ |

---

## 2. Casos de Prueba por Módulo

### 2.1 Módulo: Gestión de Tickets

#### TC-001: Crear Ticket Válido
**Objetivo:** Verificar creación exitosa de ticket con datos válidos  
**Prioridad:** Alta  
**Precondiciones:** Sistema operativo, base de datos limpia  

**Pasos:**
1. Enviar POST /api/tickets con datos válidos
2. Verificar respuesta HTTP 201
3. Validar estructura de respuesta
4. Confirmar ticket en base de datos
5. Verificar mensaje en cola RabbitMQ

**Datos de Entrada:**
```json
{
  "nationalId": "12345678",
  "telefono": "987654321",
  "branchOffice": "Sucursal Centro",
  "queueType": "PERSONAL"
}
```

**Resultado Esperado:**
```json
{
  "identificador": "uuid-generado",
  "numero": "P001",
  "queueType": "PERSONAL",
  "status": "WAITING",
  "positionInQueue": 1,
  "estimatedWaitMinutes": 15,
  "ticketsAheadOfYou": 0,
  "branchOffice": "Sucursal Centro",
  "createdAt": "2024-12-01T10:00:00"
}
```

#### TC-002: Crear Ticket Sin Teléfono
**Objetivo:** Verificar que el teléfono es opcional  
**Prioridad:** Media  

**Datos de Entrada:**
```json
{
  "nationalId": "87654321",
  "telefono": null,
  "branchOffice": "Sucursal Norte",
  "queueType": "CAJA"
}
```

**Resultado Esperado:**
- Ticket creado exitosamente
- No se envían notificaciones Telegram
- Campo telefono = null en respuesta

#### TC-003: Validación de ID Nacional Inválido
**Objetivo:** Verificar validación de formato de ID  
**Prioridad:** Alta  

**Datos de Entrada:**
```json
{
  "nationalId": "123",
  "telefono": "987654321",
  "branchOffice": "Sucursal Centro",
  "queueType": "PERSONAL"
}
```

**Resultado Esperado:**
- HTTP 400 Bad Request
- Mensaje: "ID nacional inválido"

#### TC-004: Consultar Ticket por UUID
**Objetivo:** Verificar consulta de ticket existente  
**Prioridad:** Alta  
**Precondiciones:** Ticket previamente creado  

**Pasos:**
1. Crear ticket (TC-001)
2. Enviar GET /api/tickets/{uuid}
3. Verificar respuesta

**Resultado Esperado:**
- HTTP 200 OK
- Información completa del ticket
- Datos consistentes con creación

#### TC-005: Consultar Ticket Inexistente
**Objetivo:** Verificar manejo de ticket no encontrado  
**Prioridad:** Media  

**Pasos:**
1. Enviar GET /api/tickets/{uuid-inexistente}

**Resultado Esperado:**
- HTTP 404 Not Found
- Mensaje de error apropiado

#### TC-006: Consultar Posición en Cola
**Objetivo:** Verificar cálculo de posición actual  
**Prioridad:** Alta  
**Precondiciones:** Múltiples tickets en cola  

**Pasos:**
1. Crear 3 tickets en cola PERSONAL
2. Consultar posición del segundo ticket
3. Verificar cálculo correcto

**Resultado Esperado:**
```json
{
  "numero": "P002",
  "queueType": "PERSONAL",
  "currentPosition": 2,
  "ticketsAhead": 1,
  "estimatedWaitMinutes": 30,
  "avgServiceTimeMinutes": 15,
  "ticketsAheadNumbers": ["P001"]
}
```

### 2.2 Módulo: Dashboard Administrativo

#### TC-007: Dashboard General
**Objetivo:** Verificar información del dashboard principal  
**Prioridad:** Alta  

**Pasos:**
1. Crear tickets en diferentes colas
2. Enviar GET /api/admin/dashboard
3. Verificar estructura de respuesta

**Resultado Esperado:**
```json
{
  "ticketsPorCola": {
    "CAJA": [...],
    "PERSONAL": [...],
    "EMPRESAS": [...],
    "GERENCIA": [...]
  },
  "estadisticasAsesores": {...},
  "timestamp": "2024-12-01T10:00:00"
}
```

#### TC-008: Estado de Cola Específica
**Objetivo:** Verificar información detallada por cola  
**Prioridad:** Alta  

**Pasos:**
1. Crear tickets en cola CAJA
2. Enviar GET /api/admin/queues/CAJA
3. Verificar información

**Resultado Esperado:**
- Lista de tickets activos en cola CAJA
- Contador correcto de tickets
- Información detallada por ticket

#### TC-009: Gestión de Asesores
**Objetivo:** Verificar listado y gestión de asesores  
**Prioridad:** Media  

**Pasos:**
1. Enviar GET /api/admin/advisors
2. Cambiar estado de asesor: PUT /api/admin/advisors/1/status?status=BUSY
3. Verificar cambio aplicado

**Resultado Esperado:**
- Lista completa de asesores
- Cambio de estado exitoso
- Estado reflejado en consultas posteriores

### 2.3 Módulo: Notificaciones

#### TC-010: Notificación de Confirmación
**Objetivo:** Verificar envío de notificación inmediata  
**Prioridad:** Alta  
**Precondiciones:** Bot de Telegram configurado  

**Pasos:**
1. Crear ticket con teléfono válido
2. Verificar mensaje en RabbitMQ
3. Confirmar procesamiento por worker
4. Validar entrega en Telegram

**Resultado Esperado:**
- Mensaje enviado a Telegram en < 5 segundos
- Contenido correcto del mensaje
- Log de envío exitoso

#### TC-011: Notificación de Proximidad
**Objetivo:** Verificar notificación cuando quedan 3 turnos  
**Prioridad:** Alta  
**Precondiciones:** Sistema con workers activos  

**Pasos:**
1. Crear 5 tickets en cola PERSONAL
2. Simular atención de 2 tickets
3. Verificar notificación al ticket #3

**Resultado Esperado:**
- Notificación enviada automáticamente
- Campo `proximoTurnoNotificado` = true
- Solo una notificación por ticket

#### TC-012: Notificación de Turno Activo
**Objetivo:** Verificar notificación cuando es el turno  
**Prioridad:** Alta  

**Pasos:**
1. Crear ticket
2. Asignar asesor
3. Cambiar estado a CALLED
4. Verificar notificación

**Resultado Esperado:**
- Mensaje con información del asesor
- Número de módulo incluido
- Instrucciones claras

---

## 3. Pruebas de Integración

### 3.1 Integración PostgreSQL

#### TC-013: Persistencia de Datos
**Objetivo:** Verificar correcta persistencia en base de datos  
**Herramienta:** TestContainers  

```java
@Testcontainers
class DatabaseIntegrationTest {
    
    @Container
    static PostgreSQLContainer<?> postgres = new PostgreSQLContainer<>("postgres:16")
            .withDatabaseName("ticketero_test")
            .withUsername("test")
            .withPassword("test");
    
    @Test
    void shouldPersistTicketCorrectly() {
        // Test implementation
    }
}
```

#### TC-014: Transacciones y Rollback
**Objetivo:** Verificar manejo correcto de transacciones  

**Escenario:**
1. Iniciar transacción
2. Crear ticket
3. Simular error en outbox
4. Verificar rollback completo

### 3.2 Integración RabbitMQ

#### TC-015: Patrón Outbox
**Objetivo:** Verificar funcionamiento del patrón Outbox  

**Pasos:**
1. Crear ticket (debe guardar en outbox)
2. Verificar mensaje en tabla outbox_message
3. Ejecutar OutboxPublisherService
4. Confirmar mensaje en RabbitMQ
5. Verificar estado actualizado en outbox

#### TC-016: Procesamiento de Workers
**Objetivo:** Verificar procesamiento correcto de mensajes  

**Pasos:**
1. Enviar mensaje a cola RabbitMQ
2. Verificar procesamiento por TicketWorker
3. Confirmar ACK del mensaje
4. Validar efectos secundarios (notificaciones)

### 3.3 Integración Telegram

#### TC-017: Envío de Mensajes
**Objetivo:** Verificar integración real con Telegram API  
**Nota:** Usar bot de prueba  

**Pasos:**
1. Configurar bot de prueba
2. Enviar mensaje vía TelegramService
3. Verificar entrega en chat de prueba
4. Validar formato del mensaje

#### TC-018: Manejo de Errores de Telegram
**Objetivo:** Verificar comportamiento ante fallos de Telegram  

**Pasos:**
1. Configurar token inválido
2. Intentar enviar mensaje
3. Verificar que el ticket se crea correctamente
4. Confirmar log de error apropiado

---

## 4. Pruebas de API

### 4.1 Colección Postman

#### Configuración de Entorno
```json
{
  "baseUrl": "http://localhost:8080",
  "validNationalId": "12345678",
  "validPhone": "987654321",
  "branchOffice": "Sucursal Test"
}
```

#### TC-019: Suite Completa de API
**Colección:** `Ticketero_API_Tests.postman_collection.json`

**Tests incluidos:**
1. Health Check
2. Crear Ticket - Casos válidos
3. Crear Ticket - Validaciones
4. Consultar Ticket
5. Posición en Cola
6. Dashboard Admin
7. Gestión de Asesores

### 4.2 Pruebas de Contrato

#### TC-020: Validación de Esquemas
**Objetivo:** Verificar que las respuestas cumplen con el contrato  

```javascript
// Postman Test Script
pm.test("Response schema is valid", function () {
    const schema = {
        type: "object",
        properties: {
            identificador: { type: "string", format: "uuid" },
            numero: { type: "string", pattern: "^[CPEG][0-9]{3}$" },
            queueType: { enum: ["CAJA", "PERSONAL", "EMPRESAS", "GERENCIA"] }
        },
        required: ["identificador", "numero", "queueType"]
    };
    
    pm.response.to.have.jsonSchema(schema);
});
```

---

## 5. Pruebas de Notificaciones

### 5.1 Flujo Completo de Notificaciones

#### TC-021: Ciclo Completo de Notificaciones
**Objetivo:** Verificar las 3 notificaciones en orden  
**Duración:** ~5 minutos  
**Herramientas:** Postman + Telegram  

**Pasos:**
1. **Setup:** Limpiar cola, configurar bot
2. **Crear ticket:** POST /api/tickets con teléfono
3. **Verificar notificación 1:** Confirmación inmediata
4. **Simular progreso:** Crear tickets adicionales, procesar algunos
5. **Verificar notificación 2:** Proximidad (3 turnos antes)
6. **Simular llamada:** Cambiar estado a CALLED
7. **Verificar notificación 3:** Turno activo

**Criterios de Éxito:**
- ✅ 3 mensajes recibidos en Telegram
- ✅ Contenido correcto en cada mensaje
- ✅ Timing apropiado entre mensajes
- ✅ No mensajes duplicados

### 5.2 Casos Especiales

#### TC-022: Ticket Sin Teléfono
**Objetivo:** Verificar que no se envían notificaciones  

**Pasos:**
1. Crear ticket con telefono = null
2. Procesar hasta turno activo
3. Verificar que no hay mensajes Telegram

#### TC-023: Fallo de Telegram
**Objetivo:** Verificar resiliencia ante fallos  

**Pasos:**
1. Desconectar bot de Telegram
2. Crear ticket
3. Verificar que ticket se crea correctamente
4. Reconectar bot
5. Verificar reintento de notificación

---

## 6. Pruebas de Dashboard

### 6.1 Datos en Tiempo Real

#### TC-024: Actualización de Dashboard
**Objetivo:** Verificar que el dashboard refleja cambios en tiempo real  

**Pasos:**
1. Obtener estado inicial: GET /api/admin/dashboard
2. Crear nuevo ticket
3. Obtener estado actualizado
4. Verificar incremento en contador

#### TC-025: Estadísticas por Cola
**Objetivo:** Verificar cálculos estadísticos correctos  

**Pasos:**
1. Crear 5 tickets en cola PERSONAL
2. Completar 2 tickets
3. Obtener estadísticas: GET /api/admin/queues/PERSONAL/stats
4. Verificar cálculos:
   - Total creados: 5
   - En espera: 3
   - Completados: 2
   - Tiempo promedio: calculado

---

## 7. Escenarios de Error

### 7.1 Errores de Validación

#### TC-026: Datos Inválidos
**Casos a probar:**

| Campo | Valor Inválido | Error Esperado |
|-------|----------------|----------------|
| nationalId | "123" | "ID nacional inválido" |
| nationalId | "12345678901234" | "ID nacional inválido" |
| nationalId | "1234567A" | "ID nacional inválido" |
| telefono | "123" | "Teléfono inválido" |
| branchOffice | "" | "La sucursal es obligatoria" |
| queueType | null | "El tipo de cola es obligatorio" |

### 7.2 Errores de Sistema

#### TC-027: Base de Datos No Disponible
**Objetivo:** Verificar comportamiento ante fallo de BD  

**Pasos:**
1. Detener contenedor PostgreSQL
2. Intentar crear ticket
3. Verificar error HTTP 500
4. Verificar mensaje de error apropiado

#### TC-028: RabbitMQ No Disponible
**Objetivo:** Verificar comportamiento ante fallo de mensajería  

**Pasos:**
1. Detener RabbitMQ
2. Crear ticket
3. Verificar que ticket se crea (outbox)
4. Reiniciar RabbitMQ
5. Verificar procesamiento posterior

---

## 8. Datos de Prueba

### 8.1 Dataset Base

```sql
-- Configuración de colas
INSERT INTO queue_config (queue_type, avg_service_time_minutes, max_tickets_per_day, is_active) VALUES
('CAJA', 5, 200, true),
('PERSONAL', 15, 100, true),
('EMPRESAS', 25, 50, true),
('GERENCIA', 30, 20, true);

-- Asesores de prueba
INSERT INTO advisor (name, module_number, status, queue_specialization) VALUES
('Ana García', 1, 'AVAILABLE', 'CAJA'),
('Carlos López', 2, 'AVAILABLE', 'PERSONAL'),
('María Rodríguez', 3, 'AVAILABLE', 'EMPRESAS'),
('Juan Pérez', 4, 'AVAILABLE', 'GERENCIA');
```

### 8.2 Datos de Prueba Válidos

```json
{
  "validTickets": [
    {
      "nationalId": "12345678",
      "telefono": "987654321",
      "branchOffice": "Sucursal Centro",
      "queueType": "CAJA"
    },
    {
      "nationalId": "87654321",
      "telefono": "123456789",
      "branchOffice": "Sucursal Norte",
      "queueType": "PERSONAL"
    },
    {
      "nationalId": "11223344",
      "telefono": null,
      "branchOffice": "Sucursal Sur",
      "queueType": "EMPRESAS"
    }
  ]
}
```

### 8.3 Datos Inválidos

```json
{
  "invalidTickets": [
    {
      "nationalId": "123",
      "telefono": "987654321",
      "branchOffice": "Sucursal Centro",
      "queueType": "CAJA",
      "expectedError": "ID nacional inválido"
    },
    {
      "nationalId": "12345678",
      "telefono": "123",
      "branchOffice": "Sucursal Centro",
      "queueType": "CAJA",
      "expectedError": "Teléfono inválido"
    }
  ]
}
```

---

## 9. Automatización

### 9.1 Pipeline de Testing

```yaml
# .github/workflows/functional-tests.yml
name: Functional Tests

on: [push, pull_request]

jobs:
  functional-tests:
    runs-on: ubuntu-latest
    
    services:
      postgres:
        image: postgres:16
        env:
          POSTGRES_PASSWORD: test
        options: >-
          --health-cmd pg_isready
          --health-interval 10s
          --health-timeout 5s
          --health-retries 5
      
      rabbitmq:
        image: rabbitmq:3.13-management
        env:
          RABBITMQ_DEFAULT_USER: test
          RABBITMQ_DEFAULT_PASS: test
    
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-java@v4
        with:
          java-version: '21'
      
      - name: Run Functional Tests
        run: ./mvnw test -Dtest="*IntegrationTest"
      
      - name: Run Postman Tests
        run: |
          npm install -g newman
          newman run tests/postman/Ticketero_API_Tests.postman_collection.json \
                 -e tests/postman/test-environment.json
```

### 9.2 Tests de Integración con TestContainers

```java
@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT)
@Testcontainers
class TicketIntegrationTest {
    
    @Container
    static PostgreSQLContainer<?> postgres = new PostgreSQLContainer<>("postgres:16");
    
    @Container
    static RabbitMQContainer rabbitmq = new RabbitMQContainer("rabbitmq:3.13");
    
    @Autowired
    private TestRestTemplate restTemplate;
    
    @Test
    void shouldCreateTicketEndToEnd() {
        // Arrange
        TicketCreateRequest request = new TicketCreateRequest(
            "12345678", "987654321", "Test Branch", QueueType.PERSONAL
        );
        
        // Act
        ResponseEntity<TicketResponse> response = restTemplate.postForEntity(
            "/api/tickets", request, TicketResponse.class
        );
        
        // Assert
        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.CREATED);
        assertThat(response.getBody().numero()).startsWith("P");
        assertThat(response.getBody().positionInQueue()).isEqualTo(1);
    }
}
```

---

## 10. Reportes y Métricas

### 10.1 Cobertura de Pruebas

**Objetivo:** 80% de cobertura funcional

| Módulo | Casos de Prueba | Cobertura |
|--------|----------------|-----------|
| Gestión de Tickets | 6 | 100% |
| Dashboard Admin | 3 | 100% |
| Notificaciones | 4 | 100% |
| Integración | 6 | 90% |
| **Total** | **19** | **95%** |

### 10.2 Métricas de Calidad

- ✅ **Tiempo de ejecución:** < 5 minutos para suite completa
- ✅ **Tasa de éxito:** > 95% en ejecuciones automatizadas
- ✅ **Cobertura de endpoints:** 100% de endpoints públicos
- ✅ **Cobertura de casos de error:** 80% de escenarios de fallo

---

## 11. Checklist de Ejecución

### Pre-ejecución
- [ ] Base de datos limpia
- [ ] RabbitMQ operativo
- [ ] Bot de Telegram configurado
- [ ] Variables de entorno configuradas
- [ ] Logs habilitados

### Durante Ejecución
- [ ] Monitorear logs de aplicación
- [ ] Verificar mensajes en RabbitMQ
- [ ] Confirmar notificaciones Telegram
- [ ] Validar datos en base de datos

### Post-ejecución
- [ ] Limpiar datos de prueba
- [ ] Generar reporte de resultados
- [ ] Documentar fallos encontrados
- [ ] Actualizar casos de prueba si es necesario

---

**Documento preparado por:** QA Team  
**Revisado por:** Tech Lead  
**Aprobado por:** Product Owner  

**Última actualización:** Diciembre 2024  
**Próxima revisión:** Enero 2025