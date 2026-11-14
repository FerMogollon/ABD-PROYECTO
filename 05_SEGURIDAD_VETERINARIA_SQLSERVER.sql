/* =====================================================================
   VETERINARIA - SEGURIDAD (SQL Server 2025)
   Ejecutar DESPUES de 01_DDL, 02_TRIGGERS, 03_DML y 04_CONSULTAS.
   Requisitos:
     - Servidor en modo de autenticacion mixta (SQL Server + Windows).
     - Ejecutar con un login sysadmin.
     - La auditoria se guarda en la carpeta Log de la instancia (el servicio de SQL Server
       ya tiene permiso de escritura ahi, no hay que crear ni configurar carpetas).

   POLITICAS DE SEGURIDAD IMPLEMENTADAS
   P1. Minimo privilegio: los permisos se dan a ROLES (nunca a usuarios) y solo
       sobre lo necesario. Ninguna aplicacion usa sa ni un login con privilegios altos.
   P2. Separacion de funciones: quien factura no receta, quien receta no maneja
       inventario, quien audita no modifica datos.
   P3. Autenticacion: un login por persona/funcion con contrasena compleja y
       expiracion (CHECK_POLICY / CHECK_EXPIRATION). sa se deshabilita.
   P4. Proteccion de datos personales: DUI, correo y telefono se enmascaran
       (Dynamic Data Masking); solo recepcion y DBA ven los datos reales.
       El analista de Power BI solo accede a vistas sin datos personales.
   P5. Integridad financiera: nadie puede borrar facturas, detalles ni pagos.
   P6. Auditoria: SQL Server Audit (accesos fallidos, cambios de permisos/estructura,
       DML sobre tablas sensibles) + bitacora con valores anteriores y nuevos
       en Factura, Pago y Medicamento. Solo el auditor lee la bitacora.
   P7. Respaldo: solo el rol de backup puede respaldar la base.

   ORGANIZACION EN ESQUEMAS (ver 01_DDL): clientes, clinica, catalogo,
   facturacion, reportes y auditoria. Cada esquema agrupa objetos con el mismo nivel
   de sensibilidad, asi los permisos se otorgan por esquema y el mantenimiento es simple.
   Como todos pertenecen a dbo, funciona el "ownership chaining": los triggers y las
   vistas acceden a otras tablas sin que el usuario necesite permiso directo sobre ellas
   (ej. caja inserta un pago y el trigger actualiza la cita aunque caja no pueda tocar Cita).
   ===================================================================== */


/* =====================================================================
   1) LOGINS (nivel servidor)
   Las contrasenas son de EJEMPLO: cambiarlas antes de entregar/usar.
   ===================================================================== */
USE master;
GO

IF SUSER_ID(N'lg_dba')         IS NULL CREATE LOGIN lg_dba         WITH PASSWORD = N'Vet#Dba2026!Secure',     CHECK_POLICY = ON, CHECK_EXPIRATION = ON, DEFAULT_DATABASE = Veterinaria;
IF SUSER_ID(N'lg_recepcion')   IS NULL CREATE LOGIN lg_recepcion   WITH PASSWORD = N'Vet#Recepcion2026!',     CHECK_POLICY = ON, CHECK_EXPIRATION = ON, DEFAULT_DATABASE = Veterinaria;
IF SUSER_ID(N'lg_veterinario') IS NULL CREATE LOGIN lg_veterinario WITH PASSWORD = N'Vet#Veterinario2026!',   CHECK_POLICY = ON, CHECK_EXPIRATION = ON, DEFAULT_DATABASE = Veterinaria;
IF SUSER_ID(N'lg_caja')        IS NULL CREATE LOGIN lg_caja        WITH PASSWORD = N'Vet#Caja2026!Secure',    CHECK_POLICY = ON, CHECK_EXPIRATION = ON, DEFAULT_DATABASE = Veterinaria;
IF SUSER_ID(N'lg_farmacia')    IS NULL CREATE LOGIN lg_farmacia    WITH PASSWORD = N'Vet#Farmacia2026!',      CHECK_POLICY = ON, CHECK_EXPIRATION = ON, DEFAULT_DATABASE = Veterinaria;
IF SUSER_ID(N'lg_bi')          IS NULL CREATE LOGIN lg_bi          WITH PASSWORD = N'Vet#PowerBI2026!Secure', CHECK_POLICY = ON, CHECK_EXPIRATION = ON, DEFAULT_DATABASE = Veterinaria;
IF SUSER_ID(N'lg_auditor')     IS NULL CREATE LOGIN lg_auditor     WITH PASSWORD = N'Vet#Auditor2026!Secure', CHECK_POLICY = ON, CHECK_EXPIRATION = ON, DEFAULT_DATABASE = Veterinaria;
IF SUSER_ID(N'lg_backup')      IS NULL CREATE LOGIN lg_backup      WITH PASSWORD = N'Vet#Backup2026!Secure',  CHECK_POLICY = ON, CHECK_EXPIRATION = ON, DEFAULT_DATABASE = Veterinaria;
GO

