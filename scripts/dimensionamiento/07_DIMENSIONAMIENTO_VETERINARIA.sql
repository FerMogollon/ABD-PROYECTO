/* =====================================================================
   VETERINARIA - DIMENSIONAMIENTO DE LA BASE DE DATOS (SQL Server 2025)
   Ejecutar DESPUES de 01 a 05 (y volver a ejecutar cuando se creen los indices
   de Rendimiento: el factor de indices se recalcula solo).

   ---------------------------------------------------------------------
   METODO (formulas de Microsoft "Estimate the size of a clustered/nonclustered index")
   El script toma las columnas REALES de cada tabla desde el catalogo (sys.columns),
   no valores escritos a mano, y mide el largo promedio real de las columnas de
   largo variable con AVG(DATALENGTH(...)) sobre los datos cargados.

   PASO 1  Bytes por fila de DATOS (indice agrupado = la tabla)
           Fijos      = suma de bytes de columnas de largo fijo (bigint 8, int 4, date 3,
                        time(0) 3, datetime2(0) 6, decimal(10,2) 9, char(n) n)
           Variables  = 2 + (2 x NumColVariables) + promedio de bytes de las columnas variables
           Bitmap NULL= 2 + ((NumColumnas + 7) / 8)   (division entera)
           Fila       = Fijos + Variables + BitmapNULL + 4 (encabezado de fila)
   PASO 2  Filas por pagina  = FLOOR(8096 / (Fila + 2))      [8096 = bytes utiles de una pagina
                               de 8 KB; +2 = entrada en la tabla de ranuras de la pagina]
           Con FILLFACTOR < 100 se restan las filas que se dejan libres por pagina.
   PASO 3  Paginas hoja      = CEILING(Filas / FilasPorPagina)
   PASO 4  Niveles intermedios del arbol B: cada nivel tiene CEILING(paginas del nivel de abajo /
           filas por pagina intermedia) paginas, hasta llegar a la raiz (1 pagina).
           Fila intermedia = llave del indice (+ llave de agrupamiento si no es unico) + 1 + 6
   PASO 5  +1 pagina IAM por indice (mapa de asignacion)
   PASO 6  KB = paginas x 8
   INDICES NO AGRUPADOS: fila hoja = llave + columnas incluidas + llave de agrupamiento
           (la PK actua como "puntero" a la fila) + 1 byte de encabezado.
   FACTOR DE INDICES = KB de indices no agrupados / KB de datos
   PROYECCION: filas(a) = filas actuales + crecimiento anual x a  (supuestos abajo)
   ARCHIVOS: datos = total proyectado a 5 anios x (1 + margen), redondeado a multiplos de 64 MB
             log   = el mayor de 64 MB o 1.25 x el objeto mas grande (con recuperacion FULL un
                     REBUILD de indice registra en el log aproximadamente su tamano completo;
                     los respaldos de log cada 15 min (ver 06_RESPALDOS) lo mantienen truncado)
   --------------------------------------------------------------------- */

USE Veterinaria;
GO

SET NOCOUNT ON;

-- Limpieza por si el script se ejecuta mas de una vez en la misma sesion
DROP TABLE IF EXISTS #horizonte, #tabla, #col, #idx, #cl, #idxcol, #tam0, #tam, #crec, #filas, #dim0, #dim, #nohoja, #res_idx, #res;

/* =====================================================================
   0) PARAMETROS Y SUPUESTOS (editar para otros escenarios)
   ===================================================================== */
DECLARE @CitasPorAnio            INT          = 3600;  -- 12 citas diarias x 300 dias laborales
DECLARE @FillFactor              INT          = 100;   -- 100 = paginas llenas (valor por defecto)
DECLARE @MargenCrecimiento       DECIMAL(5,2) = 0.25;  -- 25 % de holgura para crecer y reorganizar indices
DECLARE @FilasBitacoraPorFactura DECIMAL(5,2) = 7.0;   -- cambios auditados por factura (ver abajo)
DECLARE @FactorCompresion        DECIMAL(5,2) = 0.40;  -- un respaldo comprimido pesa ~40 % de los datos

