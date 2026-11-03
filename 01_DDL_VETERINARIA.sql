/* =====================================================================
   VETERINARIA - DDL (SQL Server 2025)
   Migrado desde PostgreSQL.
   Orden de ejecucion: 01_DDL -> 02_TRIGGERS -> 03_DML -> 04_CONSULTAS
   ===================================================================== */

IF DB_ID(N'Veterinaria') IS NULL
    CREATE DATABASE Veterinaria COLLATE Latin1_General_CI_AS;
GO

/* Para reiniciar desde cero (borra TODO), ejecutar antes:
   USE master;
   ALTER DATABASE Veterinaria SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
   DROP DATABASE Veterinaria;
*/

USE Veterinaria;
GO

/* ESQUEMAS: agrupan las tablas por funcion para poder dar permisos por esquema
   (ver 05_SEGURIDAD.sql). Todos pertenecen a dbo, lo que habilita el "ownership
   chaining": un rol con acceso a una vista/trigger no necesita acceso a las tablas base.
     clientes     -> datos personales (Propietario, Mascota)
     clinica      -> operacion medica (Veterinario, Cita, Diagnostico, Tratamiento...)
     catalogo     -> items facturables, procedimientos, medicamentos e inventario
     facturacion  -> dinero (Factura, Detalle_Factura, Pago)
     reportes     -> vistas sin datos personales para Power BI
     auditoria    -> bitacora de cambios (solo lectura para el auditor)
*/
IF SCHEMA_ID(N'clientes')    IS NULL EXEC(N'CREATE SCHEMA clientes    AUTHORIZATION dbo');
IF SCHEMA_ID(N'clinica')     IS NULL EXEC(N'CREATE SCHEMA clinica     AUTHORIZATION dbo');
IF SCHEMA_ID(N'catalogo')    IS NULL EXEC(N'CREATE SCHEMA catalogo    AUTHORIZATION dbo');
IF SCHEMA_ID(N'facturacion') IS NULL EXEC(N'CREATE SCHEMA facturacion AUTHORIZATION dbo');
IF SCHEMA_ID(N'reportes')    IS NULL EXEC(N'CREATE SCHEMA reportes    AUTHORIZATION dbo');
IF SCHEMA_ID(N'auditoria')   IS NULL EXEC(N'CREATE SCHEMA auditoria   AUTHORIZATION dbo');
GO

/* Notas de migracion:
   - generated always as identity   -> IDENTITY(1,1)
   - numeric(10,2)                  -> DECIMAL(10,2)
   - timestamp (Postgres)           -> DATETIME2 (en SQL Server "timestamp" es rowversion)
   - current_date                   -> CAST(GETDATE() AS DATE)
   - ON DELETE RESTRICT             -> ON DELETE NO ACTION (equivalente en SQL Server)
   - Operador regex (~)             -> LIKE con patrones (SQL Server no tiene regex nativo)
   - DUI, Correo y Telefono de Propietario llevan Dynamic Data Masking (politica de seguridad)
*/

CREATE TABLE clientes.Propietario (
    ID_Propietario BIGINT IDENTITY(1,1) NOT NULL,
    Nombre         VARCHAR(150) NOT NULL,
    DUI            VARCHAR(10)  MASKED WITH (FUNCTION = 'partial(0,"XXXXXXXX-",1)') NOT NULL,
    Correo         VARCHAR(150) MASKED WITH (FUNCTION = 'email()') NULL,
    Telefono       VARCHAR(20)  MASKED WITH (FUNCTION = 'partial(0,"XXXX-XXXX-",4)') NOT NULL,
    CONSTRAINT pk_propietario PRIMARY KEY (ID_Propietario),
    CONSTRAINT uq_propietario_dui UNIQUE (DUI),
    -- Formato 8 digitos, guion, 1 digito (ej. 40523095-9)
    CONSTRAINT ck_propietario_dui_formato CHECK (
        DUI LIKE '[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]-[0-9]'
    ),
    -- Formato basico de correo: algo@dominio.ext, sin espacios
    CONSTRAINT ck_propietario_correo_formato CHECK (
        Correo LIKE '%_@_%._%' AND Correo NOT LIKE '%[ ]%'
    )
);
GO