-- P3: deshabilitar sa. DESCOMENTAR solo si NO estas conectado como sa (te quedarias sin acceso).
-- ALTER LOGIN sa DISABLE;
GO


/* =====================================================================
   2) ROLES, USUARIOS Y PERMISOS (nivel base de datos)
   ===================================================================== */
USE Veterinaria;
GO

-- 2.1 Roles por funcion
IF DATABASE_PRINCIPAL_ID(N'rol_dba')          IS NULL CREATE ROLE rol_dba;
IF DATABASE_PRINCIPAL_ID(N'rol_recepcion')    IS NULL CREATE ROLE rol_recepcion;
IF DATABASE_PRINCIPAL_ID(N'rol_veterinario')  IS NULL CREATE ROLE rol_veterinario;
IF DATABASE_PRINCIPAL_ID(N'rol_caja')         IS NULL CREATE ROLE rol_caja;
IF DATABASE_PRINCIPAL_ID(N'rol_farmacia')     IS NULL CREATE ROLE rol_farmacia;
IF DATABASE_PRINCIPAL_ID(N'rol_analista_bi')  IS NULL CREATE ROLE rol_analista_bi;
IF DATABASE_PRINCIPAL_ID(N'rol_auditor')      IS NULL CREATE ROLE rol_auditor;
IF DATABASE_PRINCIPAL_ID(N'rol_backup')       IS NULL CREATE ROLE rol_backup;
GO

-- 2.2 Usuarios de base de datos (esquema por defecto segun su funcion)
IF DATABASE_PRINCIPAL_ID(N'usr_dba')         IS NULL CREATE USER usr_dba         FOR LOGIN lg_dba         WITH DEFAULT_SCHEMA = dbo;
IF DATABASE_PRINCIPAL_ID(N'usr_recepcion')   IS NULL CREATE USER usr_recepcion   FOR LOGIN lg_recepcion   WITH DEFAULT_SCHEMA = clientes;
IF DATABASE_PRINCIPAL_ID(N'usr_veterinario') IS NULL CREATE USER usr_veterinario FOR LOGIN lg_veterinario WITH DEFAULT_SCHEMA = clinica;
IF DATABASE_PRINCIPAL_ID(N'usr_caja')        IS NULL CREATE USER usr_caja        FOR LOGIN lg_caja        WITH DEFAULT_SCHEMA = facturacion;
IF DATABASE_PRINCIPAL_ID(N'usr_farmacia')    IS NULL CREATE USER usr_farmacia    FOR LOGIN lg_farmacia    WITH DEFAULT_SCHEMA = catalogo;
IF DATABASE_PRINCIPAL_ID(N'usr_bi')          IS NULL CREATE USER usr_bi          FOR LOGIN lg_bi          WITH DEFAULT_SCHEMA = reportes;
IF DATABASE_PRINCIPAL_ID(N'usr_auditor')     IS NULL CREATE USER usr_auditor     FOR LOGIN lg_auditor     WITH DEFAULT_SCHEMA = auditoria;
IF DATABASE_PRINCIPAL_ID(N'usr_backup')      IS NULL CREATE USER usr_backup      FOR LOGIN lg_backup      WITH DEFAULT_SCHEMA = dbo;
GO

