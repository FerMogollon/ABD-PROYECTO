/* =====================================================================
   VETERINARIA - 3 CONSULTAS CON FUNCIONES VENTANA: ANTES vs DESPUES
 
   CONSULTAS
   1) Ingresos por veterinario y mes (gerencial)
      Ventanas: RANK, LAG, SUM acumulado, SUM por mes (% del mes)
      Indice DESPUES: IX_Cita_Fecha
   2) Cartera pendiente de cobro por propietario (cobranza)
      Ventanas: DENSE_RANK, SUM acumulado, SUM por propietario, SUM total (% cartera)
      Indices DESPUES: IX_Factura_Fecha + IX_Pago_Factura
   3) Ficha de visitas de las mascotas de un propietario (clinica)
      Ventanas: ROW_NUMBER, LAG, SUM acumulado
      Indices DESPUES: IX_Cita_Mascota_Fecha + IX_Diagnostico_Cita

   ===================================================================== */
USE Veterinaria;
GO
SET NOCOUNT ON;
GO
 
/* =====================================================================
   CONSULTA 1: INGRESOS POR VETERINARIO Y MES
   ===================================================================== */
 
-- Estado "ANTES": sin los indices 
DROP INDEX IF EXISTS IX_Cita_Fecha         ON clinica.Cita;
DROP INDEX IF EXISTS IX_Cita_Mascota_Fecha ON clinica.Cita;
DROP INDEX IF EXISTS IX_Factura_Fecha      ON facturacion.Factura;
DROP INDEX IF EXISTS IX_Pago_Factura       ON facturacion.Pago;
DROP INDEX IF EXISTS IX_Diagnostico_Cita   ON clinica.Diagnostico;
GO
UPDATE STATISTICS clinica.Cita        WITH FULLSCAN;
UPDATE STATISTICS facturacion.Factura WITH FULLSCAN;
CHECKPOINT;
DBCC DROPCLEANBUFFERS;
ALTER DATABASE SCOPED CONFIGURATION CLEAR PROCEDURE_CACHE;
GO
 
-- CONSULTA 1 - ANTES
DECLARE @Desde DATE = '2026-03-01', @Hasta DATE = '2026-06-01';
SET STATISTICS IO ON;
SET STATISTICS TIME ON;
 
WITH IngresosMes AS (
    SELECT c.ID_Veterinario,
           DATEFROMPARTS(YEAR(c.Fecha), MONTH(c.Fecha), 1) AS Mes,
           COUNT(*)     AS Facturas,
           SUM(f.Monto) AS Ingresos
    FROM   clinica.Cita c
    JOIN   facturacion.Factura f ON f.ID_Cita = c.ID_Cita
    WHERE  c.Fecha >= @Desde AND c.Fecha < @Hasta
      AND  c.Estado = 'Completada'
    GROUP BY c.ID_Veterinario, DATEFROMPARTS(YEAR(c.Fecha), MONTH(c.Fecha), 1)
)
SELECT v.Nombre AS Veterinario, im.Mes, im.Facturas, im.Ingresos,
       RANK() OVER (PARTITION BY im.Mes ORDER BY im.Ingresos DESC)                         AS Ranking_Mes,
       LAG(im.Ingresos) OVER (PARTITION BY im.ID_Veterinario ORDER BY im.Mes)              AS Ingresos_Mes_Anterior,
       im.Ingresos - LAG(im.Ingresos) OVER (PARTITION BY im.ID_Veterinario ORDER BY im.Mes) AS Variacion,
       SUM(im.Ingresos) OVER (PARTITION BY im.ID_Veterinario ORDER BY im.Mes
                              ROWS UNBOUNDED PRECEDING)                                    AS Acumulado,
       CAST(100.0 * im.Ingresos / SUM(im.Ingresos) OVER (PARTITION BY im.Mes) AS DECIMAL(5,1)) AS Pct_del_Mes
FROM   IngresosMes im
JOIN   clinica.Veterinario v ON v.ID_Veterinario = im.ID_Veterinario
ORDER BY im.Mes, Ranking_Mes
OPTION (RECOMPILE);
 
SET STATISTICS IO OFF;
SET STATISTICS TIME OFF;
GO
 
