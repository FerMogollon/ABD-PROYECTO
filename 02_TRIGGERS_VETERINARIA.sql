/* =====================================================================
   VETERINARIA - TRIGGERS (SQL Server 2025)
   Migrado desde PostgreSQL (PL/pgSQL).

   Diferencias clave respecto a PostgreSQL:
   - No existe BEFORE ni FOR EACH ROW. Los triggers se ejecutan UNA vez por
     sentencia (pueden afectar muchas filas) y leen las tablas virtuales
     "inserted" y "deleted". Por eso todo se escribe con logica de conjuntos.
   - Los triggers "BEFORE" de validacion pasan a ser AFTER: validan y, si hay
     error, hacen ROLLBACK TRANSACTION + THROW para deshacer la operacion.
   - RAISE EXCEPTION -> THROW (numero de error >= 50000).
   - No hay funcion separada: el cuerpo va dentro del propio trigger.
   ===================================================================== */

USE Veterinaria;
GO

/* ---------------------------------------------------------------------
   1) Recalcular el monto de la factura al cambiar su detalle
   --------------------------------------------------------------------- */
CREATE OR ALTER TRIGGER facturacion.trg_actualizar_monto_factura
ON facturacion.Detalle_Factura
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;

    -- Facturas afectadas: las de las filas nuevas/modificadas y las de las borradas
    UPDATE f
    SET    f.Monto = ISNULL((SELECT SUM(d.Precio_Unitario * d.Cantidad)
                             FROM   facturacion.Detalle_Factura d
                             WHERE  d.Num_Factura = f.Num_Factura), 0)
    FROM   facturacion.Factura f
    WHERE  f.Num_Factura IN (SELECT Num_Factura FROM inserted
                             UNION
                             SELECT Num_Factura FROM deleted);
END;
GO

/* ---------------------------------------------------------------------
   2) Bloquear medicamentos cuyas precauciones mencionan la especie
   --------------------------------------------------------------------- */
CREATE OR ALTER TRIGGER clinica.trg_verificar_alergia_medicamento
ON clinica.Tratamiento
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @msg NVARCHAR(2000);

    SELECT TOP (1)
           @msg = CONCAT(
               'ALERTA VETERINARIA: La mascota "', m.Nombre, '" es de especie "', m.Especie,
               '". El medicamento "', it.Descripcion, '" indica contraindicacion/alergia: "',
               med.Precauciones, '". Registro denegado.')
    FROM   inserted i
    JOIN   clinica.Diagnostico d       ON d.ID_Diagnostico = i.ID_Diagnostico
    JOIN   clinica.Cita c              ON c.ID_Cita        = d.ID_Cita
    JOIN   clientes.Mascota m           ON m.ID_Mascota     = c.ID_Mascota
    JOIN   catalogo.Medicamento med     ON med.ID_Medicamento = i.ID_Medicamento
    JOIN   catalogo.Item_Facturable it  ON it.ID_Item       = med.ID_Medicamento
    -- CHARINDEX evita problemas con comodines; el COLLATE replica el ILIKE de Postgres
    WHERE  CHARINDEX(m.Especie COLLATE Latin1_General_CI_AS,
                     med.Precauciones COLLATE Latin1_General_CI_AS) > 0;

    IF @msg IS NOT NULL
    BEGIN
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW 50001, @msg, 1;
    END
END;
GO

/* ---------------------------------------------------------------------
   3) Verificar stock y descontar inventario al facturar un medicamento
      (si el item es un procedimiento, no hay fila en Medicamento y no
       se toca el inventario)
   --------------------------------------------------------------------- */