-- 2.3 Usuario -> rol
ALTER ROLE rol_dba         ADD MEMBER usr_dba;
ALTER ROLE rol_recepcion   ADD MEMBER usr_recepcion;
ALTER ROLE rol_veterinario ADD MEMBER usr_veterinario;
ALTER ROLE rol_caja        ADD MEMBER usr_caja;
ALTER ROLE rol_farmacia    ADD MEMBER usr_farmacia;
ALTER ROLE rol_analista_bi ADD MEMBER usr_bi;
ALTER ROLE rol_auditor     ADD MEMBER usr_auditor;
ALTER ROLE rol_backup      ADD MEMBER usr_backup;
GO

/* 2.4 Permisos por rol (lo que no se otorga queda denegado por defecto) */

-- rol_dba: control total de la base
GRANT CONTROL ON DATABASE::Veterinaria TO rol_dba;

-- rol_recepcion: gestiona clientes y agenda; ve datos reales (UNMASK); sin diagnosticos ni dinero
GRANT SELECT, INSERT, UPDATE ON SCHEMA::clientes     TO rol_recepcion;
GRANT SELECT, INSERT, UPDATE ON OBJECT::clinica.Cita TO rol_recepcion;
GRANT SELECT ON OBJECT::clinica.Veterinario          TO rol_recepcion;
GRANT UNMASK TO rol_recepcion;
DENY  SELECT, INSERT, UPDATE, DELETE ON SCHEMA::facturacion    TO rol_recepcion;
DENY  SELECT, INSERT, UPDATE, DELETE ON OBJECT::clinica.Diagnostico TO rol_recepcion;
DENY  SELECT, INSERT, UPDATE, DELETE ON OBJECT::clinica.Tratamiento TO rol_recepcion;

-- rol_veterinario: historia clinica; lee clientes (DUI/correo/telefono enmascarados) y catalogo
GRANT SELECT ON SCHEMA::clinica   TO rol_veterinario;
GRANT SELECT ON SCHEMA::clientes  TO rol_veterinario;
GRANT SELECT ON SCHEMA::catalogo  TO rol_veterinario;
GRANT INSERT, UPDATE ON OBJECT::clinica.Diagnostico              TO rol_veterinario;
GRANT INSERT, UPDATE ON OBJECT::clinica.Tratamiento              TO rol_veterinario;
GRANT INSERT, UPDATE ON OBJECT::clinica.Diagnostico_Procedimiento TO rol_veterinario;
DENY  SELECT, INSERT, UPDATE, DELETE ON SCHEMA::facturacion      TO rol_veterinario;

-- rol_caja: lee e inserta en facturacion; NUNCA borra (P5). Lee datos de apoyo (enmascarados)
GRANT SELECT, INSERT ON SCHEMA::facturacion               TO rol_caja;
GRANT SELECT ON OBJECT::clinica.Cita                      TO rol_caja;
GRANT SELECT ON OBJECT::clientes.Propietario              TO rol_caja;
GRANT SELECT ON OBJECT::clientes.Mascota                  TO rol_caja;
GRANT SELECT ON OBJECT::catalogo.Item_Facturable          TO rol_caja;
DENY  DELETE ON SCHEMA::facturacion                       TO rol_caja;