-- Estado "DESPUES": crear indice
CREATE INDEX IX_Cita_Fecha ON clinica.Cita (Fecha) INCLUDE (ID_Veterinario, Estado);
GO
UPDATE STATISTICS clinica.Cita WITH FULLSCAN;
CHECKPOINT;
DBCC DROPCLEANBUFFERS;
ALTER DATABASE SCOPED CONFIGURATION CLEAR PROCEDURE_CACHE;
GO
 
-- CONSULTA 1 - DESPUES 
DECLARE @Desde DATE = '2026-03-01', @Hasta DATE = '2026-06-01';
SET STATISTICS IO ON;
SET STATISTICS TIME ON;
 
WITH IngresosMes AS (
    SELECT c.ID_Veterinario,
           DATEFROMPARTS(YEAR(c.Fecha), MONTH(c.Fecha), 1) AS Mes,
           COUNT(*)     AS Facturas,
           SUM(f.Monto) AS Ingresos
    FROM   clinica.Cita c
    JOIN   facturacion.Factura f ON f.ID_Cita = c.ID_Cita
    WHERE  c.Fecha >= @Desde AND c.Fecha < @Hasta
      AND  c.Estado = 'Completada'
    GROUP BY c.ID_Veterinario, DATEFROMPARTS(YEAR(c.Fecha), MONTH(c.Fecha), 1)
)
SELECT v.Nombre AS Veterinario, im.Mes, im.Facturas, im.Ingresos,
       RANK() OVER (PARTITION BY im.Mes ORDER BY im.Ingresos DESC)                         AS Ranking_Mes,
       LAG(im.Ingresos) OVER (PARTITION BY im.ID_Veterinario ORDER BY im.Mes)              AS Ingresos_Mes_Anterior,
       im.Ingresos - LAG(im.Ingresos) OVER (PARTITION BY im.ID_Veterinario ORDER BY im.Mes) AS Variacion,
       SUM(im.Ingresos) OVER (PARTITION BY im.ID_Veterinario ORDER BY im.Mes
                              ROWS UNBOUNDED PRECEDING)                                    AS Acumulado,
       CAST(100.0 * im.Ingresos / SUM(im.Ingresos) OVER (PARTITION BY im.Mes) AS DECIMAL(5,1)) AS Pct_del_Mes
FROM   IngresosMes im
JOIN   clinica.Veterinario v ON v.ID_Veterinario = im.ID_Veterinario
ORDER BY im.Mes, Ranking_Mes
OPTION (RECOMPILE);
 
SET STATISTICS IO OFF;
SET STATISTICS TIME OFF;
GO
 
 
/* =====================================================================
   CONSULTA 2: CARTERA PENDIENTE DE COBRO POR PROPIETARIO
   (facturas emitidas en el rango con saldo = Monto - suma de pagos)
   ===================================================================== */
 
-- Estado "ANTES": sin los indices
DROP INDEX IF EXISTS IX_Cita_Fecha         ON clinica.Cita;
DROP INDEX IF EXISTS IX_Cita_Mascota_Fecha ON clinica.Cita;
DROP INDEX IF EXISTS IX_Factura_Fecha      ON facturacion.Factura;
DROP INDEX IF EXISTS IX_Pago_Factura       ON facturacion.Pago;
DROP INDEX IF EXISTS IX_Diagnostico_Cita   ON clinica.Diagnostico;
GO
UPDATE STATISTICS facturacion.Factura WITH FULLSCAN;
UPDATE STATISTICS facturacion.Pago    WITH FULLSCAN;
CHECKPOINT;
DBCC DROPCLEANBUFFERS;
ALTER DATABASE SCOPED CONFIGURATION CLEAR PROCEDURE_CACHE;
GO
 
-- CONSULTA 2 - ANTES
DECLARE @Desde DATE = '2026-03-01', @Hasta DATE = '2026-06-01';
SET STATISTICS IO ON;
SET STATISTICS TIME ON;
 
