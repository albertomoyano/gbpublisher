-- ═══════════════════════════════════════════════════════════
-- GBPUBLISHER — MIGRACIÓN TABLAS DE LIBROS
-- Fecha: 2026-06-01
--
-- PRERREQUISITO: backup ya realizado
-- CONDICIÓN: las tres tablas NO contienen datos



-- ═══════════════════════════════════════════════════════════
-- PASO 2: CREAR libros_md
-- ═══════════════════════════════════════════════════════════

CREATE TABLE `libros_md` (

  -- IDENTIFICACIÓN
  `id_libro` INT NOT NULL AUTO_INCREMENT,
  `id_proyecto` INT NOT NULL,
  `isbn_impreso` VARCHAR(17) DEFAULT NULL,
  `isbn_electronico` VARCHAR(17) DEFAULT NULL,
  `doi_libro` VARCHAR(100) DEFAULT NULL,
  `doi_prefix` VARCHAR(50) DEFAULT NULL,
  `handle_prefix` VARCHAR(100) DEFAULT NULL,

  -- TÍTULO
  `titulo_libro` VARCHAR(500) NOT NULL,
  `subtitulo` VARCHAR(500) DEFAULT NULL,
  `titulo_abreviado` VARCHAR(200) DEFAULT NULL,
  `titulo_original` VARCHAR(500) DEFAULT NULL,
  `idioma_titulo_original` VARCHAR(10) DEFAULT NULL,

  -- TIPO, EDICIÓN Y FORMATO
  `tipo_libro` ENUM(
    'monografia',
    'obra_colectiva',
    'compilacion',
    'traduccion',
    'referencia',
    'manual',
    'actas'
  ) DEFAULT 'monografia',
  `edicion` VARCHAR(50) DEFAULT NULL,
  `numero_edicion` INT DEFAULT NULL,
  `numero_paginas` INT DEFAULT NULL,

  -- PUBLICACIÓN
  `ano_publicacion` YEAR DEFAULT NULL,
  `mes_publicacion` VARCHAR(20) DEFAULT NULL,
  `fecha_publicacion_completa` DATE DEFAULT NULL,
  `idioma_principal` VARCHAR(10) DEFAULT 'es',
  `idiomas_publicacion` VARCHAR(200) DEFAULT NULL,
  `estado_publicacion` ENUM(
    'en_preparacion',
    'publicado',
    'agotado',
    'descatalogado'
  ) DEFAULT 'en_preparacion',

  -- EDITORIAL
  `editorial` VARCHAR(300) DEFAULT NULL,
  `institucion_editora` VARCHAR(300) DEFAULT NULL,
  `ror_editorial` VARCHAR(50) DEFAULT NULL,
  `ciudad_publicacion` VARCHAR(200) DEFAULT NULL,
  `pais_publicacion` VARCHAR(100) DEFAULT NULL,
  `direccion_editorial` TEXT DEFAULT NULL,
  `email_editorial` VARCHAR(200) DEFAULT NULL,

  -- COLECCIÓN / SERIE
  `nombre_coleccion` VARCHAR(500) DEFAULT NULL,
  `issn_coleccion` VARCHAR(9) DEFAULT NULL,
  `numero_en_coleccion` VARCHAR(20) DEFAULT NULL,

  -- CLASIFICACIÓN TEMÁTICA
  `area_conocimiento` VARCHAR(200) DEFAULT NULL,
  `disciplina` VARCHAR(200) DEFAULT NULL,
  `subdisciplina` TEXT DEFAULT NULL,
  `palabras_clave_libro` TEXT DEFAULT NULL,
  `clasificacion_unesco` VARCHAR(50) DEFAULT NULL,
  `clasificacion_oecd` VARCHAR(50) DEFAULT NULL,

  -- ACCESO Y LICENCIA
  `tipo_acceso` ENUM(
    'abierto',
    'venta',
    'mixto',
    'embargado'
  ) DEFAULT 'abierto',
  `licencia_defecto` VARCHAR(100) DEFAULT NULL,
  `url_licencia` VARCHAR(500) DEFAULT NULL,
  `politica_acceso_abierto` TEXT DEFAULT NULL,
  `periodo_embargo` INT DEFAULT NULL,

  -- URLs Y REPOSITORIOS
  `url_libro` VARCHAR(500) DEFAULT NULL,
  `url_oai_pmh` VARCHAR(500) DEFAULT NULL,
  `url_logo` VARCHAR(500) DEFAULT NULL,
  `imagen_tapa` VARCHAR(255) DEFAULT NULL,
  `repositorio_produccion_url` VARCHAR(500) DEFAULT NULL,
  `repositorio_produccion_plataforma` VARCHAR(100) DEFAULT NULL,
  `repositorio_produccion_tipo` VARCHAR(100) DEFAULT NULL,
  `repositorio_produccion_privado` TINYINT(1) DEFAULT 1,
  `sistema_gestion_contenidos` VARCHAR(200) DEFAULT NULL,
  `repositorio_preservacion_url` VARCHAR(500) DEFAULT NULL,
  `repositorio_preservacion_plataforma` VARCHAR(100) DEFAULT NULL,

  -- INDEXACIÓN
  `indexado_en` TEXT DEFAULT NULL,
  `identificador_scielo` VARCHAR(50) DEFAULT NULL,

  -- RESUMEN Y DESCRIPCIÓN
  `resumen_libro` TEXT DEFAULT NULL,
  `resumen_traducido` TEXT DEFAULT NULL,
  `idioma_resumen_traducido` VARCHAR(10) DEFAULT NULL,
  `descripcion_libro` TEXT DEFAULT NULL,
  `objetivos_alcance` TEXT DEFAULT NULL,

  -- PRODUCCIÓN
  `estilo_cita` VARCHAR(100) DEFAULT NULL,

  -- AUDITORÍA
  `fecha_creacion` DATETIME DEFAULT CURRENT_TIMESTAMP,
  `fecha_actualizacion` TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    ON UPDATE CURRENT_TIMESTAMP,
  `usuario_creacion` VARCHAR(100) DEFAULT NULL,
  `notas_internas` TEXT DEFAULT NULL,

  -- CLAVES E ÍNDICES
  PRIMARY KEY (`id_libro`),
  UNIQUE KEY `uk_proyecto` (`id_proyecto`),
  INDEX `idx_isbn` (`isbn_impreso`),
  INDEX `idx_titulo` (`titulo_libro`),
  INDEX `idx_doi` (`doi_libro`),

  -- FOREIGN KEYS
  CONSTRAINT `libros_md_fk_proyecto`
    FOREIGN KEY (`id_proyecto`)
    REFERENCES `proyectos` (`id`)
    ON DELETE RESTRICT ON UPDATE CASCADE

) ENGINE=InnoDB
  DEFAULT CHARSET=utf8mb4
  COLLATE=utf8mb4_unicode_ci;


