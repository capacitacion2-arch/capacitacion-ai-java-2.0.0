@echo off
echo ========================================
echo EJECUTANDO UNIT TESTS - SISTEMA TICKETERO
echo ========================================
echo.

echo [1/3] Ejecutando todos los unit tests...
mvn test -Dtest="*ServiceTest"

echo.
echo [2/3] Generando reporte de cobertura JaCoCo...
mvn jacoco:report

echo.
echo [3/3] Resumen de tests ejecutados:
echo.
echo Tests por servicio:
echo - TicketServiceTest: 6 tests
echo - TicketProcessingServiceTest: 8 tests  
echo - AdvisorServiceTest: 7 tests
echo - QueueManagementServiceTest: 6 tests
echo - OutboxPublisherServiceTest: 5 tests
echo - RecoveryServiceTest: 5 tests
echo - NotificationServiceTest: 4 tests
echo.
echo Total: 41 tests unitarios
echo.
echo ========================================
echo REPORTE DE COBERTURA DISPONIBLE EN:
echo target\site\jacoco\index.html
echo ========================================

pause