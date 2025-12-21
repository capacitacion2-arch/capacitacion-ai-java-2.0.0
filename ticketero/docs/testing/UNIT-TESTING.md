# 🔬 Estrategia de Pruebas Unitarias - Sistema Ticketero

**Proyecto:** Ticketero - Queue Management System  
**Versión:** 2.0  
**Fecha:** Diciembre 2024  
**Framework:** JUnit 5 + Mockito + Spring Boot Test  

---

## 📑 Contenido

1. [Estrategia General](#1-estrategia-general)
2. [Configuración y Herramientas](#2-configuración-y-herramientas)
3. [Pruebas por Capa](#3-pruebas-por-capa)
4. [Ejemplos de Implementación](#4-ejemplos-de-implementación)
5. [Cobertura y Métricas](#5-cobertura-y-métricas)
6. [Mejores Prácticas](#6-mejores-prácticas)
7. [Casos Especiales](#7-casos-especiales)
8. [Automatización](#8-automatización)

---

## 1. Estrategia General

### 1.1 Objetivos

- ✅ **Cobertura:** Mínimo 80% de cobertura de líneas
- ✅ **Calidad:** Tests rápidos, confiables y mantenibles
- ✅ **Aislamiento:** Cada test es independiente
- ✅ **Documentación:** Tests como documentación viva del código

### 1.2 Pirámide de Testing

```
        /\
       /  \
      / E2E \     ← Pocos, lentos, costosos
     /______\
    /        \
   / Integration \  ← Algunos, medianos
  /______________\
 /                \
/ Unit Tests       \  ← Muchos, rápidos, baratos
/____________________\
```

**Distribución objetivo:**
- **70%** Unit Tests
- **20%** Integration Tests  
- **10%** End-to-End Tests

### 1.3 Alcance por Capa

| Capa | Cobertura Objetivo | Estrategia |
|------|-------------------|------------|
| **Controllers** | 60% | Tests de contrato, validaciones |
| **Services** | 90% | Lógica de negocio completa |
| **Repositories** | 30% | Solo queries custom |
| **Utils/Helpers** | 95% | Funciones puras |

---

## 2. Configuración y Herramientas

### 2.1 Dependencias Maven

```xml
<dependencies>
    <!-- Testing Framework -->
    <dependency>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-test</artifactId>
        <scope>test</scope>
    </dependency>
    
    <!-- Mockito para mocking -->
    <dependency>
        <groupId>org.mockito</groupId>
        <artifactId>mockito-core</artifactId>
        <scope>test</scope>
    </dependency>
    
    <!-- AssertJ para assertions fluidas -->
    <dependency>
        <groupId>org.assertj</groupId>
        <artifactId>assertj-core</artifactId>
        <scope>test</scope>
    </dependency>
    
    <!-- TestContainers para integration tests -->
    <dependency>
        <groupId>org.testcontainers</groupId>
        <artifactId>junit-jupiter</artifactId>
        <scope>test</scope>
    </dependency>
</dependencies>
```

### 2.2 Configuración JaCoCo

```xml
<plugin>
    <groupId>org.jacoco</groupId>
    <artifactId>jacoco-maven-plugin</artifactId>
    <version>0.8.11</version>
    <configuration>
        <rules>
            <rule>
                <element>BUNDLE</element>
                <limits>
                    <limit>
                        <counter>INSTRUCTION</counter>
                        <value>COVEREDRATIO</value>
                        <minimum>0.80</minimum>
                    </limit>
                </limits>
            </rule>
        </rules>
        <excludes>
            <exclude>**/model/dto/**</exclude>
            <exclude>**/model/entity/**</exclude>
            <exclude>**/config/**</exclude>
            <exclude>**/TicketeroApplication.class</exclude>
        </excludes>
    </configuration>
</plugin>
```

### 2.3 Configuración de Test

```yaml
# application-test.yml
spring:
  datasource:
    url: jdbc:h2:mem:testdb
    driver-class-name: org.h2.Driver
  jpa:
    hibernate:
      ddl-auto: create-drop
  rabbitmq:
    host: localhost
    port: 5672
    
logging:
  level:
    com.example.ticketero: DEBUG
    org.springframework.test: INFO
```

---

## 3. Pruebas por Capa

### 3.1 Capa de Servicios (Services)

#### Estrategia
- **Foco:** Lógica de negocio
- **Mocking:** Repositories y servicios externos
- **Cobertura:** 90%+

#### Ejemplo: TicketServiceTest

```java
@ExtendWith(MockitoExtension.class)
class TicketServiceTest {

    @Mock
    private TicketRepository ticketRepository;
    
    @Mock
    private OutboxMessageRepository outboxMessageRepository;
    
    @Mock
    private QueueManagementService queueManagementService;
    
    @Mock
    private NotificationService notificationService;
    
    @Mock
    private MetricsService metricsService;
    
    @Mock
    private ObjectMapper objectMapper;
    
    @InjectMocks
    private TicketService ticketService;

    @Test
    @DisplayName("Debe crear ticket con datos válidos y calcular posición correcta")
    void crearTicket_conDatosValidos_debeRetornarTicketConPosicionCorrecta() {
        // Given
        TicketCreateRequest request = new TicketCreateRequest(
            "12345678", "987654321", "Sucursal Centro", QueueType.PERSONAL
        );
        
        when(queueManagementService.calcularPosicionEnCola(QueueType.PERSONAL))
            .thenReturn(3);
        when(queueManagementService.calcularTiempoEstimado(QueueType.PERSONAL, 3))
            .thenReturn(45);
        
        Ticket ticketGuardado = Ticket.builder()
            .id(1L)
            .codigoReferencia(UUID.randomUUID())
            .numero("P001")
            .nationalId("12345678")
            .telefono("987654321")
            .queueType(QueueType.PERSONAL)
            .status(TicketStatus.WAITING)
            .positionInQueue(3)
            .estimatedWaitMinutes(45)
            .build();
            
        when(ticketRepository.saveAndFlush(any(Ticket.class)))
            .thenReturn(ticketGuardado);

        // When
        TicketResponse response = ticketService.crearTicket(request);

        // Then
        assertThat(response).isNotNull();
        assertThat(response.numero()).isEqualTo("P001");
        assertThat(response.positionInQueue()).isEqualTo(3);
        assertThat(response.estimatedWaitMinutes()).isEqualTo(45);
        assertThat(response.queueType()).isEqualTo(QueueType.PERSONAL);
        
        // Verificar interacciones
        verify(ticketRepository).saveAndFlush(any(Ticket.class));
        verify(outboxMessageRepository).save(any(OutboxMessage.class));
        verify(notificationService).notificarTicketCreado(any(Ticket.class));
        verify(metricsService).incrementTicketsCreated(QueueType.PERSONAL);
    }

    @Test
    @DisplayName("Debe manejar ticket sin teléfono correctamente")
    void crearTicket_sinTelefono_debeCrearTicketSinNotificaciones() {
        // Given
        TicketCreateRequest request = new TicketCreateRequest(
            "87654321", null, "Sucursal Norte", QueueType.CAJA
        );
        
        when(queueManagementService.calcularPosicionEnCola(QueueType.CAJA))
            .thenReturn(1);
        when(queueManagementService.calcularTiempoEstimado(QueueType.CAJA, 1))
            .thenReturn(5);
        
        Ticket ticketGuardado = Ticket.builder()
            .id(2L)
            .numero("C001")
            .nationalId("87654321")
            .telefono(null)
            .queueType(QueueType.CAJA)
            .build();
            
        when(ticketRepository.saveAndFlush(any(Ticket.class)))
            .thenReturn(ticketGuardado);

        // When
        TicketResponse response = ticketService.crearTicket(request);

        // Then
        assertThat(response.numero()).isEqualTo("C001");
        
        // Verificar que NO se llama al servicio de notificaciones
        verify(notificationService, never()).notificarTicketCreado(any());
    }

    @Test
    @DisplayName("Debe lanzar excepción cuando ticket no existe")
    void obtenerTicketPorCodigo_ticketInexistente_debeLanzarExcepcion() {
        // Given
        UUID codigoInexistente = UUID.randomUUID();
        when(ticketRepository.findByCodigoReferencia(codigoInexistente))
            .thenReturn(Optional.empty());

        // When & Then
        assertThatThrownBy(() -> ticketService.obtenerTicketPorCodigo(codigoInexistente))
            .isInstanceOf(TicketNotFoundException.class)
            .hasMessageContaining(codigoInexistente.toString());
    }

    @Test
    @DisplayName("Debe calcular posición en cola correctamente")
    void obtenerPosicionEnCola_conTicketsAdelante_debeCalcularCorrectamente() {
        // Given
        String numeroTicket = "P002";
        
        Ticket ticket = Ticket.builder()
            .numero(numeroTicket)
            .queueType(QueueType.PERSONAL)
            .positionInQueue(3)
            .estimatedWaitMinutes(45)
            .build();
            
        List<Ticket> ticketsAdelante = Arrays.asList(
            Ticket.builder().numero("P001").positionInQueue(1).build(),
            Ticket.builder().numero("P003").positionInQueue(2).build()
        );
        
        when(ticketRepository.findByNumero(numeroTicket))
            .thenReturn(Optional.of(ticket));
        when(ticketRepository.findByQueueAndStatus(QueueType.PERSONAL, TicketStatus.WAITING))
            .thenReturn(ticketsAdelante);

        // When
        QueuePositionResponse response = ticketService.obtenerPosicionEnCola(numeroTicket);

        // Then
        assertThat(response.numero()).isEqualTo(numeroTicket);
        assertThat(response.currentPosition()).isEqualTo(3);
        assertThat(response.ticketsAhead()).isEqualTo(2);
        assertThat(response.ticketsAheadNumbers()).containsExactly("P001", "P003");
    }
}
```

### 3.2 Capa de Controladores (Controllers)

#### Estrategia
- **Foco:** Validaciones, mapeo HTTP, manejo de errores
- **Herramienta:** `@WebMvcTest`
- **Mocking:** Services

#### Ejemplo: TicketControllerTest

```java
@WebMvcTest(TicketController.class)
class TicketControllerTest {

    @Autowired
    private MockMvc mockMvc;
    
    @MockBean
    private TicketService ticketService;
    
    @Autowired
    private ObjectMapper objectMapper;

    @Test
    @DisplayName("POST /api/tickets - Debe crear ticket con datos válidos")
    void crearTicket_datosValidos_debeRetornar201() throws Exception {
        // Given
        TicketCreateRequest request = new TicketCreateRequest(
            "12345678", "987654321", "Sucursal Centro", QueueType.PERSONAL
        );
        
        TicketResponse expectedResponse = new TicketResponse(
            UUID.randomUUID(), "P001", QueueType.PERSONAL, TicketStatus.WAITING,
            1, 15, 0, "Sucursal Centro", null,
            LocalDateTime.now(), null, null, null
        );
        
        when(ticketService.crearTicket(any(TicketCreateRequest.class)))
            .thenReturn(expectedResponse);

        // When & Then
        mockMvc.perform(post("/api/tickets")
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.numero").value("P001"))
                .andExpect(jsonPath("$.queueType").value("PERSONAL"))
                .andExpect(jsonPath("$.positionInQueue").value(1))
                .andExpect(jsonPath("$.estimatedWaitMinutes").value(15));
        
        verify(ticketService).crearTicket(any(TicketCreateRequest.class));
    }

    @Test
    @DisplayName("POST /api/tickets - Debe retornar 400 con ID nacional inválido")
    void crearTicket_idNacionalInvalido_debeRetornar400() throws Exception {
        // Given
        TicketCreateRequest request = new TicketCreateRequest(
            "123", "987654321", "Sucursal Centro", QueueType.PERSONAL
        );

        // When & Then
        mockMvc.perform(post("/api/tickets")
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.message").value(containsString("ID nacional inválido")));
        
        verify(ticketService, never()).crearTicket(any());
    }

    @Test
    @DisplayName("GET /api/tickets/{uuid} - Debe retornar ticket existente")
    void obtenerTicket_ticketExistente_debeRetornar200() throws Exception {
        // Given
        UUID codigoReferencia = UUID.randomUUID();
        TicketResponse expectedResponse = new TicketResponse(
            codigoReferencia, "P001", QueueType.PERSONAL, TicketStatus.WAITING,
            1, 15, 0, "Sucursal Centro", null,
            LocalDateTime.now(), null, null, null
        );
        
        when(ticketService.obtenerTicketPorCodigo(codigoReferencia))
            .thenReturn(expectedResponse);

        // When & Then
        mockMvc.perform(get("/api/tickets/{uuid}", codigoReferencia))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.identificador").value(codigoReferencia.toString()))
                .andExpect(jsonPath("$.numero").value("P001"));
    }

    @Test
    @DisplayName("GET /api/tickets/{uuid} - Debe retornar 404 para ticket inexistente")
    void obtenerTicket_ticketInexistente_debeRetornar404() throws Exception {
        // Given
        UUID codigoInexistente = UUID.randomUUID();
        when(ticketService.obtenerTicketPorCodigo(codigoInexistente))
            .thenThrow(new TicketNotFoundException(codigoInexistente));

        // When & Then
        mockMvc.perform(get("/api/tickets/{uuid}", codigoInexistente))
                .andExpect(status().isNotFound());
    }
}
```

### 3.3 Capa de Repositorios (Repositories)

#### Estrategia
- **Foco:** Solo queries custom complejas
- **Herramienta:** `@DataJpaTest`
- **Base de datos:** H2 en memoria

#### Ejemplo: TicketRepositoryTest

```java
@DataJpaTest
class TicketRepositoryTest {

    @Autowired
    private TestEntityManager entityManager;
    
    @Autowired
    private TicketRepository ticketRepository;

    @Test
    @DisplayName("Debe encontrar tickets activos por cola")
    void findActiveByQueue_conTicketsEnCola_debeRetornarSoloActivos() {
        // Given
        Ticket ticketActivo1 = Ticket.builder()
            .numero("P001")
            .nationalId("12345678")
            .branchOffice("Test")
            .queueType(QueueType.PERSONAL)
            .status(TicketStatus.WAITING)
            .build();
            
        Ticket ticketActivo2 = Ticket.builder()
            .numero("P002")
            .nationalId("87654321")
            .branchOffice("Test")
            .queueType(QueueType.PERSONAL)
            .status(TicketStatus.CALLED)
            .build();
            
        Ticket ticketCompletado = Ticket.builder()
            .numero("P003")
            .nationalId("11223344")
            .branchOffice("Test")
            .queueType(QueueType.PERSONAL)
            .status(TicketStatus.COMPLETED)
            .build();
            
        entityManager.persistAndFlush(ticketActivo1);
        entityManager.persistAndFlush(ticketActivo2);
        entityManager.persistAndFlush(ticketCompletado);

        // When
        List<Ticket> result = ticketRepository.findActiveByQueue(QueueType.PERSONAL);

        // Then
        assertThat(result).hasSize(2);
        assertThat(result).extracting(Ticket::getNumero)
            .containsExactlyInAnyOrder("P001", "P002");
        assertThat(result).extracting(Ticket::getStatus)
            .allMatch(status -> status != TicketStatus.COMPLETED);
    }

    @Test
    @DisplayName("Debe encontrar ticket por código de referencia")
    void findByCodigoReferencia_ticketExistente_debeRetornarTicket() {
        // Given
        UUID codigoReferencia = UUID.randomUUID();
        Ticket ticket = Ticket.builder()
            .codigoReferencia(codigoReferencia)
            .numero("P001")
            .nationalId("12345678")
            .branchOffice("Test")
            .queueType(QueueType.PERSONAL)
            .status(TicketStatus.WAITING)
            .build();
            
        entityManager.persistAndFlush(ticket);

        // When
        Optional<Ticket> result = ticketRepository.findByCodigoReferencia(codigoReferencia);

        // Then
        assertThat(result).isPresent();
        assertThat(result.get().getNumero()).isEqualTo("P001");
        assertThat(result.get().getCodigoReferencia()).isEqualTo(codigoReferencia);
    }
}
```

### 3.4 Utilidades y Helpers

#### Ejemplo: LogSanitizerTest

```java
class LogSanitizerTest {

    @Test
    @DisplayName("Debe sanitizar ID nacional mostrando solo primeros y últimos dígitos")
    void sanitize_idNacional_debeMostrarSoloPrimerosYUltimos() {
        // Given
        String idNacional = "12345678";

        // When
        String result = LogSanitizer.sanitize(idNacional);

        // Then
        assertThat(result).isEqualTo("123****78");
    }

    @Test
    @DisplayName("Debe manejar strings cortos sin sanitizar")
    void sanitize_stringCorto_debeRetornarCompleto() {
        // Given
        String input = "123";

        // When
        String result = LogSanitizer.sanitize(input);

        // Then
        assertThat(result).isEqualTo("123");
    }

    @Test
    @DisplayName("Debe manejar null sin lanzar excepción")
    void sanitize_null_debeRetornarNull() {
        // When
        String result = LogSanitizer.sanitize(null);

        // Then
        assertThat(result).isNull();
    }
}
```

---

## 4. Ejemplos de Implementación

### 4.1 Test de Servicio Complejo

```java
@ExtendWith(MockitoExtension.class)
class QueueManagementServiceTest {

    @Mock
    private TicketRepository ticketRepository;
    
    @Mock
    private QueueConfigRepository queueConfigRepository;
    
    @InjectMocks
    private QueueManagementService queueManagementService;

    @Test
    @DisplayName("Debe calcular tiempo estimado basado en posición y configuración")
    void calcularTiempoEstimado_conPosicionYConfiguracion_debeCalcularCorrectamente() {
        // Given
        QueueType queueType = QueueType.PERSONAL;
        int posicion = 3;
        
        QueueConfig config = QueueConfig.builder()
            .queueType(queueType)
            .avgServiceTimeMinutes(15)
            .build();
            
        when(queueConfigRepository.findByQueueType(queueType))
            .thenReturn(Optional.of(config));

        // When
        int tiempoEstimado = queueManagementService.calcularTiempoEstimado(queueType, posicion);

        // Then
        assertThat(tiempoEstimado).isEqualTo(45); // 3 * 15 minutos
    }

    @Test
    @DisplayName("Debe usar tiempo por defecto cuando no hay configuración")
    void calcularTiempoEstimado_sinConfiguracion_debeUsarDefault() {
        // Given
        QueueType queueType = QueueType.PERSONAL;
        int posicion = 2;
        
        when(queueConfigRepository.findByQueueType(queueType))
            .thenReturn(Optional.empty());

        // When
        int tiempoEstimado = queueManagementService.calcularTiempoEstimado(queueType, posicion);

        // Then
        assertThat(tiempoEstimado).isEqualTo(30); // 2 * 15 minutos (default)
    }
}
```

### 4.2 Test con Múltiples Mocks

```java
@ExtendWith(MockitoExtension.class)
class NotificationServiceTest {

    @Mock
    private TelegramService telegramService;
    
    @Mock
    private TicketRepository ticketRepository;
    
    @InjectMocks
    private NotificationService notificationService;

    @Test
    @DisplayName("Debe enviar notificación de confirmación cuando ticket tiene teléfono")
    void notificarTicketCreado_conTelefono_debeEnviarNotificacion() {
        // Given
        Ticket ticket = Ticket.builder()
            .numero("P001")
            .telefono("987654321")
            .queueType(QueueType.PERSONAL)
            .positionInQueue(1)
            .estimatedWaitMinutes(15)
            .branchOffice("Sucursal Centro")
            .build();

        // When
        notificationService.notificarTicketCreado(ticket);

        // Then
        ArgumentCaptor<String> messageCaptor = ArgumentCaptor.forClass(String.class);
        verify(telegramService).enviarMensaje(eq("987654321"), messageCaptor.capture());
        
        String mensaje = messageCaptor.getValue();
        assertThat(mensaje).contains("P001");
        assertThat(mensaje).contains("posición: 1");
        assertThat(mensaje).contains("15 minutos");
        assertThat(mensaje).contains("Sucursal Centro");
    }

    @Test
    @DisplayName("No debe enviar notificación cuando ticket no tiene teléfono")
    void notificarTicketCreado_sinTelefono_noDebeEnviarNotificacion() {
        // Given
        Ticket ticket = Ticket.builder()
            .numero("P001")
            .telefono(null)
            .queueType(QueueType.PERSONAL)
            .build();

        // When
        notificationService.notificarTicketCreado(ticket);

        // Then
        verify(telegramService, never()).enviarMensaje(anyString(), anyString());
    }
}
```

### 4.3 Test de Excepciones

```java
@ExtendWith(MockitoExtension.class)
class TicketServiceExceptionTest {

    @Mock
    private TicketRepository ticketRepository;
    
    @InjectMocks
    private TicketService ticketService;

    @Test
    @DisplayName("Debe lanzar excepción cuando falla la persistencia")
    void crearTicket_falloEnPersistencia_debeLanzarExcepcion() {
        // Given
        TicketCreateRequest request = new TicketCreateRequest(
            "12345678", "987654321", "Sucursal Centro", QueueType.PERSONAL
        );
        
        when(ticketRepository.saveAndFlush(any(Ticket.class)))
            .thenThrow(new DataAccessException("Database error") {});

        // When & Then
        assertThatThrownBy(() -> ticketService.crearTicket(request))
            .isInstanceOf(DataAccessException.class)
            .hasMessageContaining("Database error");
    }

    @Test
    @DisplayName("Debe manejar gracefully errores de serialización JSON")
    void crearTicket_errorSerializacion_debeLanzarRuntimeException() {
        // Given
        TicketCreateRequest request = new TicketCreateRequest(
            "12345678", "987654321", "Sucursal Centro", QueueType.PERSONAL
        );
        
        when(objectMapper.writeValueAsString(any()))
            .thenThrow(new JsonProcessingException("Serialization error") {});

        // When & Then
        assertThatThrownBy(() -> ticketService.crearTicket(request))
            .isInstanceOf(RuntimeException.class)
            .hasMessageContaining("Error serializando mensaje outbox");
    }
}
```

---

## 5. Cobertura y Métricas

### 5.1 Objetivos de Cobertura

| Tipo de Cobertura | Objetivo | Herramienta |
|-------------------|----------|-------------|
| **Líneas** | 80% | JaCoCo |
| **Ramas** | 70% | JaCoCo |
| **Métodos** | 85% | JaCoCo |
| **Clases** | 90% | JaCoCo |

### 5.2 Exclusiones de Cobertura

```xml
<excludes>
    <!-- DTOs y Entities (solo data holders) -->
    <exclude>**/model/dto/**</exclude>
    <exclude>**/model/entity/**</exclude>
    
    <!-- Configuraciones (Spring Boot) -->
    <exclude>**/config/**</exclude>
    
    <!-- Main class -->
    <exclude>**/TicketeroApplication.class</exclude>
    
    <!-- Enums simples -->
    <exclude>**/model/enums/**</exclude>
</excludes>
```

### 5.3 Reporte de Cobertura

```bash
# Generar reporte
./mvnw clean test jacoco:report

# Ver reporte HTML
open target/site/jacoco/index.html

# Verificar umbral
./mvnw jacoco:check
```

### 5.4 Métricas de Calidad

```java
// Ejemplo de métricas en test
@Test
void testMetrics() {
    // Tiempo de ejecución < 100ms
    long startTime = System.currentTimeMillis();
    
    // Test logic here
    
    long executionTime = System.currentTimeMillis() - startTime;
    assertThat(executionTime).isLessThan(100);
}
```

---

## 6. Mejores Prácticas

### 6.1 Nomenclatura de Tests

```java
// Patrón: methodName_condition_expectedBehavior
@Test
void crearTicket_conDatosValidos_debeRetornarTicketConPosicionCorrecta() { }

@Test
void obtenerTicket_ticketInexistente_debeLanzarTicketNotFoundException() { }

@Test
void calcularPosicion_colaVacia_debeRetornarPosicionUno() { }
```

### 6.2 Estructura AAA (Arrange-Act-Assert)

```java
@Test
void ejemploEstructuraAAA() {
    // Arrange (Given)
    TicketCreateRequest request = new TicketCreateRequest(...);
    when(mockService.method()).thenReturn(expectedValue);
    
    // Act (When)
    TicketResponse result = ticketService.crearTicket(request);
    
    // Assert (Then)
    assertThat(result).isNotNull();
    assertThat(result.numero()).startsWith("P");
    verify(mockService).method();
}
```

### 6.3 Uso de Test Data Builders

```java
// TestDataBuilder.java
public class TestDataBuilder {
    
    public static TicketCreateRequest.Builder validTicketRequest() {
        return TicketCreateRequest.builder()
            .nationalId("12345678")
            .telefono("987654321")
            .branchOffice("Sucursal Test")
            .queueType(QueueType.PERSONAL);
    }
    
    public static Ticket.Builder validTicket() {
        return Ticket.builder()
            .id(1L)
            .codigoReferencia(UUID.randomUUID())
            .numero("P001")
            .nationalId("12345678")
            .status(TicketStatus.WAITING);
    }
}

// Uso en tests
@Test
void test() {
    TicketCreateRequest request = TestDataBuilder.validTicketRequest()
        .queueType(QueueType.CAJA)
        .build();
}
```

### 6.4 Assertions Fluidas con AssertJ

```java
@Test
void ejemploAssertions() {
    List<Ticket> tickets = ticketService.obtenerTicketsPorCola(QueueType.PERSONAL);
    
    assertThat(tickets)
        .isNotEmpty()
        .hasSize(3)
        .extracting(Ticket::getStatus)
        .containsOnly(TicketStatus.WAITING)
        .doesNotContain(TicketStatus.COMPLETED);
        
    assertThat(tickets.get(0))
        .satisfies(ticket -> {
            assertThat(ticket.getNumero()).startsWith("P");
            assertThat(ticket.getPositionInQueue()).isPositive();
            assertThat(ticket.getCreatedAt()).isBefore(LocalDateTime.now());
        });
}
```

### 6.5 Manejo de Excepciones

```java
@Test
void debeManejearExcepcionesCorrectamente() {
    // Verificar que se lanza la excepción correcta
    assertThatThrownBy(() -> ticketService.obtenerTicketPorCodigo(UUID.randomUUID()))
        .isInstanceOf(TicketNotFoundException.class)
        .hasMessageContaining("Ticket not found");
    
    // Verificar que NO se lanza excepción
    assertThatCode(() -> ticketService.crearTicket(validRequest))
        .doesNotThrowAnyException();
}
```

---

## 7. Casos Especiales

### 7.1 Testing de Métodos Asíncronos

```java
@Test
void testMetodoAsincrono() throws Exception {
    // Given
    CompletableFuture<String> future = new CompletableFuture<>();
    when(asyncService.processAsync()).thenReturn(future);
    
    // When
    CompletableFuture<String> result = serviceUnderTest.processAsync();
    
    // Complete the future
    future.complete("success");
    
    // Then
    assertThat(result.get(1, TimeUnit.SECONDS)).isEqualTo("success");
}
```

### 7.2 Testing con Fechas y Tiempo

```java
@Test
void testConFechas() {
    // Usar Clock mock para controlar tiempo
    Clock fixedClock = Clock.fixed(
        Instant.parse("2024-12-01T10:00:00Z"), 
        ZoneOffset.UTC
    );
    
    // Inyectar clock en servicio o usar @MockBean
    when(clockService.now()).thenReturn(LocalDateTime.now(fixedClock));
    
    // Test logic
    TicketResponse response = ticketService.crearTicket(request);
    
    assertThat(response.createdAt()).isEqualTo(LocalDateTime.now(fixedClock));
}
```

### 7.3 Testing de Transacciones

```java
@Test
@Transactional
@Rollback
void testTransaccional() {
    // Test que requiere transacción real
    // Se hace rollback automáticamente
}

@Test
void testRollbackEnError() {
    // Simular error que causa rollback
    when(repository.save(any())).thenThrow(new DataAccessException("DB Error") {});
    
    assertThatThrownBy(() -> service.crearTicket(request))
        .isInstanceOf(DataAccessException.class);
    
    // Verificar que no se guardó nada
    verify(repository, never()).saveAndFlush(any());
}
```

---

## 8. Automatización

### 8.1 Ejecución en Pipeline

```yaml
# .github/workflows/unit-tests.yml
name: Unit Tests

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-java@v4
        with:
          java-version: '21'
      
      - name: Run Unit Tests
        run: ./mvnw test
      
      - name: Generate Coverage Report
        run: ./mvnw jacoco:report
      
      - name: Check Coverage Threshold
        run: ./mvnw jacoco:check
      
      - name: Upload Coverage to Codecov
        uses: codecov/codecov-action@v3
        with:
          file: ./target/site/jacoco/jacoco.xml
```

### 8.2 Scripts de Testing

```bash
#!/bin/bash
# run-unit-tests.sh

echo "🧪 Ejecutando tests unitarios..."

# Limpiar y compilar
./mvnw clean compile test-compile

# Ejecutar solo tests unitarios (excluir integration tests)
./mvnw test -Dtest="!*IntegrationTest"

# Generar reporte de cobertura
./mvnw jacoco:report

# Verificar umbral de cobertura
./mvnw jacoco:check

echo "✅ Tests completados. Ver reporte en target/site/jacoco/index.html"
```

### 8.3 Configuración IDE

```xml
<!-- .idea/runConfigurations/Unit_Tests.xml -->
<component name="ProjectRunConfigurationManager">
  <configuration default="false" name="Unit Tests" type="JUnit" factoryName="JUnit">
    <module name="ticketero" />
    <option name="PACKAGE_NAME" value="com.example.ticketero" />
    <option name="MAIN_CLASS_NAME" value="" />
    <option name="METHOD_NAME" value="" />
    <option name="TEST_OBJECT" value="package" />
    <option name="PARAMETERS" value="" />
    <patterns>
      <pattern testClass="*Test" />
    </patterns>
  </configuration>
</component>
```

---

## 9. Checklist de Testing

### Pre-desarrollo
- [ ] Escribir test antes del código (TDD)
- [ ] Definir casos de prueba basados en requerimientos
- [ ] Configurar mocks necesarios

### Durante desarrollo
- [ ] Mantener tests actualizados con cambios
- [ ] Ejecutar tests frecuentemente
- [ ] Verificar cobertura incrementalmente

### Pre-commit
- [ ] Todos los tests pasan
- [ ] Cobertura > 80%
- [ ] No tests ignorados sin justificación
- [ ] Nombres de tests descriptivos

### Code Review
- [ ] Tests cubren casos edge
- [ ] Mocks apropiados y no excesivos
- [ ] Assertions claras y específicas
- [ ] Tests independientes entre sí

---

**Documento preparado por:** Development Team  
**Revisado por:** Tech Lead  
**Aprobado por:** QA Lead  

**Última actualización:** Diciembre 2024  
**Próxima revisión:** Enero 2025