CREATE TABLE #horizonte (anio INT NOT NULL PRIMARY KEY);
INSERT INTO #horizonte (anio) VALUES (0), (1), (3), (5);   -- 0 = hoy

/* =====================================================================
   1) TABLAS Y FILAS ACTUALES
   ===================================================================== */
SELECT t.object_id,
       s.name AS esquema,
       t.name AS tabla,
       (s.name + N'.' + t.name) COLLATE DATABASE_DEFAULT AS nombre,
       SUM(p.rows) AS filas
INTO   #tabla
FROM   sys.tables t
JOIN   sys.schemas s    ON s.schema_id = t.schema_id
JOIN   sys.partitions p ON p.object_id = t.object_id AND p.index_id IN (0, 1)
WHERE  s.name IN (N'clientes', N'clinica', N'catalogo', N'facturacion', N'auditoria')
GROUP BY t.object_id, s.name, t.name;

/* =====================================================================
   2) COLUMNAS: bytes fijos y promedio real de las columnas variables
   ===================================================================== */
SELECT c.object_id,
       c.column_id,
       c.name AS columna,
       ty.name AS tipo,
       c.max_length,
       c.is_nullable,
       CAST(CASE WHEN ty.name IN (N'varchar', N'nvarchar', N'varbinary') THEN 1 ELSE 0 END AS BIT) AS es_var,
       -- En sys.columns max_length de los tipos fijos ya es su tamano de almacenamiento
       CASE WHEN ty.name IN (N'varchar', N'nvarchar', N'varbinary') THEN 0 ELSE c.max_length END AS bytes_fijos,
       CAST(NULL AS DECIMAL(18,2)) AS prom_var
INTO   #col
FROM   sys.columns c
JOIN   #tabla t   ON t.object_id = c.object_id
JOIN   sys.types ty ON ty.user_type_id = c.system_type_id;

-- Largo promedio real (en bytes) de cada columna variable, contando NULL como 0
DECLARE @sql NVARCHAR(MAX) = N'';
SELECT @sql = @sql
     + N'UPDATE #col SET prom_var = (SELECT AVG(CAST(ISNULL(DATALENGTH(' + QUOTENAME(c.columna) + N'), 0) AS DECIMAL(18,4))) FROM '
     + QUOTENAME(t.esquema) + N'.' + QUOTENAME(t.tabla) + N') WHERE object_id = '
     + CAST(c.object_id AS NVARCHAR(20)) + N' AND column_id = ' + CAST(c.column_id AS NVARCHAR(10)) + N';' + CHAR(10)
FROM   #col c
JOIN   #tabla t ON t.object_id = c.object_id
WHERE  c.es_var = 1;
EXEC sys.sp_executesql @sql;

-- Tablas vacias: sin datos reales se supone el 50 % del maximo (200 bytes para tipos MAX)
UPDATE #col
SET    prom_var = CASE WHEN max_length = -1 THEN 200 ELSE max_length * 0.5 END
WHERE  es_var = 1 AND prom_var IS NULL;

/* =====================================================================
   3) INDICES Y TAMANO DE FILA POR NIVEL
   ===================================================================== */
SELECT i.object_id, i.index_id, i.name AS indice, i.type AS tipo, i.is_unique, i.is_primary_key
INTO   #idx
FROM   sys.indexes i
JOIN   #tabla t ON t.object_id = i.object_id
WHERE  i.type IN (1, 2);                  -- 1 = agrupado, 2 = no agrupado

-- Llave de agrupamiento de cada tabla (se repite dentro de todo indice no agrupado)
SELECT ic.object_id, ic.column_id
INTO   #cl
FROM   sys.index_columns ic
JOIN   #idx i ON i.object_id = ic.object_id AND i.index_id = ic.index_id
WHERE  i.tipo = 1 AND ic.is_included_column = 0;