CREATE TABLE clinica.Veterinario (
    ID_Veterinario BIGINT IDENTITY(1,1) NOT NULL,
    Nombre         VARCHAR(150) NOT NULL,
    Correo         VARCHAR(150) NOT NULL,
    CONSTRAINT pk_veterinario PRIMARY KEY (ID_Veterinario),
    CONSTRAINT uq_veterinario_correo UNIQUE (Correo),
    CONSTRAINT ck_veterinario_correo_formato CHECK (
        Correo LIKE '%_@_%._%' AND Correo NOT LIKE '%[ ]%'
    )
);
GO

CREATE TABLE clinica.Especialidad (
    ID_Especialidad BIGINT IDENTITY(1,1) NOT NULL,
    Nombre          VARCHAR(150) NOT NULL,
    Estado          VARCHAR(15)  NOT NULL CONSTRAINT df_especialidad_estado DEFAULT 'Activo',
    CONSTRAINT pk_especialidad PRIMARY KEY (ID_Especialidad),
    CONSTRAINT ck_especialidad_estado CHECK (Estado IN ('Activo', 'Inactivo', 'Suspendido'))
);
GO

CREATE TABLE clinica.Veterinario_Especialidad (
    ID_Veterinario  BIGINT NOT NULL,
    ID_Especialidad BIGINT NOT NULL,
    CONSTRAINT pk_veterinario_especialidad PRIMARY KEY (ID_Veterinario, ID_Especialidad),
    CONSTRAINT fk_ve_veterinario FOREIGN KEY (ID_Veterinario)
        REFERENCES clinica.Veterinario (ID_Veterinario)
        ON UPDATE CASCADE ON DELETE NO ACTION,
    CONSTRAINT fk_ve_especialidad FOREIGN KEY (ID_Especialidad)
        REFERENCES clinica.Especialidad (ID_Especialidad)
        ON UPDATE CASCADE ON DELETE NO ACTION
);
GO

CREATE TABLE clientes.Mascota (
    ID_Mascota       BIGINT IDENTITY(1,1) NOT NULL,
    Especie          VARCHAR(150) NOT NULL,
    Nombre           VARCHAR(150) NOT NULL,
    Raza             VARCHAR(150) NULL,
    Fecha_Nacimiento DATE NULL,
    ID_Propietario   BIGINT NOT NULL,
    CONSTRAINT pk_mascota PRIMARY KEY (ID_Mascota),
    CONSTRAINT ck_mascota_fecha_nacimiento CHECK (Fecha_Nacimiento <= CAST(GETDATE() AS DATE)),
    CONSTRAINT fk_mascota_propietario FOREIGN KEY (ID_Propietario)
        REFERENCES clientes.Propietario (ID_Propietario)
        ON UPDATE CASCADE ON DELETE NO ACTION
);
GO

CREATE TABLE clinica.Cita (
    ID_Cita        BIGINT IDENTITY(1,1) NOT NULL,
    Fecha          DATE NOT NULL,
    Hora           TIME(0) NOT NULL,
    Consultorio    VARCHAR(50) NULL,
    Estado         VARCHAR(15) NOT NULL CONSTRAINT df_cita_estado DEFAULT 'Programada',
    ID_Mascota     BIGINT NOT NULL,
    ID_Veterinario BIGINT NOT NULL,
    CONSTRAINT pk_cita PRIMARY KEY (ID_Cita),
    CONSTRAINT ck_cita_estado CHECK (Estado IN ('Programada', 'Completada', 'Cancelada')),
    CONSTRAINT fk_cita_mascota FOREIGN KEY (ID_Mascota)
        REFERENCES clientes.Mascota (ID_Mascota)
        ON UPDATE CASCADE ON DELETE NO ACTION,
    CONSTRAINT fk_cita_veterinario FOREIGN KEY (ID_Veterinario)
        REFERENCES clinica.Veterinario (ID_Veterinario)
        ON UPDATE CASCADE ON DELETE NO ACTION
);
GO