-- rol_farmacia: ve el catalogo y solo puede modificar la columna Stock de Medicamento
GRANT SELECT ON SCHEMA::catalogo                          TO rol_farmacia;
GRANT UPDATE (Stock) ON OBJECT::catalogo.Medicamento      TO rol_farmacia;

-- rol_analista_bi: solo lectura de las vistas de reportes (sin datos personales)
GRANT SELECT ON SCHEMA::reportes                          TO rol_analista_bi;

-- rol_auditor: solo lectura de la bitacora
GRANT SELECT ON SCHEMA::auditoria                         TO rol_auditor;

-- rol_backup: solo respaldos (rol fijo db_backupoperator)
ALTER ROLE db_backupoperator ADD MEMBER rol_backup;
GO


/* =====================================================================
   3) VISTAS PARA POWER BI (esquema reportes, sin datos personales)
   ===================================================================== */
CREATE OR ALTER VIEW reportes.vw_bi_citas
AS
SELECT c.ID_Cita, c.Fecha, c.Hora, c.Estado AS Estado_Cita, c.Consultorio,
       v.Nombre AS Veterinario, m.Especie, m.Raza
FROM   clinica.Cita c
JOIN   clinica.Veterinario v ON v.ID_Veterinario = c.ID_Veterinario
JOIN   clientes.Mascota m    ON m.ID_Mascota     = c.ID_Mascota;
GO

CREATE OR ALTER VIEW reportes.vw_bi_facturacion
AS
SELECT f.Num_Factura, f.Fecha, f.Monto AS Total_Factura, f.Estado_Pago,
       ISNULL(p.Total_Abonado, 0)             AS Total_Abonado,
       f.Monto - ISNULL(p.Total_Abonado, 0)   AS Saldo_Pendiente
FROM   facturacion.Factura f
LEFT JOIN (SELECT Num_Factura, SUM(Monto) AS Total_Abonado
           FROM   facturacion.Pago
           GROUP BY Num_Factura) p ON p.Num_Factura = f.Num_Factura;
GO

CREATE OR ALTER VIEW reportes.vw_bi_pagos
AS
SELECT p.ID_Pago, p.Fecha_Pago, p.Metodo_Pago, p.Monto
FROM   facturacion.Pago p;
GO

CREATE OR ALTER VIEW reportes.vw_bi_medicamentos
AS
SELECT it.Descripcion AS Medicamento, med.Stock,
       COUNT(t.ID_Tratamiento) AS Veces_Prescrito
FROM   catalogo.Medicamento med
JOIN   catalogo.Item_Facturable it ON it.ID_Item = med.ID_Medicamento
LEFT JOIN clinica.Tratamiento t    ON t.ID_Medicamento = med.ID_Medicamento
GROUP BY it.Descripcion, med.Stock;
GO


/* =====================================================================
   4) BITACORA DE CAMBIOS (valores anteriores y nuevos)
   Complementa a SQL Server Audit: Audit dice QUIEN y CUANDO; la bitacora
   guarda el valor antes/despues de las tablas financieras y de inventario.
   Los triggers escriben en la bitacora por ownership chaining: nadie mas
   que el DBA puede modificarla y el auditor solo la lee.
   ===================================================================== */
IF OBJECT_ID(N'auditoria.Bitacora', N'U') IS NULL
CREATE TABLE auditoria.Bitacora (
    ID_Bitacora      BIGINT IDENTITY(1,1) NOT NULL,
    Fecha            DATETIME2(0)  NOT NULL CONSTRAINT df_bitacora_fecha DEFAULT SYSDATETIME(),
    Tabla            SYSNAME       NOT NULL,
    Operacion        CHAR(1)       NOT NULL,
    Llave            VARCHAR(100)  NOT NULL,
    Usuario          SYSNAME       NOT NULL CONSTRAINT df_bitacora_usuario DEFAULT ORIGINAL_LOGIN(),
    Host             NVARCHAR(128) NULL     CONSTRAINT df_bitacora_host DEFAULT HOST_NAME(),
    Aplicacion       NVARCHAR(128) NULL     CONSTRAINT df_bitacora_app DEFAULT APP_NAME(),
    Datos_Anteriores NVARCHAR(MAX) NULL,
    Datos_Nuevos     NVARCHAR(MAX) NULL,
    CONSTRAINT pk_bitacora PRIMARY KEY (ID_Bitacora),
    CONSTRAINT ck_bitacora_operacion CHECK (Operacion IN ('I', 'U', 'D'))
);
GO

