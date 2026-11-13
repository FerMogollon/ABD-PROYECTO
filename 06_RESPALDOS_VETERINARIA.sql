/* =====================================================================
   VETERINARIA - ESTRATEGIA DE RESPALDOS Y RECUPERACION (SQL Server 2025)
   Ejecutar DESPUES de 01_DDL, 02_TRIGGERS, 03_DML, 04_CONSULTAS y 05_SEGURIDAD.
   Requisitos previos en contenedor Docker, crear la carpeta para guardar los respaldos, ejecutar en la CMD:
     docker exec -u 0 -it <contenedor> mkdir -p /var/opt/mssql/backups_veterinaria
     docker exec -u 0 -it <contenedor> chown -R mssql:mssql /var/opt/mssql/backups_veterinaria
     docker exec -u 0 -it <contenedor> /opt/mssql/bin/mssql-conf set sqlagent.enabled true
/*
Si se ejecuta el tercer comando y ve el Agente detenido (en rojo) en SSMS, en lugar de systemctl
solo debe correr:
     docker restart <contenedor>
*/
   PLAN DE RESPALDOS APROBADO:
     1. Completo (Full)      : Diario a las 9:00 p.m. (21:00) - Linea base fuera de horario.
     2. Diferencial (Diff)   : Cada 3 horas (09:00, 12:00, 15:00, 18:00) - Maximo 11 logs en cadena.
     3. Log de Transacciones : Cada 15 minutos (08:00 a 20:00) - RPO <= 15 minutos.
     4. Tail-Log (Desastre)  : Ejecucion manual inmediata ante falla - RPO = 0 (Point-in-Time).
   ===================================================================== */

USE master;
GO

/* =====================================================================
   1) MODELO DE RECUPERACION FULL Y DIRECTORIO DE RESPALDOS
   Obligatorio para habilitar respaldos de Log de Transacciones y Tail-Log.
   ===================================================================== */
IF DB_ID(N'Veterinaria') IS NOT NULL
BEGIN
    ALTER DATABASE [Veterinaria] SET RECOVERY FULL;
END
ELSE
BEGIN
    RAISERROR(N'La base de datos Veterinaria no existe. Ejecute primero 01_DDL_VETERINARIA.sql.', 16, 1);
END
GO

-- Intentar crear la carpeta desde SQL Server si aun no existe
BEGIN TRY
    EXEC master.sys.xp_create_subdir N'/var/opt/mssql/backups_veterinaria/';
END TRY
BEGIN CATCH
    PRINT N'Verifique que /var/opt/mssql/backups_veterinaria/ exista con propietario mssql:mssql.';
END CATCH;
GO


/* =====================================================================
   2) OPERADOR DE NOTIFICACIONES (SQL Server Agent)
   ===================================================================== */
USE msdb;
GO

IF NOT EXISTS (SELECT 1 FROM msdb.dbo.sysoperators WHERE name = N'Op_DBA_Veterinaria')
BEGIN
    EXEC msdb.dbo.sp_add_operator
        @name = N'Op_DBA_Veterinaria',
        @enabled = 1,
        @email_address = N'dba.veterinaria@clinica.local';
END
GO


/* =====================================================================
   3) LIMPIEZA PREVIA DE JOBS (Permite re-ejecutar el script limpiamente)
   ===================================================================== */
IF EXISTS (SELECT 1 FROM msdb.dbo.sysjobs WHERE name = N'Job_Veterinaria_Backup_Full')
    EXEC msdb.dbo.sp_delete_job @job_name = N'Job_Veterinaria_Backup_Full', @delete_unused_schedule = 1;

IF EXISTS (SELECT 1 FROM msdb.dbo.sysjobs WHERE name = N'Job_Veterinaria_Backup_Diff')
    EXEC msdb.dbo.sp_delete_job @job_name = N'Job_Veterinaria_Backup_Diff', @delete_unused_schedule = 1;