CREATE TABLE clinica.Diagnostico (
    ID_Diagnostico BIGINT IDENTITY(1,1) NOT NULL,
    Descripcion    VARCHAR(500) NOT NULL,
    ID_Cita        BIGINT NOT NULL,
    CONSTRAINT pk_diagnostico PRIMARY KEY (ID_Diagnostico),
    CONSTRAINT fk_diagnostico_cita FOREIGN KEY (ID_Cita)
        REFERENCES clinica.Cita (ID_Cita)
        ON UPDATE CASCADE ON DELETE NO ACTION
);
GO

/* En el original el CHECK de Monto se creo como (> 0) y luego se cambio a (>= 0)
   con ALTER TABLE. Aqui se crea directamente la version final. */
CREATE TABLE facturacion.Factura (
    Num_Factura    BIGINT IDENTITY(1,1) NOT NULL,
    Fecha          DATE NULL CONSTRAINT df_factura_fecha DEFAULT CAST(GETDATE() AS DATE),
    Monto          DECIMAL(10,2) NOT NULL,
    Estado_Pago    VARCHAR(15) NOT NULL CONSTRAINT df_factura_estado_pago DEFAULT 'Pendiente',
    ID_Cita        BIGINT NOT NULL,
    ID_Propietario BIGINT NOT NULL,
    CONSTRAINT pk_factura PRIMARY KEY (Num_Factura),
    CONSTRAINT ck_factura_estado_pago CHECK (Estado_Pago IN ('Pendiente', 'Parcial', 'Pagado')),
    CONSTRAINT uq_factura_cita UNIQUE (ID_Cita),
    CONSTRAINT ck_factura_monto CHECK (Monto >= 0),
    CONSTRAINT fk_factura_cita FOREIGN KEY (ID_Cita)
        REFERENCES clinica.Cita (ID_Cita)
        ON UPDATE CASCADE ON DELETE NO ACTION,
    -- ON UPDATE NO ACTION: SQL Server rechaza CASCADE aqui porque existiria un segundo
    -- camino de cascada Propietario -> Mascota -> Cita -> Factura (error 1785).
    -- No afecta el comportamiento real: los IDs son IDENTITY y no se actualizan.
    CONSTRAINT fk_factura_propietario FOREIGN KEY (ID_Propietario)
        REFERENCES clientes.Propietario (ID_Propietario)
        ON UPDATE NO ACTION ON DELETE NO ACTION
);
GO

CREATE TABLE catalogo.Item_Facturable (
    ID_Item     BIGINT IDENTITY(1,1) NOT NULL,
    Descripcion VARCHAR(500) NOT NULL,
    Costo       DECIMAL(10,2) NOT NULL,
    CONSTRAINT pk_item_facturable PRIMARY KEY (ID_Item),
    CONSTRAINT ck_item_costo CHECK (Costo > 0)
);
GO

CREATE TABLE facturacion.Detalle_Factura (
    ID_Detalle      BIGINT IDENTITY(1,1) NOT NULL,
    Precio_Unitario DECIMAL(10,2) NOT NULL,
    Cantidad        BIGINT NOT NULL,
    Num_Factura     BIGINT NOT NULL,
    ID_Item         BIGINT NOT NULL,
    CONSTRAINT pk_detalle_factura PRIMARY KEY (ID_Detalle),
    CONSTRAINT ck_detallefact_cantidad CHECK (Cantidad > 0),
    CONSTRAINT ck_detallefact_precio_unitario CHECK (Precio_Unitario > 0),
    CONSTRAINT fk_detallefact_num_factura FOREIGN KEY (Num_Factura)
        REFERENCES facturacion.Factura (Num_Factura)
        ON UPDATE CASCADE ON DELETE NO ACTION,
    CONSTRAINT fk_detallef_id_item FOREIGN KEY (ID_Item)
        REFERENCES catalogo.Item_Facturable (ID_Item)
        ON UPDATE CASCADE ON DELETE NO ACTION
);
GO

