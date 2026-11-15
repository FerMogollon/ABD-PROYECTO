# Veterinaria Huellitas · Sistema de Gestión de Clínica Veterinaria

Proyecto de bases de datos para administrar las operaciones de la clínica veterinaria Huellitas: propietarios y mascotas, citas, diagnósticos, tratamientos, medicamentos, facturación y pagos.

El repositorio contiene la base de datos **`Veterinaria`** para **Microsoft SQL Server**, scripts de creación y carga, consultas analíticas, configuración de seguridad y auditoría, dimensionamiento y estrategia de respaldo y recuperación. Los scripts fueron migrados desde PostgreSQL a T-SQL.

## Qué incluye

| Área | Contenido |
|---|---|
| Modelo de datos | Tablas relacionadas y organizadas por esquemas funcionales, con claves, restricciones y reglas de integridad. |
| Lógica de negocio | Triggers para validar operaciones, actualizar montos, administrar inventario y procesar pagos; procedimiento para cancelar citas vencidas. |
| Datos de prueba | Carga de datos de ejemplo para probar el modelo y las consultas. |
| Consultas y rendimiento | Tres consultas analíticas con funciones ventana, mediciones con `STATISTICS IO` y `STATISTICS TIME`, e índices para comparar antes y después. |
| Seguridad | Roles y permisos por función, enmascaramiento dinámico de datos personales, vistas para reportes, bitácora y SQL Server Audit. |
| Continuidad | Modelo de recuperación `FULL`, jobs de SQL Server Agent para respaldos Full, Diferencial y Log, y ejemplos de restauración. |
| Dimensionamiento | Estimación del espacio de datos y log, con proyección de crecimiento a cinco años basada en los supuestos del script. |

## Esquemas de la base de datos

| Esquema | Propósito |
|---|---|
| `clientes` | Propietarios y mascotas. |
| `clinica` | Veterinarios, especialidades, citas, diagnósticos y tratamientos. |
| `catalogo` | Procedimientos, medicamentos e ítems facturables. |
| `facturacion` | Facturas, detalles y pagos. |
| `reportes` | Vistas de lectura para consultas e integración con herramientas de análisis. |
| `auditoria` | Bitácora de cambios y datos de auditoría. |

## Reglas de negocio destacadas

- Los datos de propietarios, mascotas, citas, diagnósticos, tratamientos y facturación se relacionan mediante claves foráneas.
- El monto de una factura se recalcula a partir de sus detalles.
- Al facturar medicamentos se valida y descuenta el inventario; un tratamiento con una contraindicación para la especie de la mascota se rechaza.
- Las facturas deben corresponder al propietario de la mascota asociada a la cita.
- Los pagos actualizan el estado de pago de la factura y pueden marcar la cita como completada.
- Las citas vencidas que no estén completadas o canceladas pueden cancelarse mediante la lógica incluida.

## Estructura del repositorio

```text
ABD-PROYECTO/
├── scripts/
│   ├── 01_DDL_VETERINARIA.sql
│   ├── 02_TRIGGERS_VETERINARIA.sql
│   ├── 03_DML_VETERINARIA.sql
│   ├── consultas/
│   │   └──04_CONSULTAS_VETERINARIA.sql
│   ├── seguridad/
│   │   └── 05_SEGURIDAD_VETERINARIA_SQLSERVER.sql
│   ├── respaldos/
│   │   └── 06_RESPALDOS_VETERINARIA.sql
│   └── dimensionamiento/
│       └── 07_DIMENSIONAMIENTO_VETERINARIA.sql
└── backups_veterinaria/
    ├── Veterinaria_Full.bak
    ├── Veterinaria_Diff.bak
    └── Veterinaria_Log.trn
```

Los archivos `.bak` y `.trn` son copias de respaldos generados para este proyecto. El script de respaldo guarda los archivos en `/var/opt/mssql/backups_veterinaria/` cuando SQL Server se ejecuta en Docker; esa ruta está dentro del contenedor. Para conservar una copia en Windows, hace falta copiar los archivos al equipo o configurar un volumen compartido.

## Requisitos

- Microsoft SQL Server 2025.
- SQL Server Management Studio (SSMS) u otra herramienta compatible para ejecutar T-SQL.
- Permisos de administrador de SQL Server para crear la base, configurar logins, auditoría y jobs.
- SQL Server Agent habilitado para ejecutar los respaldos programados.
- Para el despliegue en Docker, un contenedor SQL Server con una carpeta de respaldos accesible y permisos de escritura para el usuario `mssql`.