IF EXISTS (SELECT 1 FROM msdb.dbo.sysjobs WHERE name = N'Job_Veterinaria_Backup_Log')
    EXEC msdb.dbo.sp_delete_job @job_name = N'Job_Veterinaria_Backup_Log', @delete_unused_schedule = 1;
GO


/* =====================================================================
   4) JOB 1: RESPALDO COMPLETO (FULL) - Diario a las 9:00 p.m. (21:00)
   ===================================================================== */
DECLARE @jobId_Full BINARY(16);

EXEC msdb.dbo.sp_add_job
    @job_name = N'Job_Veterinaria_Backup_Full',
    @enabled = 1,
    @description = N'Respaldo completo diario de Veterinaria a las 21:00 (linea base fuera de horario).',
    @category_name = N'Database Maintenance',
    @owner_login_name = N'sa',
    @notify_level_eventlog = 2,
    @notify_level_email = 2,
    @notify_email_operator_name = N'Op_DBA_Veterinaria',
    @job_id = @jobId_Full OUTPUT;

EXEC msdb.dbo.sp_add_jobstep
    @job_id = @jobId_Full,
    @step_name = N'Paso_Backup_Full_Veterinaria',
    @step_id = 1,
    @subsystem = N'TSQL',
    @database_name = N'master',
    @command = N'
