# 🐘 Bd-PostgreSQL-Reminicence

Este repositorio contiene la **base de datos oficial del proyecto Reminicence**, implementada en **PostgreSQL**.  
Incluye la estructura de definición (DDL), manipulación de datos (DML), funciones, procedimientos almacenados y scripts de automatización para la creación y despliegue de la base de datos.

---

## 📚 Estructura del repositorio

```

Bd-PostgreSQL-Reminicence/
│
├── docs/
│   └── models/
│       └── ERD/                 # Diagramas y modelos entidad-relación
│
├── sql/
│   ├── ddl/                     # Scripts de definición de tablas, índices y restricciones
│   ├── dml/                     # Scripts de manipulación de datos
│   │   ├── audit/               # Auditorías y logs
│   │   ├── data/                # Carga de datos iniciales
│   │   ├── functions/           # Funciones definidas por el usuario
│   │   └── procedures-stored/   # Procedimientos almacenados
│
├── pipelines/                   # Automatización para ejecución de scripts SQL
│
├── .gitignore                   # Archivos y carpetas ignoradas por Git
├── LICENSE                      # Licencia MIT
└── README.md                    # Documentación principal del proyecto

````

---

## ⚙️ Requisitos

Para ejecutar correctamente los scripts, se requiere:

- **PostgreSQL 15 o superior**
- **psql** o herramientas como **pgAdmin / DBeaver**
- **Python 3.10+** (solo si se desea usar los pipelines automáticos)
- Permisos de creación de base de datos y esquemas

---

## 🔄 Ejecución automatizada (Pipeline SQL)

Para automatizar la creación de la base de datos, el esquema y las tablas, este repositorio incluye un **pipeline en Python** que ejecuta los scripts SQL de manera ordenada.

📄 **Documentación completa del pipeline:**
👉 [Pipeline to Automate SQL Script Execution in PostgreSQL](./pipelines/README.md)

Este pipeline permite:

* Crear la base de datos y el usuario (`music_admin`) desde código.
* Ejecutar scripts DDL y DML en orden automático.
* Loggear cada sentencia ejecutada con control de errores.

---

## 🧠 Propósito del proyecto

El objetivo principal de esta base de datos es **soportar el sistema de gestión musical Reminicence**, garantizando:

* Integridad y consistencia de los datos.
* Modularidad entre los scripts DDL y DML.
* Facilidad de mantenimiento y despliegue automatizado.
* Escalabilidad y trazabilidad mediante auditoría y versionamiento.

---

## 🧩 Licencia

Este proyecto se distribuye bajo la **Licencia MIT**.
Consulta el archivo [`LICENSE`](./LICENSE) para más detalles.

---

## 👨‍💻 Autor

Proyecto desarrollado por **Carlos Julio Wilches**
Parte del ecosistema tecnológico del sistema **Reminicence**.