WITH Saldos AS (
    SELECT f.Num_Factura, f.ID_Propietario, f.Fecha, f.Estado_Pago, f.Monto,
           ISNULL(pg.Pagado, 0)           AS Pagado,
           f.Monto - ISNULL(pg.Pagado, 0) AS Saldo
    FROM   facturacion.Factura f
    OUTER APPLY (SELECT SUM(p.Monto) AS Pagado
                 FROM   facturacion.Pago p
                 WHERE  p.Num_Factura = f.Num_Factura) pg
    WHERE  f.Fecha >= @Desde AND f.Fecha < @Hasta
),
Pendientes AS (
    SELECT *, SUM(Saldo) OVER (PARTITION BY ID_Propietario) AS Deuda_Propietario
    FROM   Saldos
    WHERE  Saldo > 0
)
SELECT pr.Nombre AS Propietario, pe.Num_Factura, pe.Fecha, pe.Estado_Pago,
       pe.Monto, pe.Pagado, pe.Saldo, pe.Deuda_Propietario,
       DENSE_RANK() OVER (ORDER BY pe.Deuda_Propietario DESC)                          AS Ranking_Deudor,
       SUM(pe.Saldo) OVER (PARTITION BY pe.ID_Propietario
                           ORDER BY pe.Fecha, pe.Num_Factura ROWS UNBOUNDED PRECEDING) AS Saldo_Acumulado,
       CAST(100.0 * pe.Saldo / SUM(pe.Saldo) OVER () AS DECIMAL(5,1))                  AS Pct_Cartera,
       DATEDIFF(DAY, pe.Fecha, CAST(GETDATE() AS DATE))                                AS Dias_Antiguedad
FROM   Pendientes pe
JOIN   clientes.Propietario pr ON pr.ID_Propietario = pe.ID_Propietario
ORDER BY Ranking_Deudor, pe.Fecha, pe.Num_Factura
OPTION (RECOMPILE);
 
SET STATISTICS IO OFF;
SET STATISTICS TIME OFF;
GO
 
-- Estado "DESPUES": crear indices
CREATE INDEX IX_Factura_Fecha ON facturacion.Factura (Fecha) INCLUDE (ID_Propietario, Estado_Pago, Monto);
CREATE INDEX IX_Pago_Factura  ON facturacion.Pago (Num_Factura) INCLUDE (Monto);   -- la FK no tenia indice
GO
UPDATE STATISTICS facturacion.Factura WITH FULLSCAN;
UPDATE STATISTICS facturacion.Pago    WITH FULLSCAN;
CHECKPOINT;
DBCC DROPCLEANBUFFERS;
ALTER DATABASE SCOPED CONFIGURATION CLEAR PROCEDURE_CACHE;
GO
 
-- CONSULTA 2 - DESPUES 
DECLARE @Desde DATE = '2026-03-01', @Hasta DATE = '2026-06-01';
SET STATISTICS IO ON;
SET STATISTICS TIME ON;
 
WITH Saldos AS (
    SELECT f.Num_Factura, f.ID_Propietario, f.Fecha, f.Estado_Pago, f.Monto,
           ISNULL(pg.Pagado, 0)           AS Pagado,
           f.Monto - ISNULL(pg.Pagado, 0) AS Saldo
    FROM   facturacion.Factura f
    OUTER APPLY (SELECT SUM(p.Monto) AS Pagado
                 FROM   facturacion.Pago p
                 WHERE  p.Num_Factura = f.Num_Factura) pg
    WHERE  f.Fecha >= @Desde AND f.Fecha < @Hasta
),
Pendientes AS (
    SELECT *, SUM(Saldo) OVER (PARTITION BY ID_Propietario) AS Deuda_Propietario
    FROM   Saldos
    WHERE  Saldo > 0
)
SELECT pr.Nombre AS Propietario, pe.Num_Factura, pe.Fecha, pe.Estado_Pago,
       pe.Monto, pe.Pagado, pe.Saldo, pe.Deuda_Propietario,
       DENSE_RANK() OVER (ORDER BY pe.Deuda_Propietario DESC)                          AS Ranking_Deudor,
       SUM(pe.Saldo) OVER (PARTITION BY pe.ID_Propietario
                           ORDER BY pe.Fecha, pe.Num_Factura ROWS UNBOUNDED PRECEDING) AS Saldo_Acumulado,
       CAST(100.0 * pe.Saldo / SUM(pe.Saldo) OVER () AS DECIMAL(5,1))                  AS Pct_Cartera,
       DATEDIFF(DAY, pe.Fecha, CAST(GETDATE() AS DATE))                                AS Dias_Antiguedad
FROM   Pendientes pe
JOIN   clientes.Propietario pr ON pr.ID_Propietario = pe.ID_Propietario
ORDER BY Ranking_Deudor, pe.Fecha, pe.Num_Factura
OPTION (RECOMPILE);
 
SET STATISTICS IO OFF;
SET STATISTICS TIME OFF;
GO
 
 
/* =====================================================================
   CONSULTA 3: FICHA DE VISITAS DE LAS MASCOTAS DE UN PROPIETARIO
   (el propietario se elige solo: el que mas visitas no canceladas tiene)
   ===================================================================== */
 