DECLARE @Fecha VARCHAR(20) = CONVERT(VARCHAR(8), SYSDATETIME(), 112) + ''_'' + REPLACE(CONVERT(VARCHAR(8), SYSDATETIME(), 108), '':'', '''');
DECLARE @Ruta NVARCHAR(500) = N''/var/opt/mssql/backups_veterinaria/Veterinaria_Full_'' + @Fecha + N''.bak'';

BACKUP DATABASE [Veterinaria]
TO DISK = @Ruta
WITH INIT, CHECKSUM, COMPRESSION, STATS = 10,
     NAME = N''Veterinaria - Respaldo Completo Diario'';
',
    @on_success_action = 1,
    @on_fail_action = 2;

EXEC msdb.dbo.sp_add_jobschedule
    @job_id = @jobId_Full,
    @name = N'Sch_Veterinaria_Full_2100',
    @enabled = 1,
    @freq_type = 4,              -- Diario
    @freq_interval = 1,          -- Cada 1 dia
    @active_start_time = 210000; -- 21:00:00 (9:00 p.m.)

EXEC msdb.dbo.sp_add_jobserver
    @job_id = @jobId_Full,
    @server_name = N'(local)';
GO


/* =====================================================================
   5) JOB 2: RESPALDO DIFERENCIAL - Cada 3 horas (09:00, 12:00, 15:00, 18:00)
   ===================================================================== */
DECLARE @jobId_Diff BINARY(16);

EXEC msdb.dbo.sp_add_job
    @job_name = N'Job_Veterinaria_Backup_Diff',
    @enabled = 1,
    @description = N'Respaldo diferencial de Veterinaria cada 3 horas (09:00 a 18:00). Limita cadena a max 11 logs.',
    @category_name = N'Database Maintenance',
    @owner_login_name = N'sa',
    @notify_level_eventlog = 2,
    @notify_level_email = 2,
    @notify_email_operator_name = N'Op_DBA_Veterinaria',
    @job_id = @jobId_Diff OUTPUT;

EXEC msdb.dbo.sp_add_jobstep
    @job_id = @jobId_Diff,
    @step_name = N'Paso_Backup_Diff_Veterinaria',
    @step_id = 1,
    @subsystem = N'TSQL',
    @database_name = N'master',
    @command = N'
DECLARE @Fecha VARCHAR(20) = CONVERT(VARCHAR(8), SYSDATETIME(), 112) + ''_'' + REPLACE(CONVERT(VARCHAR(8), SYSDATETIME(), 108), '':'', '''');
DECLARE @Ruta NVARCHAR(500) = N''/var/opt/mssql/backups_veterinaria/Veterinaria_Diff_'' + @Fecha + N''.bak'';

BACKUP DATABASE [Veterinaria]
TO DISK = @Ruta
WITH DIFFERENTIAL, INIT, CHECKSUM, COMPRESSION, STATS = 10,
     NAME = N''Veterinaria - Respaldo Diferencial Cada 3 Horas'';
',
    @on_success_action = 1,
    @on_fail_action = 2;

EXEC msdb.dbo.sp_add_jobschedule
    @job_id = @jobId_Diff,
    @name = N'Sch_Veterinaria_Diff_Cada3Horas',
    @enabled = 1,
    @freq_type = 4,              -- Diario
    @freq_interval = 1,          -- Cada 1 dia
    @freq_subday_type = 8,       -- Horas
    @freq_subday_interval = 3,   -- Cada 3 horas
    @active_start_time = 090000, -- Inicia 09:00:00 (9:00 a.m.)
    @active_end_time = 180000;   -- Termina 18:00:00 (6:00 p.m.) -> Ejecuta: 09:00, 12:00, 15:00, 18:00

EXEC msdb.dbo.sp_add_jobserver
    @job_id = @jobId_Diff,
    @server_name = N'(local)';
GO


/* =====================================================================
   6) JOB 3: RESPALDO DE LOG DE TRANSACCIONES - Cada 15 min (08:00 a 20:00)
   ===================================================================== */
DECLARE @jobId_Log BINARY(16);

EXEC msdb.dbo.sp_add_job
    @job_name = N'Job_Veterinaria_Backup_Log',
    @enabled = 1,
    @description = N'Respaldo de Log de Transacciones cada 15 minutos en horario operativo (08:00 a 20:00). RPO <= 15m.',
    @category_name = N'Database Maintenance',
    @owner_login_name = N'sa',
    @notify_level_eventlog = 2,
    @notify_level_email = 2,
    @notify_email_operator_name = N'Op_DBA_Veterinaria',
    @job_id = @jobId_Log OUTPUT;

EXEC msdb.dbo.sp_add_jobstep
    @job_id = @jobId_Log,
    @step_name = N'Paso_Backup_Log_Veterinaria',
    @step_id = 1,
    @subsystem = N'TSQL',
    @database_name = N'master',
    @command = N'
DECLARE @Fecha VARCHAR(20) = CONVERT(VARCHAR(8), SYSDATETIME(), 112) + ''_'' + REPLACE(CONVERT(VARCHAR(8), SYSDATETIME(), 108), '':'', '''');
DECLARE @Ruta NVARCHAR(500) = N''/var/opt/mssql/backups_veterinaria/Veterinaria_Log_'' + @Fecha + N''.trn'';

BACKUP LOG [Veterinaria]
TO DISK = @Ruta
WITH INIT, CHECKSUM, COMPRESSION,
     NAME = N''Veterinaria - Respaldo Log Cada 15 Minutos'';
',
    @on_success_action = 1,
    @on_fail_action = 2;

EXEC msdb.dbo.sp_add_jobschedule
    @job_id = @jobId_Log,
    @name = N'Sch_Veterinaria_Log_Cada15Min',
    @enabled = 1,
    @freq_type = 4,              -- Diario
    @freq_interval = 1,          -- Cada 1 dia
    @freq_subday_type = 4,       -- Minutos
    @freq_subday_interval = 15,  -- Cada 15 minutos
    @active_start_time = 080000, -- Inicia 08:00:00 (8:00 a.m.)
    @active_end_time = 200000;   -- Termina 20:00:00 (8:00 p.m.)

EXEC msdb.dbo.sp_add_jobserver
    @job_id = @jobId_Log,
    @server_name = N'(local)';
GO


/* =====================================================================
   7) AUDITORIA Y VERIFICACION DE CADENA DE RESPALDOS
   ===================================================================== */
-- 7.1 Consultar programaciones registradas en SQL Server Agent
SELECT j.name AS [Trabajo (Job)],
       j.enabled AS [Activo],
       s.name AS [Programacion],
       CASE s.freq_subday_type
            WHEN 1 THEN N'Una vez al dia'
            WHEN 4 THEN N'Cada ' + CAST(s.freq_subday_interval AS NVARCHAR(10)) + N' minutos'
            WHEN 8 THEN N'Cada ' + CAST(s.freq_subday_interval AS NVARCHAR(10)) + N' horas'
       END AS [Frecuencia],
       s.active_start_time AS [Hora Inicio (HHMMSS)],
       s.active_end_time   AS [Hora Fin (HHMMSS)]
FROM   msdb.dbo.sysjobs j
JOIN   msdb.dbo.sysjobschedules js ON j.job_id = js.job_id
JOIN   msdb.dbo.sysschedules s     ON js.schedule_id = s.schedule_id
WHERE  j.name LIKE N'Job_Veterinaria_%'
ORDER BY j.name;
GO

-- 7.2 Consultar historial de archivos generados (Orden exacto para restaurar)
SELECT s.backup_start_date AS [Fecha Inicio],
       CASE s.type
            WHEN 'D' THEN N'1. FULL'
            WHEN 'I' THEN N'2. DIFERENCIAL'
            WHEN 'L' THEN N'3. LOG'
       END AS [Capa],
       CAST(ROUND(s.compressed_backup_size / 1024.0 / 1024.0, 2) AS DECIMAL(10,2)) AS [Tamano Comprimido (MB)],
       m.physical_device_name AS [Ruta en Contenedor]
FROM   msdb.dbo.backupset s
JOIN   msdb.dbo.backupmediafamily m ON s.media_set_id = m.media_set_id
WHERE  s.database_name = N'Veterinaria'
ORDER BY s.backup_start_date ASC;
GO

/*
Ejecute este comando en tu CMD para listar los respaldos guardados dentro de la carpeta del proyecto en tu contenedor:
     docker exec -it <contenedor> ls -lh /var/opt/mssql/backups_veterinaria/ 
*/


/* =====================================================================
   8) PROTOCOLO ANTE DESASTRE: TAIL-LOG + RESTAURACION POINT-IN-TIME (RPO = 0)
   Descomentar y ajustar los nombres de archivo reales obtenidos en 7.2
   para ejecutar una simulacion de recuperacion ante fallos.
   =====================================================================
USE master;
GO

-- Paso A: Capturar el Tail-Log (transacciones ocurridas tras el ultimo backup programado)
BACKUP LOG [Veterinaria]
TO DISK = N'/var/opt/mssql/backups_veterinaria/Veterinaria_TailLog_Desastre.trn'
WITH NO_TRUNCATE, NORECOVERY, CHECKSUM, COMPRESSION;
GO

-- Paso B: Restaurar la linea base FULL (mantiene la BD en estado RESTORING)
RESTORE DATABASE [Veterinaria]
FROM DISK = N'/var/opt/mssql/backups_veterinaria/Veterinaria_Full_YYYYMMDD_HHMMSS.bak'
WITH NORECOVERY, REPLACE;
GO

-- Paso C: Restaurar el ULTIMO Diferencial disponible (mantiene estado RESTORING)
RESTORE DATABASE [Veterinaria]
FROM DISK = N'/var/opt/mssql/backups_veterinaria/Veterinaria_Diff_YYYYMMDD_HHMMSS.bak'
WITH NORECOVERY;
GO

-- Paso D: Restaurar TODOS los Logs intermedios en orden cronologico (WITH NORECOVERY)
RESTORE LOG [Veterinaria]
FROM DISK = N'/var/opt/mssql/backups_veterinaria/Veterinaria_Log_YYYYMMDD_HHMMSS.trn'
WITH NORECOVERY;
GO

-- Paso E: Restaurar el Tail-Log y poner la base de datos ONLINE (WITH RECOVERY)
RESTORE LOG [Veterinaria]
FROM DISK = N'/var/opt/mssql/backups_veterinaria/Veterinaria_TailLog_Desastre.trn'
WITH RECOVERY;
GO

-- Paso F: Validar integridad fisica y logica tras la recuperacion (WRT)
DBCC CHECKDB (N'Veterinaria') WITH NO_INFOMSGS;
GO
*/