CREATE OR ALTER TRIGGER facturacion.trg_aud_factura
ON facturacion.Factura
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;
    INSERT INTO auditoria.Bitacora (Tabla, Operacion, Llave, Datos_Anteriores, Datos_Nuevos)
    SELECT 'facturacion.Factura',
           CASE WHEN i.Num_Factura IS NULL THEN 'D' WHEN d.Num_Factura IS NULL THEN 'I' ELSE 'U' END,
           CAST(COALESCE(i.Num_Factura, d.Num_Factura) AS VARCHAR(100)),
           CASE WHEN d.Num_Factura IS NULL THEN NULL ELSE
                (SELECT d2.* FROM deleted d2 WHERE d2.Num_Factura = d.Num_Factura
                 FOR JSON PATH, WITHOUT_ARRAY_WRAPPER) END,
           CASE WHEN i.Num_Factura IS NULL THEN NULL ELSE
                (SELECT i2.* FROM inserted i2 WHERE i2.Num_Factura = i.Num_Factura
                 FOR JSON PATH, WITHOUT_ARRAY_WRAPPER) END
    FROM   inserted i
    FULL OUTER JOIN deleted d ON d.Num_Factura = i.Num_Factura;
END;
GO

CREATE OR ALTER TRIGGER facturacion.trg_aud_pago
ON facturacion.Pago
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;
    INSERT INTO auditoria.Bitacora (Tabla, Operacion, Llave, Datos_Anteriores, Datos_Nuevos)
    SELECT 'facturacion.Pago',
           CASE WHEN i.ID_Pago IS NULL THEN 'D' WHEN d.ID_Pago IS NULL THEN 'I' ELSE 'U' END,
           CAST(COALESCE(i.ID_Pago, d.ID_Pago) AS VARCHAR(100)),
           CASE WHEN d.ID_Pago IS NULL THEN NULL ELSE
                (SELECT d2.* FROM deleted d2 WHERE d2.ID_Pago = d.ID_Pago
                 FOR JSON PATH, WITHOUT_ARRAY_WRAPPER) END,
           CASE WHEN i.ID_Pago IS NULL THEN NULL ELSE
                (SELECT i2.* FROM inserted i2 WHERE i2.ID_Pago = i.ID_Pago
                 FOR JSON PATH, WITHOUT_ARRAY_WRAPPER) END
    FROM   inserted i
    FULL OUTER JOIN deleted d ON d.ID_Pago = i.ID_Pago;
END;
GO

CREATE OR ALTER TRIGGER catalogo.trg_aud_medicamento
ON catalogo.Medicamento
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;
    INSERT INTO auditoria.Bitacora (Tabla, Operacion, Llave, Datos_Anteriores, Datos_Nuevos)
    SELECT 'catalogo.Medicamento',
           CASE WHEN i.ID_Medicamento IS NULL THEN 'D' WHEN d.ID_Medicamento IS NULL THEN 'I' ELSE 'U' END,
           CAST(COALESCE(i.ID_Medicamento, d.ID_Medicamento) AS VARCHAR(100)),
           CASE WHEN d.ID_Medicamento IS NULL THEN NULL ELSE
                (SELECT d2.* FROM deleted d2 WHERE d2.ID_Medicamento = d.ID_Medicamento
                 FOR JSON PATH, WITHOUT_ARRAY_WRAPPER) END,
           CASE WHEN i.ID_Medicamento IS NULL THEN NULL ELSE
                (SELECT i2.* FROM inserted i2 WHERE i2.ID_Medicamento = i.ID_Medicamento
                 FOR JSON PATH, WITHOUT_ARRAY_WRAPPER) END
    FROM   inserted i
    FULL OUTER JOIN deleted d ON d.ID_Medicamento = i.ID_Medicamento;