-- Estado "ANTES": sin los indices
DROP INDEX IF EXISTS IX_Cita_Fecha         ON clinica.Cita;
DROP INDEX IF EXISTS IX_Cita_Mascota_Fecha ON clinica.Cita;
DROP INDEX IF EXISTS IX_Factura_Fecha      ON facturacion.Factura;
DROP INDEX IF EXISTS IX_Pago_Factura       ON facturacion.Pago;
DROP INDEX IF EXISTS IX_Diagnostico_Cita   ON clinica.Diagnostico;
GO
UPDATE STATISTICS clinica.Cita        WITH FULLSCAN;
UPDATE STATISTICS clientes.Mascota    WITH FULLSCAN;
UPDATE STATISTICS clinica.Diagnostico WITH FULLSCAN;
UPDATE STATISTICS facturacion.Factura WITH FULLSCAN;
CHECKPOINT;
DBCC DROPCLEANBUFFERS;
ALTER DATABASE SCOPED CONFIGURATION CLEAR PROCEDURE_CACHE;
GO
 
-- CONSULTA 3 - ANTES

DECLARE @ID_Propietario BIGINT = (
    SELECT TOP 1 m.ID_Propietario
    FROM   clinica.Cita c
    JOIN   clientes.Mascota m ON m.ID_Mascota = c.ID_Mascota
    WHERE  c.Estado <> 'Cancelada'
    GROUP BY m.ID_Propietario
    ORDER BY COUNT(*) DESC, m.ID_Propietario);
SET STATISTICS IO ON;
SET STATISTICS TIME ON;
 
SELECT pr.Nombre AS Propietario, m.Nombre AS Mascota, m.Especie,
       c.Fecha, c.Estado, dg.Diagnosticos, f.Monto,
       ROW_NUMBER() OVER (PARTITION BY m.ID_Mascota ORDER BY c.Fecha, c.Hora) AS Nro_Visita,
       DATEDIFF(DAY, LAG(c.Fecha) OVER (PARTITION BY m.ID_Mascota ORDER BY c.Fecha, c.Hora), c.Fecha) AS Dias_Desde_Anterior,
       SUM(f.Monto) OVER (PARTITION BY m.ID_Mascota ORDER BY c.Fecha, c.Hora
                          ROWS UNBOUNDED PRECEDING)                           AS Gasto_Acumulado
FROM   clientes.Mascota m
JOIN   clientes.Propietario pr ON pr.ID_Propietario = m.ID_Propietario
JOIN   clinica.Cita c          ON c.ID_Mascota      = m.ID_Mascota
OUTER APPLY (SELECT STRING_AGG(d.Descripcion, '; ') AS Diagnosticos   -- una cita puede tener varios diagnosticos
             FROM   clinica.Diagnostico d
             WHERE  d.ID_Cita = c.ID_Cita) dg
LEFT JOIN facturacion.Factura f ON f.ID_Cita = c.ID_Cita
WHERE  m.ID_Propietario = @ID_Propietario
  AND  c.Estado <> 'Cancelada'
ORDER BY m.Nombre, Nro_Visita
OPTION (RECOMPILE);
 
SET STATISTICS IO OFF;
SET STATISTICS TIME OFF;
GO
 
-- Estado "DESPUES": crear indices
CREATE INDEX IX_Cita_Mascota_Fecha ON clinica.Cita (ID_Mascota, Fecha, Hora) INCLUDE (Estado);
CREATE INDEX IX_Diagnostico_Cita   ON clinica.Diagnostico (ID_Cita) INCLUDE (Descripcion);   -- la FK no tenia indice
GO
UPDATE STATISTICS clinica.Cita        WITH FULLSCAN;
UPDATE STATISTICS clinica.Diagnostico WITH FULLSCAN;
CHECKPOINT;
DBCC DROPCLEANBUFFERS;
ALTER DATABASE SCOPED CONFIGURATION CLEAR PROCEDURE_CACHE;
GO
 
-- CONSULTA 3 - DESPUES 
DECLARE @ID_Propietario BIGINT = (
    SELECT TOP 1 m.ID_Propietario
    FROM   clinica.Cita c
    JOIN   clientes.Mascota m ON m.ID_Mascota = c.ID_Mascota
    WHERE  c.Estado <> 'Cancelada'
    GROUP BY m.ID_Propietario
    ORDER BY COUNT(*) DESC, m.ID_Propietario);
