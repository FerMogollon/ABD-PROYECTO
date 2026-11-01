/* =====================================================================
   VETERINARIA - CONSULTAS Y PRUEBAS (SQL Server 2025)
   Migrado desde PostgreSQL.

   Equivalencias usadas:
   - LIMIT n                          -> SELECT TOP (n)
   - current_date                     -> CAST(GETDATE() AS DATE)
   - extract(month/year ...)          -> rangos de fechas (aprovechan indices)
   - interval '6 months'              -> DATEADD(MONTH, -6, ...)
   - string_agg(x, ', ' order by x)   -> STRING_AGG(x, ', ') WITHIN GROUP (ORDER BY x)
   - || (concatenar)                  -> CONCAT()
   - GROUP BY por alias               -> GROUP BY por columna (T-SQL no permite alias)
   ===================================================================== */

USE Veterinaria;
GO

/* =====================================================================
   A) CONSULTAS DEL PROYECTO
   ===================================================================== */

-- 1. Mascotas mas atendidas en el mes y anio actuales
SELECT TOP (5)
       m.Nombre AS mascota,
       COUNT(c.ID_Mascota) AS veces_atendido
FROM   Mascota m
JOIN   Cita c ON m.ID_Mascota = c.ID_Mascota
WHERE  c.Fecha >= DATEFROMPARTS(YEAR(GETDATE()), MONTH(GETDATE()), 1)
  AND  c.Fecha <  DATEADD(MONTH, 1, DATEFROMPARTS(YEAR(GETDATE()), MONTH(GETDATE()), 1))
GROUP BY m.ID_Mascota, m.Nombre
ORDER BY COUNT(c.ID_Mascota) DESC;
GO

-- 2. Veterinarios ordenados segun el mayor numero de citas en el segundo trimestre del anio actual
SELECT v.Nombre AS veterinario,
       COUNT(c.ID_Cita) AS numero_citas
FROM   Veterinario v
JOIN   Cita c ON v.ID_Veterinario = c.ID_Veterinario
WHERE  c.Fecha >= DATEFROMPARTS(YEAR(GETDATE()), 4, 1)
  AND  c.Fecha <  DATEFROMPARTS(YEAR(GETDATE()), 7, 1)
GROUP BY v.ID_Veterinario, v.Nombre
ORDER BY numero_citas DESC;
GO

-- 3. Medicamentos prescritos con mayor frecuencia
SELECT TOP (3)
       i.Descripcion AS medicamento,
       COUNT(t.ID_Medicamento) AS veces_prescrito
FROM   Medicamento m
JOIN   Tratamiento t       ON m.ID_Medicamento = t.ID_Medicamento
JOIN   Item_Facturable i   ON m.ID_Medicamento = i.ID_Item
GROUP BY m.ID_Medicamento, i.Descripcion
ORDER BY veces_prescrito DESC;
GO

-- 4. Ingresos totales por especialidad veterinaria
SELECT e.Nombre AS especialidad,
       SUM(f.Monto) AS ingresos_totales
FROM   Especialidad e
JOIN   Veterinario_Especialidad ve ON e.ID_Especialidad = ve.ID_Especialidad
JOIN   Veterinario v               ON ve.ID_Veterinario = v.ID_Veterinario
JOIN   Cita c                      ON v.ID_Veterinario  = c.ID_Veterinario
JOIN   Factura f                   ON c.ID_Cita         = f.ID_Cita
GROUP BY e.ID_Especialidad, e.Nombre
ORDER BY ingresos_totales DESC;
GO

-- 5. Propietarios con mascotas que han asistido a citas en los ultimos 6 meses
SELECT DISTINCT
       p.Nombre AS propietario,
       m.Nombre AS mascota
FROM   Propietario p
JOIN   Mascota m ON p.ID_Propietario = m.ID_Propietario
JOIN   Cita c    ON m.ID_Mascota     = c.ID_Mascota
WHERE  c.Fecha >= DATEADD(MONTH, -6, CAST(GETDATE() AS DATE))
ORDER BY p.Nombre;
GO

-- 6. Propietarios con mas de una mascota
SELECT p.Nombre AS propietario,
       STRING_AGG(m.Nombre, ', ') WITHIN GROUP (ORDER BY m.Nombre) AS mascotas,
       COUNT(m.ID_Mascota) AS cantidad_mascotas
FROM   Propietario p
JOIN   Mascota m ON p.ID_Propietario = m.ID_Propietario
GROUP BY p.ID_Propietario, p.Nombre   -- se agrupa tambien por ID para no mezclar homonimos
HAVING COUNT(m.ID_Mascota) > 1
ORDER BY cantidad_mascotas DESC;
GO