-- Columnas de cada nivel: H = hoja, N = niveles intermedios
SELECT x.object_id, x.index_id, x.nivel, x.column_id
INTO   #idxcol
FROM (
    -- Agrupado, hoja = la fila completa de la tabla
    SELECT i.object_id, i.index_id, 'H' AS nivel, c.column_id
    FROM   #idx i JOIN #col c ON c.object_id = i.object_id
    WHERE  i.tipo = 1
    UNION
    -- Agrupado, intermedios = su llave
    SELECT i.object_id, i.index_id, 'N', ic.column_id
    FROM   #idx i
    JOIN   sys.index_columns ic ON ic.object_id = i.object_id AND ic.index_id = i.index_id
    WHERE  i.tipo = 1 AND ic.is_included_column = 0
    UNION
    -- No agrupado, hoja = llave + incluidas
    SELECT i.object_id, i.index_id, 'H', ic.column_id
    FROM   #idx i
    JOIN   sys.index_columns ic ON ic.object_id = i.object_id AND ic.index_id = i.index_id
    WHERE  i.tipo = 2
    UNION
    -- No agrupado, hoja = ... + llave de agrupamiento
    SELECT i.object_id, i.index_id, 'H', cl.column_id
    FROM   #idx i JOIN #cl cl ON cl.object_id = i.object_id
    WHERE  i.tipo = 2
    UNION
    -- No agrupado, intermedios = su llave
    SELECT i.object_id, i.index_id, 'N', ic.column_id
    FROM   #idx i
    JOIN   sys.index_columns ic ON ic.object_id = i.object_id AND ic.index_id = i.index_id
    WHERE  i.tipo = 2 AND ic.is_included_column = 0
    UNION
    -- No agrupado NO unico, intermedios = ... + llave de agrupamiento
    SELECT i.object_id, i.index_id, 'N', cl.column_id
    FROM   #idx i JOIN #cl cl ON cl.object_id = i.object_id
    WHERE  i.tipo = 2 AND i.is_unique = 0
) x;

SELECT x.object_id, x.index_id, x.nivel, i.tipo,
       COUNT(*) AS ncols,
       SUM(CASE WHEN c.es_var = 0 THEN c.bytes_fijos ELSE 0 END) AS bytes_fijos,
       SUM(CASE WHEN c.es_var = 1 THEN 1 ELSE 0 END)             AS ncols_var,
       SUM(CASE WHEN c.es_var = 1 THEN c.prom_var ELSE 0 END)    AS bytes_var,
       MAX(CASE WHEN c.is_nullable = 1 THEN 1 ELSE 0 END)        AS hay_nulos
INTO   #tam0
FROM   #idxcol x
JOIN   #idx i ON i.object_id = x.object_id AND i.index_id = x.index_id
JOIN   #col c ON c.object_id = x.object_id AND c.column_id = x.column_id
GROUP BY x.object_id, x.index_id, x.nivel, i.tipo;

SELECT t.*,
       CAST(CASE
            -- fila de datos (agrupado, hoja): fijos + variables + bitmap + 4
            WHEN t.tipo = 1 AND t.nivel = 'H' THEN t.bytes_fijos + a.bytes_var_total + (2 + (t.ncols + 7) / 8) + 4
            -- fila hoja de indice no agrupado: fijos + variables + bitmap + 1
            WHEN t.tipo = 2 AND t.nivel = 'H' THEN t.bytes_fijos + a.bytes_var_total + a.bitmap + 1
            -- fila de nivel intermedio: fijos + variables + bitmap + 1 + 6 (puntero a pagina hija)
            ELSE t.bytes_fijos + a.bytes_var_total + a.bitmap + 1 + 6
       END AS DECIMAL(18,2)) AS bytes_fila
