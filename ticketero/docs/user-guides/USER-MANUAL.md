# 👥 Manual de Usuario - Sistema Ticketero

**Proyecto:** Ticketero - Queue Management System  
**Versión:** 2.0  
**Fecha:** Diciembre 2024  
**Audiencia:** Ejecutivos de Sucursal, Administradores, Personal Bancario  

---

## 📑 Contenido

1. [Introducción al Sistema](#1-introducción-al-sistema)
2. [Primeros Pasos](#2-primeros-pasos)
3. [Gestión de Tickets](#3-gestión-de-tickets)
4. [Dashboard Administrativo](#4-dashboard-administrativo)
5. [Gestión de Asesores](#5-gestión-de-asesores)
6. [Notificaciones Telegram](#6-notificaciones-telegram)
7. [Casos de Uso Comunes](#7-casos-de-uso-comunes)
8. [Solución de Problemas](#8-solución-de-problemas)
9. [Preguntas Frecuentes](#9-preguntas-frecuentes)

---

## 1. Introducción al Sistema

### 1.1 ¿Qué es el Sistema Ticketero?

El Sistema Ticketero es una solución digital que moderniza la gestión de turnos en sucursales bancarias, eliminando las colas físicas y mejorando la experiencia del cliente mediante:

- **📱 Notificaciones automáticas** vía Telegram
- **⏱️ Tiempos de espera reales** calculados dinámicamente
- **📊 Dashboard administrativo** para supervisión
- **🔄 Gestión inteligente** de colas por tipo de servicio

### 1.2 Beneficios Principales

| Beneficio | Descripción |
|-----------|-------------|
| **Reducción de Colas** | Los clientes no necesitan esperar físicamente |
| **Mejor Experiencia** | Notificaciones proactivas sobre su turno |
| **Eficiencia Operativa** | Gestión optimizada de recursos humanos |
| **Visibilidad Total** | Monitoreo en tiempo real de todas las colas |
| **Flexibilidad** | Adaptable a diferentes tipos de servicio |

### 1.3 Tipos de Usuario

| Rol | Responsabilidades | Acceso |
|-----|-------------------|--------|
| **Ejecutivo de Sucursal** | Crear tickets, atender clientes | API básica |
| **Administrador** | Supervisar sistema, gestionar asesores | Dashboard completo |
| **Asesor Bancario** | Atender turnos asignados | Consulta de estado |
| **Cliente** | Recibir notificaciones | Solo Telegram |

---

## 2. Primeros Pasos

### 2.1 Acceso al Sistema

El sistema funciona a través de una **API REST** que puede ser consumida desde:

- **Aplicaciones web** (desarrolladas por el banco)
- **Herramientas como Postman** (para pruebas)
- **Sistemas internos** del banco
- **Aplicaciones móviles** (futuro)

**URL Base:** `http://localhost:8080` (entorno local)  
**URL Producción:** `https://ticketero.banco.com` (configurar según banco)

### 2.2 Configuración Inicial

#### Para Administradores

1. **Verificar servicios activos:**
   ```bash
   curl http://localhost:8080/actuator/health
   ```
   
2. **Configurar bot de Telegram:**
   - Crear bot con @BotFather
   - Obtener token del bot
   - Configurar en variables de entorno

3. **Verificar colas disponibles:**
   ```bash
   curl http://localhost:8080/api/admin/dashboard
   ```

#### Para Ejecutivos

1. **Herramienta recomendada:** Postman o aplicación web del banco
2. **Endpoints principales:**
   - Crear ticket: `POST /api/tickets`
   - Consultar ticket: `GET /api/tickets/{uuid}`
   - Ver posición: `GET /api/tickets/{numero}/position`

---

## 3. Gestión de Tickets

### 3.1 Crear un Nuevo Ticket

#### Información Requerida

| Campo | Descripción | Formato | Obligatorio |
|-------|-------------|---------|-------------|
| **ID Nacional** | Identificación del cliente | 8-12 dígitos | ✅ Sí |
| **Teléfono** | Para notificaciones Telegram | 9-15 dígitos | ❌ No |
| **Sucursal** | Nombre de la sucursal | Texto libre | ✅ Sí |
| **Tipo de Cola** | Servicio requerido | CAJA/PERSONAL/EMPRESAS/GERENCIA | ✅ Sí |

#### Proceso Paso a Paso

**Paso 1: Recopilar información del cliente**
```
Cliente: "Necesito hacer un depósito"
Ejecutivo: Identifica que necesita cola CAJA
```

**Paso 2: Crear el ticket**
```bash
POST /api/tickets
Content-Type: application/json

{
  "nationalId": "12345678",
  "telefono": "987654321",
  "branchOffice": "Sucursal Centro",
  "queueType": "CAJA"
}
```

**Paso 3: Entregar información al cliente**
```json
Respuesta del sistema:
{
  "identificador": "550e8400-e29b-41d4-a716-446655440000",
  "numero": "C001",
  "queueType": "CAJA",
  "status": "WAITING",
  "positionInQueue": 3,
  "estimatedWaitMinutes": 15,
  "ticketsAheadOfYou": 2,
  "branchOffice": "Sucursal Centro",
  "createdAt": "2024-12-01T10:30:00"
}
```

**Paso 4: Informar al cliente**
```
"Su número de turno es C001. 
Está en la posición 3 con un tiempo estimado de 15 minutos.
Recibirá notificaciones en Telegram cuando sea su turno."
```

### 3.2 Tipos de Cola Disponibles

#### CAJA - Operaciones Básicas
- **Servicios:** Depósitos, retiros, pagos
- **Tiempo promedio:** 5 minutos
- **Prefijo:** C (C001, C002, C003...)

#### PERSONAL - Banca Personal  
- **Servicios:** Apertura de cuentas, tarjetas, consultas
- **Tiempo promedio:** 15 minutos
- **Prefijo:** P (P001, P002, P003...)

#### EMPRESAS - Banca Empresarial
- **Servicios:** Créditos empresariales, servicios corporativos
- **Tiempo promedio:** 25 minutos
- **Prefijo:** E (E001, E002, E003...)

#### GERENCIA - Atención Gerencial
- **Servicios:** Casos especiales, reclamos, productos premium
- **Tiempo promedio:** 30 minutos
- **Prefijo:** G (G001, G002, G003...)

### 3.3 Consultar Estado de Ticket

#### Por Código de Referencia (UUID)
```bash
GET /api/tickets/550e8400-e29b-41d4-a716-446655440000
```

#### Por Número de Ticket
```bash
GET /api/tickets/C001/position
```

**Respuesta típica:**
```json
{
  "numero": "C001",
  "queueType": "CAJA",
  "currentPosition": 2,
  "ticketsAhead": 1,
  "estimatedWaitMinutes": 10,
  "avgServiceTimeMinutes": 5,
  "ticketsAheadNumbers": ["C002"]
}
```

---

## 4. Dashboard Administrativo

### 4.1 Vista General del Sistema

#### Acceder al Dashboard
```bash
GET /api/admin/dashboard
```

#### Información Mostrada

**Estado de Colas:**
- Número de tickets por cola
- Tickets en espera vs atendidos
- Tiempo promedio de atención

**Estado de Asesores:**
- Asesores disponibles/ocupados
- Productividad por asesor
- Distribución de carga

**Métricas del Sistema:**
- Total de tickets creados hoy
- Tiempo de respuesta promedio
- Tasa de notificaciones exitosas

### 4.2 Monitoreo por Cola

#### Ver Estado de Cola Específica
```bash
GET /api/admin/queues/PERSONAL
```

**Información detallada:**
```json
{
  "queueType": "PERSONAL",
  "activeTickets": 5,
  "tickets": [
    {
      "numero": "P001",
      "status": "IN_PROGRESS",
      "assignedAdvisor": "Ana García",
      "moduleNumber": 2,
      "waitTime": "00:12:30"
    },
    {
      "numero": "P002", 
      "status": "WAITING",
      "positionInQueue": 1,
      "estimatedWaitMinutes": 8
    }
  ]
}
```

#### Estadísticas Avanzadas
```bash
GET /api/admin/queues/PERSONAL/stats
```

**Métricas incluidas:**
- Tickets procesados hoy
- Tiempo promedio de atención
- Tiempo máximo de espera
- Tasa de abandono (si aplica)

### 4.3 Resumen Ejecutivo

#### Dashboard Consolidado
```bash
GET /api/admin/summary
```

**Vista de alto nivel para gerencia:**
- KPIs principales
- Comparativo con días anteriores
- Alertas y recomendaciones
- Estado general del sistema

---

## 5. Gestión de Asesores

### 5.1 Ver Lista de Asesores

```bash
GET /api/admin/advisors
```

**Información por asesor:**
```json
{
  "id": 1,
  "name": "Ana García",
  "moduleNumber": 2,
  "status": "AVAILABLE",
  "queueSpecialization": "PERSONAL",
  "currentTicket": null,
  "ticketsProcessedToday": 12,
  "avgServiceTime": "00:14:30"
}
```

### 5.2 Estados de Asesor

| Estado | Descripción | Cuándo Usar |
|--------|-------------|-------------|
| **AVAILABLE** | Disponible para atender | Asesor libre, esperando cliente |
| **BUSY** | Atendiendo cliente | Durante atención activa |
| **BREAK** | En descanso | Pausa, almuerzo, reunión |
| **OFFLINE** | Fuera de servicio | Fin de turno, ausencia |

### 5.3 Cambiar Estado de Asesor

#### Marcar como Ocupado
```bash
PUT /api/admin/advisors/1/status?status=BUSY
```

#### Enviar a Descanso
```bash
PUT /api/admin/advisors/1/status?status=BREAK
```

#### Casos de Uso Comunes

**Inicio de turno:**
```bash
# Marcar asesor como disponible
PUT /api/admin/advisors/1/status?status=AVAILABLE
```

**Pausa para almuerzo:**
```bash
# Enviar a descanso
PUT /api/admin/advisors/1/status?status=BREAK

# Después del almuerzo
PUT /api/admin/advisors/1/status?status=AVAILABLE
```

**Fin de turno:**
```bash
# Marcar como offline
PUT /api/admin/advisors/1/status?status=OFFLINE
```

### 5.4 Estadísticas de Asesores

```bash
GET /api/admin/advisors/stats
```

**Métricas incluidas:**
- Productividad por asesor
- Tiempo promedio de atención
- Tickets procesados por hora
- Distribución de carga de trabajo

---

## 6. Notificaciones Telegram

### 6.1 Configuración del Bot

#### Para Administradores del Sistema

**Paso 1: Crear bot en Telegram**
1. Abrir Telegram y buscar @BotFather
2. Enviar `/newbot`
3. Seguir instrucciones para nombrar el bot
4. Guardar el token proporcionado

**Paso 2: Configurar en el sistema**
```bash
# Variables de entorno
TELEGRAM_BOT_TOKEN=123456789:ABCdefGHIjklMNOpqrsTUVwxyz
TELEGRAM_CHAT_ID=987654321
```

### 6.2 Tipos de Notificación

#### 1. Confirmación de Ticket (Inmediata)
```
🎫 ¡Tu turno está listo!

Número: P001
Cola: Banca Personal  
Posición: 3
Tiempo estimado: 45 minutos
Sucursal: Centro

Te avisaremos cuando falten 3 turnos.
```

#### 2. Aviso de Proximidad (3 turnos antes)
```
⏰ ¡Faltan 3 turnos para ti!

Número: P001
Cola: Banca Personal
Tiempo estimado: 15 minutos

Prepárate para dirigirte a la sucursal.
```

#### 3. Turno Activo (Es tu turno)
```
🔔 ¡ES TU TURNO!

Número: P001
Módulo: 2
Asesor: Ana García

Dirígete al módulo 2 ahora.
```

### 6.3 Solución de Problemas con Notificaciones

#### Cliente no recibe notificaciones

**Verificaciones:**
1. ¿El teléfono fue proporcionado correctamente?
2. ¿El cliente tiene Telegram instalado?
3. ¿El bot está configurado correctamente?

**Solución:**
```bash
# Verificar configuración del bot
curl http://localhost:8080/actuator/health

# Ver logs de notificaciones
docker logs ticketero-api | grep "telegram"
```

#### Notificaciones duplicadas

**Causa común:** Reintentos automáticos del sistema

**Solución:** Verificar que el campo `proximoTurnoNotificado` esté funcionando correctamente

---

## 7. Casos de Uso Comunes

### 7.1 Escenario: Cliente para Depósito

**Situación:** Cliente llega para hacer un depósito en efectivo

**Proceso:**
1. **Ejecutivo:** "Buenos días, ¿en qué le puedo ayudar?"
2. **Cliente:** "Necesito hacer un depósito"
3. **Ejecutivo:** Identifica que necesita cola CAJA
4. **Ejecutivo:** Solicita ID y teléfono (opcional)
5. **Sistema:** Crea ticket C003
6. **Ejecutivo:** "Su número es C003, posición 2, tiempo estimado 10 minutos"
7. **Cliente:** Recibe notificación en Telegram
8. **Cliente:** Puede irse y regresar cuando sea su turno

### 7.2 Escenario: Cliente para Apertura de Cuenta

**Situación:** Cliente nuevo quiere abrir cuenta de ahorros

**Proceso:**
1. **Ejecutivo:** Identifica que necesita cola PERSONAL
2. **Sistema:** Crea ticket P005
3. **Cliente:** Posición 4, tiempo estimado 60 minutos
4. **Cliente:** Puede hacer otras actividades mientras espera
5. **Sistema:** Envía notificación cuando faltan 3 turnos
6. **Cliente:** Regresa a la sucursal
7. **Sistema:** Notifica cuando es su turno exacto

### 7.3 Escenario: Día de Alta Demanda

**Situación:** Día de pago, muchos clientes

**Proceso administrativo:**
1. **Administrador:** Monitorea dashboard cada 30 minutos
2. **Sistema:** Muestra colas saturadas
3. **Administrador:** Asigna asesores adicionales a colas críticas
4. **Sistema:** Recalcula tiempos automáticamente
5. **Clientes:** Reciben tiempos actualizados vía Telegram

### 7.4 Escenario: Asesor en Descanso

**Situación:** Asesor necesita tomar descanso

**Proceso:**
1. **Asesor:** Termina atención actual
2. **Administrador:** Cambia estado a BREAK
3. **Sistema:** Redistribuye tickets pendientes
4. **Clientes:** Reciben tiempos actualizados
5. **Después del descanso:** Cambiar estado a AVAILABLE

---

## 8. Solución de Problemas

### 8.1 Problemas Comunes

#### Error: "ID nacional inválido"

**Causa:** Formato incorrecto del ID
**Solución:** 
- Verificar que tenga entre 8-12 dígitos
- Solo números, sin letras ni símbolos
- Ejemplos válidos: `12345678`, `123456789012`

#### Error: "Teléfono inválido"

**Causa:** Formato incorrecto del teléfono
**Solución:**
- Entre 9-15 dígitos
- Solo números, sin símbolos
- Ejemplos válidos: `987654321`, `51987654321`

#### Error: "Tipo de cola obligatorio"

**Causa:** No se especificó queueType
**Solución:** Usar uno de: `CAJA`, `PERSONAL`, `EMPRESAS`, `GERENCIA`

#### Sistema lento o no responde

**Verificaciones:**
1. **Estado del sistema:**
   ```bash
   curl http://localhost:8080/actuator/health
   ```

2. **Servicios activos:**
   ```bash
   docker-compose ps
   ```

3. **Logs del sistema:**
   ```bash
   docker logs ticketero-api
   ```

### 8.2 Códigos de Error HTTP

| Código | Significado | Acción |
|--------|-------------|--------|
| **200** | ✅ Éxito | Continuar normalmente |
| **201** | ✅ Creado | Ticket creado exitosamente |
| **400** | ❌ Datos inválidos | Verificar formato de datos |
| **404** | ❌ No encontrado | Verificar UUID o número de ticket |
| **500** | ❌ Error del servidor | Contactar soporte técnico |

### 8.3 Contacto de Soporte

**Para problemas técnicos:**
- Email: soporte.ticketero@banco.com
- Teléfono: +1-800-TICKETS
- Horario: Lunes a Viernes, 8:00 AM - 6:00 PM

**Para emergencias (sistema caído):**
- Teléfono: +1-800-URGENTE
- Disponible 24/7

---

## 9. Preguntas Frecuentes

### 9.1 Preguntas Generales

**P: ¿Qué pasa si el cliente no tiene Telegram?**
R: El sistema funciona igual, pero no recibirá notificaciones. Puede consultar su posición en cualquier momento con el ejecutivo.

**P: ¿Se puede cambiar el tipo de cola después de crear el ticket?**
R: No, debe crear un nuevo ticket. El sistema está diseñado para mantener integridad de las colas.

**P: ¿Cuánto tiempo es válido un ticket?**
R: Los tickets no expiran automáticamente, pero se recomienda atender el mismo día.

**P: ¿Qué pasa si el cliente llega tarde a su turno?**
R: Puede ser atendido cuando llegue, pero podría tener que esperar según disponibilidad.

### 9.2 Preguntas Técnicas

**P: ¿El sistema funciona sin internet?**
R: El sistema local funciona, pero las notificaciones Telegram requieren internet.

**P: ¿Se pueden crear tickets desde múltiples dispositivos?**
R: Sí, cualquier dispositivo con acceso a la API puede crear tickets.

**P: ¿Hay límite de tickets por día?**
R: Sí, configurable por cola. Por defecto: CAJA (200), PERSONAL (100), EMPRESAS (50), GERENCIA (20).

### 9.3 Preguntas de Administración

**P: ¿Cómo agregar un nuevo asesor?**
R: Actualmente se hace directamente en la base de datos. Próxima versión incluirá interfaz administrativa.

**P: ¿Se pueden cambiar los tiempos promedio de atención?**
R: Sí, modificando la configuración en la tabla `queue_config`.

**P: ¿Hay reportes históricos?**
R: Actualmente no. Los datos se almacenan y pueden consultarse directamente en la base de datos.

---

## 10. Mejores Prácticas

### 10.1 Para Ejecutivos de Sucursal

- ✅ **Verificar datos** antes de crear ticket
- ✅ **Explicar el proceso** al cliente
- ✅ **Proporcionar número de ticket** claramente
- ✅ **Confirmar teléfono** para notificaciones
- ❌ **No crear tickets duplicados** para el mismo cliente

### 10.2 Para Administradores

- ✅ **Monitorear dashboard** regularmente
- ✅ **Ajustar estados de asesores** según necesidad
- ✅ **Revisar métricas** diariamente
- ✅ **Mantener configuración** actualizada
- ❌ **No cambiar configuraciones** sin documentar

### 10.3 Para el Banco

- ✅ **Capacitar personal** en el uso del sistema
- ✅ **Comunicar beneficios** a los clientes
- ✅ **Monitorear satisfacción** del cliente
- ✅ **Planificar escalamiento** según demanda
- ❌ **No depender únicamente** del sistema digital

---

## 11. Glosario

| Término | Definición |
|---------|------------|
| **API** | Interfaz de programación que permite comunicación con el sistema |
| **Dashboard** | Panel de control administrativo |
| **Outbox Pattern** | Patrón que garantiza consistencia entre base de datos y mensajería |
| **Queue Type** | Tipo de cola (CAJA, PERSONAL, EMPRESAS, GERENCIA) |
| **RabbitMQ** | Sistema de mensajería para notificaciones |
| **Ticket** | Turno digital generado por el sistema |
| **UUID** | Identificador único universal del ticket |

---

**Manual preparado por:** Equipo de Producto  
**Revisado por:** Equipo de UX y Soporte  
**Aprobado por:** Gerencia de Sucursales  

**Versión:** 2.0  
**Última actualización:** Diciembre 2024  
**Próxima revisión:** Marzo 2025

---

*Para sugerencias de mejora de este manual, contactar: documentacion@banco.com*