/* =====================================================================
   B) CONSULTAS DE VERIFICACION / PRUEBA
   ===================================================================== */

-- Ver que los montos coincidan en las facturas
/*
SELECT f.Num_Factura,
       f.Monto AS monto_guardado,
       COALESCE(SUM(df.Precio_Unitario * df.Cantidad), 0) AS monto_calculado
FROM   Factura f
LEFT JOIN Detalle_Factura df ON f.Num_Factura = df.Num_Factura
GROUP BY f.Num_Factura, f.Monto
HAVING f.Monto <> COALESCE(SUM(df.Precio_Unitario * df.Cantidad), 0);
*/

-- Confirmar que los IDs de las facturas coincidan con los propietarios de las mascotas
SELECT f.Num_Factura,
       f.ID_Cita,
       c.ID_Mascota,
       m.ID_Propietario AS propietario_correcto,
       f.ID_Propietario AS propietario_en_factura
FROM   Factura f
JOIN   Cita c    ON f.ID_Cita    = c.ID_Cita
JOIN   Mascota m ON c.ID_Mascota = m.ID_Mascota
WHERE  f.ID_Propietario <> m.ID_Propietario;
GO

-- Revisar que todos los diagnosticos de los tratamientos existan
/*
SELECT *
FROM   Tratamiento t
LEFT JOIN Diagnostico d ON t.ID_Diagnostico = d.ID_Diagnostico
WHERE  d.ID_Diagnostico IS NULL;
*/

-- Revisar que todos los diagnosticos tengan procedimientos validos
/*
SELECT *
FROM   Diagnostico_Procedimiento dp
LEFT JOIN Procedimiento p ON dp.ID_Procedimiento = p.ID_Procedimiento
WHERE  p.ID_Procedimiento IS NULL;
*/

-- Verificar que los precios coincidan con el costo del item
/*
SELECT df.Num_Factura, df.ID_Item, df.Precio_Unitario, i.Costo
FROM   Detalle_Factura df
JOIN   Item_Facturable i ON df.ID_Item = i.ID_Item
WHERE  df.Precio_Unitario <> i.Costo;

SELECT ID_Item, Descripcion, Costo FROM Item_Facturable ORDER BY ID_Item;
SELECT ID_Item, Cantidad, Precio_Unitario, ID_Detalle FROM Detalle_Factura ORDER BY ID_Item;
*/

-- Revisar las facturas (detalle concatenado por factura)
/*
SELECT f.Num_Factura,
       f.Fecha,
       p.Nombre AS propietario,
       m.Nombre AS mascota,
       STRING_AGG(CONCAT(i.Descripcion, ' (x', df.Cantidad, ', $', df.Precio_Unitario, ')'), ' | ')
           WITHIN GROUP (ORDER BY df.ID_Detalle) AS detalles,
       f.Monto
FROM   Factura f
JOIN   Cita c               ON f.ID_Cita     = c.ID_Cita
JOIN   Mascota m            ON c.ID_Mascota  = m.ID_Mascota
JOIN   Propietario p        ON m.ID_Propietario = p.ID_Propietario
JOIN   Detalle_Factura df   ON f.Num_Factura = df.Num_Factura
JOIN   Item_Facturable i    ON df.ID_Item    = i.ID_Item
GROUP BY f.Num_Factura, f.Fecha, p.Nombre, m.Nombre, f.Monto
ORDER BY f.Num_Factura;
*/


/* =====================================================================
   C) CORRECCIONES DE DATOS (estaban en el archivo original de consultas)
   Se ejecutan una sola vez, despues de cargar el DML.
   ===================================================================== */

-- Actualizar ciertas facturas
UPDATE Factura SET ID_Propietario = 13 WHERE ID_Cita = 15;
UPDATE Factura SET ID_Propietario = 2  WHERE ID_Cita = 13;
UPDATE Factura SET ID_Propietario = 12 WHERE ID_Cita = 14;
GO

-- Esta da error a proposito: valida el trigger trg_seguridad_facturacion
-- (la cita 13 pertenece al propietario 2, no al 13)
-- UPDATE Factura SET ID_Propietario = 13 WHERE ID_Cita = 13;