END;
GO


/* =====================================================================
   5) SQL SERVER AUDIT
   Registra accesos fallidos, cambios de roles/permisos/estructura y el
   DML sobre las tablas sensibles. Los eventos se guardan en archivos
   .sqlaudit que se consultan con sys.fn_get_audit_file (ver seccion 7).
   ===================================================================== */
USE master;
GO

-- Limpiar versiones anteriores para poder re-ejecutar el script
IF EXISTS (SELECT 1 FROM sys.server_audit_specifications WHERE name = N'Audit_Veterinaria_Servidor')
BEGIN
    ALTER SERVER AUDIT SPECIFICATION Audit_Veterinaria_Servidor WITH (STATE = OFF);
    DROP SERVER AUDIT SPECIFICATION Audit_Veterinaria_Servidor;
END
IF EXISTS (SELECT 1 FROM sys.server_audits WHERE name = N'Audit_Veterinaria')
BEGIN
    ALTER SERVER AUDIT Audit_Veterinaria WITH (STATE = OFF);
    DROP SERVER AUDIT Audit_Veterinaria;
END
GO

-- Los archivos .sqlaudit se guardan en la carpeta Log de la instancia (junto al ERRORLOG)
DECLARE @err  NVARCHAR(500) = CAST(SERVERPROPERTY('ErrorLogFileName') AS NVARCHAR(500));
DECLARE @sep  NCHAR(1)      = CASE WHEN @err LIKE N'%\%' THEN N'\' ELSE N'/' END;
DECLARE @ruta NVARCHAR(500) = LEFT(@err, LEN(@err) - CHARINDEX(@sep, REVERSE(@err)) + 1);
DECLARE @sql  NVARCHAR(MAX) =
    N'CREATE SERVER AUDIT Audit_Veterinaria TO FILE (FILEPATH = N''' + @ruta +
    N''', MAXSIZE = 50 MB, MAX_ROLLOVER_FILES = 10) WITH (ON_FAILURE = CONTINUE);';
EXEC sys.sp_executesql @sql;
PRINT 'Auditoria guardada en: ' + @ruta;
GO

-- Eventos de servidor: logins fallidos/exitosos y cambios de logins, roles y permisos
CREATE SERVER AUDIT SPECIFICATION Audit_Veterinaria_Servidor
FOR SERVER AUDIT Audit_Veterinaria
    ADD (FAILED_LOGIN_GROUP),
    ADD (SUCCESSFUL_LOGIN_GROUP),
    ADD (SERVER_PRINCIPAL_CHANGE_GROUP),
    ADD (SERVER_ROLE_MEMBER_CHANGE_GROUP),
    ADD (SERVER_PERMISSION_CHANGE_GROUP)
WITH (STATE = ON);
GO

ALTER SERVER AUDIT Audit_Veterinaria WITH (STATE = ON);
GO

USE Veterinaria;
GO

-- Eventos de base de datos: DML en tablas sensibles + cambios de roles, permisos y estructura
IF EXISTS (SELECT 1 FROM sys.database_audit_specifications WHERE name = N'Audit_Veterinaria_BD')
BEGIN
    ALTER DATABASE AUDIT SPECIFICATION Audit_Veterinaria_BD WITH (STATE = OFF);
    DROP DATABASE AUDIT SPECIFICATION Audit_Veterinaria_BD;
END
GO

CREATE DATABASE AUDIT SPECIFICATION Audit_Veterinaria_BD
FOR SERVER AUDIT Audit_Veterinaria
    ADD (INSERT, UPDATE, DELETE ON SCHEMA::facturacion        BY public),
    ADD (INSERT, UPDATE, DELETE ON OBJECT::catalogo.Medicamento BY public),
    ADD (INSERT, UPDATE, DELETE ON OBJECT::clientes.Propietario BY public),
    ADD (SELECT                 ON OBJECT::clientes.Propietario BY public),
    ADD (DATABASE_ROLE_MEMBER_CHANGE_GROUP),
    ADD (DATABASE_PERMISSION_CHANGE_GROUP),
    ADD (DATABASE_OBJECT_PERMISSION_CHANGE_GROUP),
    ADD (SCHEMA_OBJECT_CHANGE_GROUP)
WITH (STATE = ON);
GO


/* =====================================================================
   6) PRUEBAS DE SEGURIDAD (cada usuario solo puede lo que su rol permite)
   EXECUTE AS simula al usuario; REVERT regresa a tu sesion.
   Los bloques "Esperado: ..." deben imprimir un error de permiso denegado.
   ===================================================================== */

-- 6.1 Caja: ve datos de propietarios ENMASCARADOS
EXECUTE AS USER = 'usr_caja';
SELECT TOP (3) Nombre, DUI, Correo, Telefono FROM clientes.Propietario;
REVERT;
GO

-- 6.2 Recepcion: ve los datos REALES (tiene UNMASK)
EXECUTE AS USER = 'usr_recepcion';
SELECT TOP (3) Nombre, DUI, Correo, Telefono FROM clientes.Propietario;
REVERT;
GO

-- 6.3 Caja no puede borrar pagos (P5)
EXECUTE AS USER = 'usr_caja';
BEGIN TRY
    DELETE FROM facturacion.Pago WHERE ID_Pago = -1;
END TRY
BEGIN CATCH
    PRINT 'Esperado (caja no borra pagos): ' + ERROR_MESSAGE();
END CATCH;
REVERT;
GO

-- 6.4 Caja no puede modificar el inventario directamente
EXECUTE AS USER = 'usr_caja';
BEGIN TRY
    UPDATE catalogo.Medicamento SET Stock = 0 WHERE ID_Medicamento = -1;
END TRY
BEGIN CATCH
    PRINT 'Esperado (caja no toca inventario): ' + ERROR_MESSAGE();
END CATCH;
REVERT;
GO

-- 6.5 Farmacia: puede cambiar Stock pero NO otras columnas
EXECUTE AS USER = 'usr_farmacia';
UPDATE catalogo.Medicamento SET Stock = Stock WHERE ID_Medicamento = 12;      -- permitido
BEGIN TRY
    UPDATE catalogo.Medicamento SET Precauciones = Precauciones WHERE ID_Medicamento = 12;
END TRY
BEGIN CATCH
    PRINT 'Esperado (farmacia solo modifica Stock): ' + ERROR_MESSAGE();
END CATCH;
REVERT;
GO

-- 6.6 Veterinario: no accede a facturacion
EXECUTE AS USER = 'usr_veterinario';
BEGIN TRY
    SELECT TOP (1) * FROM facturacion.Factura;
END TRY
BEGIN CATCH
    PRINT 'Esperado (veterinario no ve facturacion): ' + ERROR_MESSAGE();
END CATCH;
REVERT;
GO

-- 6.7 Analista BI: lee las vistas de reportes pero no las tablas base
EXECUTE AS USER = 'usr_bi';
SELECT TOP (3) * FROM reportes.vw_bi_facturacion;
BEGIN TRY
    SELECT TOP (1) * FROM clientes.Propietario;
END TRY
BEGIN CATCH
    PRINT 'Esperado (BI no ve datos personales): ' + ERROR_MESSAGE();
END CATCH;
REVERT;
GO

-- 6.8 Recepcion no ve diagnosticos
EXECUTE AS USER = 'usr_recepcion';
BEGIN TRY
    SELECT TOP (1) * FROM clinica.Diagnostico;
END TRY
BEGIN CATCH
    PRINT 'Esperado (recepcion no ve diagnosticos): ' + ERROR_MESSAGE();
END CATCH;
REVERT;
GO

-- 6.9 Resumen de permisos efectivos por rol
SELECT dp.name AS rol,
       p.state_desc AS estado,
       p.permission_name AS permiso,
       CASE p.class_desc
            WHEN 'SCHEMA'           THEN N'SCHEMA::' + s.name COLLATE DATABASE_DEFAULT
            WHEN 'OBJECT_OR_COLUMN' THEN N'OBJECT::' + OBJECT_SCHEMA_NAME(p.major_id) + N'.' + OBJECT_NAME(p.major_id)
            ELSE p.class_desc COLLATE DATABASE_DEFAULT
       END AS sobre
FROM   sys.database_permissions p
JOIN   sys.database_principals dp ON dp.principal_id = p.grantee_principal_id
LEFT JOIN sys.schemas s ON p.class_desc = 'SCHEMA' AND s.schema_id = p.major_id
WHERE  dp.name LIKE 'rol[_]%'
ORDER BY dp.name, p.state_desc, sobre, p.permission_name;
GO


/* =====================================================================
   7) CONSULTA DE LOGS DE AUDITORIA
   ===================================================================== */

-- 7.1 Bitacora de cambios con valores anteriores/nuevos (la lee rol_auditor)
SELECT TOP (20) ID_Bitacora, Fecha, Tabla, Operacion, Llave, Usuario, Host,
       Datos_Anteriores, Datos_Nuevos
FROM   auditoria.Bitacora
ORDER BY ID_Bitacora DESC;
GO

-- 7.2 Demostracion: un cambio auditado (se ve quien, cuando, antes y despues)
UPDATE catalogo.Medicamento SET Stock = Stock + 1 WHERE ID_Medicamento = 12;
SELECT TOP (1) * FROM auditoria.Bitacora WHERE Tabla = 'catalogo.Medicamento' ORDER BY ID_Bitacora DESC;
UPDATE catalogo.Medicamento SET Stock = Stock - 1 WHERE ID_Medicamento = 12;   -- revertir
GO

-- 7.3 Eventos de SQL Server Audit (logins fallidos, cambios de permisos, DML sensible)
DECLARE @err  NVARCHAR(500) = CAST(SERVERPROPERTY('ErrorLogFileName') AS NVARCHAR(500));
DECLARE @sep  NCHAR(1)      = CASE WHEN @err LIKE N'%\%' THEN N'\' ELSE N'/' END;
DECLARE @ruta NVARCHAR(500) = LEFT(@err, LEN(@err) - CHARINDEX(@sep, REVERSE(@err)) + 1) + N'Audit_Veterinaria*.sqlaudit';

SELECT event_time, action_id, succeeded, server_principal_name, database_name,
       schema_name, object_name, statement
FROM   sys.fn_get_audit_file(@ruta, DEFAULT, DEFAULT)
ORDER BY event_time DESC;
GO

-- 7.4 Solo accesos fallidos (LGIF = failed login)
DECLARE @err  NVARCHAR(500) = CAST(SERVERPROPERTY('ErrorLogFileName') AS NVARCHAR(500));
DECLARE @sep  NCHAR(1)      = CASE WHEN @err LIKE N'%\%' THEN N'\' ELSE N'/' END;
DECLARE @ruta NVARCHAR(500) = LEFT(@err, LEN(@err) - CHARINDEX(@sep, REVERSE(@err)) + 1) + N'Audit_Veterinaria*.sqlaudit';

SELECT event_time, server_principal_name, client_ip, application_name
FROM   sys.fn_get_audit_file(@ruta, DEFAULT, DEFAULT)
WHERE  action_id = 'LGIF'
ORDER BY event_time DESC;
GO