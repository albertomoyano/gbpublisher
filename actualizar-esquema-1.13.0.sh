#!/usr/bin/env bash
#
# ============================================
# Script    : actualizar-esquema-1.13.0.sh
# Propósito : Actualización 1.13.0 de la base de gbpublisher, sobre una base
#             EN USO y preservando sus datos. Esquema nuevo de revistas
#             (claude/rediseno-revistas.md, decisiones 1 a 16 y modelo
#             lógico v1):
#               1. Crea 23 tablas, en orden de dependencia: revista (N0),
#                  número (N1), artículo (N2) y sus tablas hijas.
#               2. Carga el catálogo tipo_declaracion con los dos tipos de
#                  la etapa 1 (financiamiento, conflicto_interes).
#             ES ADITIVA (decisión 16): NO TOCA revistas_md, articulos,
#             articulo_autor NI NINGUNA OTRA TABLA EXISTENTE. Las viejas se
#             retiran en el 2.0.0. No migra datos: el traspaso del único
#             usuario de revistas es puntual y va aparte.
#             Al final emite un INFORME DE CONTROL, solo de lectura.
# Uso       : sudo bash actualizar-esquema-1.13.0.sh
# Requisitos: MySQL 8.0.16 o posterior (aplica las restricciones CHECK);
#             permisos sudo.
# Reglas    : BBDD_LEEME.md §5 y SC-22. IDEMPOTENTE; respaldo verificado;
#             verificación posterior; sin efecto si ya está aplicado.
#             Exige la 1.12.0 registrada: la cadena es ordenada. Sobre esa
#             base, qué crear lo decide el ESTADO REAL.
# Criterio  : por cada tabla nueva, tres estados posibles:
#               - no existe                          -> se crea
#               - existe con las columnas esperadas  -> ya está
#               - existe con otra cantidad           -> ABORTA sin tocar nada
#             El catálogo se carga con INSERT IGNORE: una fila que ya está
#             no se pisa (su etiqueta pudo haberse pulido).
# Claves    : las tablas hijas del artículo se BORRAN EN CASCADA con su
#             artículo: no tienen sentido solas, y así el borrado de un
#             artículo es una sola sentencia. Todas las demás claves son
#             RESTRICT: revista, número, sección, dossier y autor no se
#             borran mientras algo los use. A DIFERENCIA DE LA 1.10.0, ACÁ
#             NO HAY REGISTRO HISTÓRICO QUE PRESERVAR: SON METADATOS.
#             Ninguna columna que aparece en un CHECK lleva acción
#             referencial en cascada (MySQL 8.0.46, error 3823; ver 1.10.0).
# Catálogos : idiomas, licencias, credit_roles y tipo_declaracion ALIMENTAN
#             los formularios; cada registro guarda SU VALOR, sin clave
#             foránea al catálogo (SC-23): lo publicado queda como se
#             publicó aunque el catálogo cambie.
# Lote      : en la misma entrega, m_ConexionBD.ObtenerEsquemaEsperado suma
#             las 23 tablas con sus conteos. Las tablas viejas siguen en el
#             índice hasta el 2.0.0.
# ============================================

set -euo pipefail

# --- 0. CONFIGURACIÓN ---
DB="gbpublisher"
PARCHE="actualizacion-1.13.0"
PREVIO="actualizacion-1.12.0"
DESCRIPCION="Revistas: esquema nuevo (revista, número, artículo y tablas hijas), aditivo"
DIR_RESPALDO="${HOME}/gbpublisher-respaldos"

# LAS 23 TABLAS EN ORDEN DE DEPENDENCIA, CON SU CANTIDAD DE COLUMNAS.
# LOS CONTEOS SON LOS DE hEsquema EN m_ConexionBD
TABLAS=(
  revista
  revista_plantilla_resumen
  revista_plantilla_resumen_seccion
  revista_plantilla_resumen_titulo
  revista_seccion
  revista_seccion_titulo
  revista_bloque
  numero
  numero_dossier
  numero_dossier_titulo
  numero_contribuyente
  articulo
  articulo_texto
  articulo_resumen_seccion
  articulo_palabra_clave
  articulo_contribuyente
  contribuyente_afiliacion
  contribuyente_credit
  articulo_financiamiento
  tipo_declaracion
  articulo_declaracion
  articulo_relacion
  articulo_ubicacion
)
COLUMNAS=(23 4 3 4 7 3 3 15 8 4 6 31 6 4 6 9 7 2 7 5 7 11 3)
# CLAVES FORÁNEAS Y RESTRICCIONES CHECK QUE TIENE QUE HABER AL TERMINAR
FK_ESPERADAS=30
CHECK_ESPERADAS=11

declare -A DDL