-- Alinear precios del detalle con el costo del item
UPDATE Detalle_Factura SET Precio_Unitario = 12  WHERE ID_Item = 12;
UPDATE Detalle_Factura SET Precio_Unitario = 12  WHERE ID_Item = 1;
UPDATE Detalle_Factura SET Precio_Unitario = 15  WHERE ID_Item = 10;
UPDATE Detalle_Factura SET Precio_Unitario = 22  WHERE ID_Item = 11;
UPDATE Detalle_Factura SET Precio_Unitario = 18  WHERE ID_Item = 13;
UPDATE Detalle_Factura SET Precio_Unitario = 20  WHERE ID_Item = 15;
UPDATE Detalle_Factura SET Precio_Unitario = 9   WHERE ID_Item = 18;
UPDATE Detalle_Factura SET Precio_Unitario = 15  WHERE ID_Item = 22;
UPDATE Detalle_Factura SET Precio_Unitario = 350 WHERE ID_Item = 29;
UPDATE Detalle_Factura SET Precio_Unitario = 30  WHERE ID_Item = 33;
GO


/* =====================================================================
   D) PRUEBAS DE TRIGGERS
   Cada prueba va en su propio lote (GO): cuando un trigger lanza error,
   se aborta solo ese lote y se puede continuar con el siguiente.
   ===================================================================== */

-- ---------------------------------------------------------------
-- PROBAR trg_actualizar_monto_factura
-- ---------------------------------------------------------------
-- Monto actual de la Factura 1
SELECT Num_Factura, Monto FROM Factura WHERE Num_Factura = 1;
GO

-- Insertar un nuevo detalle de $50 (2 unidades a $25)
INSERT INTO Detalle_Factura (Precio_Unitario, Cantidad, Num_Factura, ID_Item)
VALUES (25.00, 2, 1, 1);
GO

-- Verificar que el monto de la Factura 1 sumo esos $50 exactos
SELECT Num_Factura, Monto FROM Factura WHERE Num_Factura = 1;
GO

-- Borrar el detalle que acabamos de meter: el monto vuelve a bajar
DELETE FROM Detalle_Factura WHERE ID_Item = 1 AND Cantidad = 2 AND Num_Factura = 1;
GO

SELECT Num_Factura, Monto FROM Factura WHERE Num_Factura = 1;
GO


-- ---------------------------------------------------------------
-- PROBAR trg_verificar_alergia_medicamento
-- ---------------------------------------------------------------
-- Agregar 'Perro' a las precauciones del medicamento 12
UPDATE Medicamento
SET    Precauciones = 'Totalmente contraindicado para Perro'
WHERE  ID_Medicamento = 12;
GO

-- Intentar recetarlo al diagnostico 1 (pertenece al perro Max) -> DEBE DAR ERROR 50001
INSERT INTO Tratamiento (Frecuencia, Dosis, Vigencia, Descripcion, ID_Diagnostico, ID_Medicamento)
VALUES ('Cada 8 horas', '1 pastilla', '2026-12-31', 'Prueba de bloqueo por alergia', 1, 12);
GO

-- Revertir cambios
UPDATE Medicamento
SET    Precauciones = 'No administrar a animales con historial de alergia a la penicilina.'
WHERE  ID_Medicamento = 12;
GO


-- ---------------------------------------------------------------
-- PROBAR trg_actualizar_inventario
-- ---------------------------------------------------------------
-- Stock actual del medicamento 13
SELECT ID_Medicamento, Stock FROM Medicamento WHERE ID_Medicamento = 13;
GO

-- Escenario A: compra exitosa (descuenta 5 unidades)
INSERT INTO Detalle_Factura (Precio_Unitario, Cantidad, Num_Factura, ID_Item)
VALUES (15.00, 5, 1, 13);
GO

-- Comprobar que el stock bajo
SELECT ID_Medicamento, Stock FROM Medicamento WHERE ID_Medicamento = 13;
GO

-- Escenario B: intento de compra masiva sin stock -> DEBE DAR ERROR 50002
INSERT INTO Detalle_Factura (Precio_Unitario, Cantidad, Num_Factura, ID_Item)
VALUES (15.00, 5000, 1, 13);
GO


-- ---------------------------------------------------------------
-- PROBAR trg_actualizacion_citas
-- ---------------------------------------------------------------
-- Insertar una cita con fecha pasada pero con estado 'Programada'
INSERT INTO Cita (Fecha, Hora, Consultorio, Estado, ID_Mascota, ID_Veterinario)
VALUES ('2023-01-01', '10:00:00', 'Consultorio X', 'Programada', 1, 1);
GO

-- Verificar que el trigger la dejo como 'Cancelada'
SELECT TOP (1) ID_Cita, Fecha, Estado
FROM   Cita
ORDER BY ID_Cita DESC;
GO