## Cómo ejecutar los scripts

Conéctate a la instancia de SQL Server desde SSMS y ejecuta los scripts en este orden:

1. [`01_DDL_VETERINARIA.sql`](scripts/01_DDL_VETERINARIA.sql) — crea la base `Veterinaria`, los esquemas y las tablas.
2. [`02_TRIGGERS_VETERINARIA.sql`](scripts/02_TRIGGERS_VETERINARIA.sql) — crea triggers, procedimiento y vistas de facturación.
3. [`03_DML_VETERINARIA.sql`](scripts/03_DML_VETERINARIA.sql) — carga datos de ejemplo. Ejecutarlo después del DDL y los triggers permite que estos participen durante la carga.
4. [`04_CONSULTAS_VETERINARIA.sql`](scripts/04_CONSULTAS_VETERINARIA.sql) — ejecuta las consultas y crea índices. Incluye operaciones de limpieza de caché para las mediciones; ejecútalo en un entorno de pruebas.
5. [`05_SEGURIDAD_VETERINARIA_SQLSERVER.sql`](scripts/seguridad/05_SEGURIDAD_VETERINARIA_SQLSERVER.sql) — configura logins, usuarios, roles, permisos, vistas de reportes y auditoría. Requiere autenticación mixta y privilegios de `sysadmin`.
6. [`06_RESPALDOS_VETERINARIA.sql`](scripts/respaldos/06_RESPALDOS_VETERINARIA.sql) — configura el modelo de recuperación `FULL` y los jobs de respaldo de SQL Server Agent. Requiere que el Agent esté habilitado y que la ruta de respaldo exista y sea escribible por SQL Server.
7. [`07_DIMENSIONAMIENTO_VETERINARIA.sql`](scripts/dimensionamiento/07_DIMENSIONAMIENTO_VETERINARIA.sql) — calcula el dimensionamiento según los datos y los índices presentes. Ejecutarlo después de los scripts de creación; para incluir los índices de rendimiento, ejecutarlo después del paso 4.

> **Precaución:** `01_DDL_VETERINARIA.sql` incluye un bloque comentado para borrar y recrear la base. No lo descomentes salvo que quieras eliminar la base y sus datos.

## Seguridad

El script de seguridad crea credenciales de ejemplo para los logins. **Cámbialas antes de ejecutar el script y no reutilices credenciales de ejemplo en producción.** Revisa también los permisos, la ruta de auditoría y la configuración de autenticación de acuerdo con tu entorno.

La implementación separa permisos mediante roles, aplica enmascaramiento dinámico a ciertos datos personales y limita el acceso del analista a vistas del esquema `reportes`. La auditoría incluye una bitácora de cambios y configuración de SQL Server Audit.

## Respaldo y recuperación

El script [`06_RESPALDOS_VETERINARIA.sql`](scripts/respaldos/06_RESPALDOS_VETERINARIA.sql) define esta programación:

| Tipo | Frecuencia configurada | Retención |
|---|---|---|
| Completo (Full) | Diario a las 21:00 | 14 días |
| Diferencial | Cada 3 horas, de 09:00 a 18:00 | 14 días |
| Log de transacciones | Cada 15 minutos, de 08:00 a 20:00 | 14 días |

La estrategia establece un objetivo de **RPO de hasta 15 minutos** mientras los jobs se ejecuten correctamente. Para restaurar, se aplica el Full, el último Diferencial y los logs posteriores en orden; el último paso usa `WITH RECOVERY`. El script también contiene ejemplos de Tail-Log y de restauración en una base separada. Reemplaza los nombres de archivo de ejemplo por los nombres reales y valida la secuencia antes de restaurar.

Si SQL Server corre en Docker, crea la carpeta de respaldos dentro del contenedor y asigna permisos de escritura al usuario del servicio. Los respaldos guardados allí no aparecerán automáticamente en el Explorador de Windows; cópialos al host o configura un volumen montado.

## Consultas analíticas

[`04_CONSULTAS_VETERINARIA.sql`](scripts/04_CONSULTAS_VETERINARIA.sql) compara las consultas antes y después de agregar índices:

1. Ingresos por veterinario y mes.
2. Cartera pendiente de cobro por propietario.
3. Historial de visitas de las mascotas de un propietario.

Las consultas usan funciones ventana como `RANK`, `DENSE_RANK`, `ROW_NUMBER`, `LAG` y sumas acumuladas. Las mediciones dependen del servidor y de los datos disponibles, por lo que deben repetirse en el entorno donde se evalúe el proyecto.