# ---------- N0 · REVISTA ----------
DDL[revista]="CREATE TABLE IF NOT EXISTS revista (
  id_revista INT NOT NULL AUTO_INCREMENT,
  titulo VARCHAR(500) NOT NULL COMMENT 'JATS journal-title',
  titulo_abreviado VARCHAR(200) NULL DEFAULT NULL COMMENT 'JATS abbrev-journal-title',
  acronimo VARCHAR(20) NULL DEFAULT NULL COMMENT 'JATS journal-id; acrónimo SciELO',
  issn_impreso VARCHAR(9) NULL DEFAULT NULL,
  issn_electronico VARCHAR(9) NULL DEFAULT NULL,
  editorial VARCHAR(300) NULL DEFAULT NULL COMMENT 'JATS publisher-name',
  institucion_editora VARCHAR(300) NULL DEFAULT NULL,
  ror_editorial VARCHAR(50) NULL DEFAULT NULL,
  ciudad VARCHAR(200) NULL DEFAULT NULL COMMENT 'JATS publisher-loc',
  pais VARCHAR(100) NULL DEFAULT NULL,
  email_editorial VARCHAR(200) NULL DEFAULT NULL COMMENT 'Depositante de Crossref',
  doi_prefix VARCHAR(50) NULL DEFAULT NULL,
  estilo_cita VARCHAR(100) NULL DEFAULT NULL COMMENT 'Identificador del catálogo cita-*-config.tex (SC-57)',
  modelo_paginacion ENUM('por_numero','por_volumen','continua') NOT NULL DEFAULT 'por_numero',
  idiomas_publicacion VARCHAR(200) NULL DEFAULT NULL COMMENT 'Códigos separados por coma (SC-23)',
  licencia_defecto VARCHAR(100) NULL DEFAULT NULL COMMENT 'Se hereda hasta publicar',
  url_licencia_defecto VARCHAR(500) NULL DEFAULT NULL COMMENT 'Se hereda hasta publicar',
  titular_copyright_defecto VARCHAR(300) NULL DEFAULT NULL COMMENT 'Se hereda hasta publicar',
  tipo_acceso_defecto ENUM('abierto','suscripcion','embargo') NULL DEFAULT NULL COMMENT 'Se hereda hasta publicar',
  fecha_creacion DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  fecha_actualizacion TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  usuario_creacion VARCHAR(100) NULL DEFAULT NULL,
  PRIMARY KEY (id_revista)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Revista: nivel permanente (N0)';"

DDL[revista_plantilla_resumen]="CREATE TABLE IF NOT EXISTS revista_plantilla_resumen (
  id_plantilla INT NOT NULL AUTO_INCREMENT,
  id_revista INT NOT NULL,
  nombre VARCHAR(100) NOT NULL COMMENT 'Por ejemplo IMRyD',
  activa TINYINT(1) NOT NULL DEFAULT 1,
  PRIMARY KEY (id_plantilla),
  UNIQUE KEY uq_plantilla_nombre (id_revista, nombre),
  CONSTRAINT fk_plantilla_revista FOREIGN KEY (id_revista) REFERENCES revista (id_revista) ON DELETE RESTRICT ON UPDATE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Plantillas de resumen estructurado de la revista';"

DDL[revista_plantilla_resumen_seccion]="CREATE TABLE IF NOT EXISTS revista_plantilla_resumen_seccion (
  id_plantilla INT NOT NULL,
  codigo VARCHAR(50) NOT NULL COMMENT 'Estable: introduccion, metodos, resultados, conclusiones...',
  orden INT NOT NULL,
  PRIMARY KEY (id_plantilla, codigo),
  UNIQUE KEY uq_plantilla_seccion_orden (id_plantilla, orden),
  CONSTRAINT fk_plantilla_seccion FOREIGN KEY (id_plantilla) REFERENCES revista_plantilla_resumen (id_plantilla) ON DELETE RESTRICT ON UPDATE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Secciones de una plantilla de resumen, en orden';"

DDL[revista_plantilla_resumen_titulo]="CREATE TABLE IF NOT EXISTS revista_plantilla_resumen_titulo (
  id_plantilla INT NOT NULL,
  codigo VARCHAR(50) NOT NULL,
  idioma VARCHAR(20) NOT NULL COMMENT 'Código BCP 47 (SC-23)',
  titulo VARCHAR(200) NOT NULL COMMENT 'Lo que se imprime: Métodos, Methods...',
  PRIMARY KEY (id_plantilla, codigo, idioma),
  CONSTRAINT fk_plantilla_titulo FOREIGN KEY (id_plantilla, codigo) REFERENCES revista_plantilla_resumen_seccion (id_plantilla, codigo) ON DELETE RESTRICT ON UPDATE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Título de cada sección de plantilla, por idioma';"

DDL[revista_seccion]="CREATE TABLE IF NOT EXISTS revista_seccion (
  id_seccion INT NOT NULL AUTO_INCREMENT,
  id_revista INT NOT NULL,
  codigo VARCHAR(50) NOT NULL COMMENT 'Único por revista',
  orden INT NOT NULL DEFAULT 0,
  article_type_defecto VARCHAR(50) NULL DEFAULT NULL COMMENT 'Código JATS que propone al crear un artículo',
  id_plantilla_resumen INT NULL DEFAULT NULL COMMENT 'Nulo: resumen simple',
  activa TINYINT(1) NOT NULL DEFAULT 1,
  PRIMARY KEY (id_seccion),
  UNIQUE KEY uq_seccion_codigo (id_revista, codigo),
  KEY fk_seccion_plantilla (id_plantilla_resumen),
  CONSTRAINT fk_seccion_revista FOREIGN KEY (id_revista) REFERENCES revista (id_revista) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT fk_seccion_plantilla FOREIGN KEY (id_plantilla_resumen) REFERENCES revista_plantilla_resumen (id_plantilla) ON DELETE RESTRICT ON UPDATE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Secciones permanentes de la revista (decisión 15)';"

DDL[revista_seccion_titulo]="CREATE TABLE IF NOT EXISTS revista_seccion_titulo (
  id_seccion INT NOT NULL,
  idioma VARCHAR(20) NOT NULL COMMENT 'Código BCP 47 (SC-23)',
  titulo VARCHAR(300) NOT NULL COMMENT 'JATS subj-group heading; sumario',
  PRIMARY KEY (id_seccion, idioma),
  CONSTRAINT fk_seccion_titulo FOREIGN KEY (id_seccion) REFERENCES revista_seccion (id_seccion) ON DELETE RESTRICT ON UPDATE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Título visible de cada sección, por idioma';"