-- ═══════════════════════════════════════════════════════════
-- PASO 3: CREAR capitulos
-- ═══════════════════════════════════════════════════════════

CREATE TABLE `capitulos` (

  -- IDENTIFICACIÓN
  `id_capitulo` INT NOT NULL AUTO_INCREMENT,
  `id_proyecto` INT NOT NULL,
  `id_libro` INT NOT NULL,
  `nombre_archivo` VARCHAR(300) DEFAULT NULL,

  -- ESTRUCTURA DEL LIBRO
  -- El orden se resuelve por prefijo de nombre_archivo:
  --   fm-NN-*.md (front-matter)
  --   a-NN-*.md  (body / mainmatter)
  --   bm-NN-*.md (back-matter)
  `numero_capitulo` VARCHAR(20) DEFAULT NULL,
  `tipo_capitulo` ENUM(
    'prologo',
    'prefacio',
    'introduccion',
    'capitulo',
    'epilogo',
    'posfacio',
    'apendice',
    'glosario',
    'agradecimientos',
    'dedicatoria',
    'sobre_autores',
    'colofon'
  ) DEFAULT 'capitulo',
  `seccion_libro` VARCHAR(200) DEFAULT NULL,

  -- TÍTULO
  `titulo_capitulo` VARCHAR(500) NOT NULL,
  `subtitulo` VARCHAR(500) DEFAULT NULL,
  `titulo_corto` VARCHAR(200) DEFAULT NULL,
  `titulo_traducido` TEXT DEFAULT NULL,
  `idioma_titulo_traducido` VARCHAR(10) DEFAULT NULL,

  -- IDENTIFICADORES
  `doi` VARCHAR(100) DEFAULT NULL,
  `crossref_estado` ENUM(
    'pendiente',
    'sandbox',
    'produccion'
  ) DEFAULT NULL,
  `crossref_fecha_deposito` DATETIME DEFAULT NULL,
  `elocation_id` VARCHAR(50) DEFAULT NULL,

  -- PAGINACIÓN
  `pagina_inicio` VARCHAR(20) DEFAULT NULL,
  `pagina_fin` VARCHAR(20) DEFAULT NULL,
  `numero_paginas` INT DEFAULT NULL,

  -- PUBLICACIÓN E IDIOMA
  `idioma_capitulo` VARCHAR(10) DEFAULT NULL,
  `fecha_publicacion_online` DATE DEFAULT NULL,

  -- FECHAS EDITORIALES
  `fecha_recepcion` DATE DEFAULT NULL,
  `fecha_aceptacion` DATE DEFAULT NULL,
  `fecha_revision` DATE DEFAULT NULL,

  -- AUTORÍA
  `autor_correspondencia` INT DEFAULT NULL,
  `autor_corporativo` VARCHAR(300) DEFAULT NULL,
  `autores_anonimos` TINYINT(1) DEFAULT 0,
  `grupo_autores` VARCHAR(300) DEFAULT NULL,
  `author_notes` TEXT DEFAULT NULL,

  -- RESÚMENES (hasta 3 idiomas)
  `resumen_1` TEXT DEFAULT NULL,
  `idioma_resumen_1` VARCHAR(10) DEFAULT NULL,
  `resumen_2` TEXT DEFAULT NULL,
  `idioma_resumen_2` VARCHAR(10) DEFAULT NULL,
  `resumen_3` TEXT DEFAULT NULL,
  `idioma_resumen_3` VARCHAR(10) DEFAULT NULL,

  -- PALABRAS CLAVE (hasta 3 idiomas)
  `palabras_clave_1` TEXT DEFAULT NULL,
  `idioma_kwd_1` VARCHAR(10) DEFAULT NULL,
  `palabras_clave_2` TEXT DEFAULT NULL,
  `idioma_kwd_2` VARCHAR(10) DEFAULT NULL,
  `palabras_clave_3` TEXT DEFAULT NULL,
  `idioma_kwd_3` VARCHAR(10) DEFAULT NULL,

  -- DESCRIPTORES Y CLASIFICACIÓN
  `mesh_terms` TEXT DEFAULT NULL,
  `descriptores_decs` TEXT DEFAULT NULL,
  `clasificacion_tematica` TEXT DEFAULT NULL,

  -- CONTENIDO
  `numero_figuras` INT DEFAULT NULL,
  `numero_tablas` INT DEFAULT NULL,
  `numero_ecuaciones` INT DEFAULT NULL,
  `material_suplementario` TEXT DEFAULT NULL,
  `dataset_asociado` TEXT DEFAULT NULL,

  -- FINANCIAMIENTO Y ÉTICA
  `financiamiento` TEXT DEFAULT NULL,
  `numero_proyecto` TEXT DEFAULT NULL,
  `conflictos_interes` TEXT DEFAULT NULL,
  `tiene_conflictos` TINYINT(1) DEFAULT 0,
  `funding_statement` TEXT DEFAULT NULL,
  `declaracion_etica` TEXT DEFAULT NULL,
  `consentimiento_informado` TINYINT(1) DEFAULT 0,
  `aprobacion_comite_etica` TINYINT(1) DEFAULT 0,
  `numero_aprobacion_etica` VARCHAR(100) DEFAULT NULL,
  `disponibilidad_datos` TEXT DEFAULT NULL,
  `data_availability_statement` TEXT DEFAULT NULL,

  -- LICENCIA Y ACCESO
  `licencia` VARCHAR(100) DEFAULT NULL,
  `url_licencia` VARCHAR(500) DEFAULT NULL,
  `copyright_holder` VARCHAR(300) DEFAULT NULL,
  `copyright_year` YEAR DEFAULT NULL,
  `declaracion_copyright` TEXT DEFAULT NULL,

  -- URLs
  `url_capitulo` VARCHAR(500) DEFAULT NULL,
  `url_pdf` VARCHAR(500) DEFAULT NULL,

  -- VALIDACIÓN Y CALIDAD
  `revisado_xml` TINYINT(1) DEFAULT 0,
  `validado_jats` TINYINT(1) DEFAULT 0,
  `errores_validacion` TEXT DEFAULT NULL,
  `calidad_metadatos` INT DEFAULT NULL,
  `completitud_metadatos` DECIMAL(5,2) DEFAULT NULL,

  -- ESTADO Y AUDITORÍA
  `estado_capitulo` ENUM(
    'borrador',
    'en_revision',
    'aceptado',
    'en_produccion',
    'publicado'
  ) DEFAULT 'borrador',
  `fecha_creacion_registro` DATETIME DEFAULT CURRENT_TIMESTAMP,
  `fecha_actualizacion_registro` TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    ON UPDATE CURRENT_TIMESTAMP,
  `usuario_creacion` VARCHAR(100) DEFAULT NULL,
  `responsable_edicion` VARCHAR(100) DEFAULT NULL,
  `notas_internas` TEXT DEFAULT NULL,

  -- CLAVES E ÍNDICES
  PRIMARY KEY (`id_capitulo`),
  INDEX `idx_proyecto` (`id_proyecto`),
  INDEX `idx_libro` (`id_libro`),
  INDEX `idx_nombre_archivo` (`nombre_archivo`),
  INDEX `idx_titulo` (`titulo_capitulo`),
  INDEX `idx_doi` (`doi`),
  INDEX `idx_estado` (`estado_capitulo`),

  -- FOREIGN KEYS
  CONSTRAINT `capitulos_fk_proyecto`
    FOREIGN KEY (`id_proyecto`)
    REFERENCES `proyectos` (`id`)
    ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `capitulos_fk_libro`
    FOREIGN KEY (`id_libro`)
    REFERENCES `libros_md` (`id_libro`)
    ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `capitulos_fk_autor_corresp`
    FOREIGN KEY (`autor_correspondencia`)
    REFERENCES `autores` (`id_autor`)
    ON DELETE SET NULL

) ENGINE=InnoDB
  DEFAULT CHARSET=utf8mb4
  COLLATE=utf8mb4_unicode_ci;