-- ---------------------------------------------------------------
-- PROBAR trg_seguridad_facturacion
-- ---------------------------------------------------------------
-- La cita 11 es de la mascota 11 (Copito), cuyo duenio es el propietario 10 y
-- todavia no tiene factura. Intentar facturarla al propietario 99 -> DEBE DAR ERROR 50003.
-- (En la version Postgres se usaba la cita 1; aqui se usa una cita sin factura porque en
--  SQL Server la restriccion UNIQUE(ID_Cita) se evalua antes que el trigger AFTER.)
INSERT INTO Factura (Fecha, Monto, ID_Cita, ID_Propietario)
VALUES ('2026-06-19', 0, 11, 99);
GO


-- ---------------------------------------------------------------
-- PROBAR trg_procesar_pago_estado
-- ---------------------------------------------------------------
DECLARE @hoy DATE = CAST(GETDATE() AS DATE);

-- Crear una cita nueva (a futuro, para que no sea cancelada por vencida)
INSERT INTO Cita (Fecha, Hora, Consultorio, Estado, ID_Mascota, ID_Veterinario)
VALUES (DATEADD(DAY, 7, @hoy), '12:00:00', 'Consultorio B', 'Programada', 1, 1);

-- Crear su factura correspondiente (monto inicia en 0)
INSERT INTO Factura (Fecha, Monto, ID_Cita, ID_Propietario)
VALUES (@hoy, 0, (SELECT MAX(ID_Cita) FROM Cita), 1);

-- Cargarle una "Esterilizacion felina" que cuesta $160
INSERT INTO Detalle_Factura (Precio_Unitario, Cantidad, Num_Factura, ID_Item)
VALUES (160.00, 1, (SELECT MAX(Num_Factura) FROM Factura), 24);

-- El cliente pasa a caja pero solo abona $50 en efectivo
INSERT INTO Pago (Monto, Metodo_Pago, Num_Factura)
VALUES (50.00, 'Efectivo', (SELECT MAX(Num_Factura) FROM Factura));
GO

-- Resultado esperado: Estado_Pago = 'Parcial' y estado de la cita = 'Completada'
SELECT f.Num_Factura,
       f.Monto AS total_a_pagar,
       SUM(p.Monto) AS total_abonado,
       f.Estado_Pago,
       c.Estado AS estado_cita
FROM   Factura f
LEFT JOIN Pago p ON f.Num_Factura = p.Num_Factura
JOIN   Cita c    ON f.ID_Cita     = c.ID_Cita
WHERE  f.Num_Factura = (SELECT MAX(Num_Factura) FROM Factura)
GROUP BY f.Num_Factura, f.Monto, f.Estado_Pago, c.Estado;
GO


-- ---------------------------------------------------------------
-- PROBAR trg_validar_sobrepago (continua con la factura de la prueba anterior:
-- total $160, abonados $50)
-- ---------------------------------------------------------------
-- Intentar abonar $200 -> DEBE DAR ERROR 50004 (50 + 200 > 160)
INSERT INTO Pago (Monto, Metodo_Pago, Num_Factura)
VALUES (200.00, 'Tarjeta', (SELECT MAX(Num_Factura) FROM Factura));
GO

-- Segundo abono valido de $60 -> sigue 'Parcial' (110 de 160)
INSERT INTO Pago (Monto, Metodo_Pago, Num_Factura)
VALUES (60.00, 'Transferencia', (SELECT MAX(Num_Factura) FROM Factura));
GO

-- Estado de cuenta: abonado 110, saldo pendiente 50, 2 abonos
SELECT * FROM dbo.vw_estado_cuenta_factura
WHERE  Num_Factura = (SELECT MAX(Num_Factura) FROM Factura);
GO

-- Historial de abonos con acumulado y saldo despues de cada uno
SELECT * FROM dbo.vw_historial_abonos
WHERE  Num_Factura = (SELECT MAX(Num_Factura) FROM Factura)
ORDER BY Fecha_Pago, ID_Pago;
GO

-- Abono final de $50 -> la factura pasa a 'Pagado'
INSERT INTO Pago (Monto, Metodo_Pago, Num_Factura)
VALUES (50.00, 'Efectivo', (SELECT MAX(Num_Factura) FROM Factura));
GO

SELECT * FROM dbo.vw_estado_cuenta_factura
WHERE  Num_Factura = (SELECT MAX(Num_Factura) FROM Factura);
GO


-- ---------------------------------------------------------------
-- PROBAR el procedimiento almacenado
-- ---------------------------------------------------------------
EXEC dbo.citas_completadas_portiempo_vencido;
GO