DDL[revista_bloque]="CREATE TABLE IF NOT EXISTS revista_bloque (
  id_revista INT NOT NULL,
  bloque VARCHAR(50) NOT NULL COMMENT 'Código del bloque N3',
  nivel ENUM('desactivado','habilitado','solicitado','exigido') NOT NULL DEFAULT 'desactivado' COMMENT 'Patrón de OJS (METADATA_*)',
  PRIMARY KEY (id_revista, bloque),
  CONSTRAINT fk_bloque_revista FOREIGN KEY (id_revista) REFERENCES revista (id_revista) ON DELETE RESTRICT ON UPDATE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Activación de los bloques opcionales por revista';"

# ---------- N1 · NÚMERO ----------
# volumen, numero Y suplemento SON NOT NULL CON '' POR OMISIÓN: CON NULL LA
# CLAVE ÚNICA NO DETECTA DUPLICADOS (MySQL TRATA CADA NULL COMO DISTINTO)
DDL[numero]="CREATE TABLE IF NOT EXISTS numero (
  id_numero INT NOT NULL AUTO_INCREMENT,
  id_proyecto INT NOT NULL COMMENT 'Un número por proyecto: su carpeta',
  id_revista INT NOT NULL,
  volumen VARCHAR(20) NOT NULL DEFAULT '',
  numero VARCHAR(20) NOT NULL DEFAULT '',
  suplemento VARCHAR(20) NOT NULL DEFAULT '',
  titulo_especial VARCHAR(300) NULL DEFAULT NULL COMMENT 'Número temático completo: JATS issue-title, Crossref titles',
  anio YEAR NULL DEFAULT NULL COMMENT 'JATS pub-date date-type=collection',
  mes TINYINT NULL DEFAULT NULL,
  pagina_inicial INT NULL DEFAULT NULL COMMENT 'Solo por_volumen: dónde arranca este número',
  estado ENUM('abierto','cerrado') NOT NULL DEFAULT 'abierto',
  imagen_tapa VARCHAR(255) NULL DEFAULT NULL,
  fecha_creacion DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  fecha_actualizacion TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  usuario_creacion VARCHAR(100) NULL DEFAULT NULL,
  PRIMARY KEY (id_numero),
  UNIQUE KEY uq_numero_proyecto (id_proyecto),
  UNIQUE KEY uq_numero_identidad (id_revista, volumen, numero, suplemento),
  CONSTRAINT fk_numero_proyecto FOREIGN KEY (id_proyecto) REFERENCES proyectos (id) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT fk_numero_revista FOREIGN KEY (id_revista) REFERENCES revista (id_revista) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT chk_numero_mes CHECK (mes IS NULL OR mes BETWEEN 1 AND 12),
  CONSTRAINT chk_numero_pagina CHECK (pagina_inicial IS NULL OR pagina_inicial > 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Número de revista (N1), uno a uno con el proyecto';"

DDL[numero_dossier]="CREATE TABLE IF NOT EXISTS numero_dossier (
  id_dossier INT NOT NULL AUTO_INCREMENT,
  id_numero INT NOT NULL,
  id_seccion INT NOT NULL COMMENT 'La sección Dossier de la revista: da el encabezado',
  orden INT NOT NULL DEFAULT 0,
  epigrafe TEXT NULL COMMENT 'Opcional, como en las partes del libro',
  fecha_creacion DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  fecha_actualizacion TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  usuario_creacion VARCHAR(100) NULL DEFAULT NULL,
  PRIMARY KEY (id_dossier),
  KEY fk_dossier_numero (id_numero),
  KEY fk_dossier_seccion (id_seccion),
  CONSTRAINT fk_dossier_numero FOREIGN KEY (id_numero) REFERENCES numero (id_numero) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT fk_dossier_seccion FOREIGN KEY (id_seccion) REFERENCES revista_seccion (id_seccion) ON DELETE RESTRICT ON UPDATE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Dossier: agrupación dentro de un número (equivale a la parte del libro)';"

DDL[numero_dossier_titulo]="CREATE TABLE IF NOT EXISTS numero_dossier_titulo (
  id_dossier INT NOT NULL,
  idioma VARCHAR(20) NOT NULL COMMENT 'Código BCP 47 (SC-23)',
  titulo VARCHAR(500) NOT NULL,
  subtitulo VARCHAR(500) NULL DEFAULT NULL,
  PRIMARY KEY (id_dossier, idioma),
  CONSTRAINT fk_dossier_titulo FOREIGN KEY (id_dossier) REFERENCES numero_dossier (id_dossier) ON DELETE CASCADE ON UPDATE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Título y subtítulo del dossier, por idioma';"

DDL[numero_contribuyente]="CREATE TABLE IF NOT EXISTS numero_contribuyente (
  id INT NOT NULL AUTO_INCREMENT,
  id_numero INT NOT NULL,
  id_dossier INT NULL DEFAULT NULL COMMENT 'Nulo: editor del número completo (Crossref journal_issue)',
  id_autor INT NOT NULL,
  rol VARCHAR(50) NOT NULL DEFAULT 'editor',
  orden INT NOT NULL DEFAULT 0,
  PRIMARY KEY (id),
  KEY fk_ncontrib_numero (id_numero),
  KEY fk_ncontrib_dossier (id_dossier),
  KEY fk_ncontrib_autor (id_autor),
  CONSTRAINT fk_ncontrib_numero FOREIGN KEY (id_numero) REFERENCES numero (id_numero) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT fk_ncontrib_dossier FOREIGN KEY (id_dossier) REFERENCES numero_dossier (id_dossier) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT fk_ncontrib_autor FOREIGN KEY (id_autor) REFERENCES autores (id_autor) ON DELETE RESTRICT ON UPDATE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Editores del número o de un dossier';"

# ---------- N2 · ARTÍCULO ----------
# id_numero E id_dossier APARECEN EN UN CHECK: SUS CLAVES SON RESTRICT (3823)
DDL[articulo]="CREATE TABLE IF NOT EXISTS articulo (
  id_articulo INT NOT NULL AUTO_INCREMENT,
  id_numero INT NULL DEFAULT NULL COMMENT 'Nulo admitido: el artículo es autónomo (decisión 12)',
  id_dossier INT NULL DEFAULT NULL,
  id_seccion INT NULL DEFAULT NULL,
  nombre_archivo VARCHAR(300) NULL DEFAULT NULL COMMENT 'Código de posición: a-01... (m_OrdenPiezas)',
  article_type VARCHAR(50) NOT NULL COMMENT 'Código JATS: @article-type',
  idioma_principal VARCHAR(20) NOT NULL COMMENT 'Obligatorio (SC-23)',
  titulo VARCHAR(500) NULL DEFAULT NULL,
  subtitulo VARCHAR(500) NULL DEFAULT NULL,
  titulo_corto VARCHAR(200) NULL DEFAULT NULL COMMENT 'Opcional: solo la cabecera del PDF',
  estado ENUM('borrador','en_produccion','publicado') NOT NULL DEFAULT 'borrador' COMMENT 'Al publicar se congela la herencia (decisión 14)',
  fecha_recepcion DATE NULL DEFAULT NULL,
  fecha_revision DATE NULL DEFAULT NULL,
  fecha_aceptacion DATE NULL DEFAULT NULL,
  fecha_publicacion DATE NULL DEFAULT NULL COMMENT 'JATS pub-date date-type=pub',
  pagina_inicio VARCHAR(20) NULL DEFAULT NULL COMMENT 'La escribe Gambas con lo que devuelve la composición del número',
  pagina_fin VARCHAR(20) NULL DEFAULT NULL,
  elocation_id VARCHAR(50) NULL DEFAULT NULL COMMENT 'Solo modelo continua',
  doi VARCHAR(100) NULL DEFAULT NULL,
  pmid VARCHAR(50) NULL DEFAULT NULL,
  id_doaj VARCHAR(50) NULL DEFAULT NULL,
  autores_anonimos TINYINT(1) NOT NULL DEFAULT 0,
  notas_autor TEXT NULL COMMENT 'JATS author-notes',
  licencia VARCHAR(100) NULL DEFAULT NULL COMMENT 'Nulo: hereda de la revista hasta publicar',
  url_licencia VARCHAR(500) NULL DEFAULT NULL COMMENT 'Nulo: hereda hasta publicar',
  titular_copyright VARCHAR(300) NULL DEFAULT NULL COMMENT 'Nulo: hereda hasta publicar',
  anio_copyright YEAR NULL DEFAULT NULL COMMENT 'Nulo: el año de fecha_publicacion',
  tipo_acceso ENUM('abierto','suscripcion','embargo') NULL DEFAULT NULL COMMENT 'Nulo: hereda hasta publicar',
  fecha_creacion DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  fecha_actualizacion TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  usuario_creacion VARCHAR(100) NULL DEFAULT NULL,
  PRIMARY KEY (id_articulo),
  UNIQUE KEY uq_articulo_archivo (id_numero, nombre_archivo),
  UNIQUE KEY uq_articulo_doi (doi),
  KEY fk_articulo_dossier (id_dossier),
  KEY fk_articulo_seccion (id_seccion),
  CONSTRAINT fk_articulo_numero FOREIGN KEY (id_numero) REFERENCES numero (id_numero) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT fk_articulo_dossier FOREIGN KEY (id_dossier) REFERENCES numero_dossier (id_dossier) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT fk_articulo_seccion FOREIGN KEY (id_seccion) REFERENCES revista_seccion (id_seccion) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT chk_articulo_dossier CHECK (id_dossier IS NULL OR id_numero IS NOT NULL),
  CONSTRAINT chk_articulo_publicado CHECK (estado <> 'publicado' OR fecha_publicacion IS NOT NULL)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Artículo de revista (N2)';"

# ---------- TABLAS HIJAS DEL ARTÍCULO: CASCADA CON SU ARTÍCULO ----------
DDL[articulo_texto]="CREATE TABLE IF NOT EXISTS articulo_texto (
  id_texto INT NOT NULL AUTO_INCREMENT,
  id_articulo INT NOT NULL,
  tipo ENUM('titulo','subtitulo','resumen') NOT NULL COMMENT 'titulo y subtitulo: solo las traducciones',
  idioma VARCHAR(20) NOT NULL COMMENT 'Código BCP 47 (SC-23)',
  texto TEXT NULL COMMENT 'Nulo solo en un resumen estructurado: el texto va por sección',
  orden INT NOT NULL DEFAULT 0,
  PRIMARY KEY (id_texto),
  UNIQUE KEY uq_texto (id_articulo, tipo, idioma),
  CONSTRAINT fk_texto_articulo FOREIGN KEY (id_articulo) REFERENCES articulo (id_articulo) ON DELETE CASCADE ON UPDATE RESTRICT,
  CONSTRAINT chk_texto_contenido CHECK (tipo = 'resumen' OR texto IS NOT NULL)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Títulos traducidos y resúmenes, por idioma';"

DDL[articulo_resumen_seccion]="CREATE TABLE IF NOT EXISTS articulo_resumen_seccion (
  id_texto INT NOT NULL,
  codigo VARCHAR(50) NOT NULL COMMENT 'El de la plantilla: introduccion, metodos...',
  orden INT NOT NULL,
  texto TEXT NOT NULL,
  PRIMARY KEY (id_texto, codigo),
  CONSTRAINT fk_rsec_texto FOREIGN KEY (id_texto) REFERENCES articulo_texto (id_texto) ON DELETE CASCADE ON UPDATE RESTRICT,
  CONSTRAINT chk_rsec_texto CHECK (texto <> '')
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Secciones de un resumen estructurado';"

# vocabulario NOT NULL CON '' POR OMISIÓN ('' = DEL AUTOR): CON NULL LA CLAVE
# ÚNICA NO DETECTARÍA UNA PALABRA REPETIDA
DDL[articulo_palabra_clave]="CREATE TABLE IF NOT EXISTS articulo_palabra_clave (
  id INT NOT NULL AUTO_INCREMENT,
  id_articulo INT NOT NULL,
  idioma VARCHAR(20) NOT NULL COMMENT 'Código BCP 47 (SC-23)',
  vocabulario VARCHAR(50) NOT NULL DEFAULT '' COMMENT 'Vacío: del autor. MeSH, DeCS...',
  orden INT NOT NULL DEFAULT 0,
  termino VARCHAR(300) NOT NULL,
  PRIMARY KEY (id),
  UNIQUE KEY uq_kwd (id_articulo, idioma, vocabulario, termino),
  CONSTRAINT fk_kwd_articulo FOREIGN KEY (id_articulo) REFERENCES articulo (id_articulo) ON DELETE CASCADE ON UPDATE RESTRICT,
  CONSTRAINT chk_kwd_termino CHECK (termino <> '')
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Palabras clave por idioma y vocabulario';"

# id_autor ESTÁ EN UN CHECK: SU CLAVE ES RESTRICT. id_articulo NO: CASCADA
DDL[articulo_contribuyente]="CREATE TABLE IF NOT EXISTS articulo_contribuyente (
  id_contribuyente INT NOT NULL AUTO_INCREMENT,
  id_articulo INT NOT NULL,
  id_autor INT NULL DEFAULT NULL COMMENT 'Nulo: autoría colectiva',
  nombre_colectivo VARCHAR(300) NULL DEFAULT NULL COMMENT 'JATS collab',
  orden INT NOT NULL,
  rol ENUM('autor','editor','traductor') NOT NULL DEFAULT 'autor' COMMENT 'Se traduce a contrib-type al generar',
  correspondencia TINYINT(1) NOT NULL DEFAULT 0 COMMENT 'Fuente única del autor de correspondencia',
  email VARCHAR(200) NULL DEFAULT NULL COMMENT 'Email en este artículo',
  notas TEXT NULL,
  PRIMARY KEY (id_contribuyente),
  UNIQUE KEY uq_contrib_orden (id_articulo, orden),
  KEY fk_contrib_autor (id_autor),
  CONSTRAINT fk_contrib_articulo FOREIGN KEY (id_articulo) REFERENCES articulo (id_articulo) ON DELETE CASCADE ON UPDATE RESTRICT,
  CONSTRAINT fk_contrib_autor FOREIGN KEY (id_autor) REFERENCES autores (id_autor) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT chk_contrib_quien CHECK ((id_autor IS NULL) <> (nombre_colectivo IS NULL))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Contribuyentes del artículo, en orden';"

DDL[contribuyente_afiliacion]="CREATE TABLE IF NOT EXISTS contribuyente_afiliacion (
  id INT NOT NULL AUTO_INCREMENT,
  id_contribuyente INT NOT NULL,
  orden INT NOT NULL DEFAULT 0,
  institucion VARCHAR(500) NOT NULL,
  departamento VARCHAR(300) NULL DEFAULT NULL,
  ciudad VARCHAR(200) NULL DEFAULT NULL,
  pais VARCHAR(100) NULL DEFAULT NULL,
  PRIMARY KEY (id),
  KEY fk_afil_contrib (id_contribuyente),
  CONSTRAINT fk_afil_contrib FOREIGN KEY (id_contribuyente) REFERENCES articulo_contribuyente (id_contribuyente) ON DELETE CASCADE ON UPDATE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Afiliaciones de un contribuyente en este artículo (varias)';"

DDL[contribuyente_credit]="CREATE TABLE IF NOT EXISTS contribuyente_credit (
  id_contribuyente INT NOT NULL,
  rol_credit VARCHAR(64) NOT NULL COMMENT 'Valor de credit_roles.nombre, sin clave foránea (SC-23)',
  PRIMARY KEY (id_contribuyente, rol_credit),
  CONSTRAINT fk_credit_contrib FOREIGN KEY (id_contribuyente) REFERENCES articulo_contribuyente (id_contribuyente) ON DELETE CASCADE ON UPDATE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Roles CRediT de cada contribuyente';"

DDL[articulo_financiamiento]="CREATE TABLE IF NOT EXISTS articulo_financiamiento (
  id INT NOT NULL AUTO_INCREMENT,
  id_articulo INT NOT NULL,
  orden INT NOT NULL DEFAULT 0,
  financiador VARCHAR(500) NOT NULL COMMENT 'JATS funding-source',
  id_financiador VARCHAR(100) NULL DEFAULT NULL,
  tipo_id ENUM('ror','funder_id') NULL DEFAULT NULL,
  numero_proyecto VARCHAR(200) NULL DEFAULT NULL COMMENT 'JATS award-id',
  PRIMARY KEY (id),
  KEY fk_fin_articulo (id_articulo),
  CONSTRAINT fk_fin_articulo FOREIGN KEY (id_articulo) REFERENCES articulo (id_articulo) ON DELETE CASCADE ON UPDATE RESTRICT,
  CONSTRAINT chk_fin_id CHECK ((id_financiador IS NULL) = (tipo_id IS NULL))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Financiamiento estructurado';"

DDL[tipo_declaracion]="CREATE TABLE IF NOT EXISTS tipo_declaracion (
  codigo VARCHAR(50) NOT NULL,
  etiqueta VARCHAR(100) NOT NULL,
  bloque VARCHAR(50) NULL DEFAULT NULL COMMENT 'Nulo: núcleo. Si no, el bloque N3 que lo habilita',
  orden INT NOT NULL DEFAULT 1000,
  activo TINYINT(1) NOT NULL DEFAULT 1,
  PRIMARY KEY (codigo)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Catálogo de tipos de declaración: alimenta el formulario (SC-23)';"

DDL[articulo_declaracion]="CREATE TABLE IF NOT EXISTS articulo_declaracion (
  id INT NOT NULL AUTO_INCREMENT,
  id_articulo INT NOT NULL,
  tipo VARCHAR(50) NOT NULL COMMENT 'Código de tipo_declaracion, sin clave foránea (SC-23)',
  idioma VARCHAR(20) NOT NULL COMMENT 'Código BCP 47 (SC-23)',
  texto TEXT NOT NULL,
  identificador VARCHAR(200) NULL DEFAULT NULL COMMENT 'Número de aprobación, registro del ensayo...',
  orden INT NOT NULL DEFAULT 0,
  PRIMARY KEY (id),
  KEY fk_decl_articulo (id_articulo),
  CONSTRAINT fk_decl_articulo FOREIGN KEY (id_articulo) REFERENCES articulo (id_articulo) ON DELETE CASCADE ON UPDATE RESTRICT,
  CONSTRAINT chk_decl_texto CHECK (texto <> '')
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Declaraciones: financiamiento, conflicto de interés y bloques N3';"

# id_articulo_local ESTÁ EN UN CHECK: SU CLAVE ES RESTRICT
DDL[articulo_relacion]="CREATE TABLE IF NOT EXISTS articulo_relacion (
  id INT NOT NULL AUTO_INCREMENT,
  id_articulo INT NOT NULL,
  tipo VARCHAR(50) NOT NULL COMMENT 'Código JATS related-article-type',
  id_articulo_local INT NULL DEFAULT NULL COMMENT 'Nulo: artículo externo',
  doi VARCHAR(100) NULL DEFAULT NULL,
  revista VARCHAR(500) NULL DEFAULT NULL,
  anio YEAR NULL DEFAULT NULL,
  volumen VARCHAR(20) NULL DEFAULT NULL,
  numero VARCHAR(20) NULL DEFAULT NULL,
  fpage VARCHAR(20) NULL DEFAULT NULL,
  lpage VARCHAR(20) NULL DEFAULT NULL,
  PRIMARY KEY (id),
  KEY fk_rel_articulo (id_articulo),
  KEY fk_rel_local (id_articulo_local),
  CONSTRAINT fk_rel_articulo FOREIGN KEY (id_articulo) REFERENCES articulo (id_articulo) ON DELETE CASCADE ON UPDATE RESTRICT,
  CONSTRAINT fk_rel_local FOREIGN KEY (id_articulo_local) REFERENCES articulo (id_articulo) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT chk_rel_destino CHECK (id_articulo_local IS NOT NULL OR doi IS NOT NULL OR revista IS NOT NULL)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Relaciones: corrección, retractación, comentario...';"

DDL[articulo_ubicacion]="CREATE TABLE IF NOT EXISTS articulo_ubicacion (
  id_articulo INT NOT NULL,
  tipo ENUM('pagina','html','pdf','epub','xml') NOT NULL,
  url VARCHAR(500) NOT NULL COMMENT 'Carga manual: el HTML puede alojarse fuera de OJS',
  PRIMARY KEY (id_articulo, tipo),
  CONSTRAINT fk_ubic_articulo FOREIGN KEY (id_articulo) REFERENCES articulo (id_articulo) ON DELETE CASCADE ON UPDATE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='URL de cada salida publicada';"

# EL CATÁLOGO DE LA ETAPA 1. LOS TIPOS DEL BLOQUE BIOMÉDICO ENTRAN EN LA
# ETAPA 4 CON SU PROPIA ACTUALIZACIÓN
SEMILLA_DECLARACION="INSERT IGNORE INTO tipo_declaracion (codigo, etiqueta, bloque, orden) VALUES
  ('financiamiento', 'Declaración de financiamiento', NULL, 10),
  ('conflicto_interes', 'Conflicto de intereses', NULL, 20);"
SEMILLA_FILAS=2

if [ -t 1 ]; then
  ROJO=$'\e[0;31m'; VERDE=$'\e[0;32m'; AMBAR=$'\e[0;33m'
  AZUL=$'\e[0;34m'; NEGRITA=$'\e[1m'; RESET=$'\e[0m'
else
  ROJO=""; VERDE=""; AMBAR=""; AZUL=""; NEGRITA=""; RESET=""
fi

info()  { echo "${AZUL}➜${RESET} $*"; }
ok()    { echo "${VERDE}✔${RESET} $*"; }
warn()  { echo "${AMBAR}⚠${RESET} $*"; }
error() { echo "${ROJO}✖${RESET} $*" >&2; }

if [ "$(id -u)" -eq 0 ]; then SUDO=""; else SUDO="sudo"; fi

mysql_adm() {
  $SUDO mysql --default-character-set=utf8mb4 "$@"
}

# -r (raw): SIN ÉL, EL MODO -B DUPLICA LAS BARRAS DE UN VALOR CON APÓSTROFO
valor() {
  mysql_adm -N -B -r -e "$1"
}

columnas_de() {
  valor "SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA='${DB}' AND TABLE_NAME='$1';"
}

# LA LISTA DE TABLAS NUEVAS COMO LITERAL SQL, PARA LA VERIFICACIÓN
lista_sql() {
  local T S=""
  for T in "${TABLAS[@]}"; do S="${S:+${S},}'${T}'"; done
  echo "$S"
}

# --- 1. BIENVENIDA ---
echo
echo "${NEGRITA}Actualización del esquema de gbpublisher a 1.13.0${RESET}"
echo "--------------------------------------------------"
echo "Crea las tablas del esquema nuevo de revistas (revista, número, artículo y sus tablas hijas)."
echo "Es aditiva: no modifica ni borra ninguna tabla existente y no toca datos."
echo

# --- 2. VERIFICACIONES PREVIAS ---
if ! command -v mysql >/dev/null 2>&1 || ! command -v mysqldump >/dev/null 2>&1; then
  error "Faltan los clientes mysql o mysqldump."
  exit 1
fi

if [ -n "$SUDO" ] && ! sudo -v; then
  error "No se pudieron obtener permisos de administrador (sudo)."
  exit 1
fi

if ! mysql_adm -e "SELECT 1;" >/dev/null 2>&1; then
  error "No se pudo conectar al servidor con la cuenta administrativa."
  exit 1
fi

if [ "$(valor "SELECT COUNT(*) FROM information_schema.SCHEMATA WHERE SCHEMA_NAME='${DB}';")" != "1" ]; then
  error "No existe la base '${DB}'."
  exit 1
fi

if [ "$(valor "SELECT COUNT(*) FROM information_schema.TABLES WHERE TABLE_SCHEMA='${DB}' AND TABLE_NAME='esquema_version';")" != "1" ]; then
  error "La base no tiene la tabla esquema_version: no parece instalada desde un baseline."
  exit 1
fi

# LAS DOS TABLAS EXISTENTES DE LAS QUE DEPENDEN LAS NUEVAS
for T in proyectos autores; do
  if [ "$(valor "SELECT COUNT(*) FROM information_schema.TABLES WHERE TABLE_SCHEMA='${DB}' AND TABLE_NAME='${T}';")" != "1" ]; then
    error "No existe la tabla ${T}."
    exit 1
  fi
done

# LAS RESTRICCIONES CHECK SE APLICAN DESDE MySQL 8.0.16; ANTES SE ACEPTAN Y
# SE IGNORAN EN SILENCIO
VERSION="$(valor "SELECT VERSION();")"
if [ "$(valor "SELECT (CAST(SUBSTRING_INDEX(VERSION(), '.', 1) AS UNSIGNED) * 10000 + CAST(SUBSTRING_INDEX(SUBSTRING_INDEX(VERSION(), '.', 2), '.', -1) AS UNSIGNED) * 100 + CAST(SUBSTRING_INDEX(SUBSTRING_INDEX(SUBSTRING_INDEX(VERSION(), '-', 1), '.', 3), '.', -1) AS UNSIGNED)) >= 80016;")" != "1" ]; then
  error "El servidor es ${VERSION}: hace falta MySQL 8.0.16 o posterior para las restricciones CHECK."
  exit 1
fi

NIVEL="$(valor "SELECT GROUP_CONCAT(parche ORDER BY aplicado_en SEPARATOR ', ') FROM \`${DB}\`.esquema_version;")"
info "Servidor: ${VERSION}"
info "Nivel registrado: ${NIVEL}"

# LA CADENA ES ORDENADA: 1.13.0 VA SOBRE 1.12.0
if [ "$(valor "SELECT COUNT(*) FROM \`${DB}\`.esquema_version WHERE parche='${PREVIO}';")" != "1" ]; then
  error "Falta la actualización 1.12.0. Aplicala primero (actualizar-esquema-1.12.0.sh)."
  exit 1
fi

# --- 3. ESTADO REAL ---
# SE DECIDE POR information_schema, NUNCA POR LAS FILAS DE esquema_version
A_CREAR=()
for i in "${!TABLAS[@]}"; do
  T="${TABLAS[$i]}"
  N="$(columnas_de "$T")"
  if [ "$N" = "0" ]; then
    A_CREAR+=("$T")
  elif [ "$N" != "${COLUMNAS[$i]}" ]; then
    # UNA TABLA CON OTRA FORMA ES UNA INTERVENCIÓN MANUAL: NO SE PISA
    error "La tabla ${T} existe con ${N} columnas (se esperaban ${COLUMNAS[$i]})."
    error "Revisala a mano antes de volver a correr el script. No se modificó nada."
    exit 1
  fi
done

# EL CATÁLOGO: SE CARGA SI FALTA ALGUNA DE SUS FILAS
SEMBRAR=1
if [ "$(columnas_de tipo_declaracion)" != "0" ]; then
  if [ "$(valor "SELECT COUNT(*) FROM \`${DB}\`.tipo_declaracion WHERE codigo IN ('financiamiento','conflicto_interes');")" = "${SEMILLA_FILAS}" ]; then
    SEMBRAR=0
  fi
fi

if [ "${#A_CREAR[@]}" -eq 0 ] && [ "$SEMBRAR" -eq 0 ]; then
  ok "No hay nada que crear ni cargar."
  SOLO_INFORME=1
else
  SOLO_INFORME=0
  if [ "${#A_CREAR[@]}" -gt 0 ]; then
    info "Tablas a crear (${#A_CREAR[@]}): ${A_CREAR[*]}"
  fi
  if [ "$SEMBRAR" -eq 1 ]; then
    info "Se carga el catálogo tipo_declaracion (financiamiento, conflicto_interes)."
  fi
  echo

  read -r -p "Para continuar, escribí SI en mayúsculas: " RESPUESTA
  if [ "$RESPUESTA" != "SI" ]; then
    warn "Cancelado. No se modificó nada."
    exit 0
  fi
fi

if [ "$SOLO_INFORME" -eq 0 ]; then

  # --- 4. RESPALDO PREVIO VERIFICADO ---
  mkdir -p "$DIR_RESPALDO"
  RESPALDO="${DIR_RESPALDO}/gbpublisher-antes-1.13.0-$(date '+%Y%m%d-%H%M%S').sql"
  info "Respaldo en ${RESPALDO}"

  $SUDO mysqldump --single-transaction --routines --triggers --events \
    --default-character-set=utf8mb4 "$DB" > "$RESPALDO"

  if [ ! -s "$RESPALDO" ]; then
    error "El respaldo quedó vacío. No se modificó nada."
    exit 1
  fi
  if ! tail -n 1 "$RESPALDO" | grep -q "Dump completed"; then
    error "El respaldo no terminó completo (falta la marca final). No se modificó nada."
    exit 1
  fi
  # LAS TABLAS TESTIGO SON LAS DOS DE LAS QUE DEPENDEN LAS NUEVAS
  if ! grep -q "CREATE TABLE \`proyectos\`" "$RESPALDO" || ! grep -q "CREATE TABLE \`autores\`" "$RESPALDO"; then
    error "El respaldo no contiene las tablas proyectos y autores. No se modificó nada."
    exit 1
  fi
  ok "Respaldo verificado ($(du -h "$RESPALDO" | cut -f1))."

  # --- 5. CREACIÓN DE LAS TABLAS QUE FALTAN ---
  # EN ORDEN DE DEPENDENCIA. CADA CREATE ES UN COMMIT IMPLÍCITO DE MySQL: SI
  # SE CORTA A MITAD, LA CORRIDA SIGUIENTE CREA SOLO LAS QUE FALTAN
  for T in "${A_CREAR[@]}"; do
    mysql_adm "$DB" -e "${DDL[$T]}"
    ok "Creada ${T}."
  done

  # --- 6. CATÁLOGO ---
  if [ "$SEMBRAR" -eq 1 ]; then
    mysql_adm "$DB" -e "${SEMILLA_DECLARACION}"
    ok "Catálogo tipo_declaracion cargado."
  fi

  # --- 7. VERIFICACIÓN POSTERIOR ---
  FALLA=0
  for i in "${!TABLAS[@]}"; do
    N="$(columnas_de "${TABLAS[$i]}")"
    if [ "$N" != "${COLUMNAS[$i]}" ]; then
      error "La tabla ${TABLAS[$i]} tiene ${N} columnas (se esperaban ${COLUMNAS[$i]})."
      FALLA=1
    fi
  done

  LISTA_SQL="$(lista_sql)"
  FK="$(valor "SELECT COUNT(*) FROM information_schema.REFERENTIAL_CONSTRAINTS WHERE CONSTRAINT_SCHEMA='${DB}' AND TABLE_NAME IN (${LISTA_SQL});")"
  if [ "$FK" != "$FK_ESPERADAS" ]; then
    error "Hay ${FK} claves foráneas en las tablas nuevas (se esperaban ${FK_ESPERADAS})."
    FALLA=1
  fi
  CHK="$(valor "SELECT COUNT(*) FROM information_schema.TABLE_CONSTRAINTS WHERE CONSTRAINT_SCHEMA='${DB}' AND CONSTRAINT_TYPE='CHECK' AND TABLE_NAME IN (${LISTA_SQL});")"
  if [ "$CHK" != "$CHECK_ESPERADAS" ]; then
    error "Hay ${CHK} restricciones CHECK en las tablas nuevas (se esperaban ${CHECK_ESPERADAS})."
    FALLA=1
  fi
  SEM="$(valor "SELECT COUNT(*) FROM \`${DB}\`.tipo_declaracion WHERE codigo IN ('financiamiento','conflicto_interes');")"
  if [ "$SEM" != "$SEMILLA_FILAS" ]; then
    error "El catálogo tipo_declaracion tiene ${SEM} de sus ${SEMILLA_FILAS} filas."
    FALLA=1
  fi

  if [ "$FALLA" -ne 0 ]; then
    error "NO se registra la actualización."
    # SIN innodb_strict_mode=0 LA RESTAURACIÓN FALLA EN articulos (GV-67)
    error "Para volver atrás: sudo mysql --init-command=\"SET SESSION innodb_strict_mode=0\" ${DB} < ${RESPALDO}"
    exit 1
  fi
  ok "Verificación correcta: ${#TABLAS[@]} tablas, ${FK} claves foráneas y ${CHK} restricciones CHECK."

  # --- 8. REGISTRO ---
  mysql_adm "$DB" -e "INSERT IGNORE INTO esquema_version (parche, descripcion) VALUES ('${PARCHE}', '${DESCRIPCION}');"
  ok "Registrado en esquema_version como ${PARCHE}."
  info "Para volver atrás: sudo mysql --init-command=\"SET SESSION innodb_strict_mode=0\" ${DB} < ${RESPALDO}"

else
  # YA ESTABA: SE REGISTRA PARA QUE EL NIVEL DECLARADO REFLEJE EL ESTADO REAL
  if [ "$(valor "SELECT COUNT(*) FROM \`${DB}\`.esquema_version WHERE parche='${PARCHE}';")" = "0" ]; then
    mysql_adm "$DB" -e "INSERT INTO esquema_version (parche, descripcion) VALUES ('${PARCHE}', '${DESCRIPCION}');"
    ok "Las tablas ya estaban; registrado en esquema_version como ${PARCHE}."
  fi
fi

# --- 9. INFORME DE CONTROL (SOLO LECTURA) ---
echo
info "Informe de control: esquema nuevo de revistas"
mysql_adm "$DB" -e "SELECT
  (SELECT COUNT(*) FROM revista) AS revistas,
  (SELECT COUNT(*) FROM numero) AS numeros,
  (SELECT COUNT(*) FROM articulo) AS articulos_nuevos,
  (SELECT COUNT(*) FROM tipo_declaracion) AS tipos_declaracion,
  (SELECT COUNT(*) FROM revistas_md) AS revistas_md_viejas,
  (SELECT COUNT(*) FROM articulos) AS articulos_viejos;"
echo "Las tablas viejas de revistas siguen intactas: su retiro va en el 2.0.0."
echo "El informe no modifica nada."
echo
ok "${NEGRITA}Actualización 1.13.0 lista.${RESET}"