-- ═══════════════════════════════════════════════════════════
-- PASO 4: CREAR capitulo_autor
-- ═══════════════════════════════════════════════════════════

CREATE TABLE `capitulo_autor` (

  `id_relacion` INT NOT NULL AUTO_INCREMENT,
  `id_capitulo` INT NOT NULL,
  `id_autor` INT NOT NULL,
  `orden_autoria` INT NOT NULL,
  `rol_autor` ENUM(
    'autor',
    'coautor',
    'autor_correspondencia',
    'editor',
    'revisor',
    'traductor',
    'ilustrador'
  ) DEFAULT 'autor',
  `taxonomia_credit` TEXT DEFAULT NULL,
  `es_autor_correspondencia` TINYINT(1) DEFAULT 0,
  `afiliacion_momento` TEXT DEFAULT NULL,
  `departamento_momento` VARCHAR(300) DEFAULT NULL,
  `ciudad_momento` VARCHAR(200) DEFAULT NULL,
  `pais_momento` VARCHAR(100) DEFAULT NULL,
  `ror_afiliacion_momento` VARCHAR(50) DEFAULT NULL,
  `email_momento` VARCHAR(200) DEFAULT NULL,
  `contribuciones_credit` JSON DEFAULT NULL,
  `notas_autor` TEXT DEFAULT NULL,
  `porcentaje_contribucion` INT DEFAULT NULL,
  `fecha_asignacion` DATETIME DEFAULT CURRENT_TIMESTAMP,
  `usuario_asignacion` VARCHAR(100) DEFAULT NULL,

  PRIMARY KEY (`id_relacion`),
  UNIQUE KEY `unique_capitulo_autor` (`id_capitulo`, `id_autor`),
  INDEX `idx_capitulo` (`id_capitulo`),
  INDEX `idx_autor` (`id_autor`),
  INDEX `idx_orden` (`id_capitulo`, `orden_autoria`),
  INDEX `idx_correspondencia` (`id_capitulo`, `es_autor_correspondencia`),

  -- FOREIGN KEYS
  CONSTRAINT `capitulo_autor_fk_capitulo`
    FOREIGN KEY (`id_capitulo`)
    REFERENCES `capitulos` (`id_capitulo`)
    ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `capitulo_autor_fk_autor`
    FOREIGN KEY (`id_autor`)
    REFERENCES `autores` (`id_autor`)
    ON DELETE RESTRICT ON UPDATE CASCADE

) ENGINE=InnoDB
  DEFAULT CHARSET=utf8mb4
  COLLATE=utf8mb4_unicode_ci;