CREATE TABLE catalogo.Procedimiento (
    ID_Procedimiento BIGINT NOT NULL,
    Riesgo           VARCHAR(500) NOT NULL,
    Tiempo_Estimado  INT NOT NULL,
    CONSTRAINT pk_procedimiento PRIMARY KEY (ID_Procedimiento),
    CONSTRAINT ck_procedimiento_tiempo CHECK (Tiempo_Estimado >= 0),
    CONSTRAINT fk_procedimiento_item FOREIGN KEY (ID_Procedimiento)
        REFERENCES catalogo.Item_Facturable (ID_Item)
        ON UPDATE CASCADE ON DELETE NO ACTION
);
GO

CREATE TABLE catalogo.Medicamento (
    ID_Medicamento    BIGINT NOT NULL,
    Via               VARCHAR(150) NOT NULL,
    Dosis_Recomendada VARCHAR(150) NOT NULL,
    Precauciones      VARCHAR(500) NOT NULL,
    Stock             INT NOT NULL CONSTRAINT df_medicamento_stock DEFAULT 0,
    CONSTRAINT pk_medicamento PRIMARY KEY (ID_Medicamento),
    CONSTRAINT ck_medicamento_stock CHECK (Stock >= 0),
    CONSTRAINT fk_medicamento_item FOREIGN KEY (ID_Medicamento)
        REFERENCES catalogo.Item_Facturable (ID_Item)
        ON UPDATE CASCADE ON DELETE NO ACTION
);
GO

CREATE TABLE clinica.Diagnostico_Procedimiento (
    ID_Procedimiento BIGINT NOT NULL,
    ID_Diagnostico   BIGINT NOT NULL,
    CONSTRAINT pk_diagnostico_procedimiento PRIMARY KEY (ID_Procedimiento, ID_Diagnostico),
    CONSTRAINT fk_dp_procedimiento FOREIGN KEY (ID_Procedimiento)
        REFERENCES catalogo.Procedimiento (ID_Procedimiento)
        ON UPDATE CASCADE ON DELETE NO ACTION,
    CONSTRAINT fk_dp_diagnostico FOREIGN KEY (ID_Diagnostico)
        REFERENCES clinica.Diagnostico (ID_Diagnostico)
        ON UPDATE CASCADE ON DELETE NO ACTION
);
GO

CREATE TABLE clinica.Tratamiento (
    ID_Tratamiento BIGINT IDENTITY(1,1) NOT NULL,
    Frecuencia     VARCHAR(200) NOT NULL,
    Dosis          VARCHAR(200) NOT NULL,
    Vigencia       DATE NOT NULL,
    Descripcion    VARCHAR(500) NULL,
    ID_Diagnostico BIGINT NOT NULL,
    ID_Medicamento BIGINT NOT NULL,
    CONSTRAINT pk_tratamiento PRIMARY KEY (ID_Tratamiento),
    CONSTRAINT fk_tratamiento_diagnostico FOREIGN KEY (ID_Diagnostico)
        REFERENCES clinica.Diagnostico (ID_Diagnostico)
        ON UPDATE CASCADE ON DELETE NO ACTION,
    CONSTRAINT fk_tratamiento_medicamento FOREIGN KEY (ID_Medicamento)
        REFERENCES catalogo.Medicamento (ID_Medicamento)
        ON UPDATE CASCADE ON DELETE NO ACTION
);
GO

CREATE TABLE facturacion.Pago (
    ID_Pago     BIGINT IDENTITY(1,1) NOT NULL,
    Monto       DECIMAL(10,2) NOT NULL,
    Metodo_Pago VARCHAR(20) NOT NULL,
    Fecha_Pago  DATETIME2(0) NOT NULL CONSTRAINT df_pago_fecha DEFAULT SYSDATETIME(),
    Num_Factura BIGINT NOT NULL,
    CONSTRAINT pk_pago PRIMARY KEY (ID_Pago),
    CONSTRAINT ck_pago_monto CHECK (Monto > 0),
    CONSTRAINT ck_pago_metodo CHECK (Metodo_Pago IN ('Efectivo', 'Transferencia', 'Bitcoin', 'Tarjeta')),
    CONSTRAINT fk_pago_num_factura FOREIGN KEY (Num_Factura)
        REFERENCES facturacion.Factura (Num_Factura)
        ON UPDATE CASCADE ON DELETE NO ACTION
);
GO