SET STATISTICS IO ON;
SET STATISTICS TIME ON;
 
SELECT pr.Nombre AS Propietario, m.Nombre AS Mascota, m.Especie,
       c.Fecha, c.Estado, dg.Diagnosticos, f.Monto,
       ROW_NUMBER() OVER (PARTITION BY m.ID_Mascota ORDER BY c.Fecha, c.Hora) AS Nro_Visita,
       DATEDIFF(DAY, LAG(c.Fecha) OVER (PARTITION BY m.ID_Mascota ORDER BY c.Fecha, c.Hora), c.Fecha) AS Dias_Desde_Anterior,
       SUM(f.Monto) OVER (PARTITION BY m.ID_Mascota ORDER BY c.Fecha, c.Hora
                          ROWS UNBOUNDED PRECEDING)                           AS Gasto_Acumulado
FROM   clientes.Mascota m
JOIN   clientes.Propietario pr ON pr.ID_Propietario = m.ID_Propietario
JOIN   clinica.Cita c          ON c.ID_Mascota      = m.ID_Mascota
OUTER APPLY (SELECT STRING_AGG(d.Descripcion, '; ') AS Diagnosticos
             FROM   clinica.Diagnostico d
             WHERE  d.ID_Cita = c.ID_Cita) dg
LEFT JOIN facturacion.Factura f ON f.ID_Cita = c.ID_Cita
WHERE  m.ID_Propietario = @ID_Propietario
  AND  c.Estado <> 'Cancelada'
ORDER BY m.Nombre, Nro_Visita
OPTION (RECOMPILE);
 
SET STATISTICS IO OFF;
SET STATISTICS TIME OFF;
GO
 
 
/* =====================================================================
   INDICES CREADOS PARA LAS CONSULTAS 1, 2 Y 3
   ===================================================================== */
CREATE INDEX IX_Cita_Fecha ON clinica.Cita (Fecha) INCLUDE (ID_Veterinario, Estado);
CREATE INDEX IX_Factura_Fecha ON facturacion.Factura (Fecha) INCLUDE (ID_Propietario, Estado_Pago, Monto);
CREATE INDEX IX_Pago_Factura  ON facturacion.Pago (Num_Factura) INCLUDE (Monto);
CREATE INDEX IX_Cita_Mascota_Fecha ON clinica.Cita (ID_Mascota, Fecha, Hora) INCLUDE (Estado);
CREATE INDEX IX_Diagnostico_Cita   ON clinica.Diagnostico (ID_Cita) INCLUDE (Descripcion); 
GO
 
 
/* =====================================================================
   COSTO DE LOS INDICES 
   ===================================================================== */
SELECT OBJECT_SCHEMA_NAME(i.object_id) + '.' + OBJECT_NAME(i.object_id) AS Tabla,
       i.name                  AS Indice,
       i.type_desc             AS Tipo,
       SUM(ps.used_page_count) AS Paginas,
       SUM(ps.used_page_count) * 8 AS KB,
       SUM(ps.row_count)       AS Filas
FROM   sys.indexes i
JOIN   sys.dm_db_partition_stats ps
       ON ps.object_id = i.object_id AND ps.index_id = i.index_id
WHERE  i.object_id IN (OBJECT_ID(N'clinica.Cita'), OBJECT_ID(N'clinica.Diagnostico'),
                       OBJECT_ID(N'facturacion.Factura'), OBJECT_ID(N'facturacion.Pago'))
GROUP BY i.object_id, i.name, i.type_desc
ORDER BY Tabla, i.type_desc, i.name;
GO
 
/* =========================================================================
   USO DE LOS INDICES DESDE EL ULTIMO REINICIO DEL SERVIDOR
   
   ========================================================================= */
SELECT i.name AS Indice, us.user_seeks, us.user_scans, us.user_lookups, us.user_updates
FROM   sys.indexes i
LEFT JOIN sys.dm_db_index_usage_stats us
       ON us.object_id = i.object_id AND us.index_id = i.index_id AND us.database_id = DB_ID()
WHERE  i.name IN (N'IX_Cita_Fecha', N'IX_Cita_Mascota_Fecha', N'IX_Factura_Fecha',
                  N'IX_Pago_Factura', N'IX_Diagnostico_Cita');
GO
 