INTO   #tam
FROM   #tam0 t
CROSS APPLY (SELECT CASE WHEN t.ncols_var > 0 THEN 2 + t.ncols_var * 2 + t.bytes_var ELSE 0 END AS bytes_var_total,
                    CASE WHEN t.hay_nulos = 1 THEN 2 + (t.ncols + 7) / 8 ELSE 0 END           AS bitmap) a;

/* =====================================================================
   4) CRECIMIENTO ANUAL (filas nuevas por anio) Y FILAS PROYECTADAS
   Las tablas dependientes de la cita se proyectan con la proporcion REAL que hoy
   tienen respecto a Cita (por ejemplo, facturas por cita).
   ===================================================================== */
DECLARE @f_cita DECIMAL(18,4) = ISNULL((SELECT filas FROM #tabla WHERE nombre = N'clinica.Cita'), 0);
IF @f_cita = 0 SET @f_cita = 1;

DECLARE @r_diag DECIMAL(18,6) = ISNULL((SELECT filas FROM #tabla WHERE nombre = N'clinica.Diagnostico'), 0)            / @f_cita;
DECLARE @r_trat DECIMAL(18,6) = ISNULL((SELECT filas FROM #tabla WHERE nombre = N'clinica.Tratamiento'), 0)             / @f_cita;
DECLARE @r_dp   DECIMAL(18,6) = ISNULL((SELECT filas FROM #tabla WHERE nombre = N'clinica.Diagnostico_Procedimiento'), 0) / @f_cita;
DECLARE @r_fact DECIMAL(18,6) = ISNULL((SELECT filas FROM #tabla WHERE nombre = N'facturacion.Factura'), 0)             / @f_cita;
DECLARE @r_det  DECIMAL(18,6) = ISNULL((SELECT filas FROM #tabla WHERE nombre = N'facturacion.Detalle_Factura'), 0)     / @f_cita;
DECLARE @r_pago DECIMAL(18,6) = ISNULL((SELECT filas FROM #tabla WHERE nombre = N'facturacion.Pago'), 0)                 / @f_cita;

CREATE TABLE #crec (
    nombre     NVARCHAR(260) COLLATE DATABASE_DEFAULT NOT NULL PRIMARY KEY,
    filas_anio DECIMAL(18,4) NOT NULL,
    criterio   NVARCHAR(300) NOT NULL
);

INSERT INTO #crec (nombre, filas_anio, criterio) VALUES
 (N'clientes.Propietario',               @CitasPorAnio * 0.10,   N'1 propietario nuevo por cada 10 citas'),
 (N'clientes.Mascota',                   @CitasPorAnio * 0.13,   N'1.3 mascotas por propietario nuevo'),
 (N'clinica.Veterinario',                1.0,                    N'1 veterinario nuevo por anio'),
 (N'clinica.Especialidad',               0.0,                    N'catalogo estable'),
 (N'clinica.Veterinario_Especialidad',   1.0,                    N'1 especialidad por veterinario nuevo'),
 (N'clinica.Cita',                       @CitasPorAnio * 1.0,    N'tabla motor: citas por anio (parametro)'),
 (N'clinica.Diagnostico',                @CitasPorAnio * @r_diag, N'proporcion actual diagnosticos / citas'),
 (N'clinica.Tratamiento',                @CitasPorAnio * @r_trat, N'proporcion actual tratamientos / citas'),
 (N'clinica.Diagnostico_Procedimiento',  @CitasPorAnio * @r_dp,   N'proporcion actual diagnostico-procedimiento / citas'),
 (N'facturacion.Factura',                @CitasPorAnio * @r_fact, N'proporcion actual facturas / citas (las canceladas no se facturan)'),
 (N'facturacion.Detalle_Factura',        @CitasPorAnio * @r_det,  N'proporcion actual lineas de detalle / citas'),
 (N'facturacion.Pago',                   @CitasPorAnio * @r_pago, N'proporcion actual pagos / citas'),
 (N'catalogo.Item_Facturable',           10.0,                   N'10 items nuevos por anio'),
 (N'catalogo.Procedimiento',             5.0,                    N'5 procedimientos nuevos por anio'),
 (N'catalogo.Medicamento',               5.0,                    N'5 medicamentos nuevos por anio'),
 (N'auditoria.Bitacora',                 @CitasPorAnio * @r_fact * @FilasBitacoraPorFactura,
                                         N'por factura: 1 alta + ~3 recalculos de monto + 1 pago + 1 cambio de estado + ~1 stock');

SELECT a.anio,
       t.object_id,
       CAST(CEILING(t.filas + ISNULL(c.filas_anio, 0) * a.anio) AS BIGINT) AS filas
INTO   #filas
FROM   #horizonte a
CROSS JOIN #tabla t
LEFT JOIN  #crec c ON c.nombre = t.nombre COLLATE DATABASE_DEFAULT;

/* =====================================================================
   5) PAGINAS POR INDICE Y ANIO (hojas + niveles intermedios + IAM)
   ===================================================================== */
SELECT a.anio, i.object_id, i.index_id, i.tipo, f.filas,
       h.bytes_fila AS bytes_hoja,
       n.bytes_fila AS bytes_nh
INTO   #dim0
FROM   #horizonte a
CROSS JOIN #idx i
JOIN   #filas f ON f.object_id = i.object_id AND f.anio = a.anio
JOIN   #tam h ON h.object_id = i.object_id AND h.index_id = i.index_id AND h.nivel = 'H'
JOIN   #tam n ON n.object_id = i.object_id AND n.index_id = i.index_id AND n.nivel = 'N';

SELECT d.*,
       z.filas_pag_hoja,
       y.filas_pag_nh,
       CAST(CASE WHEN d.filas = 0 THEN 0 ELSE CEILING(d.filas * 1.0 / z.filas_pag_hoja) END AS BIGINT) AS paginas_hoja
INTO   #dim
FROM   #dim0 d
CROSS APPLY (SELECT CASE WHEN FLOOR(8096.0 / (d.bytes_hoja + 2))
                             - FLOOR(8096.0 * (100 - @FillFactor) / 100.0 / (d.bytes_hoja + 2)) < 1
                         THEN 1
                         ELSE CAST(FLOOR(8096.0 / (d.bytes_hoja + 2))
                                 - FLOOR(8096.0 * (100 - @FillFactor) / 100.0 / (d.bytes_hoja + 2)) AS INT)
                    END AS filas_pag_hoja) z
CROSS APPLY (SELECT CASE WHEN FLOOR(8096.0 / (d.bytes_nh + 2)) < 2
                         THEN 2
                         ELSE CAST(FLOOR(8096.0 / (d.bytes_nh + 2)) AS INT)
                    END AS filas_pag_nh) y;

-- Niveles intermedios: se divide el nivel de abajo entre las filas por pagina intermedia
-- hasta llegar a la raiz (una sola pagina)
;WITH niveles AS (
    SELECT d.anio, d.object_id, d.index_id, d.filas_pag_nh,
           CAST(CEILING(1.0 * d.paginas_hoja / d.filas_pag_nh) AS BIGINT) AS paginas,
           1 AS nivel
    FROM   #dim d
    WHERE  d.paginas_hoja > 1
    UNION ALL
    SELECT n.anio, n.object_id, n.index_id, n.filas_pag_nh,
           CAST(CEILING(1.0 * n.paginas / n.filas_pag_nh) AS BIGINT),
           n.nivel + 1
    FROM   niveles n
    WHERE  n.paginas > 1
)
SELECT anio, object_id, index_id, SUM(paginas) AS paginas_no_hoja
INTO   #nohoja
FROM   niveles
GROUP BY anio, object_id, index_id
OPTION (MAXRECURSION 50);

SELECT d.anio, d.object_id, d.index_id, d.tipo, d.filas,
       d.paginas_hoja,
       ISNULL(nh.paginas_no_hoja, 0)                 AS paginas_no_hoja,
       CASE WHEN d.paginas_hoja > 0 THEN 1 ELSE 0 END AS paginas_iam
INTO   #res_idx
FROM   #dim d
LEFT JOIN #nohoja nh ON nh.anio = d.anio AND nh.object_id = d.object_id AND nh.index_id = d.index_id;

-- Resumen por tabla y anio: KB de datos (agrupado) y KB de indices (no agrupados)
SELECT anio, object_id,
       MAX(filas) AS filas,
       SUM(CASE WHEN tipo = 1 THEN (paginas_hoja + paginas_no_hoja + paginas_iam) ELSE 0 END) * 8 AS kb_datos,
       SUM(CASE WHEN tipo = 2 THEN (paginas_hoja + paginas_no_hoja + paginas_iam) ELSE 0 END) * 8 AS kb_indices
INTO   #res
FROM   #res_idx
GROUP BY anio, object_id;

/* =====================================================================
   RESULTADOS
   ===================================================================== */

-- RESULTADO 1: SUPUESTOS USADOS
SELECT N'Citas por anio'                     AS Parametro, CAST(@CitasPorAnio AS VARCHAR(20))            AS Valor, N'12 citas diarias x 300 dias' AS Nota
UNION ALL SELECT N'Fill factor',             CAST(@FillFactor AS VARCHAR(20)),            N'100 = paginas llenas'
UNION ALL SELECT N'Margen de crecimiento',   CAST(@MargenCrecimiento AS VARCHAR(20)),     N'holgura sobre el total proyectado'
UNION ALL SELECT N'Cambios auditados por factura', CAST(@FilasBitacoraPorFactura AS VARCHAR(20)), N'filas de auditoria.Bitacora por factura'
UNION ALL SELECT N'Compresion de respaldos', CAST(@FactorCompresion AS VARCHAR(20)),      N'respaldo comprimido / datos';

-- RESULTADO 2: CRECIMIENTO ANUAL POR TABLA
SELECT c.nombre AS Tabla, t.filas AS Filas_Actuales, c.filas_anio AS Filas_Nuevas_Por_Anio, c.criterio AS Criterio
FROM   #crec c
LEFT JOIN #tabla t ON t.nombre = c.nombre COLLATE DATABASE_DEFAULT
ORDER BY c.nombre;

-- RESULTADO 3: TAMANO DE FILA Y FILAS POR PAGINA (pasos 1 y 2)
-- Bytes_Fila_Real = promedio medido en las paginas hoja (sys.dm_db_index_physical_stats)
SELECT t.nombre AS Tabla,
       t.filas  AS Filas_Actuales,
       h.ncols  AS Columnas,
       CAST(h.bytes_fijos AS INT)       AS Bytes_Fijos,
       h.ncols_var                      AS Columnas_Variables,
       CAST(h.bytes_var AS DECIMAL(10,1)) AS Bytes_Variables_Promedio,
       h.bytes_fila                     AS Bytes_Fila_Teorico,
       CAST(rf.avg_record_size_in_bytes AS DECIMAL(10,1)) AS Bytes_Fila_Real,
       CAST(FLOOR(8096.0 / (h.bytes_fila + 2)) AS INT) AS Filas_Por_Pagina
FROM   #tabla t
JOIN   #tam h ON h.object_id = t.object_id AND h.tipo = 1 AND h.nivel = 'H'
LEFT JOIN (
    SELECT ips.object_id, ips.avg_record_size_in_bytes
    FROM   sys.dm_db_index_physical_stats(DB_ID(), NULL, NULL, NULL, 'DETAILED') ips
    WHERE  ips.index_id = 1 AND ips.index_level = 0 AND ips.alloc_unit_type_desc = N'IN_ROW_DATA'
) rf ON rf.object_id = t.object_id
ORDER BY t.nombre;

-- RESULTADO 4: INDICES (hoy y a 5 anios) -> base del factor de indices
SELECT t.nombre AS Tabla,
       i.indice AS Indice,
       CASE i.tipo WHEN 1 THEN N'Agrupado (datos)' ELSE N'No agrupado' END AS Tipo,
       CASE WHEN i.is_unique = 1 THEN N'Si' ELSE N'No' END AS Unico,
       h.bytes_fila AS Bytes_Fila_Hoja,
       CAST(FLOOR(8096.0 / (h.bytes_fila + 2)) AS INT) AS Filas_Por_Pagina_Hoja,
       a.paginas_hoja + a.paginas_no_hoja + a.paginas_iam AS Paginas_Hoy,
       (a.paginas_hoja + a.paginas_no_hoja + a.paginas_iam) * 8 AS KB_Hoy,
       (b.paginas_hoja + b.paginas_no_hoja + b.paginas_iam) * 8 AS KB_A_5_Anios
FROM   #idx i
JOIN   #tabla t   ON t.object_id = i.object_id
JOIN   #tam h     ON h.object_id = i.object_id AND h.index_id = i.index_id AND h.nivel = 'H'
JOIN   #res_idx a ON a.object_id = i.object_id AND a.index_id = i.index_id AND a.anio = 0
JOIN   #res_idx b ON b.object_id = i.object_id AND b.index_id = i.index_id AND b.anio = (SELECT MAX(anio) FROM #horizonte)
ORDER BY t.nombre, i.tipo, i.indice;

-- RESULTADO 5: DIMENSIONAMIENTO POR TABLA (datos + indices) Y PROYECCION
SELECT t.nombre AS Tabla,
       r0.filas AS Filas_Hoy,
       r0.kb_datos AS Datos_KB_Hoy,
       r0.kb_indices AS Indices_KB_Hoy,
       r1.filas AS Filas_1_Anio,
       r1.kb_datos + r1.kb_indices AS Total_KB_1_Anio,
       r3.filas AS Filas_3_Anios,
       r3.kb_datos + r3.kb_indices AS Total_KB_3_Anios,
       r5.filas AS Filas_5_Anios,
       r5.kb_datos AS Datos_KB_5_Anios,
       r5.kb_indices AS Indices_KB_5_Anios,
       r5.kb_datos + r5.kb_indices AS Total_KB_5_Anios,
       CAST(r5.kb_indices * 1.0 / NULLIF(r5.kb_datos, 0) AS DECIMAL(6,2)) AS Factor_Indices_5_Anios
FROM   #tabla t
JOIN   #res r0 ON r0.object_id = t.object_id AND r0.anio = 0
JOIN   #res r1 ON r1.object_id = t.object_id AND r1.anio = 1
JOIN   #res r3 ON r3.object_id = t.object_id AND r3.anio = 3
JOIN   #res r5 ON r5.object_id = t.object_id AND r5.anio = 5
ORDER BY r5.kb_datos + r5.kb_indices DESC;

-- RESULTADO 6: TOTALES POR HORIZONTE (incluye factor de indices global y margen)
SELECT r.anio AS Anios,
       SUM(r.filas) AS Filas_Totales,
       CAST(SUM(r.kb_datos)   / 1024.0 AS DECIMAL(12,2)) AS Datos_MB,
       CAST(SUM(r.kb_indices) / 1024.0 AS DECIMAL(12,2)) AS Indices_MB,
       CAST((SUM(r.kb_datos) + SUM(r.kb_indices)) / 1024.0 AS DECIMAL(12,2)) AS Total_MB,
       CAST(SUM(r.kb_indices) * 1.0 / NULLIF(SUM(r.kb_datos), 0) AS DECIMAL(6,2)) AS Factor_Indices,
       CAST((SUM(r.kb_datos) + SUM(r.kb_indices)) * (1 + @MargenCrecimiento) / 1024.0 AS DECIMAL(12,2)) AS Total_Con_Margen_MB
FROM   #res r
GROUP BY r.anio
ORDER BY r.anio;

-- RESULTADO 7: VALIDACION, TEORICO vs REAL HOY (sys.dm_db_partition_stats)
;WITH medido AS (
    SELECT ps.object_id,
           SUM(CASE WHEN ps.index_id IN (0, 1) THEN ps.used_page_count ELSE 0 END) * 8 AS kb_datos,
           SUM(CASE WHEN ps.index_id > 1       THEN ps.used_page_count ELSE 0 END) * 8 AS kb_indices
    FROM   sys.dm_db_partition_stats ps
    WHERE  ps.object_id IN (SELECT object_id FROM #tabla)
    GROUP BY ps.object_id
)
SELECT t.nombre AS Tabla,
       a.kb_datos   AS Datos_KB_Teorico,   m.kb_datos   AS Datos_KB_Real,
       CAST(100.0 * (a.kb_datos - m.kb_datos) / NULLIF(m.kb_datos, 0) AS DECIMAL(6,1)) AS Dif_Datos_Pct,
       a.kb_indices AS Indices_KB_Teorico, m.kb_indices AS Indices_KB_Real,
       CAST(100.0 * (a.kb_indices - m.kb_indices) / NULLIF(m.kb_indices, 0) AS DECIMAL(6,1)) AS Dif_Indices_Pct
FROM   #tabla t
JOIN   #res a  ON a.object_id = t.object_id AND a.anio = 0
JOIN   medido m ON m.object_id = t.object_id
ORDER BY t.nombre;

-- RESULTADO 8: TAMANO RECOMENDADO DE ARCHIVOS Y SCRIPT SUGERIDO
DECLARE @anio_max INT = (SELECT MAX(anio) FROM #horizonte);
DECLARE @total_kb DECIMAL(18,2) = (SELECT SUM(kb_datos + kb_indices) FROM #res WHERE anio = @anio_max);
DECLARE @mayor_kb DECIMAL(18,2) = (SELECT MAX(kb_datos + kb_indices) FROM #res WHERE anio = @anio_max);

DECLARE @datos_mb INT = CAST(CEILING(CEILING(@total_kb * (1 + @MargenCrecimiento) / 1024.0) / 64.0) * 64 AS INT);
DECLARE @log_mb   INT = CAST(CEILING(CASE WHEN @mayor_kb * 1.25 / 1024.0 < 64 THEN 64
                                          ELSE @mayor_kb * 1.25 / 1024.0 END / 64.0) * 64 AS INT);

SELECT f.name AS Archivo,
       f.type_desc AS Tipo,
       f.size * 8 / 1024 AS Tamano_Actual_MB,
       r.mb AS Tamano_Recomendado_MB,
       CASE WHEN f.size * 8 / 1024 < r.mb
            THEN CONCAT(N'ALTER DATABASE ', QUOTENAME(DB_NAME()), N' MODIFY FILE (NAME = N''', f.name,
                        N''', SIZE = ', r.mb, N'MB, FILEGROWTH = 64MB);')
            ELSE N'-- el archivo ya tiene el tamano recomendado' END AS Script_Sugerido
FROM   sys.database_files f
CROSS APPLY (SELECT CASE WHEN f.type = 0 THEN @datos_mb ELSE @log_mb END AS mb) r
WHERE  f.type IN (0, 1);

SELECT N'Datos proyectados a ' + CAST(@anio_max AS NVARCHAR(5)) + N' anios (MB)'            AS Concepto, CAST(@total_kb / 1024.0 AS DECIMAL(12,2)) AS Valor_MB
UNION ALL SELECT N'Archivo de datos recomendado (total + margen, multiplo de 64 MB)',        @datos_mb
UNION ALL SELECT N'Archivo de log recomendado (max. entre 64 MB y 1.25 x objeto mayor)',       @log_mb
UNION ALL SELECT N'Respaldo FULL comprimido estimado',                                        CAST(@total_kb * @FactorCompresion / 1024.0 AS DECIMAL(12,2));