CREATE OR ALTER TRIGGER facturacion.trg_actualizar_inventario
ON facturacion.Detalle_Factura
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;

    -- Total solicitado por medicamento (un INSERT puede traer varias filas del mismo item)
    DECLARE @solicitado TABLE (ID_Item BIGINT PRIMARY KEY, Cantidad BIGINT NOT NULL);

    INSERT INTO @solicitado (ID_Item, Cantidad)
    SELECT i.ID_Item, SUM(i.Cantidad)
    FROM   inserted i
    JOIN   catalogo.Medicamento med ON med.ID_Medicamento = i.ID_Item
    GROUP BY i.ID_Item;

    -- Validar disponibilidad
    DECLARE @msg NVARCHAR(2000);

    SELECT TOP (1)
           @msg = CONCAT('Inventario insuficiente para el medicamento ID: ', s.ID_Item,
                         '. Disponible: ', med.Stock, ', Solicitado: ', s.Cantidad)
    FROM   @solicitado s
    JOIN   catalogo.Medicamento med ON med.ID_Medicamento = s.ID_Item
    WHERE  med.Stock < s.Cantidad;

    IF @msg IS NOT NULL
    BEGIN
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW 50002, @msg, 1;
    END

    -- Descontar existencias
    UPDATE med
    SET    med.Stock = med.Stock - s.Cantidad
    FROM   catalogo.Medicamento med
    JOIN   @solicitado s ON s.ID_Item = med.ID_Medicamento;
END;
GO

/* ---------------------------------------------------------------------
   4) Cancelar automaticamente citas con fecha pasada que no esten en
      estado terminal (Cancelada / Completada)
   --------------------------------------------------------------------- */
CREATE OR ALTER TRIGGER clinica.trg_actualizacion_citas
ON clinica.Cita
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE c
    SET    c.Estado = 'Cancelada'
    FROM   clinica.Cita c
    JOIN   inserted i ON i.ID_Cita = c.ID_Cita
    WHERE  i.Estado NOT IN ('Cancelada', 'Completada')
      AND  i.Fecha < CAST(GETDATE() AS DATE);
END;
GO

/* ---------------------------------------------------------------------
   5) Procedimiento: cancelar en bloque las citas vencidas
      (en Postgres era PROCEDURE; se ejecuta con EXEC)
   --------------------------------------------------------------------- */
CREATE OR ALTER PROCEDURE clinica.citas_completadas_portiempo_vencido
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE clinica.Cita
    SET    Estado = 'Cancelada'
    WHERE  Fecha < CAST(GETDATE() AS DATE)
      AND  Estado NOT IN ('Completada', 'Cancelada');
END;
GO

/* ---------------------------------------------------------------------
   6) Validar que la factura se emita al duenio real de la mascota
   --------------------------------------------------------------------- */
CREATE OR ALTER TRIGGER facturacion.trg_seguridad_facturacion
ON facturacion.Factura
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    -- Si es un UPDATE que no toca estas columnas, no hay nada que validar
    IF NOT (UPDATE(ID_Cita) OR UPDATE(ID_Propietario))
        RETURN;

    DECLARE @msg NVARCHAR(2000);

    SELECT TOP (1)
           @msg = CONCAT(
               'VIOLACION DE LOGICA DE NEGOCIO: Intento de fraude o error. El cliente (ID: ',
               i.ID_Propietario, ') no es el duenio de la mascota de la cita ', i.ID_Cita,
               '. El duenio legitimo es el cliente (ID: ', m.ID_Propietario, ').')
    FROM   inserted i
    JOIN   clinica.Cita c    ON c.ID_Cita    = i.ID_Cita
    JOIN   clientes.Mascota m ON m.ID_Mascota = c.ID_Mascota
    WHERE  i.ID_Propietario <> m.ID_Propietario;

    IF @msg IS NOT NULL
    BEGIN
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW 50003, @msg, 1;
    END
END;
GO

/* ---------------------------------------------------------------------
   7) Al registrar un pago: calcular saldo (Parcial / Pagado) y marcar
      la cita como Completada
   --------------------------------------------------------------------- */
CREATE OR ALTER TRIGGER facturacion.trg_procesar_pago_estado
ON facturacion.Pago
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;

    -- Estado financiero de las facturas que recibieron pagos
    UPDATE f
    SET    f.Estado_Pago = CASE WHEN t.Total_Pagado >= f.Monto THEN 'Pagado' ELSE 'Parcial' END
    FROM   facturacion.Factura f
    JOIN  (SELECT p.Num_Factura, SUM(p.Monto) AS Total_Pagado
           FROM   facturacion.Pago p
           WHERE  p.Num_Factura IN (SELECT Num_Factura FROM inserted)
           GROUP BY p.Num_Factura) t
           ON t.Num_Factura = f.Num_Factura;

    -- Dar por finalizada la atencion medica
    UPDATE c
    SET    c.Estado = 'Completada'
    FROM   clinica.Cita c
    JOIN   facturacion.Factura f ON f.ID_Cita = c.ID_Cita
    WHERE  f.Num_Factura IN (SELECT Num_Factura FROM inserted)
      AND  c.Estado <> 'Completada';
END;
GO

/* ---------------------------------------------------------------------
   8) NUEVO: impedir sobrepagos. La suma de los abonos de una factura
      nunca puede superar el monto de la factura.
      (Cada abono queda guardado como una fila en Pago, aunque la factura
       siga en estado Parcial; ver las vistas de abajo.)
   --------------------------------------------------------------------- */
CREATE OR ALTER TRIGGER facturacion.trg_validar_sobrepago
ON facturacion.Pago
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT (UPDATE(Monto) OR UPDATE(Num_Factura))
        RETURN;

    DECLARE @msg NVARCHAR(2000);

    -- UPDLOCK/HOLDLOCK: evita que dos pagos simultaneos pasen la validacion a la vez
    SELECT TOP (1)
           @msg = CONCAT('PAGO RECHAZADO: La factura ', f.Num_Factura, ' es por $', f.Monto,
                         ' y con este pago el total abonado seria $', t.Total_Pagado,
                         ' (excede por $', t.Total_Pagado - f.Monto, ').')
    FROM   facturacion.Factura AS f WITH (UPDLOCK, HOLDLOCK)
    JOIN  (SELECT p.Num_Factura, SUM(p.Monto) AS Total_Pagado
           FROM   facturacion.Pago p
           WHERE  p.Num_Factura IN (SELECT Num_Factura FROM inserted)
           GROUP BY p.Num_Factura) t
           ON t.Num_Factura = f.Num_Factura
    WHERE  t.Total_Pagado > f.Monto;

    IF @msg IS NOT NULL
    BEGIN
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW 50004, @msg, 1;
    END
END;
GO

/* ---------------------------------------------------------------------
   9) NUEVO: vistas para consultar abonos y saldos
   --------------------------------------------------------------------- */
-- Estado de cuenta: una fila por factura
CREATE OR ALTER VIEW facturacion.vw_estado_cuenta_factura
AS
SELECT f.Num_Factura,
       f.ID_Cita,
       f.ID_Propietario,
       f.Monto                                  AS Total_Factura,
       ISNULL(SUM(p.Monto), 0)                  AS Total_Abonado,
       f.Monto - ISNULL(SUM(p.Monto), 0)        AS Saldo_Pendiente,
       COUNT(p.ID_Pago)                         AS Num_Abonos,
       f.Estado_Pago
FROM   facturacion.Factura f
LEFT JOIN facturacion.Pago p ON p.Num_Factura = f.Num_Factura
GROUP BY f.Num_Factura, f.ID_Cita, f.ID_Propietario, f.Monto, f.Estado_Pago;
GO

-- Historial de abonos: una fila por pago, con acumulado y saldo despues de cada abono
CREATE OR ALTER VIEW facturacion.vw_historial_abonos
AS
SELECT p.Num_Factura,
       pr.Nombre                                                AS Propietario,
       p.ID_Pago,
       p.Fecha_Pago,
       p.Metodo_Pago,
       p.Monto                                                  AS Abono,
       SUM(p.Monto) OVER (PARTITION BY p.Num_Factura
                          ORDER BY p.Fecha_Pago, p.ID_Pago
                          ROWS UNBOUNDED PRECEDING)             AS Acumulado,
       f.Monto - SUM(p.Monto) OVER (PARTITION BY p.Num_Factura
                          ORDER BY p.Fecha_Pago, p.ID_Pago
                          ROWS UNBOUNDED PRECEDING)             AS Saldo_Despues
FROM   facturacion.Pago p
JOIN   facturacion.Factura f      ON f.Num_Factura    = p.Num_Factura
JOIN   clientes.Propietario pr ON pr.ID_Propietario = f.ID_Propietario;
GO