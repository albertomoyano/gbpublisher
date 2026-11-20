-- ==============================================================================
-- gbpublisher — Base de datos de distribución
-- Baseline: 2.0.0
-- Generado: 2026-11-20 20:40:51 por generar-baseline.sh
--
-- Este archivo crea la base gbpublisher completa y lista para usar.
-- Contiene la estructura de todas las tablas y los datos semilla de la
-- aplicación. No contiene datos editoriales de ninguna instalación.
--
-- Instalación:
--   mysql -u root -p < gbpublisher-baseline-2.0.0.sql
--
-- Después de restaurar hay que crear el usuario de aplicación. Ver el
-- capítulo de despliegue en la documentación.
--
-- El nivel de esquema queda declarado en la tabla esquema_version. Los
-- parches posteriores consultan esa tabla para decidir si corresponde
-- aplicarse.
-- ==============================================================================

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!50503 SET NAMES utf8mb4 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;

-- Este baseline carga con innodb_strict_mode activo (el default de
-- MySQL 8): la tabla que lo hacía fallar con el error 1118 (articulos,
-- 220 columnas) se retiró en la 1.32.0 y la más ancha que quedaba
-- (bibtex, 110) pasó a pares campo/valor en la 2.0.0 (GV-67).

CREATE DATABASE IF NOT EXISTS `gbpublisher`
  DEFAULT CHARACTER SET utf8mb4
  DEFAULT COLLATE utf8mb4_unicode_ci;
USE `gbpublisher`;

-- ------------------------------------------------------------------
-- 1. ESTRUCTURA
-- ------------------------------------------------------------------
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `api_credenciales` (
  `id` int unsigned NOT NULL AUTO_INCREMENT,
  `proveedor` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `api_key_enc` text CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `identificador` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `region` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `comentarios` text CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci,
  `date_create` datetime NOT NULL,
  `date_modif` datetime NOT NULL,
  `activo` tinyint(1) NOT NULL DEFAULT '1',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_proveedor` (`proveedor`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `articulo` (
  `id_articulo` int NOT NULL AUTO_INCREMENT,
  `id_numero` int DEFAULT NULL COMMENT 'Nulo admitido: el artículo es autónomo (decisión 12)',
  `id_dossier` int DEFAULT NULL,
  `id_seccion` int DEFAULT NULL,
  `nombre_archivo` varchar(300) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'Código de posición: a-01... (m_OrdenPiezas)',
  `article_type` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT 'Código JATS: @article-type',
  `idioma_principal` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT 'Obligatorio (SC-23)',
  `titulo` varchar(500) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `subtitulo` varchar(500) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `titulo_corto` varchar(200) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'Opcional: solo la cabecera del PDF',
  `estado` enum('borrador','en_produccion','publicado') CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'borrador' COMMENT 'Al publicar se congela la herencia (decisión 14)',
  `fecha_recepcion` date DEFAULT NULL,
  `fecha_revision` date DEFAULT NULL,
  `fecha_aceptacion` date DEFAULT NULL,
  `fecha_publicacion` date DEFAULT NULL COMMENT 'JATS pub-date date-type=pub',
  `pagina_inicio` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'La escribe Gambas con lo que devuelve la composición del número',
  `pagina_fin` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `elocation_id` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'Solo modelo continua: e + año + 3 cifras (e2026001). Lo genera Gambas y se congela al publicar',
  `doi` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `pmid` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `autores_anonimos` tinyint(1) NOT NULL DEFAULT '0',
  `notas_autor` text CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci COMMENT 'JATS author-notes',
  `licencia` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'Nulo: hereda de la revista hasta publicar',
  `url_licencia` varchar(500) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'Nulo: hereda hasta publicar',
  `licencia_texto` text CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci COMMENT 'Texto de la licencia en el idioma del artículo, congelado al publicar; NULL: solo la etiqueta (1.29.0)',
  `titular_copyright` varchar(300) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'Nulo: hereda hasta publicar',
  `anio_copyright` year DEFAULT NULL COMMENT 'Nulo: el año de fecha_publicacion',
  `tipo_acceso` enum('abierto','suscripcion','embargo') CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'Nulo: hereda hasta publicar',
  `fecha_creacion` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `fecha_actualizacion` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `usuario_creacion` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  PRIMARY KEY (`id_articulo`),
  UNIQUE KEY `uq_articulo_archivo` (`id_numero`,`nombre_archivo`),
  UNIQUE KEY `uq_articulo_doi` (`doi`),
  KEY `fk_articulo_dossier` (`id_dossier`),
  KEY `fk_articulo_seccion` (`id_seccion`),
  CONSTRAINT `fk_articulo_dossier` FOREIGN KEY (`id_dossier`) REFERENCES `numero_dossier` (`id_dossier`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `fk_articulo_numero` FOREIGN KEY (`id_numero`) REFERENCES `numero` (`id_numero`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `fk_articulo_seccion` FOREIGN KEY (`id_seccion`) REFERENCES `revista_seccion` (`id_seccion`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `chk_articulo_dossier` CHECK (((`id_dossier` is null) or (`id_numero` is not null))),
  CONSTRAINT `chk_articulo_publicado` CHECK (((`estado` <> _utf8mb4'publicado') or (`fecha_publicacion` is not null)))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Artículo de revista (N2)' ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `articulo_contribuyente` (
  `id_contribuyente` int NOT NULL AUTO_INCREMENT,
  `id_articulo` int NOT NULL,
  `id_autor` int DEFAULT NULL COMMENT 'Nulo: autoría colectiva',
  `nombre_colectivo` varchar(300) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'JATS collab',
  `orden` int NOT NULL,
  `rol` enum('autor','editor','traductor') CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'autor' COMMENT 'Se traduce a contrib-type al generar',
  `correspondencia` tinyint(1) NOT NULL DEFAULT '0' COMMENT 'Fuente única del autor de correspondencia',
  `email` varchar(200) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'Email en este artículo',
  `notas` text CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci,
  PRIMARY KEY (`id_contribuyente`),
  UNIQUE KEY `uq_contrib_orden` (`id_articulo`,`orden`),
  KEY `fk_contrib_autor` (`id_autor`),
  CONSTRAINT `fk_contrib_articulo` FOREIGN KEY (`id_articulo`) REFERENCES `articulo` (`id_articulo`) ON DELETE CASCADE ON UPDATE RESTRICT,
  CONSTRAINT `fk_contrib_autor` FOREIGN KEY (`id_autor`) REFERENCES `autores` (`id_autor`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `chk_contrib_quien` CHECK (((`id_autor` is null) <> (`nombre_colectivo` is null)))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Contribuyentes del artículo, en orden' ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `articulo_declaracion` (
  `id` int NOT NULL AUTO_INCREMENT,
  `id_articulo` int NOT NULL,
  `tipo` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT 'Código de tipo_declaracion, sin clave foránea (SC-23)',
  `idioma` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT 'Código BCP 47 (SC-23)',
  `texto` text CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `identificador` varchar(200) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'Número de aprobación, registro del ensayo...',
  `orden` int NOT NULL DEFAULT '0',
  PRIMARY KEY (`id`),
  KEY `fk_decl_articulo` (`id_articulo`),
  CONSTRAINT `fk_decl_articulo` FOREIGN KEY (`id_articulo`) REFERENCES `articulo` (`id_articulo`) ON DELETE CASCADE ON UPDATE RESTRICT,
  CONSTRAINT `chk_decl_texto` CHECK ((`texto` <> _utf8mb4''))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Declaraciones: financiamiento, conflicto de interés y bloques N3' ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `articulo_financiamiento` (
  `id` int NOT NULL AUTO_INCREMENT,
  `id_articulo` int NOT NULL,
  `orden` int NOT NULL DEFAULT '0',
  `financiador` varchar(500) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT 'JATS funding-source',
  `id_financiador` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `tipo_id` enum('ror','funder_id') CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `numero_proyecto` varchar(200) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'JATS award-id',
  PRIMARY KEY (`id`),
  KEY `fk_fin_articulo` (`id_articulo`),
  CONSTRAINT `fk_fin_articulo` FOREIGN KEY (`id_articulo`) REFERENCES `articulo` (`id_articulo`) ON DELETE CASCADE ON UPDATE RESTRICT,
  CONSTRAINT `chk_fin_id` CHECK (((`id_financiador` is null) = (`tipo_id` is null)))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Financiamiento estructurado' ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `articulo_palabra_clave` (
  `id` int NOT NULL AUTO_INCREMENT,
  `id_articulo` int NOT NULL,
  `idioma` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT 'Código BCP 47 (SC-23)',
  `vocabulario` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'NULL: del autor. MeSH, DeCS...',
  `orden` int NOT NULL DEFAULT '0',
  `termino` varchar(300) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_as_ci NOT NULL,
  `identificador` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'Copia del catálogo (SC-23); solo vocabulario controlado',
  `clave_vocabulario` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci GENERATED ALWAYS AS (ifnull(`vocabulario`,_utf8mb4'')) STORED COMMENT 'Para la clave única: NULL cuenta como vacío',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_kwd` (`id_articulo`,`idioma`,`clave_vocabulario`,`termino`),
  CONSTRAINT `fk_kwd_articulo` FOREIGN KEY (`id_articulo`) REFERENCES `articulo` (`id_articulo`) ON DELETE CASCADE ON UPDATE RESTRICT,
  CONSTRAINT `chk_kwd_identificador` CHECK ((`identificador` <> _utf8mb4'')),
  CONSTRAINT `chk_kwd_termino` CHECK ((`termino` <> _utf8mb4'')),
  CONSTRAINT `chk_kwd_vocabulario` CHECK ((`vocabulario` <> _utf8mb4''))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Palabras clave por idioma y vocabulario' ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `articulo_reapertura` (
  `id_reapertura` int NOT NULL AUTO_INCREMENT,
  `id_articulo` int NOT NULL,
  `fecha` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `usuario` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT 'El administrador que reabrió (FSysAdmin)',
  `motivo` text CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  PRIMARY KEY (`id_reapertura`),
  KEY `fk_reap_articulo` (`id_articulo`),
  CONSTRAINT `fk_reap_articulo` FOREIGN KEY (`id_articulo`) REFERENCES `articulo` (`id_articulo`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `chk_reap_motivo` CHECK ((`motivo` <> _utf8mb4'')),
  CONSTRAINT `chk_reap_usuario` CHECK ((`usuario` <> _utf8mb4''))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Reaperturas de artículos publicados: solo de altas' ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_unicode_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 */ /*!50003 TRIGGER `trg_reapertura_sin_update` BEFORE UPDATE ON `articulo_reapertura` FOR EACH ROW SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'articulo_reapertura es solo de altas: no se modifica' */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_unicode_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 */ /*!50003 TRIGGER `trg_reapertura_sin_delete` BEFORE DELETE ON `articulo_reapertura` FOR EACH ROW SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'articulo_reapertura es solo de altas: no se borra' */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `articulo_relacion` (
  `id` int NOT NULL AUTO_INCREMENT,
  `id_articulo` int NOT NULL,
  `tipo` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT 'Código JATS related-article-type',
  `id_articulo_local` int DEFAULT NULL COMMENT 'Nulo: artículo externo',
  `doi` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `revista` varchar(500) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `anio` year DEFAULT NULL,
  `volumen` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `numero` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `fpage` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `lpage` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `fk_rel_articulo` (`id_articulo`),
  KEY `fk_rel_local` (`id_articulo_local`),
  CONSTRAINT `fk_rel_articulo` FOREIGN KEY (`id_articulo`) REFERENCES `articulo` (`id_articulo`) ON DELETE CASCADE ON UPDATE RESTRICT,
  CONSTRAINT `fk_rel_local` FOREIGN KEY (`id_articulo_local`) REFERENCES `articulo` (`id_articulo`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `chk_rel_destino` CHECK (((`id_articulo_local` is not null) or (`doi` is not null) or (`revista` is not null)))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Relaciones: corrección, retractación, comentario...' ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `articulo_resumen_seccion` (
  `id_texto` int NOT NULL,
  `codigo` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT 'El de la plantilla: introduccion, metodos...',
  `orden` int NOT NULL,
  `texto` text CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  PRIMARY KEY (`id_texto`,`codigo`),
  CONSTRAINT `fk_rsec_texto` FOREIGN KEY (`id_texto`) REFERENCES `articulo_texto` (`id_texto`) ON DELETE CASCADE ON UPDATE RESTRICT,
  CONSTRAINT `chk_rsec_texto` CHECK ((`texto` <> _utf8mb4''))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Secciones de un resumen estructurado' ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `articulo_texto` (
  `id_texto` int NOT NULL AUTO_INCREMENT,
  `id_articulo` int NOT NULL,
  `tipo` enum('titulo','subtitulo','resumen') CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT 'titulo y subtitulo: solo las traducciones',
  `idioma` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT 'Código BCP 47 (SC-23)',
  `texto` text CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci COMMENT 'Nulo solo en un resumen estructurado: el texto va por sección',
  `orden` int NOT NULL DEFAULT '0',
  PRIMARY KEY (`id_texto`),
  UNIQUE KEY `uq_texto` (`id_articulo`,`tipo`,`idioma`),
  CONSTRAINT `fk_texto_articulo` FOREIGN KEY (`id_articulo`) REFERENCES `articulo` (`id_articulo`) ON DELETE CASCADE ON UPDATE RESTRICT,
  CONSTRAINT `chk_texto_contenido` CHECK (((`tipo` = _utf8mb4'resumen') or (`texto` is not null)))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Títulos traducidos y resúmenes, por idioma' ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `articulo_ubicacion` (
  `id_articulo` int NOT NULL,
  `tipo` enum('pagina','html','pdf','epub','xml') CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `url` varchar(500) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT 'Carga manual: el HTML puede alojarse fuera de OJS',
  PRIMARY KEY (`id_articulo`,`tipo`),
  CONSTRAINT `fk_ubic_articulo` FOREIGN KEY (`id_articulo`) REFERENCES `articulo` (`id_articulo`) ON DELETE CASCADE ON UPDATE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='URL de cada salida publicada' ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `autores` (
  `id_autor` int NOT NULL AUTO_INCREMENT COMMENT 'Identificador único interno',
  `apellidos` varchar(200) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT 'Apellidos completos',
  `nombre` varchar(200) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT 'Nombre(s) de pila',
  `nombre_completo` varchar(400) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT 'Nombre completo formateado',
  `apellidos_nombre` varchar(400) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'Apellidos, Nombre (formato índice)',
  `nombre_preferido` varchar(400) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'Nombre como el autor prefiere aparecer',
  `iniciales` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'Iniciales (ej: J.R.R., M.T.)',
  `sufijo` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'Sufijos (Jr., Sr., III, PhD, etc.)',
  `titulo_academico` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'Título académico preferido',
  `tratamiento` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'Dr., Dra., Prof., etc.',
  `orcid` varchar(19) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'ORCID (formato: 0000-0001-2345-6789)',
  `researcher_id` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'ResearcherID (Web of Science)',
  `scopus_id` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'Scopus Author ID',
  `google_scholar_id` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'Google Scholar ID',
  `researchgate_id` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'ResearchGate profile ID',
  `academia_edu` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'Academia.edu username',
  `linkedin` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'LinkedIn profile',
  `twitter_handle` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'Twitter/X handle',
  `loop_id` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'Loop profile ID',
  `mendeley_id` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'Mendeley profile',
  `email_principal` varchar(200) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'Email principal',
  `email_alternativo` varchar(200) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'Email alternativo',
  `telefono` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'Teléfono',
  `telefono_alternativo` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'Teléfono alternativo',
  `sitio_web_personal` varchar(500) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'Sitio web personal',
  `foto_url` varchar(500) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'URL de foto del autor',
  `biografia_corta` text CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci COMMENT 'Biografía breve (250-500 palabras)',
  `biografia_extendida` text CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci COMMENT 'Biografía extendida',
  `cv_url` varchar(500) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'URL del CV',
  `genero` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'Género',
  `fecha_nacimiento` date DEFAULT NULL COMMENT 'Fecha de nacimiento (para estadísticas generacionales)',
  `pais_nacimiento` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'País de nacimiento',
  `pais_nacimiento_codigo` char(2) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'ISO 3166-1 alfa-2; el nombre va en pais_nacimiento, por valor (1.31.0)',
  `nacionalidad` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'Nacionalidad(es) separadas por ;',
  `idiomas` text CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci COMMENT 'Idiomas que habla/escribe separados por ;',
  `idioma_nativo` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'Idioma materno',
  `afiliacion_actual` varchar(500) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'Institución actual',
  `departamento` varchar(300) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'Departamento/División',
  `facultad` varchar(300) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'Facultad/Escuela',
  `cargo_actual` varchar(200) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'Cargo/Posición',
  `tipo_afiliacion` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'Tipo (profesor, investigador, postdoc, estudiante, etc.)',
  `ciudad_afiliacion` varchar(200) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'Ciudad',
  `estado_provincia` varchar(200) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'Estado/Provincia',
  `pais_afiliacion` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'País',
  `pais_afiliacion_codigo` char(2) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'ISO 3166-1 alfa-2; el nombre va en pais_afiliacion, por valor (1.31.0)',
  `codigo_postal` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'Código postal',
  `direccion_institucional` text CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci COMMENT 'Dirección completa',
  `email_institucional` varchar(200) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'Email institucional',
  `afiliaciones_anteriores` text CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci COMMENT 'Afiliaciones previas separadas por ; (formato: institución|periodo)',
  `afiliaciones_secundarias` text CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci COMMENT 'Afiliaciones adicionales actuales separadas por ;',
  `ringgold_id` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'Ringgold ID de la institución',
  `ror_afiliacion_actual` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'ROR ID (Research Organization Registry)',
  `grid_id` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'GRID ID (Global Research Identifier Database)',
  `isni` varchar(19) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'ISNI institucional si aplica',
  `area_investigacion` varchar(300) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'Área principal de investigación',
  `especialidades` text CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci COMMENT 'Especialidades separadas por ;',
  `palabras_clave_expertise` text CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci COMMENT 'Palabras clave de expertise separadas por ;',
  `clasificacion_unesco` text CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci COMMENT 'Códigos UNESCO de áreas separados por ;',
  `clasificacion_oecd` text CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci COMMENT 'Códigos OECD separados por ;',
  `disciplinas` text CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci COMMENT 'Disciplinas científicas separadas por ;',
  `grado_maximo` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'Máximo grado académico (PhD, MD, MSc, etc.)',
  `universidad_doctorado` varchar(300) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'Universidad del doctorado',
  `ano_doctorado` year DEFAULT NULL COMMENT 'Año de obtención del doctorado',
  `titulo_tesis` varchar(500) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'Título de la tesis doctoral',
  `director_tesis` varchar(300) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'Director de tesis',
  `titulaciones_adicionales` text CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci COMMENT 'Otras titulaciones separadas por ; (formato: grado|universidad|año)',
  `roles_frecuentes` text CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci COMMENT 'Roles típicos separados por ; (autor, editor, revisor, traductor, etc.)',
  `credit_roles_tipicos` text CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci COMMENT 'Roles CRediT habituales separados por ;',
  `expertise_revision` text CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci COMMENT 'Áreas de expertise para revisión por pares separadas por ;',
  `editor_revista` text CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci COMMENT 'Revistas donde es editor separadas por ;',
  `comite_editorial` text CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci COMMENT 'Comités editoriales separados por ;',
  `revisor_para` text CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci COMMENT 'Revistas para las que revisa separadas por ;',
  `editor_libro` text CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci COMMENT 'Series de libros que edita separadas por ;',
  `h_index` int DEFAULT NULL COMMENT 'H-index',
  `h_index_fuente` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'Fuente del h-index (Scopus, WoS, GScholar)',
  `i10_index` int DEFAULT NULL COMMENT 'i10-index (Google Scholar)',
  `numero_publicaciones` int DEFAULT NULL COMMENT 'Número total de publicaciones',
  `numero_citas` int DEFAULT NULL COMMENT 'Número total de citas',
  `fecha_actualizacion_metricas` date DEFAULT NULL COMMENT 'Fecha de actualización de métricas',
  `proyectos_actuales` text CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci COMMENT 'Proyectos de investigación activos separados por ;',
  `fuentes_financiamiento` text CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci COMMENT 'Agencias que lo financian separadas por ;',
  `laboratorio` varchar(300) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'Laboratorio/Grupo de investigación',
  `url_laboratorio` varchar(500) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'URL del laboratorio',
  `premios` text CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci COMMENT 'Premios recibidos separados por ; (formato: año|nombre|institución)',
  `becas` text CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci COMMENT 'Becas/Fellowships separadas por ;',
  `honores` text CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci COMMENT 'Honores académicos separados por ;',
  `membresias` text CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci COMMENT 'Membresías en sociedades científicas separadas por ;',
  `patentes` text CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci COMMENT 'Patentes registradas separadas por ; (formato: número|título|año)',
  `marcas` text CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci COMMENT 'Marcas registradas si aplica separadas por ;',
  `direccion_correspondencia` text CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci COMMENT 'Dirección para correspondencia',
  `ciudad_correspondencia` varchar(200) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'Ciudad',
  `pais_correspondencia` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'País',
  `pais_correspondencia_codigo` char(2) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'ISO 3166-1 alfa-2; el nombre va en pais_correspondencia, por valor (1.31.0)',
  `codigo_postal_correspondencia` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'Código postal',
  `email_correspondencia` varchar(200) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'Email para correspondencia',
  `telefono_correspondencia` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'Teléfono de contacto',
  `nombre_publicaciones` varchar(400) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'Como prefiere aparecer en publicaciones',
  `mostrar_afiliacion` tinyint(1) DEFAULT '1' COMMENT 'Si mostrar afiliación',
  `mostrar_email` tinyint(1) DEFAULT '0' COMMENT 'Si mostrar email',
  `tipo_autor` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'Tipo (académico, independiente, institucional, corporativo)',
  `disponible_revision` tinyint(1) DEFAULT '0' COMMENT 'Si está disponible como revisor',
  `areas_revision` text CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci COMMENT 'Áreas para revisión separadas por ;',
  `conflictos_permanentes` text CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci COMMENT 'Conflictos de interés permanentes',
  `empresas_vinculadas` text CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci COMMENT 'Empresas con las que tiene vínculos separadas por ;',
  `consultorias` text CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci COMMENT 'Consultorías activas separadas por ;',
  `numero_identificacion_fiscal` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'Número fiscal (para pagos)',
  `cbu_cuenta_bancaria` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'CBU/IBAN para transferencias',
  `forma_pago_preferida` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'Forma de pago preferida',
  `informacion_facturacion` text CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci COMMENT 'Información para facturación',
  `estado_autor` enum('activo','inactivo','jubilado','fallecido','emerito') CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT 'activo' COMMENT 'Estado actual del autor',
  `disponible_colaboraciones` tinyint(1) DEFAULT '1' COMMENT 'Si está disponible para colaborar',
  `fecha_inactividad` date DEFAULT NULL COMMENT 'Fecha desde que está inactivo',
  `fecha_fallecimiento` date DEFAULT NULL COMMENT 'Fecha de fallecimiento si aplica',
  `obituario_url` varchar(500) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'URL de obituario si aplica',
  `coautores_frecuentes` text CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci COMMENT 'IDs de coautores habituales separados por ;',
  `estudiantes_doctorales` text CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci COMMENT 'IDs de estudiantes que dirige separados por ;',
  `director_actual` int DEFAULT NULL COMMENT 'ID del director si es estudiante',
  `variantes_nombre` text CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci COMMENT 'Variantes del nombre en publicaciones separadas por ;',
  `nombres_previos` text CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci COMMENT 'Nombres anteriores (ej: antes de casarse) separados por ;',
  `seudonimos` text CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci COMMENT 'Seudónimos o nombres de pluma separados por ;',
  `registros_duplicados` text CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci COMMENT 'IDs de registros duplicados detectados separados por ;',
  `perfil_publico` tinyint(1) DEFAULT '1' COMMENT 'Si el perfil es público',
  `compartir_metricas` tinyint(1) DEFAULT '1' COMMENT 'Si permite compartir métricas',
  `compartir_contacto` tinyint(1) DEFAULT '0' COMMENT 'Si permite compartir información de contacto',
  `suscrito_newsletter` tinyint(1) DEFAULT '0' COMMENT 'Si está suscrito a comunicaciones',
  `gdpr_consentimiento` tinyint(1) DEFAULT '0' COMMENT 'Consentimiento GDPR',
  `fecha_consentimiento` date DEFAULT NULL COMMENT 'Fecha de consentimiento',
  `notas_internas` text CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci COMMENT 'Notas internas del editor',
  `observaciones` text CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci COMMENT 'Observaciones generales',
  `calificacion_colaboracion` int DEFAULT NULL COMMENT 'Calificación interna de colaboración (1-5)',
  `historial_interacciones` text CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci COMMENT 'Historial de interacciones (formato: fecha|tipo|descripción separados por ;)',
  `fecha_creacion_registro` datetime DEFAULT CURRENT_TIMESTAMP COMMENT 'Fecha de creación del registro',
  `fecha_actualizacion_registro` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT 'Última actualización',
  `usuario_creacion` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'Usuario que creó el registro',
  `fuente_registro` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'Fuente (importación, manual, etc.)',
  `verificado` tinyint(1) DEFAULT '0' COMMENT 'Si los datos fueron verificados',
  `fecha_verificacion` date DEFAULT NULL COMMENT 'Fecha de verificación',
  `verificado_por` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'Quién verificó los datos',
  PRIMARY KEY (`id_autor`),
  UNIQUE KEY `orcid` (`orcid`),
  KEY `idx_apellidos` (`apellidos`),
  KEY `idx_nombre_completo` (`nombre_completo`),
  KEY `idx_email_principal` (`email_principal`),
  KEY `idx_orcid` (`orcid`),
  KEY `idx_estado` (`estado_autor`),
  KEY `fk_autor_pais_afiliacion` (`pais_afiliacion_codigo`),
  KEY `fk_autor_pais_correspondencia` (`pais_correspondencia_codigo`),
  KEY `fk_autor_pais_nacimiento` (`pais_nacimiento_codigo`),
  CONSTRAINT `fk_autor_pais_afiliacion` FOREIGN KEY (`pais_afiliacion_codigo`) REFERENCES `pais` (`codigo`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `fk_autor_pais_correspondencia` FOREIGN KEY (`pais_correspondencia_codigo`) REFERENCES `pais` (`codigo`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `fk_autor_pais_nacimiento` FOREIGN KEY (`pais_nacimiento_codigo`) REFERENCES `pais` (`codigo`) ON DELETE RESTRICT ON UPDATE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci ROW_FORMAT=DYNAMIC COMMENT='Autores, revisores, editores y colaboradores académicos';
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `bibtex` (
  `id` int NOT NULL AUTO_INCREMENT,
  `id_proyecto` int NOT NULL,
  `tipo_de_entrada` varchar(32) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `clave_bibtex` varchar(32) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `fecha_modificacion` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `id_origen` int DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `id_proyecto` (`id_proyecto`),
  KEY `idx_clave_bibtex` (`clave_bibtex`),
  KEY `idx_tipo_entrada` (`tipo_de_entrada`),
  KEY `fk_bibtex_origen` (`id_origen`),
  CONSTRAINT `bibtex_ibfk_1` FOREIGN KEY (`id_proyecto`) REFERENCES `proyectos` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_bibtex_origen` FOREIGN KEY (`id_origen`) REFERENCES `bibtex` (`id`) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `bibtex_campo` (
  `id_bibtex` int NOT NULL COMMENT 'Entrada (bibtex.id)',
  `campo` varchar(32) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT 'Campo de biblatex (bibtex_campo_catalogo)',
  `valor` text CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  PRIMARY KEY (`id_bibtex`,`campo`),
  KEY `idx_campo_valor` (`campo`,`valor`(100)),
  FULLTEXT KEY `ft_bibtex_campo_valor` (`valor`),
  CONSTRAINT `fk_bibtex_campo_catalogo` FOREIGN KEY (`campo`) REFERENCES `bibtex_campo_catalogo` (`campo`) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `fk_bibtex_campo_entrada` FOREIGN KEY (`id_bibtex`) REFERENCES `bibtex` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `chk_bibtex_campo_valor` CHECK ((char_length(trim(`valor`)) > 0))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Datos de las referencias: un par por campo con dato (2.0.0)' ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `bibtex_campo_catalogo` (
  `campo` varchar(32) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT 'Nombre del campo en biblatex',
  `orden` smallint unsigned NOT NULL COMMENT 'Orden de salida en el .bib',
  `literal` tinyint(1) NOT NULL DEFAULT '0' COMMENT '1: se escribe tal cual, sin la regla de las órdenes de LaTeX (SC-57)',
  `nombre_anterior` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'Columna de bibtex hasta la 2.0.0: para leer los JSON viejos',
  PRIMARY KEY (`campo`),
  UNIQUE KEY `uk_orden` (`orden`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Campos de biblatex que admite gbpublisher (2.0.0)' ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `block_notas` (
  `id` int NOT NULL AUTO_INCREMENT,
  `asunto` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `contenido` text CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `fecha` datetime NOT NULL,
  `id_usuario` int NOT NULL,
  PRIMARY KEY (`id`),
  KEY `fk_bn_usuario` (`id_usuario`),
  CONSTRAINT `fk_bn_usuario` FOREIGN KEY (`id_usuario`) REFERENCES `usuarios` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `capitulo_autor` (
  `id_relacion` int NOT NULL AUTO_INCREMENT,
  `id_capitulo` int NOT NULL,
  `id_autor` int NOT NULL,
  `orden_autoria` int NOT NULL,
  `rol_autor` enum('autor','traductor') CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT 'autor',
  `taxonomia_credit` text CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci,
  `afiliacion_momento` text CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci,
  `departamento_momento` varchar(300) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `ciudad_momento` varchar(200) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `pais_momento` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `ror_afiliacion_momento` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `email_momento` varchar(200) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `publicar_email` tinyint(1) DEFAULT '0',
  `contribuciones_credit` json DEFAULT NULL,
  `notas_autor` text CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci,
  `porcentaje_contribucion` int DEFAULT NULL,
  `fecha_asignacion` datetime DEFAULT CURRENT_TIMESTAMP,
  `usuario_asignacion` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  PRIMARY KEY (`id_relacion`),
  KEY `fk_capitulo_autor_capitulo` (`id_capitulo`),
  KEY `fk_capitulo_autor_autor` (`id_autor`),
  KEY `ix_capitulo_autor_orden` (`id_capitulo`,`orden_autoria`),
  CONSTRAINT `fk_capitulo_autor_autor` FOREIGN KEY (`id_autor`) REFERENCES `autores` (`id_autor`) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `fk_capitulo_autor_capitulo` FOREIGN KEY (`id_capitulo`) REFERENCES `capitulos` (`id_capitulo`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `capitulos` (
  `id_capitulo` int NOT NULL AUTO_INCREMENT,
  `id_proyecto` int NOT NULL,
  `id_libro` int NOT NULL,
  `id_parte` int DEFAULT NULL,
  `nombre_archivo` varchar(300) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `tipo_capitulo` enum('prologo','prefacio','presentacion','palabras_preliminares','introduccion','dedicatoria','agradecimientos','nota_traductor','nota_editor','lista_figuras','lista_tablas','lista_abreviaturas','capitulo','conclusiones','epilogo','posfacio','post_scriptum','apendice','glosario','bibliografia','sobre_autores','cronologia','indice_onomastico','colofon','otro','portadilla','portada','creditos','indice_concepto','indice_autores') CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT 'capitulo',
  `tipo_capitulo_otro` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `titulo_capitulo` varchar(500) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `subtitulo` varchar(500) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `titulo_corto` varchar(200) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `titulo_traducido` text CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci,
  `idioma_titulo_traducido` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `doi` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `crossref_estado` enum('pendiente','sandbox','produccion') CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `crossref_fecha_deposito` datetime DEFAULT NULL,
  `elocation_id` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `pagina_inicio` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `pagina_fin` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `numero_paginas` int DEFAULT NULL,
  `idioma_capitulo` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `fecha_publicacion_online` date DEFAULT NULL,
  `fecha_recepcion` date DEFAULT NULL,
  `fecha_aceptacion` date DEFAULT NULL,
  `fecha_revision` date DEFAULT NULL,
  `autor_corporativo` varchar(300) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `autores_anonimos` tinyint(1) DEFAULT '0',
  `grupo_autores` varchar(300) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `author_notes` text CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci,
  `resumen_1` text CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci,
  `idioma_resumen_1` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `resumen_2` text CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci,
  `idioma_resumen_2` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `resumen_3` text CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci,
  `idioma_resumen_3` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `palabras_clave_1` text CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci,
  `idioma_kwd_1` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `palabras_clave_2` text CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci,
  `idioma_kwd_2` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `palabras_clave_3` text CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci,
  `idioma_kwd_3` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `mesh_terms` text CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci,
  `descriptores_decs` text CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci,
  `clasificacion_tematica` text CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci,
  `numero_figuras` int DEFAULT NULL,
  `numero_tablas` int DEFAULT NULL,
  `numero_ecuaciones` int DEFAULT NULL,
  `material_suplementario` text CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci,
  `dataset_asociado` text CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci,
  `financiamiento` text CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci,
  `numero_proyecto` text CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci,
  `conflictos_interes` text CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci,
  `tiene_conflictos` tinyint(1) DEFAULT '0',
  `funding_statement` text CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci,
  `declaracion_etica` text CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci,
  `consentimiento_informado` tinyint(1) DEFAULT '0',
  `aprobacion_comite_etica` tinyint(1) DEFAULT '0',
  `numero_aprobacion_etica` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `disponibilidad_datos` text CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci,
  `data_availability_statement` text CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci,
  `licencia` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `url_licencia` varchar(500) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `copyright_holder` varchar(300) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `copyright_year` year DEFAULT NULL,
  `declaracion_copyright` text CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci,
  `url_capitulo` varchar(500) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `url_pdf` varchar(500) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `revisado_xml` tinyint(1) DEFAULT '0',
  `validado_docbook` tinyint(1) DEFAULT '0',
  `errores_validacion` text CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci,
  `calidad_metadatos` int DEFAULT NULL,
  `completitud_metadatos` decimal(5,2) DEFAULT NULL,
  `estado_capitulo` enum('borrador','en_revision','aceptado','en_produccion','publicado') CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT 'borrador',
  `fecha_creacion_registro` datetime DEFAULT CURRENT_TIMESTAMP,
  `fecha_actualizacion_registro` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `usuario_creacion` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `responsable_edicion` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `notas_internas` text CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci,
  `referencias_citadas` text CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci,
  `autoria_apertura` varchar(500) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'Forma de los nombres en la apertura del capítulo, separados por punto y coma; vacía: nombres completos',
  PRIMARY KEY (`id_capitulo`),
  KEY `fk_capitulos_proyecto` (`id_proyecto`),
  KEY `fk_capitulos_libro` (`id_libro`),
  KEY `fk_capitulos_parte` (`id_parte`),
  KEY `ix_capitulos_nombre_archivo` (`nombre_archivo`),
  KEY `ix_capitulos_titulo` (`titulo_capitulo`),
  KEY `ix_capitulos_doi` (`doi`),
  KEY `ix_capitulos_estado` (`estado_capitulo`),
  CONSTRAINT `fk_capitulos_libro` FOREIGN KEY (`id_libro`) REFERENCES `libros_md` (`id_libro`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_capitulos_parte` FOREIGN KEY (`id_parte`) REFERENCES `partes_libro` (`id_parte`) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `fk_capitulos_proyecto` FOREIGN KEY (`id_proyecto`) REFERENCES `proyectos` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `cmb_biblatex` (
  `id` int NOT NULL AUTO_INCREMENT,
  `tipo` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `codigo` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `nombre` varchar(128) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `activo` tinyint(1) DEFAULT '1',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `colecciones` (
  `id_coleccion` int NOT NULL AUTO_INCREMENT,
  `nombre` varchar(500) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `nombre_abreviado` varchar(200) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `issn` varchar(9) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `doi_prefix` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `editorial` varchar(300) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `director_coleccion` varchar(300) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `email_contacto` varchar(200) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `descripcion` text CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci,
  `area_conocimiento` varchar(200) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `disciplina` varchar(200) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `ano_inicio` year DEFAULT NULL,
  `ano_fin` year DEFAULT NULL,
  `activa` tinyint(1) NOT NULL DEFAULT '1',
  `url_coleccion` varchar(500) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `url_logo` varchar(500) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `notas_internas` text CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci,
  `fecha_creacion` datetime DEFAULT CURRENT_TIMESTAMP,
  `fecha_actualizacion` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `usuario_creacion` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  PRIMARY KEY (`id_coleccion`),
  UNIQUE KEY `uk_colecciones_issn` (`issn`),
  KEY `ix_colecciones_nombre` (`nombre`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `consultas` (
  `id` int NOT NULL AUTO_INCREMENT,
  `consulta_sistema` tinyint(1) DEFAULT '0',
  `nombre` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `descripcion` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `editor_consultas` text CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `comentarios` text CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci,
  `usuario_creador` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '',
  `fecha_creacion` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_consulta_sistema` (`consulta_sistema`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `consultas_eliminadas` (
  `id` int NOT NULL AUTO_INCREMENT,
  `id_original` int NOT NULL COMMENT 'ID de la consulta original',
  `nombre` varchar(200) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `descripcion` text CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci,
  `editor_consultas` text CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci,
  `comentarios` text CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci,
  `usuario_creador` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `fecha_creacion` datetime DEFAULT NULL,
  `usuario_elimino` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `fecha_eliminacion` datetime NOT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_fecha_eliminacion` (`fecha_eliminacion`),
  KEY `idx_usuario_elimino` (`usuario_elimino`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci ROW_FORMAT=DYNAMIC COMMENT='Registro de consultas eliminadas para auditoría';
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `contador_tiempo` (
  `id` int NOT NULL AUTO_INCREMENT,
  `id_proyecto` int NOT NULL,
  `tiempo_total` int NOT NULL DEFAULT '0',
  PRIMARY KEY (`id`),
  KEY `fk_timer_proyecto` (`id_proyecto`),
  CONSTRAINT `fk_timer_proyecto` FOREIGN KEY (`id_proyecto`) REFERENCES `proyectos` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `contribuyente_afiliacion` (
  `id` int NOT NULL AUTO_INCREMENT,
  `id_contribuyente` int NOT NULL,
  `orden` int NOT NULL DEFAULT '0',
  `institucion` varchar(500) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `departamento` varchar(300) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `ciudad` varchar(200) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `pais` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `pais_codigo` char(2) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'ISO 3166-1 alfa-2; el nombre va en pais, por valor (1.30.0)',
  `ror` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'URL completa: https://ror.org/0xxxxxxNN',
  PRIMARY KEY (`id`),
  KEY `fk_afil_contrib` (`id_contribuyente`),
  KEY `fk_afil_pais` (`pais_codigo`),
  CONSTRAINT `fk_afil_contrib` FOREIGN KEY (`id_contribuyente`) REFERENCES `articulo_contribuyente` (`id_contribuyente`) ON DELETE CASCADE ON UPDATE RESTRICT,
  CONSTRAINT `fk_afil_pais` FOREIGN KEY (`pais_codigo`) REFERENCES `pais` (`codigo`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `chk_afil_ror` CHECK (regexp_like(`ror`,_utf8mb4'^https://ror[.]org/0[a-hj-km-np-tv-z0-9]{6}[0-9]{2}$',_utf8mb4'c'))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Afiliaciones de un contribuyente en este artículo (varias)' ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `contribuyente_credit` (
  `id_contribuyente` int NOT NULL,
  `rol_credit` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT 'Valor de credit_roles.nombre, sin clave foránea (SC-23)',
  `nombre_rol` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'Nombre del rol en el idioma del artículo, congelado al publicar (1.29.0)',
  `uri_rol` varchar(200) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'URI del rol en credit.niso.org, congelada al publicar (1.29.0)',
  PRIMARY KEY (`id_contribuyente`,`rol_credit`),
  CONSTRAINT `fk_credit_contrib` FOREIGN KEY (`id_contribuyente`) REFERENCES `articulo_contribuyente` (`id_contribuyente`) ON DELETE CASCADE ON UPDATE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Roles CRediT de cada contribuyente' ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `credit_rol_nombre` (
  `id_rol` int unsigned NOT NULL,
  `idioma` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT 'Código BCP 47 (SC-23)',
  `nombre` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  PRIMARY KEY (`id_rol`,`idioma`),
  CONSTRAINT `fk_credit_rol_nombre_rol` FOREIGN KEY (`id_rol`) REFERENCES `credit_roles` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Nombre de cada rol CRediT por idioma (1.28.0)' ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `credit_roles` (
  `id` int unsigned NOT NULL AUTO_INCREMENT,
  `nombre` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `descripcion` text CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci,
  `uri` varchar(200) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'URI del rol en credit.niso.org (1.28.0)',
  PRIMARY KEY (`id`),
  UNIQUE KEY `nombre` (`nombre`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `editorial` (
  `id_editorial` int NOT NULL AUTO_INCREMENT,
  `nombre` varchar(300) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT 'JATS publisher-name: EDUNPAZ, Editorial Universitaria',
  `institucion` varchar(300) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'La institución de la que depende: Universidad Nacional de José C. Paz',
  `ror` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `direccion` varchar(300) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'Página legal: Leandro N. Alem 4731, José C. Paz',
  `region` varchar(200) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'Provincia o estado: Pcia. de Buenos Aires',
  `ciudad` varchar(200) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'JATS publisher-loc',
  `pais` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `pais_codigo` char(2) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'ISO 3166-1 alfa-2; el nombre va en pais, por valor (1.30.0)',
  `url_portal` varchar(500) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `email` varchar(200) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'Contacto y depositante de Crossref; la revista lo puede reemplazar (revista.email_editorial)',
  `doi_prefix` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'El prefijo del miembro de Crossref',
  `licencia_defecto` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'Lo heredan los artículos hasta publicar',
  `url_licencia_defecto` varchar(500) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'Lo heredan los artículos hasta publicar',
  `titular_copyright_defecto` varchar(300) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'Lo heredan los artículos hasta publicar',
  `leyenda_distribucion` varchar(300) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'Página legal: Publicación electrónica - distribución gratuita',
  `aviso_responsabilidad` text CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci COMMENT 'Página legal: Las opiniones expresadas en los artículos...',
  `fecha_creacion` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `fecha_actualizacion` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id_editorial`),
  KEY `fk_editorial_pais` (`pais_codigo`),
  CONSTRAINT `fk_editorial_pais` FOREIGN KEY (`pais_codigo`) REFERENCES `pais` (`codigo`) ON DELETE RESTRICT ON UPDATE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='La editorial o institución, madre de sus revistas' ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `editorial_credito` (
  `id_credito` int NOT NULL AUTO_INCREMENT,
  `id_editorial` int NOT NULL,
  `cargo` varchar(200) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT 'Rector, Corrección de estilo...: las filas del mismo cargo se agrupan al componer',
  `nombre` varchar(300) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT 'Una persona por fila',
  `orden` int NOT NULL DEFAULT '0',
  `desde` date NOT NULL,
  `hasta` date DEFAULT NULL COMMENT 'Nulo: vigente',
  PRIMARY KEY (`id_credito`),
  KEY `fk_credito_editorial` (`id_editorial`),
  CONSTRAINT `fk_credito_editorial` FOREIGN KEY (`id_editorial`) REFERENCES `editorial` (`id_editorial`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `chk_credito_vigencia` CHECK (((`hasta` is null) or (`hasta` >= `desde`)))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Autoridades y producción de la editorial, con vigencia (página legal)' ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `formatos_pdf` (
  `id_formato_pdf` int NOT NULL AUTO_INCREMENT,
  `clasificacion` varchar(40) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `nombre_formato` varchar(60) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `ancho` decimal(5,2) NOT NULL,
  `alto` decimal(5,2) NOT NULL,
  `margen_interior` decimal(5,2) NOT NULL,
  `margen_exterior` decimal(5,2) NOT NULL,
  `margen_superior` decimal(5,2) NOT NULL,
  `margen_inferior` decimal(5,2) NOT NULL,
  `comentario` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `origen` enum('sistema','custom') CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `activo` tinyint(1) NOT NULL DEFAULT '1',
  `orden` int NOT NULL DEFAULT '0',
  PRIMARY KEY (`id_formato_pdf`),
  UNIQUE KEY `uk_clasif_nombre` (`clasificacion`,`nombre_formato`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `idiomas` (
  `id` int NOT NULL AUTO_INCREMENT,
  `codigo` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT 'Etiqueta BCP 47 (tag.bcp47 de babel): es, pt-BR',
  `nombre` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT 'Nombre en el propio idioma (name.local de babel)',
  `nombre_ingles` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'name.english de babel',
  `babel` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT 'Nombre para \\usepackage[...]{babel}',
  `nivel` tinyint DEFAULT NULL COMMENT 'Cobertura del locale según babel (level)',
  `activo` tinyint(1) NOT NULL DEFAULT '0' COMMENT 'Aparece en los combos de idioma',
  `orden` int NOT NULL DEFAULT '1000',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_idiomas_codigo` (`codigo`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Catálogo de idiomas, generado desde babel (actualización 1.3.0)' ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `libro_autor` (
  `id_relacion` int NOT NULL AUTO_INCREMENT,
  `id_libro` int NOT NULL,
  `id_autor` int NOT NULL,
  `orden_autoria` int NOT NULL,
  `rol_libro` enum('autor','editor','compilador','coordinador','prologuista_externo','traductor','ilustrador','director_coleccion') CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT 'autor',
  `afiliacion_momento` text CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci,
  `departamento_momento` varchar(300) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `ciudad_momento` varchar(200) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `pais_momento` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `ror_afiliacion_momento` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `email_momento` varchar(200) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `publicar_email` tinyint(1) DEFAULT '0',
  `contribuciones_credit` json DEFAULT NULL,
  `notas_autor` text CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci,
  `porcentaje_contribucion` int DEFAULT NULL,
  `fecha_asignacion` datetime DEFAULT CURRENT_TIMESTAMP,
  `usuario_asignacion` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  PRIMARY KEY (`id_relacion`),
  KEY `fk_libro_autor_libro` (`id_libro`),
  KEY `fk_libro_autor_autor` (`id_autor`),
  KEY `ix_libro_autor_orden` (`id_libro`,`orden_autoria`),
  CONSTRAINT `fk_libro_autor_autor` FOREIGN KEY (`id_autor`) REFERENCES `autores` (`id_autor`) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `fk_libro_autor_libro` FOREIGN KEY (`id_libro`) REFERENCES `libros_md` (`id_libro`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `libro_sigla` (
  `id_libro_sigla` int NOT NULL AUTO_INCREMENT,
  `id_proyecto` int NOT NULL,
  `id_sigla` int NOT NULL,
  `sigla` varchar(32) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_as_cs NOT NULL COMMENT 'Copia del catálogo (SC-23)',
  `desarrollo` varchar(500) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_as_ci NOT NULL COMMENT 'Copia del catálogo (SC-23)',
  `desarrollo_plural` varchar(500) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_as_ci DEFAULT NULL COMMENT 'Copia del catálogo (SC-23)',
  `idioma` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'Copia del catálogo (SC-23)',
  `clave` varchar(48) CHARACTER SET ascii COLLATE ascii_bin NOT NULL COMMENT '<id_sigla>-<sigla normalizada>, fija al adoptar',
  PRIMARY KEY (`id_libro_sigla`),
  UNIQUE KEY `uq_libsig_proyecto_sigla` (`id_proyecto`,`id_sigla`),
  UNIQUE KEY `uq_libsig_proyecto_clave` (`id_proyecto`,`clave`),
  KEY `ix_libsig_sigla` (`id_sigla`),
  CONSTRAINT `fk_libsig_proyecto` FOREIGN KEY (`id_proyecto`) REFERENCES `proyectos` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_libsig_sigla` FOREIGN KEY (`id_sigla`) REFERENCES `sigla_catalogo` (`id_sigla`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `chk_libsig_clave` CHECK (regexp_like(`clave`,_utf8mb4'^[0-9]+(-[a-z0-9]+)*$',_utf8mb4'c')),
  CONSTRAINT `chk_libsig_desarrollo` CHECK ((`desarrollo` <> _utf8mb4'')),
  CONSTRAINT `chk_libsig_idioma` CHECK ((`idioma` <> _utf8mb4'')),
  CONSTRAINT `chk_libsig_plural` CHECK ((`desarrollo_plural` <> _utf8mb4'')),
  CONSTRAINT `chk_libsig_sigla` CHECK ((`sigla` <> _utf8mb4''))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci ROW_FORMAT=DYNAMIC COMMENT='Siglas adoptadas por cada libro, con copia por valor';
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `libro_tapa_web` (
  `id_libro` int NOT NULL,
  `imagen` mediumblob NOT NULL COMMENT 'JPEG ya convertido; gbWeb copia los bytes tal cual',
  `formato` varchar(10) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'jpg',
  `ancho` int NOT NULL COMMENT 'Píxeles; para width en <img>',
  `alto` int NOT NULL COMMENT 'Píxeles; para height en <img>',
  `sha256` char(64) CHARACTER SET ascii COLLATE ascii_bin NOT NULL COMMENT 'SHA2(imagen, 256); nombra el archivo publicado',
  PRIMARY KEY (`id_libro`),
  CONSTRAINT `fk_tapaweb_libro` FOREIGN KEY (`id_libro`) REFERENCES `libros_md` (`id_libro`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `chk_tapaweb_alto` CHECK ((`alto` > 0)),
  CONSTRAINT `chk_tapaweb_ancho` CHECK ((`ancho` > 0)),
  CONSTRAINT `chk_tapaweb_formato` CHECK ((`formato` = _utf8mb4'jpg')),
  CONSTRAINT `chk_tapaweb_sha256` CHECK (regexp_like(`sha256`,_utf8mb4'^[0-9a-f]{64}$',_utf8mb4'c'))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci ROW_FORMAT=DYNAMIC COMMENT='Tapa en versión web, leída por gbWeb a través de v_web_libro_tapa';
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `libro_venta` (
  `id_libro` int NOT NULL,
  `tienda` enum('amazon','apple','google','mercadolibre') CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT 'El orden del ENUM es el de los botones en gbWeb',
  `url` varchar(500) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT 'Página del libro en la tienda',
  PRIMARY KEY (`id_libro`,`tienda`),
  CONSTRAINT `fk_libro_venta_libro` FOREIGN KEY (`id_libro`) REFERENCES `libros_md` (`id_libro`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `chk_libro_venta_url` CHECK (regexp_like(`url`,_utf8mb4'^https?://[^ ]+$',_utf8mb4'c'))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci ROW_FORMAT=DYNAMIC COMMENT='Puntos de venta de cada libro (gbWeb: v_web_libro_venta)';
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `libros_md` (
  `id_libro` int NOT NULL AUTO_INCREMENT,
  `id_proyecto` int NOT NULL,
  `id_coleccion` int DEFAULT NULL,
  `id_serie` int DEFAULT NULL,
  `numero_en_coleccion` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `numero_en_serie` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `isbn_impreso` varchar(17) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `isbn_electronico` varchar(17) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `doi_libro` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `doi_prefix` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `handle_prefix` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `titulo_libro` varchar(500) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `subtitulo` varchar(500) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `titulo_abreviado` varchar(200) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `titulo_original` varchar(500) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `idioma_titulo_original` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `tipo_libro` enum('monografia','obra_colectiva','compilacion','traduccion','referencia','manual','actas') CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT 'monografia',
  `lugar_bibliografia` enum('consolidada','por_capitulo') CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT 'por_capitulo',
  `edicion` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `numero_edicion` int DEFAULT NULL,
  `numero_paginas` int DEFAULT NULL,
  `ano_publicacion` year DEFAULT NULL,
  `mes_publicacion` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `fecha_publicacion_completa` date DEFAULT NULL,
  `idioma_principal` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT 'es',
  `idiomas_publicacion` varchar(200) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `estado_publicacion` enum('en_preparacion','publicado','agotado','descatalogado') CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT 'en_preparacion',
  `estado_libro` enum('borrador','en_correccion','en_produccion','publicado') CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT 'borrador',
  `editorial` varchar(300) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `institucion_editora` varchar(300) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `ror_editorial` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `ciudad_publicacion` varchar(200) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `pais_publicacion` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `pais_publicacion_codigo` char(2) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'ISO 3166-1 alfa-2; el nombre va en pais_publicacion, por valor (1.31.0)',
  `direccion_editorial` text CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci,
  `email_editorial` varchar(200) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `area_conocimiento` varchar(200) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `disciplina` varchar(200) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `subdisciplina` text CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci,
  `palabras_clave_libro` text CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci,
  `clasificacion_unesco` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `clasificacion_oecd` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `tipo_acceso` enum('abierto','venta','mixto','embargado') CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT 'abierto',
  `licencia_defecto` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `url_licencia` varchar(500) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `politica_acceso_abierto` text CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci,
  `periodo_embargo` int DEFAULT NULL,
  `url_libro` varchar(500) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `url_oai_pmh` varchar(500) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `url_logo` varchar(500) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `imagen_tapa` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `repositorio_produccion_url` varchar(500) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `repositorio_produccion_plataforma` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `repositorio_produccion_tipo` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `repositorio_produccion_privado` tinyint(1) DEFAULT '1',
  `sistema_gestion_contenidos` varchar(200) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `repositorio_preservacion_url` varchar(500) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `repositorio_preservacion_plataforma` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `indexado_en` text CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci,
  `identificador_scielo` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `resumen_libro` text CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci,
  `resumen_traducido` text CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci,
  `idioma_resumen_traducido` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `descripcion_libro` text CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci,
  `objetivos_alcance` text CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci,
  `estilo_cita` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `fecha_creacion` datetime DEFAULT CURRENT_TIMESTAMP,
  `fecha_actualizacion` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `usuario_creacion` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `notas_internas` text CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci,
  `id_formato_pdf` int DEFAULT NULL,
  `url_descarga_epub` varchar(500) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `url_descarga_pdf` varchar(500) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `texto_catalogacion` text CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci COMMENT 'Ficha de catalogación del impreso: Markdown de línea con marcadores (SC-25)',
  `texto_legal` text CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci COMMENT 'Texto legal del impreso: Markdown de línea con marcadores (SC-25)',
  `texto_catalogacion_digital` text CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci COMMENT 'Ficha de catalogación del EPUB; vacío: bloque genérico (SC-25)',
  `texto_legal_digital` text CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci COMMENT 'Texto legal del EPUB; vacío: bloque genérico (SC-25)',
  `logo_portada` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'Nombre del archivo en media/: logo-portada.EXT',
  `logo_coleccion` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'Nombre del archivo en media/: logo-coleccion.EXT',
  `leyenda_autoria` varchar(200) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'Línea debajo de los nombres en la portada: coordinadores, compiladoras (SC-25)',
  `url_compra` varchar(500) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'Enlace al punto de venta externo; NULL sin dato (GV-74)',
  `resumen_traducido_2` text CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci COMMENT 'Segunda traducción del resumen',
  `idioma_resumen_traducido_2` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'Código del catálogo idiomas',
  `palabras_clave_traducidas` text CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci COMMENT 'Palabras clave traducidas, separadas por coma',
  `idioma_palabras_clave_traducidas` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'Código del catálogo idiomas',
  `palabras_clave_traducidas_2` text CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci COMMENT 'Segunda traducción de las palabras clave',
  `idioma_palabras_clave_traducidas_2` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'Código del catálogo idiomas',
  `destino_html` enum('autonomo','portal') CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'autonomo' COMMENT 'Dónde se publica la salida HTML: sitio propio o integrado al portal de gbWeb',
  `url_portal` varchar(500) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'Dirección del portal, con / final: de ahí sale el marco del HTML integrado',
  PRIMARY KEY (`id_libro`),
  UNIQUE KEY `uk_libros_proyecto` (`id_proyecto`),
  KEY `ix_libros_isbn_impreso` (`isbn_impreso`),
  KEY `ix_libros_doi` (`doi_libro`),
  KEY `ix_libros_titulo` (`titulo_libro`),
  KEY `fk_libros_coleccion` (`id_coleccion`),
  KEY `fk_libros_serie` (`id_serie`),
  KEY `fk_libro_formato` (`id_formato_pdf`),
  KEY `fk_libro_pais_publicacion` (`pais_publicacion_codigo`),
  CONSTRAINT `fk_libro_formato` FOREIGN KEY (`id_formato_pdf`) REFERENCES `formatos_pdf` (`id_formato_pdf`) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `fk_libro_pais_publicacion` FOREIGN KEY (`pais_publicacion_codigo`) REFERENCES `pais` (`codigo`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `fk_libros_coleccion` FOREIGN KEY (`id_coleccion`) REFERENCES `colecciones` (`id_coleccion`) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `fk_libros_proyecto` FOREIGN KEY (`id_proyecto`) REFERENCES `proyectos` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_libros_serie` FOREIGN KEY (`id_serie`) REFERENCES `series` (`id_serie`) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `chk_libros_destino_html` CHECK (((`destino_html` = _utf8mb4'autonomo') or (`url_portal` is not null))),
  CONSTRAINT `chk_libros_url_compra` CHECK ((`url_compra` <> _utf8mb4'')),
  CONSTRAINT `chk_libros_url_portal` CHECK (((`url_portal` is null) or regexp_like(`url_portal`,_utf8mb4'^https?://[^ ]+/$',_utf8mb4'c')))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `licencia_texto` (
  `url` varchar(500) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT 'licencias.url y articulo.url_licencia',
  `idioma` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT 'Código BCP 47 (SC-23)',
  `texto` text CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT 'license-p del canónico',
  PRIMARY KEY (`url`,`idioma`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Texto de cada licencia por idioma (1.28.0)' ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `licencias` (
  `id` int NOT NULL AUTO_INCREMENT,
  `etiqueta` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT 'Texto del combo y del registro (CC BY 4.0)',
  `url` varchar(500) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'URL canónica; NULL si no tiene',
  `spdx` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'Identificador SPDX; NULL si la etiqueta es ambigua',
  `abierta` tinyint(1) NOT NULL DEFAULT '0' COMMENT 'Acceso abierto: license-type de JATS',
  `para_contenido` tinyint(1) NOT NULL DEFAULT '0' COMMENT 'Aparece en licencia de artículos, capítulos, libros y revistas',
  `para_codigo` tinyint(1) NOT NULL DEFAULT '0' COMMENT 'Aparece en licencia del repositorio de código',
  `orden` int NOT NULL DEFAULT '0',
  `activo` tinyint(1) NOT NULL DEFAULT '1',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_licencias_etiqueta` (`etiqueta`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Catálogo de licencias (actualización 1.2.0)' ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `manual_ayudas` (
  `id` int NOT NULL AUTO_INCREMENT,
  `clave` varchar(128) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `componente` varchar(150) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `idioma` varchar(5) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT 'es',
  `ayuda` text CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `usuario_creacion` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `fecha_creacion` datetime DEFAULT CURRENT_TIMESTAMP,
  `usuario_modificacion` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `fecha_modificacion` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `idx_componente_idioma` (`componente`,`idioma`),
  KEY `idx_auditoria` (`usuario_modificacion`,`fecha_modificacion`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `notas` (
  `id` int NOT NULL AUTO_INCREMENT,
  `id_autor` int NOT NULL,
  `id_destinatario` int DEFAULT NULL COMMENT 'Nota 1 a 1 (o a uno mismo)',
  `id_grupo` int DEFAULT NULL COMMENT 'Nota de proyecto',
  `texto` text CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `fecha_creacion` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `desde` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'Hora de despacho: antes no la ven los destinatarios',
  `ultima_actividad` datetime(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) COMMENT 'Alta, respuesta o cierre; la lee el sondeo',
  `fecha_cierre` datetime DEFAULT NULL COMMENT 'Cerrar es archivar',
  `id_cierre_por` int DEFAULT NULL COMMENT 'El autor, cuando cierra él',
  `cierre_sistema` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'Usuario de FSysAdmin, o la migración, cuando no cierra el autor',
  PRIMARY KEY (`id`),
  KEY `idx_notas_destinatario` (`id_destinatario`,`fecha_cierre`),
  KEY `idx_notas_grupo` (`id_grupo`,`fecha_cierre`),
  KEY `idx_notas_autor` (`id_autor`,`fecha_cierre`),
  KEY `fk_notas_cierre_por` (`id_cierre_por`),
  CONSTRAINT `fk_notas_autor` FOREIGN KEY (`id_autor`) REFERENCES `usuarios` (`id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `fk_notas_cierre_por` FOREIGN KEY (`id_cierre_por`) REFERENCES `usuarios` (`id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `fk_notas_destinatario` FOREIGN KEY (`id_destinatario`) REFERENCES `usuarios` (`id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `fk_notas_grupo` FOREIGN KEY (`id_grupo`) REFERENCES `notas_grupos` (`id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `chk_notas_cierre` CHECK ((((`fecha_cierre` is null) and (`id_cierre_por` is null) and (`cierre_sistema` is null)) or ((`fecha_cierre` is not null) and ((`id_cierre_por` is null) <> (`cierre_sistema` is null))))),
  CONSTRAINT `chk_notas_destino` CHECK (((`id_destinatario` is null) <> (`id_grupo` is null))),
  CONSTRAINT `chk_notas_texto` CHECK ((`texto` <> _utf8mb4''))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `notas_grupos` (
  `id` int NOT NULL AUTO_INCREMENT,
  `id_proyecto` int NOT NULL COMMENT 'Un solo grupo por proyecto',
  `id_creador` int NOT NULL COMMENT 'Quien creó el grupo; suma y da de baja miembros',
  `fecha_creacion` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_notas_grupos_proyecto` (`id_proyecto`),
  KEY `fk_notas_grupos_creador` (`id_creador`),
  CONSTRAINT `fk_notas_grupos_creador` FOREIGN KEY (`id_creador`) REFERENCES `usuarios` (`id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `fk_notas_grupos_proyecto` FOREIGN KEY (`id_proyecto`) REFERENCES `proyectos` (`id`) ON DELETE RESTRICT ON UPDATE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `notas_miembros` (
  `id` int NOT NULL AUTO_INCREMENT,
  `id_grupo` int NOT NULL,
  `id_usuario` int NOT NULL,
  `fecha_alta` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `id_alta_por` int NOT NULL,
  `fecha_baja` datetime DEFAULT NULL COMMENT 'Baja lógica: el registro de lo que vio y respondió queda',
  `id_baja_por` int DEFAULT NULL,
  `clave_activa` tinyint GENERATED ALWAYS AS (if((`fecha_baja` is null),1,NULL)) STORED COMMENT 'Una sola alta vigente por usuario y grupo',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_notas_miembros_activo` (`id_grupo`,`id_usuario`,`clave_activa`),
  KEY `fk_notas_miembros_usuario` (`id_usuario`),
  KEY `fk_notas_miembros_alta` (`id_alta_por`),
  KEY `fk_notas_miembros_baja` (`id_baja_por`),
  CONSTRAINT `fk_notas_miembros_alta` FOREIGN KEY (`id_alta_por`) REFERENCES `usuarios` (`id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `fk_notas_miembros_baja` FOREIGN KEY (`id_baja_por`) REFERENCES `usuarios` (`id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `fk_notas_miembros_grupo` FOREIGN KEY (`id_grupo`) REFERENCES `notas_grupos` (`id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `fk_notas_miembros_usuario` FOREIGN KEY (`id_usuario`) REFERENCES `usuarios` (`id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `chk_notas_miembros_baja` CHECK (((`fecha_baja` is null) = (`id_baja_por` is null)))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `notas_respuestas` (
  `id` int NOT NULL AUTO_INCREMENT,
  `id_nota` int NOT NULL,
  `id_autor` int NOT NULL,
  `texto` text CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `fecha` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `fk_notas_respuestas_nota` (`id_nota`),
  KEY `fk_notas_respuestas_autor` (`id_autor`),
  CONSTRAINT `fk_notas_respuestas_autor` FOREIGN KEY (`id_autor`) REFERENCES `usuarios` (`id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `fk_notas_respuestas_nota` FOREIGN KEY (`id_nota`) REFERENCES `notas` (`id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `chk_notas_respuestas_texto` CHECK ((`texto` <> _utf8mb4''))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `notas_vistas` (
  `id_nota` int NOT NULL,
  `id_usuario` int NOT NULL,
  `fecha_vista` datetime(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) COMMENT 'Última vez que el usuario abrió la nota',
  PRIMARY KEY (`id_nota`,`id_usuario`),
  KEY `fk_notas_vistas_usuario` (`id_usuario`),
  CONSTRAINT `fk_notas_vistas_nota` FOREIGN KEY (`id_nota`) REFERENCES `notas` (`id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `fk_notas_vistas_usuario` FOREIGN KEY (`id_usuario`) REFERENCES `usuarios` (`id`) ON DELETE RESTRICT ON UPDATE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `numero` (
  `id_numero` int NOT NULL AUTO_INCREMENT,
  `id_proyecto` int NOT NULL COMMENT 'Un número por proyecto: su carpeta',
  `id_revista` int NOT NULL,
  `volumen` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `numero` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `suplemento` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `titulo_especial` varchar(300) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'Número temático completo: JATS issue-title, Crossref titles',
  `anio` year DEFAULT NULL COMMENT 'JATS pub-date date-type=collection',
  `mes` tinyint DEFAULT NULL,
  `pagina_inicial` int DEFAULT NULL COMMENT 'Solo por_volumen: dónde arranca este número. Si está, manda; si no, se calcula del número anterior del volumen',
  `estado` enum('abierto','cerrado') CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'abierto',
  `imagen_tapa` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `fecha_creacion` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `fecha_actualizacion` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `usuario_creacion` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `clave_identidad` varchar(70) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci GENERATED ALWAYS AS (concat(ifnull(`volumen`,_utf8mb4''),_utf8mb4'|',ifnull(`numero`,_utf8mb4''),_utf8mb4'|',ifnull(`suplemento`,_utf8mb4''))) STORED COMMENT 'Identidad del número dentro de la revista; los NULL cuentan como vacío',
  PRIMARY KEY (`id_numero`),
  UNIQUE KEY `uq_numero_proyecto` (`id_proyecto`),
  UNIQUE KEY `uq_numero_identidad` (`id_revista`,`clave_identidad`),
  CONSTRAINT `fk_numero_proyecto` FOREIGN KEY (`id_proyecto`) REFERENCES `proyectos` (`id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `fk_numero_revista` FOREIGN KEY (`id_revista`) REFERENCES `revista` (`id_revista`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `chk_numero_mes` CHECK (((`mes` is null) or (`mes` between 1 and 12))),
  CONSTRAINT `chk_numero_numero` CHECK ((`numero` <> _utf8mb4'')),
  CONSTRAINT `chk_numero_pagina` CHECK (((`pagina_inicial` is null) or (`pagina_inicial` > 0))),
  CONSTRAINT `chk_numero_suplemento` CHECK ((`suplemento` <> _utf8mb4'')),
  CONSTRAINT `chk_numero_volumen` CHECK ((`volumen` <> _utf8mb4''))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Número de revista (N1), uno a uno con el proyecto' ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `numero_contribuyente` (
  `id` int NOT NULL AUTO_INCREMENT,
  `id_numero` int NOT NULL,
  `id_dossier` int DEFAULT NULL COMMENT 'Nulo: editor del número completo (Crossref journal_issue)',
  `id_autor` int NOT NULL,
  `rol` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'editor',
  `orden` int NOT NULL DEFAULT '0',
  PRIMARY KEY (`id`),
  KEY `fk_ncontrib_numero` (`id_numero`),
  KEY `fk_ncontrib_dossier` (`id_dossier`),
  KEY `fk_ncontrib_autor` (`id_autor`),
  CONSTRAINT `fk_ncontrib_autor` FOREIGN KEY (`id_autor`) REFERENCES `autores` (`id_autor`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `fk_ncontrib_dossier` FOREIGN KEY (`id_dossier`) REFERENCES `numero_dossier` (`id_dossier`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `fk_ncontrib_numero` FOREIGN KEY (`id_numero`) REFERENCES `numero` (`id_numero`) ON DELETE RESTRICT ON UPDATE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Editores del número o de un dossier' ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `numero_dossier` (
  `id_dossier` int NOT NULL AUTO_INCREMENT,
  `id_numero` int NOT NULL,
  `id_seccion` int NOT NULL COMMENT 'La sección Dossier de la revista: da el encabezado',
  `orden` int NOT NULL DEFAULT '0',
  `epigrafe` text CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci COMMENT 'Opcional, como en las partes del libro',
  `fecha_creacion` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `fecha_actualizacion` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `usuario_creacion` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  PRIMARY KEY (`id_dossier`),
  KEY `fk_dossier_numero` (`id_numero`),
  KEY `fk_dossier_seccion` (`id_seccion`),
  CONSTRAINT `fk_dossier_numero` FOREIGN KEY (`id_numero`) REFERENCES `numero` (`id_numero`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `fk_dossier_seccion` FOREIGN KEY (`id_seccion`) REFERENCES `revista_seccion` (`id_seccion`) ON DELETE RESTRICT ON UPDATE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Dossier: agrupación dentro de un número (equivale a la parte del libro)' ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `numero_dossier_titulo` (
  `id_dossier` int NOT NULL,
  `idioma` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT 'Código BCP 47 (SC-23)',
  `titulo` varchar(500) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `subtitulo` varchar(500) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  PRIMARY KEY (`id_dossier`,`idioma`),
  CONSTRAINT `fk_dossier_titulo` FOREIGN KEY (`id_dossier`) REFERENCES `numero_dossier` (`id_dossier`) ON DELETE CASCADE ON UPDATE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Título y subtítulo del dossier, por idioma' ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `numero_pieza` (
  `id_pieza` int NOT NULL AUTO_INCREMENT,
  `id_numero` int NOT NULL,
  `nombre_archivo` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT 'Espacio reservado fm-00 a fm-09: el nombre da la posición (SC-25)',
  `tipo` enum('tapa','legales','sumario') CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  PRIMARY KEY (`id_pieza`),
  UNIQUE KEY `uq_pieza_nombre` (`id_numero`,`nombre_archivo`),
  UNIQUE KEY `uq_pieza_tipo` (`id_numero`,`tipo`),
  CONSTRAINT `fk_pieza_numero` FOREIGN KEY (`id_numero`) REFERENCES `numero` (`id_numero`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `chk_pieza_nombre` CHECK (regexp_like(`nombre_archivo`,_utf8mb4'^fm-0[0-9](-[a-z0-9-]+)?$',_utf8mb4'c'))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Preliminares declaradas del número: piezas sin cuerpo (como SC-25)' ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `pais` (
  `codigo` char(2) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT 'ISO 3166-1 alfa-2: JATS country/@country',
  `nombre` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT 'Nombre en español (iso-codes)',
  `nombre_en` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT 'Nombre en inglés (iso-codes)',
  PRIMARY KEY (`codigo`),
  CONSTRAINT `chk_pais_codigo` CHECK (regexp_like(`codigo`,_utf8mb4'^[A-Z]{2}$',_utf8mb4'c'))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Países ISO 3166-1 (1.30.0): catálogo fijo, de iso-codes 4.16.0' ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `partes_libro` (
  `id_parte` int NOT NULL AUTO_INCREMENT,
  `id_libro` int NOT NULL,
  `orden` int NOT NULL,
  `titulo` varchar(500) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `subtitulo` varchar(500) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `epigrafe` text CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci,
  `doi_parte` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `notas_internas` text CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci,
  `fecha_creacion` datetime DEFAULT CURRENT_TIMESTAMP,
  `fecha_actualizacion` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `usuario_creacion` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  PRIMARY KEY (`id_parte`),
  KEY `fk_partes_libro` (`id_libro`),
  KEY `ix_partes_orden` (`id_libro`,`orden`),
  CONSTRAINT `fk_partes_libro` FOREIGN KEY (`id_libro`) REFERENCES `libros_md` (`id_libro`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `proyectos` (
  `id` int NOT NULL AUTO_INCREMENT,
  `nombre` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `activo` tinyint(1) NOT NULL DEFAULT '1',
  `ocupado` tinyint(1) NOT NULL DEFAULT '0',
  `tipo_producto` int NOT NULL,
  `integracion_github` enum('sin_integracion','con_integracion') CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'sin_integracion' COMMENT 'Controla si el push remoto genera estado-proyecto.json para GitHub Actions',
  `fecha_creacion` datetime DEFAULT CURRENT_TIMESTAMP,
  `fecha_modificacion` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `usuario_propietario` varchar(32) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `revista` (
  `id_revista` int NOT NULL AUTO_INCREMENT,
  `titulo` varchar(500) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT 'JATS journal-title',
  `titulo_abreviado` varchar(200) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'JATS abbrev-journal-title',
  `id_editorial` int NOT NULL COMMENT 'La editorial de la revista (1.26.0; obligatoria desde la 1.27.0)',
  `acronimo` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'JATS journal-id; acrónimo SciELO',
  `issn_impreso` varchar(9) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `issn_electronico` varchar(9) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `email_editorial` varchar(200) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'Correo propio de la revista; vacío, vale el de la editorial (1.26.0)',
  `estilo_cita` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'Identificador del catálogo cita-*-config.tex (SC-57)',
  `modelo_paginacion` enum('por_numero','por_volumen','continua','por_articulo') CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'por_numero' COMMENT 'Foliado: por_numero (cada número empieza en 1), por_volumen (sigue al número anterior del volumen), por_articulo (cada artículo empieza en 1), continua (e-id por artículo, elocation-id)',
  `rotulo_volumen` varchar(30) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'Cómo se muestra el volumen: Año, Vol., Tomo (Año III)',
  `idiomas_publicacion` varchar(200) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'Códigos separados por coma (SC-23)',
  `tipo_acceso_defecto` enum('abierto','suscripcion','embargo') CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'Se hereda hasta publicar',
  `fecha_creacion` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `fecha_actualizacion` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `usuario_creacion` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `logo` mediumblob COMMENT 'PNG de la cabecera del artículo; vacío, el genérico (1.28.0)',
  PRIMARY KEY (`id_revista`),
  KEY `fk_revista_editorial` (`id_editorial`),
  CONSTRAINT `fk_revista_editorial` FOREIGN KEY (`id_editorial`) REFERENCES `editorial` (`id_editorial`) ON DELETE RESTRICT ON UPDATE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Revista: nivel permanente (N0)' ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `revista_bloque` (
  `id_revista` int NOT NULL,
  `bloque` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT 'Código del bloque N3',
  `nivel` enum('desactivado','habilitado','solicitado','exigido') CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'desactivado' COMMENT 'Patrón de OJS (METADATA_*)',
  PRIMARY KEY (`id_revista`,`bloque`),
  CONSTRAINT `fk_bloque_revista` FOREIGN KEY (`id_revista`) REFERENCES `revista` (`id_revista`) ON DELETE RESTRICT ON UPDATE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Activación de los bloques opcionales por revista' ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `revista_organo` (
  `id_organo` int NOT NULL AUTO_INCREMENT,
  `id_revista` int NOT NULL,
  `nombre` varchar(200) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT 'Como lo llama la revista: Comité editorial, Coordinadora editorial...',
  `orden` int NOT NULL DEFAULT '0',
  `activo` tinyint(1) NOT NULL DEFAULT '1',
  PRIMARY KEY (`id_organo`),
  KEY `fk_organo_revista` (`id_revista`),
  CONSTRAINT `fk_organo_revista` FOREIGN KEY (`id_revista`) REFERENCES `revista` (`id_revista`) ON DELETE RESTRICT ON UPDATE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Órganos editoriales de la revista (página legal)' ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `revista_organo_miembro` (
  `id_miembro` int NOT NULL AUTO_INCREMENT,
  `id_organo` int NOT NULL,
  `id_autor` int NOT NULL,
  `afiliacion` varchar(300) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'La que se muestra: IESCODE-UNPAZ/CONICET, Argentina. Va en la membresía: cambia con el tiempo',
  `orden` int NOT NULL DEFAULT '0',
  `desde` date NOT NULL,
  `hasta` date DEFAULT NULL COMMENT 'Nulo: vigente',
  PRIMARY KEY (`id_miembro`),
  KEY `fk_miembro_organo` (`id_organo`),
  KEY `fk_miembro_autor` (`id_autor`),
  CONSTRAINT `fk_miembro_autor` FOREIGN KEY (`id_autor`) REFERENCES `autores` (`id_autor`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `fk_miembro_organo` FOREIGN KEY (`id_organo`) REFERENCES `revista_organo` (`id_organo`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `chk_miembro_vigencia` CHECK (((`hasta` is null) or (`hasta` >= `desde`)))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Miembros de un órgano editorial, con vigencia' ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `revista_plantilla_resumen` (
  `id_plantilla` int NOT NULL AUTO_INCREMENT,
  `id_revista` int NOT NULL,
  `nombre` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT 'Por ejemplo IMRyD',
  `activa` tinyint(1) NOT NULL DEFAULT '1',
  PRIMARY KEY (`id_plantilla`),
  UNIQUE KEY `uq_plantilla_nombre` (`id_revista`,`nombre`),
  CONSTRAINT `fk_plantilla_revista` FOREIGN KEY (`id_revista`) REFERENCES `revista` (`id_revista`) ON DELETE RESTRICT ON UPDATE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Plantillas de resumen estructurado de la revista' ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `revista_plantilla_resumen_seccion` (
  `id_plantilla` int NOT NULL,
  `codigo` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT 'Estable: introduccion, metodos, resultados, conclusiones...',
  `orden` int NOT NULL,
  PRIMARY KEY (`id_plantilla`,`codigo`),
  UNIQUE KEY `uq_plantilla_seccion_orden` (`id_plantilla`,`orden`),
  CONSTRAINT `fk_plantilla_seccion` FOREIGN KEY (`id_plantilla`) REFERENCES `revista_plantilla_resumen` (`id_plantilla`) ON DELETE RESTRICT ON UPDATE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Secciones de una plantilla de resumen, en orden' ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `revista_plantilla_resumen_titulo` (
  `id_plantilla` int NOT NULL,
  `codigo` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `idioma` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT 'Código BCP 47 (SC-23)',
  `titulo` varchar(200) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT 'Lo que se imprime: Métodos, Methods...',
  PRIMARY KEY (`id_plantilla`,`codigo`,`idioma`),
  CONSTRAINT `fk_plantilla_titulo` FOREIGN KEY (`id_plantilla`, `codigo`) REFERENCES `revista_plantilla_resumen_seccion` (`id_plantilla`, `codigo`) ON DELETE RESTRICT ON UPDATE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Título de cada sección de plantilla, por idioma' ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `revista_seccion` (
  `id_seccion` int NOT NULL AUTO_INCREMENT,
  `id_revista` int NOT NULL,
  `codigo` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT 'Único por revista',
  `orden` int NOT NULL DEFAULT '0',
  `article_type_defecto` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'Código JATS que propone al crear un artículo',
  `id_plantilla_resumen` int DEFAULT NULL COMMENT 'Nulo: resumen simple',
  `activa` tinyint(1) NOT NULL DEFAULT '1',
  PRIMARY KEY (`id_seccion`),
  UNIQUE KEY `uq_seccion_codigo` (`id_revista`,`codigo`),
  KEY `fk_seccion_plantilla` (`id_plantilla_resumen`),
  CONSTRAINT `fk_seccion_plantilla` FOREIGN KEY (`id_plantilla_resumen`) REFERENCES `revista_plantilla_resumen` (`id_plantilla`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `fk_seccion_revista` FOREIGN KEY (`id_revista`) REFERENCES `revista` (`id_revista`) ON DELETE RESTRICT ON UPDATE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Secciones permanentes de la revista (decisión 15)' ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `revista_seccion_titulo` (
  `id_seccion` int NOT NULL,
  `idioma` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT 'Código BCP 47 (SC-23)',
  `titulo` varchar(300) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT 'JATS subj-group heading; sumario',
  PRIMARY KEY (`id_seccion`,`idioma`),
  CONSTRAINT `fk_seccion_titulo` FOREIGN KEY (`id_seccion`) REFERENCES `revista_seccion` (`id_seccion`) ON DELETE RESTRICT ON UPDATE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Título visible de cada sección, por idioma' ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `series` (
  `id_serie` int NOT NULL AUTO_INCREMENT,
  `id_coleccion` int NOT NULL,
  `nombre` varchar(500) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `nombre_abreviado` varchar(200) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `issn` varchar(9) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `coordinador_serie` varchar(300) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `descripcion` text CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci,
  `ano_inicio` year DEFAULT NULL,
  `ano_fin` year DEFAULT NULL,
  `activa` tinyint(1) NOT NULL DEFAULT '1',
  `notas_internas` text CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci,
  `fecha_creacion` datetime DEFAULT CURRENT_TIMESTAMP,
  `fecha_actualizacion` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `usuario_creacion` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  PRIMARY KEY (`id_serie`),
  UNIQUE KEY `uk_series_issn` (`issn`),
  KEY `ix_series_nombre` (`nombre`),
  KEY `fk_series_coleccion` (`id_coleccion`),
  CONSTRAINT `fk_series_coleccion` FOREIGN KEY (`id_coleccion`) REFERENCES `colecciones` (`id_coleccion`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `sigla_catalogo` (
  `id_sigla` int NOT NULL AUTO_INCREMENT,
  `sigla` varchar(32) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_as_cs NOT NULL COMMENT 'Forma exacta: LyF y LYF son distintas',
  `desarrollo` varchar(500) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_as_ci NOT NULL COMMENT 'Singular; solo *...* como marca (cursiva)',
  `desarrollo_plural` varchar(500) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_as_ci DEFAULT NULL COMMENT 'Solo para el texto; no va a la lista',
  `idioma` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'BCP 47; NULL es la lengua del libro',
  PRIMARY KEY (`id_sigla`),
  UNIQUE KEY `uq_sigcat_sigla_desarrollo` (`sigla`,`desarrollo`),
  CONSTRAINT `chk_sigcat_desarrollo` CHECK ((`desarrollo` <> _utf8mb4'')),
  CONSTRAINT `chk_sigcat_idioma` CHECK ((`idioma` <> _utf8mb4'')),
  CONSTRAINT `chk_sigcat_plural` CHECK ((`desarrollo_plural` <> _utf8mb4'')),
  CONSTRAINT `chk_sigcat_sigla` CHECK ((`sigla` <> _utf8mb4''))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci ROW_FORMAT=DYNAMIC COMMENT='Catálogo de siglas de la editorial, común a todos los libros';
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `tipo_declaracion` (
  `codigo` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `etiqueta` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `bloque` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'Nulo: núcleo. Si no, el bloque N3 que lo habilita',
  `orden` int NOT NULL DEFAULT '1000',
  `activo` tinyint(1) NOT NULL DEFAULT '1',
  PRIMARY KEY (`codigo`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Catálogo de tipos de declaración: alimenta el formulario (SC-23)' ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `usuarios` (
  `id` int NOT NULL AUTO_INCREMENT,
  `usuario` varchar(12) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `clave` char(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `activo` tinyint(1) NOT NULL DEFAULT '1',
  `email` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `fecha_creacion` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `ultimo_acceso` datetime DEFAULT NULL,
  `sonido` tinyint(1) NOT NULL DEFAULT '1',
  `intervalo_notas` tinyint(1) NOT NULL DEFAULT '1',
  `metodo` varchar(24) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `en_linea` tinyint(1) NOT NULL DEFAULT '0',
  `id_proyecto_actual` int DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `fk_usuarios_proyecto_actual` (`id_proyecto_actual`),
  CONSTRAINT `fk_usuarios_proyecto_actual` FOREIGN KEY (`id_proyecto_actual`) REFERENCES `proyectos` (`id`) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `usuarios_sistema` (
  `id` int NOT NULL AUTO_INCREMENT,
  `usuario` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `clave_hash` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `rol` enum('admin','usuario') CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'usuario',
  `email` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `fecha_creacion` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `activo` tinyint(1) DEFAULT '1',
  `primer_acceso` tinyint(1) DEFAULT '1',
  `fecha_cambio_password` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `usuario` (`usuario`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;
SET @saved_cs_client     = @@character_set_client;
/*!50503 SET character_set_client = utf8mb4 */;
/*!50001 CREATE VIEW `v_web_coleccion` AS SELECT 
 1 AS `id_coleccion`,
 1 AS `nombre`,
 1 AS `nombre_abreviado`,
 1 AS `descripcion`,
 1 AS `url_logo`,
 1 AS `activa`*/;
SET character_set_client = @saved_cs_client;
SET @saved_cs_client     = @@character_set_client;
/*!50503 SET character_set_client = utf8mb4 */;
/*!50001 CREATE VIEW `v_web_libro` AS SELECT 
 1 AS `id_libro`,
 1 AS `titulo_libro`,
 1 AS `subtitulo`,
 1 AS `idioma_principal`,
 1 AS `isbn_impreso`,
 1 AS `isbn_electronico`,
 1 AS `numero_paginas`,
 1 AS `ano_publicacion`,
 1 AS `mes_numero`,
 1 AS `fecha_publicacion_completa`,
 1 AS `id_coleccion`,
 1 AS `numero_en_coleccion`,
 1 AS `estado_publicacion`,
 1 AS `tipo_acceso`,
 1 AS `resumen_libro`,
 1 AS `palabras_clave_libro`,
 1 AS `url_libro`,
 1 AS `url_descarga_pdf`,
 1 AS `url_descarga_epub`,
 1 AS `url_compra`,
 1 AS `licencia`,
 1 AS `url_licencia`,
 1 AS `idioma_nombre`,
 1 AS `idioma_nombre_ingles`,
 1 AS `resumen_traducido`,
 1 AS `idioma_resumen_traducido`,
 1 AS `resumen_traducido_2`,
 1 AS `idioma_resumen_traducido_2`,
 1 AS `palabras_clave_traducidas`,
 1 AS `idioma_palabras_clave_traducidas`,
 1 AS `palabras_clave_traducidas_2`,
 1 AS `idioma_palabras_clave_traducidas_2`,
 1 AS `destino_html`,
 1 AS `url_portal`*/;
SET character_set_client = @saved_cs_client;
SET @saved_cs_client     = @@character_set_client;
/*!50503 SET character_set_client = utf8mb4 */;
/*!50001 CREATE VIEW `v_web_libro_persona` AS SELECT 
 1 AS `id_libro`,
 1 AS `id_relacion`,
 1 AS `orden_autoria`,
 1 AS `rol_libro`,
 1 AS `nombre_mostrar`,
 1 AS `apellidos_nombre`,
 1 AS `orcid`,
 1 AS `id_autor`*/;
SET character_set_client = @saved_cs_client;
SET @saved_cs_client     = @@character_set_client;
/*!50503 SET character_set_client = utf8mb4 */;
/*!50001 CREATE VIEW `v_web_libro_tapa` AS SELECT 
 1 AS `id_libro`,
 1 AS `imagen`,
 1 AS `formato`,
 1 AS `ancho`,
 1 AS `alto`,
 1 AS `sha256`*/;
SET character_set_client = @saved_cs_client;
SET @saved_cs_client     = @@character_set_client;
/*!50503 SET character_set_client = utf8mb4 */;
/*!50001 CREATE VIEW `v_web_libro_venta` AS SELECT 
 1 AS `id_libro`,
 1 AS `tienda`,
 1 AS `url`*/;
SET character_set_client = @saved_cs_client;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `vocabulario_termino` (
  `id_termino` int NOT NULL AUTO_INCREMENT,
  `vocabulario` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT 'MeSH, DeCS... (por valor, SC-23)',
  `idioma` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT 'Código BCP 47 (SC-23)',
  `termino` varchar(300) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_as_ci NOT NULL COMMENT 'Sin distinguir mayúsculas; sí tildes y ñ',
  `identificador` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'Código del vocabulario: D006801 (MeSH)',
  PRIMARY KEY (`id_termino`),
  UNIQUE KEY `uq_voc_termino` (`vocabulario`,`idioma`,`termino`),
  UNIQUE KEY `uq_voc_identificador` (`vocabulario`,`idioma`,`identificador`),
  CONSTRAINT `chk_voc_identificador` CHECK ((`identificador` <> _utf8mb4'')),
  CONSTRAINT `chk_voc_termino` CHECK ((`termino` <> _utf8mb4'')),
  CONSTRAINT `chk_voc_vocabulario` CHECK ((`vocabulario` <> _utf8mb4''))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Catálogo global de términos de vocabularios controlados' ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!50001 DROP VIEW IF EXISTS `v_web_coleccion`*/;
/*!50001 SET @saved_cs_client          = @@character_set_client */;
/*!50001 SET @saved_cs_results         = @@character_set_results */;
/*!50001 SET @saved_col_connection     = @@collation_connection */;
/*!50001 SET character_set_client      = utf8mb4 */;
/*!50001 SET character_set_results     = utf8mb4 */;
/*!50001 SET collation_connection      = utf8mb4_unicode_ci */;
/*!50001 CREATE ALGORITHM=UNDEFINED */
/*!50013 */
/*!50001 VIEW `v_web_coleccion` AS select `c`.`id_coleccion` AS `id_coleccion`,`c`.`nombre` AS `nombre`,`c`.`nombre_abreviado` AS `nombre_abreviado`,`c`.`descripcion` AS `descripcion`,`c`.`url_logo` AS `url_logo`,`c`.`activa` AS `activa` from `colecciones` `c` where exists(select 1 from `v_web_libro` `v` where (`v`.`id_coleccion` = `c`.`id_coleccion`)) */;
/*!50001 SET character_set_client      = @saved_cs_client */;
/*!50001 SET character_set_results     = @saved_cs_results */;
/*!50001 SET collation_connection      = @saved_col_connection */;
/*!50001 DROP VIEW IF EXISTS `v_web_libro`*/;
/*!50001 SET @saved_cs_client          = @@character_set_client */;
/*!50001 SET @saved_cs_results         = @@character_set_results */;
/*!50001 SET @saved_col_connection     = @@collation_connection */;
/*!50001 SET character_set_client      = utf8mb4 */;
/*!50001 SET character_set_results     = utf8mb4 */;
/*!50001 SET collation_connection      = utf8mb4_unicode_ci */;
/*!50001 CREATE ALGORITHM=UNDEFINED */
/*!50013 */
/*!50001 VIEW `v_web_libro` AS select `l`.`id_libro` AS `id_libro`,`l`.`titulo_libro` AS `titulo_libro`,`l`.`subtitulo` AS `subtitulo`,`l`.`idioma_principal` AS `idioma_principal`,`l`.`isbn_impreso` AS `isbn_impreso`,`l`.`isbn_electronico` AS `isbn_electronico`,`l`.`numero_paginas` AS `numero_paginas`,`l`.`ano_publicacion` AS `ano_publicacion`,(case lower(trim(`l`.`mes_publicacion`)) when 'enero' then 1 when 'febrero' then 2 when 'marzo' then 3 when 'abril' then 4 when 'mayo' then 5 when 'junio' then 6 when 'julio' then 7 when 'agosto' then 8 when 'septiembre' then 9 when 'setiembre' then 9 when 'octubre' then 10 when 'noviembre' then 11 when 'diciembre' then 12 else NULL end) AS `mes_numero`,`l`.`fecha_publicacion_completa` AS `fecha_publicacion_completa`,`l`.`id_coleccion` AS `id_coleccion`,`l`.`numero_en_coleccion` AS `numero_en_coleccion`,`l`.`estado_publicacion` AS `estado_publicacion`,`l`.`tipo_acceso` AS `tipo_acceso`,`l`.`resumen_libro` AS `resumen_libro`,`l`.`palabras_clave_libro` AS `palabras_clave_libro`,`l`.`url_libro` AS `url_libro`,`l`.`url_descarga_pdf` AS `url_descarga_pdf`,`l`.`url_descarga_epub` AS `url_descarga_epub`,`l`.`url_compra` AS `url_compra`,`l`.`licencia_defecto` AS `licencia`,`l`.`url_licencia` AS `url_licencia`,`i`.`nombre` AS `idioma_nombre`,`i`.`nombre_ingles` AS `idioma_nombre_ingles`,`l`.`resumen_traducido` AS `resumen_traducido`,`l`.`idioma_resumen_traducido` AS `idioma_resumen_traducido`,`l`.`resumen_traducido_2` AS `resumen_traducido_2`,`l`.`idioma_resumen_traducido_2` AS `idioma_resumen_traducido_2`,`l`.`palabras_clave_traducidas` AS `palabras_clave_traducidas`,`l`.`idioma_palabras_clave_traducidas` AS `idioma_palabras_clave_traducidas`,`l`.`palabras_clave_traducidas_2` AS `palabras_clave_traducidas_2`,`l`.`idioma_palabras_clave_traducidas_2` AS `idioma_palabras_clave_traducidas_2`,`l`.`destino_html` AS `destino_html`,`l`.`url_portal` AS `url_portal` from (`libros_md` `l` left join `idiomas` `i` on((`i`.`codigo` = `l`.`idioma_principal`))) where (`l`.`estado_publicacion` in ('publicado','agotado','descatalogado')) */;
/*!50001 SET character_set_client      = @saved_cs_client */;
/*!50001 SET character_set_results     = @saved_cs_results */;
/*!50001 SET collation_connection      = @saved_col_connection */;
/*!50001 DROP VIEW IF EXISTS `v_web_libro_persona`*/;
/*!50001 SET @saved_cs_client          = @@character_set_client */;
/*!50001 SET @saved_cs_results         = @@character_set_results */;
/*!50001 SET @saved_col_connection     = @@collation_connection */;
/*!50001 SET character_set_client      = utf8mb4 */;
/*!50001 SET character_set_results     = utf8mb4 */;
/*!50001 SET collation_connection      = utf8mb4_unicode_ci */;
/*!50001 CREATE ALGORITHM=UNDEFINED */
/*!50013 */
/*!50001 VIEW `v_web_libro_persona` AS select `la`.`id_libro` AS `id_libro`,`la`.`id_relacion` AS `id_relacion`,`la`.`orden_autoria` AS `orden_autoria`,`la`.`rol_libro` AS `rol_libro`,coalesce(nullif(trim(`a`.`nombre_preferido`),''),`a`.`nombre_completo`) AS `nombre_mostrar`,`a`.`apellidos_nombre` AS `apellidos_nombre`,`a`.`orcid` AS `orcid`,`la`.`id_autor` AS `id_autor` from ((`libro_autor` `la` join `autores` `a` on((`a`.`id_autor` = `la`.`id_autor`))) join `v_web_libro` `v` on((`v`.`id_libro` = `la`.`id_libro`))) */;
/*!50001 SET character_set_client      = @saved_cs_client */;
/*!50001 SET character_set_results     = @saved_cs_results */;
/*!50001 SET collation_connection      = @saved_col_connection */;
/*!50001 DROP VIEW IF EXISTS `v_web_libro_tapa`*/;
/*!50001 SET @saved_cs_client          = @@character_set_client */;
/*!50001 SET @saved_cs_results         = @@character_set_results */;
/*!50001 SET @saved_col_connection     = @@collation_connection */;
/*!50001 SET character_set_client      = utf8mb4 */;
/*!50001 SET character_set_results     = utf8mb4 */;
/*!50001 SET collation_connection      = utf8mb4_unicode_ci */;
/*!50001 CREATE ALGORITHM=UNDEFINED */
/*!50013 */
/*!50001 VIEW `v_web_libro_tapa` AS select `t`.`id_libro` AS `id_libro`,`t`.`imagen` AS `imagen`,`t`.`formato` AS `formato`,`t`.`ancho` AS `ancho`,`t`.`alto` AS `alto`,`t`.`sha256` AS `sha256` from (`libro_tapa_web` `t` join `v_web_libro` `v` on((`v`.`id_libro` = `t`.`id_libro`))) */;
/*!50001 SET character_set_client      = @saved_cs_client */;
/*!50001 SET character_set_results     = @saved_cs_results */;
/*!50001 SET collation_connection      = @saved_col_connection */;
/*!50001 DROP VIEW IF EXISTS `v_web_libro_venta`*/;
/*!50001 SET @saved_cs_client          = @@character_set_client */;
/*!50001 SET @saved_cs_results         = @@character_set_results */;
/*!50001 SET @saved_col_connection     = @@collation_connection */;
/*!50001 SET character_set_client      = utf8mb4 */;
/*!50001 SET character_set_results     = utf8mb4 */;
/*!50001 SET collation_connection      = utf8mb4_unicode_ci */;
/*!50001 CREATE ALGORITHM=UNDEFINED */
/*!50013 */
/*!50001 VIEW `v_web_libro_venta` AS select `lv`.`id_libro` AS `id_libro`,`lv`.`tienda` AS `tienda`,`lv`.`url` AS `url` from (`libro_venta` `lv` join `v_web_libro` `v` on((`v`.`id_libro` = `lv`.`id_libro`))) */;
/*!50001 SET character_set_client      = @saved_cs_client */;
/*!50001 SET character_set_results     = @saved_cs_results */;
/*!50001 SET collation_connection      = @saved_col_connection */;

-- ------------------------------------------------------------------
-- 2. DATOS SEMILLA
--    Solo contenido propio de la aplicación. Las tablas no listadas
--    acá se instalan vacías a propósito.
-- ------------------------------------------------------------------
INSERT INTO `manual_ayudas` (`id`, `clave`, `componente`, `idioma`, `ayuda`, `usuario_creacion`, `fecha_creacion`, `usuario_modificacion`, `fecha_modificacion`) VALUES (50,'sponsors','sponsors','es','<!-- ESPAÑOL -->\n<h3>¿Qué es un sponsor?</h3>\n<p>Un sponsor (patrocinador o financiador) es la organización o institución que proporciona apoyo financiero o recursos para la realización de la investigación que se reporta en el artículo científico.</p>\n\n<h4>Tipos de sponsors comunes</h4>\n<p>Los sponsors pueden incluir diferentes tipos de entidades:</p>\n<ul>\n<li><strong>Agencias gubernamentales</strong>: Organismos estatales que financian investigación (ej: CONICET, CNPq, CONACYT)</li>\n<li><strong>Fundaciones privadas</strong>: Organizaciones sin fines de lucro dedicadas al apoyo científico</li>\n<li><strong>Empresas</strong>: Compañías privadas que financian investigación relacionada con sus intereses</li>\n<li><strong>Instituciones académicas</strong>: Universidades o centros de investigación que proveen fondos internos</li>\n<li><strong>Organismos internacionales</strong>: Entidades multilaterales (ej: OMS, UNESCO)</li>\n</ul>\n\n<h4>¿Cómo registrar el sponsor?</h4>\n<p>Ingrese el nombre oficial completo de la organización patrocinadora. Si hay múltiples sponsors, liste cada uno en una línea separada o separados por punto y coma.</p>\n<p><strong>Ejemplo correcto</strong>:</p>\n<pre>Consejo Nacional de Investigaciones Científicas y Técnicas (CONICET)</pre>\n\n<h4>Información complementaria</h4>\n<p>El registro del sponsor es importante para:</p>\n<ul>\n<li>Cumplir con requisitos de transparencia en la investigación</li>\n<li>Facilitar la identificación de fuentes de financiamiento</li>\n<li>Permitir análisis bibliométricos sobre patrones de financiamiento</li>\n<li>Satisfacer requisitos de indexación en bases de datos internacionales (PubMed, Scopus, Web of Science)</li>\n</ul>\n\n<h4>Relación con otros campos</h4>\n<p>Este campo se complementa con:</p>\n<ul>\n<li><strong>Award ID</strong>: Número de identificación del proyecto o beca</li>\n<li><strong>Funding Statement</strong>: Declaración completa de financiamiento</li>\n<li><strong>Conflict of Interest</strong>: Declaración de conflictos de interés relacionados con el financiamiento</li>\n</ul>\n','elisa','2026-01-08 23:20:09','elisa','2026-01-08 23:20:09');
INSERT INTO `manual_ayudas` (`id`, `clave`, `componente`, `idioma`, `ayuda`, `usuario_creacion`, `fecha_creacion`, `usuario_modificacion`, `fecha_modificacion`) VALUES (51,'sponsors','sponsors','pt','<!-- PORTUGUÉS -->\n<h3>O que é um sponsor?</h3>\n<p>Um sponsor (patrocinador ou financiador) é a organização ou instituição que fornece apoio financeiro ou recursos para a realização da pesquisa relatada no artigo científico.</p>\n\n<h4>Tipos comuns de sponsors</h4>\n<p>Os sponsors podem incluir diferentes tipos de entidades:</p>\n<ul>\n<li><strong>Agências governamentais</strong>: Órgãos estatais que financiam pesquisa (ex: CONICET, CNPq, CONACYT)</li>\n<li><strong>Fundações privadas</strong>: Organizações sem fins lucrativos dedicadas ao apoio científico</li>\n<li><strong>Empresas</strong>: Companhias privadas que financiam pesquisa relacionada aos seus interesses</li>\n<li><strong>Instituições acadêmicas</strong>: Universidades ou centros de pesquisa que fornecem fundos internos</li>\n<li><strong>Organismos internacionais</strong>: Entidades multilaterais (ex: OMS, UNESCO)</li>\n</ul>\n\n<h4>Como registrar o sponsor?</h4>\n<p>Insira o nome oficial completo da organização patrocinadora. Se houver múltiplos sponsors, liste cada um em uma linha separada ou separados por ponto e vírgula.</p>\n<p><strong>Exemplo correto</strong>:</p>\n<pre>Consejo Nacional de Investigaciones Científicas y Técnicas (CONICET)</pre>\n\n<h4>Informação complementar</h4>\n<p>O registro do sponsor é importante para:</p>\n<ul>\n<li>Cumprir com requisitos de transparência na pesquisa</li>\n<li>Facilitar a identificação de fontes de financiamento</li>\n<li>Permitir análises bibliométricas sobre padrões de financiamento</li>\n<li>Satisfazer requisitos de indexação em bases de dados internacionais (PubMed, Scopus, Web of Science)</li>\n</ul>\n\n<h4>Relação com outros campos</h4>\n<p>Este campo se complementa com:</p>\n<ul>\n<li><strong>Award ID</strong>: Número de identificação do projeto ou bolsa</li>\n<li><strong>Funding Statement</strong>: Declaração completa de financiamento</li>\n<li><strong>Conflict of Interest</strong>: Declaração de conflitos de interesse relacionados ao financiamento</li>\n</ul>\n','elisa','2026-01-08 23:20:09','elisa','2026-01-08 23:20:09');
INSERT INTO `manual_ayudas` (`id`, `clave`, `componente`, `idioma`, `ayuda`, `usuario_creacion`, `fecha_creacion`, `usuario_modificacion`, `fecha_modificacion`) VALUES (52,'sponsors','sponsors','en','<!-- INGLÉS -->\n<h3>What is a sponsor?</h3>\n<p>A sponsor (funder or funding organization) is the organization or institution that provides financial support or resources for conducting the research reported in the scientific article.</p>\n\n<h4>Common types of sponsors</h4>\n<p>Sponsors may include different types of entities:</p>\n<ul>\n<li><strong>Government agencies</strong>: State organizations that fund research (e.g., CONICET, CNPq, CONACYT)</li>\n<li><strong>Private foundations</strong>: Non-profit organizations dedicated to scientific support</li>\n<li><strong>Companies</strong>: Private corporations funding research related to their interests</li>\n<li><strong>Academic institutions</strong>: Universities or research centers providing internal funds</li>\n<li><strong>International organizations</strong>: Multilateral entities (e.g., WHO, UNESCO)</li>\n</ul>\n\n<h4>How to register the sponsor?</h4>\n<p>Enter the full official name of the sponsoring organization. If there are multiple sponsors, list each one on a separate line or separated by semicolons.</p>\n<p><strong>Correct example</strong>:</p>\n<pre>Consejo Nacional de Investigaciones Científicas y Técnicas (CONICET)</pre>\n\n<h4>Additional information</h4>\n<p>Recording the sponsor is important to:</p>\n<ul>\n<li>Comply with research transparency requirements</li>\n<li>Facilitate identification of funding sources</li>\n<li>Enable bibliometric analyses of funding patterns</li>\n<li>Meet indexing requirements in international databases (PubMed, Scopus, Web of Science)</li>\n</ul>\n\n<h4>Relationship with other fields</h4>\n<p>This field complements:</p>\n<ul>\n<li><strong>Award ID</strong>: Project or grant identification number</li>\n<li><strong>Funding Statement</strong>: Complete funding declaration</li>\n<li><strong>Conflict of Interest</strong>: Declaration of conflicts of interest related to funding</li>\n</ul>\n','elisa','2026-01-08 23:20:09','elisa','2026-01-08 23:20:09');
INSERT INTO `manual_ayudas` (`id`, `clave`, `componente`, `idioma`, `ayuda`, `usuario_creacion`, `fecha_creacion`, `usuario_modificacion`, `fecha_modificacion`) VALUES (53,'sponsors','sponsors','it','<!-- ITALIANO -->\n<h3>Cos\'è uno sponsor?</h3>\n<p>Uno sponsor (finanziatore o ente finanziatore) è l\'organizzazione o istituzione che fornisce supporto finanziario o risorse per la realizzazione della ricerca presentata nell\'articolo scientifico.</p>\n\n<h4>Tipi comuni di sponsor</h4>\n<p>Gli sponsor possono includere diversi tipi di entità:</p>\n<ul>\n<li><strong>Agenzie governative</strong>: Organismi statali che finanziano la ricerca (es: CONICET, CNPq, CONACYT)</li>\n<li><strong>Fondazioni private</strong>: Organizzazioni senza scopo di lucro dedicate al sostegno scientifico</li>\n<li><strong>Aziende</strong>: Società private che finanziano ricerche correlate ai loro interessi</li>\n<li><strong>Istituzioni accademiche</strong>: Università o centri di ricerca che forniscono fondi interni</li>\n<li><strong>Organismi internazionali</strong>: Entità multilaterali (es: OMS, UNESCO)</li>\n</ul>\n\n<h4>Come registrare lo sponsor?</h4>\n<p>Inserire il nome ufficiale completo dell\'organizzazione sponsor. Se ci sono più sponsor, elencare ciascuno su una riga separata o separati da punto e virgola.</p>\n<p><strong>Esempio corretto</strong>:</p>\n<pre>Consejo Nacional de Investigaciones Científicas y Técnicas (CONICET)</pre>\n\n<h4>Informazioni complementari</h4>\n<p>La registrazione dello sponsor è importante per:</p>\n<ul>\n<li>Rispettare i requisiti di trasparenza nella ricerca</li>\n<li>Facilitare l\'identificazione delle fonti di finanziamento</li>\n<li>Consentire analisi bibliometriche sui modelli di finanziamento</li>\n<li>Soddisfare i requisiti di indicizzazione nelle banche dati internazionali (PubMed, Scopus, Web of Science)</li>\n</ul>\n\n<h4>Relazione con altri campi</h4>\n<p>Questo campo si integra con:</p>\n<ul>\n<li><strong>Award ID</strong>: Numero di identificazione del progetto o della borsa</li>\n<li><strong>Funding Statement</strong>: Dichiarazione completa di finanziamento</li>\n<li><strong>Conflict of Interest</strong>: Dichiarazione di conflitti di interesse relativi al finanziamento</li>\n</ul>','elisa','2026-01-08 23:20:09','elisa','2026-01-08 23:20:09');
INSERT INTO `manual_ayudas` (`id`, `clave`, `componente`, `idioma`, `ayuda`, `usuario_creacion`, `fecha_creacion`, `usuario_modificacion`, `fecha_modificacion`) VALUES (54,'sponsors','sponsors','fr','<!-- FRANCÉS -->\n<h3>Qu\'est-ce qu\'un sponsor?</h3>\n<p>Un sponsor (commanditaire ou organisme de financement) est l\'organisation ou l\'institution qui fournit un soutien financier ou des ressources pour la réalisation de la recherche présentée dans l\'article scientifique.</p>\n\n<h4>Types courants de sponsors</h4>\n<p>Les sponsors peuvent inclure différents types d\'entités:</p>\n<ul>\n<li><strong>Agences gouvernementales</strong>: Organismes étatiques qui financent la recherche (ex: CONICET, CNPq, CONACYT)</li>\n<li><strong>Fondations privées</strong>: Organisations à but non lucratif dédiées au soutien scientifique</li>\n<li><strong>Entreprises</strong>: Sociétés privées qui financent des recherches liées à leurs intérêts</li>\n<li><strong>Institutions académiques</strong>: Universités ou centres de recherche fournissant des fonds internes</li>\n<li><strong>Organismes internationaux</strong>: Entités multilatérales (ex: OMS, UNESCO)</li>\n</ul>\n\n<h4>Comment enregistrer le sponsor?</h4>\n<p>Saisissez le nom officiel complet de l\'organisation sponsor. S\'il y a plusieurs sponsors, listez chacun sur une ligne séparée ou séparés par des points-virgules.</p>\n<p><strong>Exemple correct</strong>:</p>\n<pre>Consejo Nacional de Investigaciones Científicas y Técnicas (CONICET)</pre>\n\n<h4>Information complémentaire</h4>\n<p>L\'enregistrement du sponsor est important pour:</p>\n<ul>\n<li>Respecter les exigences de transparence dans la recherche</li>\n<li>Faciliter l\'identification des sources de financement</li>\n<li>Permettre des analyses bibliométriques sur les modèles de financement</li>\n<li>Satisfaire les exigences d\'indexation dans les bases de données internationales (PubMed, Scopus, Web of Science)</li>\n</ul>\n\n<h4>Relation avec d\'autres champs</h4>\n<p>Ce champ complète:</p>\n<ul>\n<li><strong>Award ID</strong>: Numéro d\'identification du projet ou de la bourse</li>\n<li><strong>Funding Statement</strong>: Déclaration complète de financement</li>\n<li><strong>Conflict of Interest</strong>: Déclaration de conflits d\'intérêts liés au financement</li>\n</ul>\n','elisa','2026-01-08 23:20:09','elisa','2026-01-08 23:20:09');
INSERT INTO `manual_ayudas` (`id`, `clave`, `componente`, `idioma`, `ayuda`, `usuario_creacion`, `fecha_creacion`, `usuario_modificacion`, `fecha_modificacion`) VALUES (55,'sponsors','sponsors','de','<!-- ALEMÁN -->\n<h3>Was ist ein Sponsor?</h3>\n<p>Ein Sponsor (Förderer oder Finanzierungsorganisation) ist die Organisation oder Institution, die finanzielle Unterstützung oder Ressourcen für die Durchführung der im wissenschaftlichen Artikel berichteten Forschung bereitstellt.</p>\n\n<h4>Häufige Arten von Sponsoren</h4>\n<p>Sponsoren können verschiedene Arten von Einrichtungen umfassen:</p>\n<ul>\n<li><strong>Regierungsbehörden</strong>: Staatliche Organisationen, die Forschung finanzieren (z.B.: CONICET, CNPq, CONACYT)</li>\n<li><strong>Private Stiftungen</strong>: Gemeinnützige Organisationen, die sich der wissenschaftlichen Förderung widmen</li>\n<li><strong>Unternehmen</strong>: Private Firmen, die Forschung im Zusammenhang mit ihren Interessen finanzieren</li>\n<li><strong>Akademische Einrichtungen</strong>: Universitäten oder Forschungszentren, die interne Mittel bereitstellen</li>\n<li><strong>Internationale Organisationen</strong>: Multilaterale Einrichtungen (z.B.: WHO, UNESCO)</li>\n</ul>\n\n<h4>Wie registriert man den Sponsor?</h4>\n<p>Geben Sie den vollständigen offiziellen Namen der fördernden Organisation ein. Falls es mehrere Sponsoren gibt, listen Sie jeden in einer separaten Zeile auf oder getrennt durch Semikolons.</p>\n<p><strong>Korrektes Beispiel</strong>:</p>\n<pre>Consejo Nacional de Investigaciones Científicas y Técnicas (CONICET)</pre>\n\n<h4>Zusätzliche Informationen</h4>\n<p>Die Registrierung des Sponsors ist wichtig, um:</p>\n<ul>\n<li>Transparenzanforderungen in der Forschung zu erfüllen</li>\n<li>Die Identifizierung von Finanzierungsquellen zu erleichtern</li>\n<li>Bibliometrische Analysen zu Finanzierungsmustern zu ermöglichen</li>\n<li>Indexierungsanforderungen in internationalen Datenbanken zu erfüllen (PubMed, Scopus, Web of Science)</li>\n</ul>\n\n<h4>Beziehung zu anderen Feldern</h4>\n<p>Dieses Feld ergänzt:</p>\n<ul>\n<li><strong>Award ID</strong>: Identifikationsnummer des Projekts oder Stipendiums</li>\n<li><strong>Funding Statement</strong>: Vollständige Finanzierungserklärung</li>\n<li><strong>Conflict of Interest</strong>: Erklärung von Interessenkonflikten im Zusammenhang mit der Finanzierung</li>\n</ul>','elisa','2026-01-08 23:20:09','elisa','2026-01-08 23:20:09');
INSERT INTO `manual_ayudas` (`id`, `clave`, `componente`, `idioma`, `ayuda`, `usuario_creacion`, `fecha_creacion`, `usuario_modificacion`, `fecha_modificacion`) VALUES (56,'book-author','book_author','es','<!-- ESPAÑOL -->\n<h3>¿Qué es bookauthor?</h3>\n<p>El campo <code>bookauthor</code> se utiliza para especificar el autor o autores de la obra principal (<code>booktitle</code>) cuando se está citando una parte específica de un libro que tiene su propio título (<code>title</code>).</p>\n\n<h4>¿Cuándo usar bookauthor?</h4>\n<p>Este campo es especialmente útil en los siguientes casos:</p>\n<ul>\n<li><strong>Capítulos en libros con autor principal</strong>: Cuando se cita un capítulo o sección de un libro donde el autor del libro completo es diferente del autor del capítulo específico</li>\n<li><strong>Obras en colecciones de un mismo autor</strong>: Cuando se referencia un ensayo o trabajo específico dentro de las obras completas de un autor</li>\n<li><strong>Traducciones y comentarios</strong>: Cuando la obra principal tiene un autor y el comentario, introducción o capítulo específico tiene otro autor</li>\n</ul>\n\n<h4>Ejemplo de uso correcto</h4>\n<pre>@InBook{lear,\n  author = {Shakespeare, William},\n  bookauthor = {Shakespeare, William},\n  maintitle = {Collected Works},\n  booktitle = {Tragedies},\n  title = {King Lear},\n  volume = {1},\n  pages = {53-159}\n}</pre>\n<p>En el ejemplo anterior, <code>author</code> se refiere al autor de \"King Lear\" y <code>bookauthor</code> al autor de \"Tragedies\".</p>\n\n<h4>Diferencias con otros campos de autoría</h4>\n<ul>\n<li><strong>author</strong>: Autor del trabajo específico (<code>title</code>)</li>\n<li><strong>bookauthor</strong>: Autor de la obra que contiene el trabajo (<code>booktitle</code>)</li>\n<li><strong>editor</strong>: Editor de la obra, cuando no hay un autor principal</li>\n</ul>\n\n<h4>Concatenación automática</h4>\n<p>Los estilos bibliográficos estándar de BibLaTeX concatenan automáticamente los campos <code>bookauthor</code>, <code>editor</code> y <code>translator</code> cuando son idénticos, evitando repeticiones innecesarias en la bibliografía.</p>\n\n<h4>Tipos de entrada donde se usa</h4>\n<p>Este campo es opcional y relevante principalmente en:</p>\n<ul>\n<li><strong>@InBook</strong>: Para partes de libros con título propio</li>\n<li><strong>@BookInBook</strong>: Para obras originalmente independientes reimpresas en colecciones</li>\n</ul>\n','franco','2026-01-09 00:34:24','franco','2026-01-09 14:07:56');
INSERT INTO `manual_ayudas` (`id`, `clave`, `componente`, `idioma`, `ayuda`, `usuario_creacion`, `fecha_creacion`, `usuario_modificacion`, `fecha_modificacion`) VALUES (57,'book-author','book_author','pt','<!-- PORTUGUÉS -->\n<h3>O que é bookauthor?</h3>\n<p>O campo <code>bookauthor</code> é usado para especificar o autor ou autores da obra principal (<code>booktitle</code>) quando se cita uma parte específica de um livro que tem seu próprio título (<code>title</code>).</p>\n\n<h4>Quando usar bookauthor?</h4>\n<p>Este campo é especialmente útil nos seguintes casos:</p>\n<ul>\n<li><strong>Capítulos em livros com autor principal</strong>: Quando se cita um capítulo ou seção de um livro onde o autor do livro completo é diferente do autor do capítulo específico</li>\n<li><strong>Obras em coleções do mesmo autor</strong>: Quando se referencia um ensaio ou trabalho específico dentro das obras completas de um autor</li>\n<li><strong>Traduções e comentários</strong>: Quando a obra principal tem um autor e o comentário, introdução ou capítulo específico tem outro autor</li>\n</ul>\n\n<h4>Exemplo de uso correto</h4>\n<pre>@InBook{lear,\n  author = {Shakespeare, William},\n  bookauthor = {Shakespeare, William},\n  maintitle = {Collected Works},\n  booktitle = {Tragedies},\n  title = {King Lear},\n  volume = {1},\n  pages = {53-159}\n}</pre>\n<p>No exemplo acima, <code>author</code> refere-se ao autor de \"King Lear\" e <code>bookauthor</code> ao autor de \"Tragedies\".</p>\n\n<h4>Diferenças com outros campos de autoria</h4>\n<ul>\n<li><strong>author</strong>: Autor do trabalho específico (<code>title</code>)</li>\n<li><strong>bookauthor</strong>: Autor da obra que contém o trabalho (<code>booktitle</code>)</li>\n<li><strong>editor</strong>: Editor da obra, quando não há um autor principal</li>\n</ul>\n\n<h4>Concatenação automática</h4>\n<p>Os estilos bibliográficos padrão do BibLaTeX concatenam automaticamente os campos <code>bookauthor</code>, <code>editor</code> e <code>translator</code> quando são idênticos, evitando repetições desnecessárias na bibliografia.</p>\n\n<h4>Tipos de entrada onde se usa</h4>\n<p>Este campo é opcional e relevante principalmente em:</p>\n<ul>\n<li><strong>@InBook</strong>: Para partes de livros com título próprio</li>\n<li><strong>@BookInBook</strong>: Para obras originalmente independentes reimpresas em coleções</li>\n</ul>\n','franco','2026-01-09 00:34:24','franco','2026-01-09 14:08:08');
INSERT INTO `manual_ayudas` (`id`, `clave`, `componente`, `idioma`, `ayuda`, `usuario_creacion`, `fecha_creacion`, `usuario_modificacion`, `fecha_modificacion`) VALUES (58,'book-author','book_author','en','<!-- INGLÉS -->\n<h3>What is bookauthor?</h3>\n<p>The <code>bookauthor</code> field is used to specify the author(s) of the main work (<code>booktitle</code>) when citing a specific part of a book that has its own title (<code>title</code>).</p>\n\n<h4>When to use bookauthor?</h4>\n<p>This field is especially useful in the following cases:</p>\n<ul>\n<li><strong>Chapters in books with a main author</strong>: When citing a chapter or section of a book where the author of the complete book differs from the author of the specific chapter</li>\n<li><strong>Works in collections by the same author</strong>: When referencing a specific essay or work within an author\'s collected works</li>\n<li><strong>Translations and commentaries</strong>: When the main work has one author and the commentary, introduction, or specific chapter has another author</li>\n</ul>\n\n<h4>Correct usage example</h4>\n<pre>@InBook{lear,\n  author = {Shakespeare, William},\n  bookauthor = {Shakespeare, William},\n  maintitle = {Collected Works},\n  booktitle = {Tragedies},\n  title = {King Lear},\n  volume = {1},\n  pages = {53-159}\n}</pre>\n<p>In the example above, <code>author</code> refers to the author of \"King Lear\" and <code>bookauthor</code> to the author of \"Tragedies\".</p>\n\n<h4>Differences with other authorship fields</h4>\n<ul>\n<li><strong>author</strong>: Author of the specific work (<code>title</code>)</li>\n<li><strong>bookauthor</strong>: Author of the work containing the piece (<code>booktitle</code>)</li>\n<li><strong>editor</strong>: Editor of the work, when there is no main author</li>\n</ul>\n\n<h4>Automatic concatenation</h4>\n<p>BibLaTeX\'s standard bibliographic styles automatically concatenate the <code>bookauthor</code>, <code>editor</code>, and <code>translator</code> fields when they are identical, avoiding unnecessary repetitions in the bibliography.</p>\n\n<h4>Entry types where it is used</h4>\n<p>This field is optional and mainly relevant in:</p>\n<ul>\n<li><strong>@InBook</strong>: For parts of books with their own title</li>\n<li><strong>@BookInBook</strong>: For originally independent works reprinted in collections</li>\n</ul>\n','franco','2026-01-09 00:34:24','franco','2026-01-09 14:08:21');
INSERT INTO `manual_ayudas` (`id`, `clave`, `componente`, `idioma`, `ayuda`, `usuario_creacion`, `fecha_creacion`, `usuario_modificacion`, `fecha_modificacion`) VALUES (59,'bookauthor','book_author','it','<!-- ITALIANO -->\n<h3>Cos\'è bookauthor?</h3>\n<p>Il campo <code>bookauthor</code> viene utilizzato per specificare l\'autore o gli autori dell\'opera principale (<code>booktitle</code>) quando si cita una parte specifica di un libro che ha un proprio titolo (<code>title</code>).</p>\n\n<h4>Quando usare bookauthor?</h4>\n<p>Questo campo è particolarmente utile nei seguenti casi:</p>\n<ul>\n<li><strong>Capitoli in libri con un autore principale</strong>: Quando si cita un capitolo o una sezione di un libro dove l\'autore del libro completo è diverso dall\'autore del capitolo specifico</li>\n<li><strong>Opere in raccolte dello stesso autore</strong>: Quando si fa riferimento a un saggio o lavoro specifico all\'interno delle opere complete di un autore</li>\n<li><strong>Traduzioni e commenti</strong>: Quando l\'opera principale ha un autore e il commento, l\'introduzione o il capitolo specifico ha un altro autore</li>\n</ul>\n\n<h4>Esempio di uso corretto</h4>\n<pre>@InBook{lear,\n  author = {Shakespeare, William},\n  bookauthor = {Shakespeare, William},\n  maintitle = {Collected Works},\n  booktitle = {Tragedies},\n  title = {King Lear},\n  volume = {1},\n  pages = {53-159}\n}</pre>\n<p>Nell\'esempio sopra, <code>author</code> si riferisce all\'autore di \"King Lear\" e <code>bookauthor</code> all\'autore di \"Tragedies\".</p>\n\n<h4>Differenze con altri campi di autore</h4>\n<ul>\n<li><strong>author</strong>: Autore del lavoro specifico (<code>title</code>)</li>\n<li><strong>bookauthor</strong>: Autore dell\'opera che contiene il lavoro (<code>booktitle</code>)</li>\n<li><strong>editor</strong>: Editore dell\'opera, quando non c\'è un autore principale</li>\n</ul>\n\n<h4>Concatenazione automatica</h4>\n<p>Gli stili bibliografici standard di BibLaTeX concatenano automaticamente i campi <code>bookauthor</code>, <code>editor</code> e <code>translator</code> quando sono identici, evitando ripetizioni non necessarie nella bibliografia.</p>\n\n<h4>Tipi di voce dove viene utilizzato</h4>\n<p>Questo campo è opzionale e principalmente rilevante in:</p>\n<ul>\n<li><strong>@InBook</strong>: Per parti di libri con titolo proprio</li>\n<li><strong>@BookInBook</strong>: Per opere originariamente indipendenti ristampate in raccolte</li>\n</ul>\n','franco','2026-01-09 00:34:24','franco','2026-01-09 00:34:24');
INSERT INTO `manual_ayudas` (`id`, `clave`, `componente`, `idioma`, `ayuda`, `usuario_creacion`, `fecha_creacion`, `usuario_modificacion`, `fecha_modificacion`) VALUES (60,'book-author','book_author','fr','<!-- FRANCÉS -->\n<h3>Qu\'est-ce que bookauthor?</h3>\n<p>Le champ <code>bookauthor</code> est utilisé pour spécifier l\'auteur ou les auteurs de l\'œuvre principale (<code>booktitle</code>) lorsqu\'on cite une partie spécifique d\'un livre qui a son propre titre (<code>title</code>).</p>\n\n<h4>Quand utiliser bookauthor?</h4>\n<p>Ce champ est particulièrement utile dans les cas suivants:</p>\n<ul>\n<li><strong>Chapitres dans des livres avec un auteur principal</strong>: Lorsqu\'on cite un chapitre ou une section d\'un livre où l\'auteur du livre complet diffère de l\'auteur du chapitre spécifique</li>\n<li><strong>Œuvres dans des collections d\'un même auteur</strong>: Lorsqu\'on référence un essai ou un travail spécifique au sein des œuvres complètes d\'un auteur</li>\n<li><strong>Traductions et commentaires</strong>: Lorsque l\'œuvre principale a un auteur et que le commentaire, l\'introduction ou le chapitre spécifique a un autre auteur</li>\n</ul>\n\n<h4>Exemple d\'utilisation correcte</h4>\n<pre>@InBook{lear,\n  author = {Shakespeare, William},\n  bookauthor = {Shakespeare, William},\n  maintitle = {Collected Works},\n  booktitle = {Tragedies},\n  title = {King Lear},\n  volume = {1},\n  pages = {53-159}\n}</pre>\n<p>Dans l\'exemple ci-dessus, <code>author</code> fait référence à l\'auteur de \"King Lear\" et <code>bookauthor</code> à l\'auteur de \"Tragedies\".</p>\n\n<h4>Différences avec les autres champs d\'auteur</h4>\n<ul>\n<li><strong>author</strong>: Auteur du travail spécifique (<code>title</code>)</li>\n<li><strong>bookauthor</strong>: Auteur de l\'œuvre contenant le travail (<code>booktitle</code>)</li>\n<li><strong>editor</strong>: Éditeur de l\'œuvre, lorsqu\'il n\'y a pas d\'auteur principal</li>\n</ul>\n\n<h4>Concaténation automatique</h4>\n<p>Les styles bibliographiques standard de BibLaTeX concatènent automatiquement les champs <code>bookauthor</code>, <code>editor</code> et <code>translator</code> lorsqu\'ils sont identiques, évitant les répétitions inutiles dans la bibliographie.</p>\n\n<h4>Types d\'entrée où il est utilisé</h4>\n<p>Ce champ est optionnel et principalement pertinent dans:</p>\n<ul>\n<li><strong>@InBook</strong>: Pour les parties de livres avec leur propre titre</li>\n<li><strong>@BookInBook</strong>: Pour les œuvres originellement indépendantes réimprimées dans des collections</li>\n</ul>\n','franco','2026-01-09 00:34:24','franco','2026-01-09 14:08:33');
INSERT INTO `manual_ayudas` (`id`, `clave`, `componente`, `idioma`, `ayuda`, `usuario_creacion`, `fecha_creacion`, `usuario_modificacion`, `fecha_modificacion`) VALUES (61,'book-author','book_author','de','<!-- ALEMÁN -->\n<h3>Was ist bookauthor?</h3>\n<p>Das Feld <code>bookauthor</code> wird verwendet, um den Autor oder die Autoren des Hauptwerks (<code>booktitle</code>) anzugeben, wenn ein bestimmter Teil eines Buches zitiert wird, der einen eigenen Titel (<code>title</code>) hat.</p>\n\n<h4>Wann verwendet man bookauthor?</h4>\n<p>Dieses Feld ist besonders nützlich in den folgenden Fällen:</p>\n<ul>\n<li><strong>Kapitel in Büchern mit einem Hauptautor</strong>: Beim Zitieren eines Kapitels oder Abschnitts eines Buches, bei dem sich der Autor des vollständigen Buches vom Autor des spezifischen Kapitels unterscheidet</li>\n<li><strong>Werke in Sammlungen desselben Autors</strong>: Beim Verweis auf einen bestimmten Essay oder ein Werk innerhalb der gesammelten Werke eines Autors</li>\n<li><strong>Übersetzungen und Kommentare</strong>: Wenn das Hauptwerk einen Autor hat und der Kommentar, die Einleitung oder das spezifische Kapitel einen anderen Autor hat</li>\n</ul>\n\n<h4>Beispiel für korrekte Verwendung</h4>\n<pre>@InBook{lear,\n  author = {Shakespeare, William},\n  bookauthor = {Shakespeare, William},\n  maintitle = {Collected Works},\n  booktitle = {Tragedies},\n  title = {King Lear},\n  volume = {1},\n  pages = {53-159}\n}</pre>\n<p>Im obigen Beispiel bezieht sich <code>author</code> auf den Autor von \"King Lear\" und <code>bookauthor</code> auf den Autor von \"Tragedies\".</p>\n\n<h4>Unterschiede zu anderen Autorenfeldern</h4>\n<ul>\n<li><strong>author</strong>: Autor des spezifischen Werks (<code>title</code>)</li>\n<li><strong>bookauthor</strong>: Autor des Werks, das die Arbeit enthält (<code>booktitle</code>)</li>\n<li><strong>editor</strong>: Herausgeber des Werks, wenn es keinen Hauptautor gibt</li>\n</ul>\n\n<h4>Automatische Verkettung</h4>\n<p>Die Standard-Bibliographiestile von BibLaTeX verketten automatisch die Felder <code>bookauthor</code>, <code>editor</code> und <code>translator</code>, wenn sie identisch sind, wodurch unnötige Wiederholungen in der Bibliographie vermieden werden.</p>\n\n<h4>Eintragstypen, in denen es verwendet wird</h4>\n<p>Dieses Feld ist optional und hauptsächlich relevant in:</p>\n<ul>\n<li><strong>@InBook</strong>: Für Teile von Büchern mit eigenem Titel</li>\n<li><strong>@BookInBook</strong>: Für ursprünglich eigenständige Werke, die in Sammlungen nachgedruckt wurden</li>\n</ul>','franco','2026-01-09 00:34:24','franco','2026-01-09 14:08:46');
INSERT INTO `manual_ayudas` (`id`, `clave`, `componente`, `idioma`, `ayuda`, `usuario_creacion`, `fecha_creacion`, `usuario_modificacion`, `fecha_modificacion`) VALUES (68,'clasificacion-oecd','clasificacion_oecd','es','<!-- ESPAÑOL -->\n<h3>¿Qué es clasificacion-oecd?</h3>\n<p>El campo <code>clasificacion-oecd</code> contiene la clasificación de Campos de Ciencia y Tecnología (FOS - Fields of Science and Technology) según el estándar establecido por la Organización para la Cooperación y el Desarrollo Económicos (OECD) en el Manual de Frascati.</p>\n\n<h4>Estructura de la clasificación</h4>\n<p>La clasificación OECD se organiza en una estructura jerárquica de dos niveles:</p>\n<ul>\n<li><strong>Nivel principal (1 dígito)</strong>: 6 campos mayores</li>\n<li><strong>Nivel secundario (2 dígitos)</strong>: 42 subcategorías</li>\n</ul>\n\n<h4>Campos principales de la clasificación OECD</h4>\n<p>Los seis campos principales son:</p>\n<ol>\n<li><strong>Ciencias Naturales</strong> (Natural Sciences)</li>\n<li><strong>Ingeniería y Tecnología</strong> (Engineering and Technology)</li>\n<li><strong>Ciencias Médicas y de la Salud</strong> (Medical and Health Sciences)</li>\n<li><strong>Ciencias Agrícolas y Veterinarias</strong> (Agricultural and Veterinary Sciences)</li>\n<li><strong>Ciencias Sociales</strong> (Social Sciences)</li>\n<li><strong>Humanidades y Artes</strong> (Humanities and Arts)</li>\n</ol>\n\n<h4>¿Para qué sirve este campo?</h4>\n<p>La clasificación OECD se utiliza para:</p>\n<ul>\n<li><strong>Indexación internacional</strong>: Facilita la inclusión en bases de datos académicas globales</li>\n<li><strong>Análisis bibliométricos</strong>: Permite comparaciones entre disciplinas y áreas de investigación</li>\n<li><strong>Estadísticas de I+D</strong>: Estandariza la recopilación de datos sobre investigación y desarrollo</li>\n<li><strong>Interoperabilidad de datos</strong>: Permite el intercambio de información entre instituciones y países</li>\n</ul>\n\n<h4>Formato de entrada</h4>\n<p>El campo debe contener el código numérico de la clasificación OECD en formato de dos dígitos separados por punto.</p>\n<p><strong>Ejemplos correctos</strong>:</p>\n<p>Una sola clasificación:</p>\n<pre>3.2</pre>\n<p>(Corresponde a \"Medicina Clínica\" dentro de \"Ciencias Médicas y de la Salud\")</p>\n<p>Múltiples clasificaciones (separadas por punto y coma):</p>\n<pre>1.2; 2.3</pre>\n<p>(Corresponde a \"Ciencias de la Computación e Información\" y \"Otras Ingenierías y Tecnologías\")</p>\n\n<h4>Relación con otros sistemas de clasificación</h4>\n<p>La clasificación OECD es compatible y se mapea con otros sistemas como:</p>\n<ul>\n<li>Web of Science Research Areas</li>\n<li>ANZSRC (Australian and New Zealand Standard Research Classification)</li>\n<li>UNESCO FOS</li>\n<li>Essential Science Indicators</li>\n</ul>\n\n<h4>Importancia para revistas académicas</h4>\n<p>Para revistas científicas, especialmente aquellas indexadas en bases internacionales como Scopus, Web of Science o SciELO, este campo es fundamental para:</p>\n<ul>\n<li>Mejorar la visibilidad de los artículos</li>\n<li>Facilitar búsquedas temáticas</li>\n<li>Cumplir con requisitos de indexación internacional</li>\n<li>Permitir análisis multidisciplinarios cuando se asignan múltiples clasificaciones</li>\n</ul>\n','elisa','2026-01-09 01:07:26','elisa','2026-01-09 01:07:26');
INSERT INTO `manual_ayudas` (`id`, `clave`, `componente`, `idioma`, `ayuda`, `usuario_creacion`, `fecha_creacion`, `usuario_modificacion`, `fecha_modificacion`) VALUES (69,'clasificacion-oecd','clasificacion_oecd','pt','<!-- PORTUGUÉS -->\n<h3>O que é clasificacion-oecd?</h3>\n<p>O campo <code>clasificacion-oecd</code> contém a classificação de Campos de Ciência e Tecnologia (FOS - Fields of Science and Technology) segundo o padrão estabelecido pela Organização para a Cooperação e Desenvolvimento Econômico (OCDE) no Manual de Frascati.</p>\n\n<h4>Estrutura da classificação</h4>\n<p>A classificação OCDE está organizada em uma estrutura hierárquica de dois níveis:</p>\n<ul>\n<li><strong>Nível principal (1 dígito)</strong>: 6 campos principais</li>\n<li><strong>Nível secundário (2 dígitos)</strong>: 42 subcategorias</li>\n</ul>\n\n<h4>Campos principais da classificação OCDE</h4>\n<p>Os seis campos principais são:</p>\n<ol>\n<li><strong>Ciências Naturais</strong> (Natural Sciences)</li>\n<li><strong>Engenharia e Tecnologia</strong> (Engineering and Technology)</li>\n<li><strong>Ciências Médicas e da Saúde</strong> (Medical and Health Sciences)</li>\n<li><strong>Ciências Agrárias e Veterinárias</strong> (Agricultural and Veterinary Sciences)</li>\n<li><strong>Ciências Sociais</strong> (Social Sciences)</li>\n<li><strong>Humanidades e Artes</strong> (Humanities and Arts)</li>\n</ol>\n\n<h4>Para que serve este campo?</h4>\n<p>A classificação OCDE é utilizada para:</p>\n<ul>\n<li><strong>Indexação internacional</strong>: Facilita a inclusão em bases de dados acadêmicas globais</li>\n<li><strong>Análises bibliométricas</strong>: Permite comparações entre disciplinas e áreas de pesquisa</li>\n<li><strong>Estatísticas de P&D</strong>: Padroniza a coleta de dados sobre pesquisa e desenvolvimento</li>\n<li><strong>Interoperabilidade de dados</strong>: Permite o intercâmbio de informação entre instituições e países</li>\n</ul>\n\n<h4>Formato de entrada</h4>\n<p>O campo deve conter o código numérico da classificação OCDE em formato de dois dígitos separados por ponto.</p>\n<p><strong>Exemplos corretos</strong>:</p>\n<p>Uma única classificação:</p>\n<pre>3.2</pre>\n<p>(Corresponde a \"Medicina Clínica\" dentro de \"Ciências Médicas e da Saúde\")</p>\n<p>Múltiplas classificações (separadas por ponto e vírgula):</p>\n<pre>1.2; 2.3</pre>\n<p>(Corresponde a \"Ciências da Computação e Informação\" e \"Outras Engenharias e Tecnologias\")</p>\n\n<h4>Relação com outros sistemas de classificação</h4>\n<p>A classificação OCDE é compatível e se mapeia com outros sistemas como:</p>\n<ul>\n<li>Web of Science Research Areas</li>\n<li>ANZSRC (Australian and New Zealand Standard Research Classification)</li>\n<li>UNESCO FOS</li>\n<li>Essential Science Indicators</li>\n</ul>\n\n<h4>Importância para revistas acadêmicas</h4>\n<p>Para revistas científicas, especialmente aquelas indexadas em bases internacionais como Scopus, Web of Science ou SciELO, este campo é fundamental para:</p>\n<ul>\n<li>Melhorar a visibilidade dos artigos</li>\n<li>Facilitar buscas temáticas</li>\n<li>Cumprir com requisitos de indexação internacional</li>\n<li>Permitir análises multidisciplinares quando são atribuídas múltiplas classificações</li>\n</ul>\n','elisa','2026-01-09 01:07:26','elisa','2026-01-09 01:07:26');
INSERT INTO `manual_ayudas` (`id`, `clave`, `componente`, `idioma`, `ayuda`, `usuario_creacion`, `fecha_creacion`, `usuario_modificacion`, `fecha_modificacion`) VALUES (70,'clasificacion-oecd','clasificacion_oecd','en','<!-- INGLÉS -->\n<h3>What is clasificacion-oecd?</h3>\n<p>The <code>clasificacion-oecd</code> field contains the Fields of Science and Technology (FOS) classification according to the standard established by the Organisation for Economic Co-operation and Development (OECD) in the Frascati Manual.</p>\n\n<h4>Classification structure</h4>\n<p>The OECD classification is organized in a two-level hierarchical structure:</p>\n<ul>\n<li><strong>Major level (1 digit)</strong>: 6 major fields</li>\n<li><strong>Minor level (2 digits)</strong>: 42 subcategories</li>\n</ul>\n\n<h4>Main OECD classification fields</h4>\n<p>The six main fields are:</p>\n<ol>\n<li><strong>Natural Sciences</strong></li>\n<li><strong>Engineering and Technology</strong></li>\n<li><strong>Medical and Health Sciences</strong></li>\n<li><strong>Agricultural and Veterinary Sciences</strong></li>\n<li><strong>Social Sciences</strong></li>\n<li><strong>Humanities and Arts</strong></li>\n</ol>\n\n<h4>What is this field used for?</h4>\n<p>The OECD classification is used for:</p>\n<ul>\n<li><strong>International indexing</strong>: Facilitates inclusion in global academic databases</li>\n<li><strong>Bibliometric analysis</strong>: Enables comparisons between disciplines and research areas</li>\n<li><strong>R&D statistics</strong>: Standardizes the collection of research and development data</li>\n<li><strong>Data interoperability</strong>: Allows information exchange between institutions and countries</li>\n</ul>\n\n<h4>Input format</h4>\n<p>The field must contain the OECD classification numerical code in two-digit format separated by a period.</p>\n<p><strong>Correct examples</strong>:</p>\n<p>Single classification:</p>\n<pre>3.2</pre>\n<p>(Corresponds to \"Clinical Medicine\" within \"Medical and Health Sciences\")</p>\n<p>Multiple classifications (separated by semicolons):</p>\n<pre>1.2; 2.3</pre>\n<p>(Corresponds to \"Computer and Information Sciences\" and \"Other Engineering and Technologies\")</p>\n\n<h4>Relationship with other classification systems</h4>\n<p>The OECD classification is compatible and maps to other systems such as:</p>\n<ul>\n<li>Web of Science Research Areas</li>\n<li>ANZSRC (Australian and New Zealand Standard Research Classification)</li>\n<li>UNESCO FOS</li>\n<li>Essential Science Indicators</li>\n</ul>\n\n<h4>Importance for academic journals</h4>\n<p>For scientific journals, especially those indexed in international databases such as Scopus, Web of Science or SciELO, this field is essential for:</p>\n<ul>\n<li>Improving article visibility</li>\n<li>Facilitating thematic searches</li>\n<li>Meeting international indexing requirements</li>\n<li>Enabling multidisciplinary analysis when multiple classifications are assigned</li>\n</ul>\n','elisa','2026-01-09 01:07:26','elisa','2026-01-09 01:07:26');
INSERT INTO `manual_ayudas` (`id`, `clave`, `componente`, `idioma`, `ayuda`, `usuario_creacion`, `fecha_creacion`, `usuario_modificacion`, `fecha_modificacion`) VALUES (71,'clasificacion-oecd','clasificacion_oecd','it','<!-- ITALIANO -->\n<h3>Cos\'è clasificacion-oecd?</h3>\n<p>Il campo <code>clasificacion-oecd</code> contiene la classificazione dei Campi della Scienza e della Tecnologia (FOS - Fields of Science and Technology) secondo lo standard stabilito dall\'Organizzazione per la Cooperazione e lo Sviluppo Economico (OCSE) nel Manuale di Frascati.</p>\n\n<h4>Struttura della classificazione</h4>\n<p>La classificazione OCSE è organizzata in una struttura gerarchica a due livelli:</p>\n<ul>\n<li><strong>Livello principale (1 cifra)</strong>: 6 campi principali</li>\n<li><strong>Livello secondario (2 cifre)</strong>: 42 sottocategorie</li>\n</ul>\n\n<h4>Campi principali della classificazione OCSE</h4>\n<p>I sei campi principali sono:</p>\n<ol>\n<li><strong>Scienze Naturali</strong> (Natural Sciences)</li>\n<li><strong>Ingegneria e Tecnologia</strong> (Engineering and Technology)</li>\n<li><strong>Scienze Mediche e della Salute</strong> (Medical and Health Sciences)</li>\n<li><strong>Scienze Agricole e Veterinarie</strong> (Agricultural and Veterinary Sciences)</li>\n<li><strong>Scienze Sociali</strong> (Social Sciences)</li>\n<li><strong>Scienze Umane e Arti</strong> (Humanities and Arts)</li>\n</ol>\n\n<h4>A cosa serve questo campo?</h4>\n<p>La classificazione OCSE è utilizzata per:</p>\n<ul>\n<li><strong>Indicizzazione internazionale</strong>: Facilita l\'inclusione nelle banche dati accademiche globali</li>\n<li><strong>Analisi bibliometriche</strong>: Consente confronti tra discipline e aree di ricerca</li>\n<li><strong>Statistiche di R&S</strong>: Standardizza la raccolta di dati su ricerca e sviluppo</li>\n<li><strong>Interoperabilità dei dati</strong>: Permette lo scambio di informazioni tra istituzioni e paesi</li>\n</ul>\n\n<h4>Formato di inserimento</h4>\n<p>Il campo deve contenere il codice numerico della classificazione OCSE in formato di due cifre separate da punto.</p>\n<p><strong>Esempi corretti</strong>:</p>\n<p>Una singola classificazione:</p>\n<pre>3.2</pre>\n<p>(Corrisponde a \"Medicina Clinica\" all\'interno di \"Scienze Mediche e della Salute\")</p>\n<p>Classificazioni multiple (separate da punto e virgola):</p>\n<pre>1.2; 2.3</pre>\n<p>(Corrisponde a \"Scienze dell\'Informatica e dell\'Informazione\" e \"Altre Ingegnerie e Tecnologie\")</p>\n\n<h4>Relazione con altri sistemi di classificazione</h4>\n<p>La classificazione OCSE è compatibile e si mappa con altri sistemi come:</p>\n<ul>\n<li>Web of Science Research Areas</li>\n<li>ANZSRC (Australian and New Zealand Standard Research Classification)</li>\n<li>UNESCO FOS</li>\n<li>Essential Science Indicators</li>\n</ul>\n\n<h4>Importanza per le riviste accademiche</h4>\n<p>Per le riviste scientifiche, specialmente quelle indicizzate in banche dati internazionali come Scopus, Web of Science o SciELO, questo campo è fondamentale per:</p>\n<ul>\n<li>Migliorare la visibilità degli articoli</li>\n<li>Facilitare le ricerche tematiche</li>\n<li>Soddisfare i requisiti di indicizzazione internazionale</li>\n<li>Consentire analisi multidisciplinari quando vengono assegnate classificazioni multiple</li>\n</ul>\n','elisa','2026-01-09 01:07:26','elisa','2026-01-09 01:07:26');
INSERT INTO `manual_ayudas` (`id`, `clave`, `componente`, `idioma`, `ayuda`, `usuario_creacion`, `fecha_creacion`, `usuario_modificacion`, `fecha_modificacion`) VALUES (72,'clasificacion-oecd','clasificacion_oecd','fr','<!-- FRANCÉS -->\n<h3>Qu\'est-ce que clasificacion-oecd?</h3>\n<p>Le champ <code>clasificacion-oecd</code> contient la classification des Domaines de la Science et de la Technologie (FOS - Fields of Science and Technology) selon la norme établie par l\'Organisation de Coopération et de Développement Économiques (OCDE) dans le Manuel de Frascati.</p>\n\n<h4>Structure de la classification</h4>\n<p>La classification OCDE est organisée en une structure hiérarchique à deux niveaux:</p>\n<ul>\n<li><strong>Niveau principal (1 chiffre)</strong>: 6 domaines majeurs</li>\n<li><strong>Niveau secondaire (2 chiffres)</strong>: 42 sous-catégories</li>\n</ul>\n\n<h4>Domaines principaux de la classification OCDE</h4>\n<p>Les six domaines principaux sont:</p>\n<ol>\n<li><strong>Sciences Naturelles</strong> (Natural Sciences)</li>\n<li><strong>Ingénierie et Technologie</strong> (Engineering and Technology)</li>\n<li><strong>Sciences Médicales et de la Santé</strong> (Medical and Health Sciences)</li>\n<li><strong>Sciences Agricoles et Vétérinaires</strong> (Agricultural and Veterinary Sciences)</li>\n<li><strong>Sciences Sociales</strong> (Social Sciences)</li>\n<li><strong>Sciences Humaines et Arts</strong> (Humanities and Arts)</li>\n</ol>\n\n<h4>À quoi sert ce champ?</h4>\n<p>La classification OCDE est utilisée pour:</p>\n<ul>\n<li><strong>Indexation internationale</strong>: Facilite l\'inclusion dans les bases de données académiques mondiales</li>\n<li><strong>Analyses bibliométriques</strong>: Permet des comparaisons entre disciplines et domaines de recherche</li>\n<li><strong>Statistiques de R&D</strong>: Standardise la collecte de données sur la recherche et le développement</li>\n<li><strong>Interopérabilité des données</strong>: Permet l\'échange d\'informations entre institutions et pays</li>\n</ul>\n\n<h4>Format de saisie</h4>\n<p>Le champ doit contenir le code numérique de la classification OCDE au format de deux chiffres séparés par un point.</p>\n<p><strong>Exemples corrects</strong>:</p>\n<p>Une seule classification:</p>\n<pre>3.2</pre>\n<p>(Correspond à \"Médecine Clinique\" dans \"Sciences Médicales et de la Santé\")</p>\n<p>Classifications multiples (séparées par des points-virgules):</p>\n<pre>1.2; 2.3</pre>\n<p>(Correspond à \"Sciences de l\'Informatique et de l\'Information\" et \"Autres Ingénieries et Technologies\")</p>\n\n<h4>Relation avec d\'autres systèmes de classification</h4>\n<p>La classification OCDE est compatible et se mappe avec d\'autres systèmes tels que:</p>\n<ul>\n<li>Web of Science Research Areas</li>\n<li>ANZSRC (Australian and New Zealand Standard Research Classification)</li>\n<li>UNESCO FOS</li>\n<li>Essential Science Indicators</li>\n</ul>\n\n<h4>Importance pour les revues académiques</h4>\n<p>Pour les revues scientifiques, particulièrement celles indexées dans les bases de données internationales comme Scopus, Web of Science ou SciELO, ce champ est fondamental pour:</p>\n<ul>\n<li>Améliorer la visibilité des articles</li>\n<li>Faciliter les recherches thématiques</li>\n<li>Répondre aux exigences d\'indexation internationale</li>\n<li>Permettre des analyses multidisciplinaires lorsque plusieurs classifications sont attribuées</li>\n</ul>\n','elisa','2026-01-09 01:07:26','elisa','2026-01-09 01:07:26');
INSERT INTO `manual_ayudas` (`id`, `clave`, `componente`, `idioma`, `ayuda`, `usuario_creacion`, `fecha_creacion`, `usuario_modificacion`, `fecha_modificacion`) VALUES (73,'clasificacion-oecd','clasificacion_oecd','de','<!-- ALEMÁN -->\n<h3>Was ist clasificacion-oecd?</h3>\n<p>Das Feld <code>clasificacion-oecd</code> enthält die Klassifizierung der Wissenschafts- und Technologiefelder (FOS - Fields of Science and Technology) gemäß dem von der Organisation für wirtschaftliche Zusammenarbeit und Entwicklung (OECD) im Frascati-Handbuch festgelegten Standard.</p>\n\n<h4>Struktur der Klassifizierung</h4>\n<p>Die OECD-Klassifizierung ist in einer zweistufigen hierarchischen Struktur organisiert:</p>\n<ul>\n<li><strong>Hauptebene (1 Ziffer)</strong>: 6 Hauptfelder</li>\n<li><strong>Unterebene (2 Ziffern)</strong>: 42 Unterkategorien</li>\n</ul>\n\n<h4>Hauptfelder der OECD-Klassifizierung</h4>\n<p>Die sechs Hauptfelder sind:</p>\n<ol>\n<li><strong>Naturwissenschaften</strong> (Natural Sciences)</li>\n<li><strong>Ingenieurwesen und Technologie</strong> (Engineering and Technology)</li>\n<li><strong>Medizinische und Gesundheitswissenschaften</strong> (Medical and Health Sciences)</li>\n<li><strong>Agrar- und Veterinärwissenschaften</strong> (Agricultural and Veterinary Sciences)</li>\n<li><strong>Sozialwissenschaften</strong> (Social Sciences)</li>\n<li><strong>Geisteswissenschaften und Künste</strong> (Humanities and Arts)</li>\n</ol>\n\n<h4>Wozu dient dieses Feld?</h4>\n<p>Die OECD-Klassifizierung wird verwendet für:</p>\n<ul>\n<li><strong>Internationale Indexierung</strong>: Erleichtert die Aufnahme in globale akademische Datenbanken</li>\n<li><strong>Bibliometrische Analysen</strong>: Ermöglicht Vergleiche zwischen Disziplinen und Forschungsbereichen</li>\n<li><strong>F&E-Statistiken</strong>: Standardisiert die Erfassung von Forschungs- und Entwicklungsdaten</li>\n<li><strong>Dateninteroperabilität</strong>: Ermöglicht den Informationsaustausch zwischen Institutionen und Ländern</li>\n</ul>\n\n<h4>Eingabeformat</h4>\n<p>Das Feld muss den numerischen Code der OECD-Klassifizierung im Format von zwei durch einen Punkt getrennten Ziffern enthalten.</p>\n<p><strong>Korrekte Beispiele</strong>:</p>\n<p>Eine einzelne Klassifizierung:</p>\n<pre>3.2</pre>\n<p>(Entspricht \"Klinische Medizin\" innerhalb von \"Medizinische und Gesundheitswissenschaften\")</p>\n<p>Mehrere Klassifizierungen (durch Semikolons getrennt):</p>\n<pre>1.2; 2.3</pre>\n<p>(Entspricht \"Computer- und Informationswissenschaften\" und \"Andere Ingenieurwissenschaften und Technologien\")</p>\n\n<h4>Beziehung zu anderen Klassifizierungssystemen</h4>\n<p>Die OECD-Klassifizierung ist kompatibel und lässt sich mit anderen Systemen wie folgenden verknüpfen:</p>\n<ul>\n<li>Web of Science Research Areas</li>\n<li>ANZSRC (Australian and New Zealand Standard Research Classification)</li>\n<li>UNESCO FOS</li>\n<li>Essential Science Indicators</li>\n</ul>\n\n<h4>Bedeutung für akademische Zeitschriften</h4>\n<p>Für wissenschaftliche Zeitschriften, insbesondere solche, die in internationalen Datenbanken wie Scopus, Web of Science oder SciELO indexiert sind, ist dieses Feld grundlegend für:</p>\n<ul>\n<li>Verbesserung der Sichtbarkeit von Artikeln</li>\n<li>Erleichterung thematischer Suchen</li>\n<li>Erfüllung internationaler Indexierungsanforderungen</li>\n<li>Ermöglichung multidisziplinärer Analysen bei Zuweisung mehrerer Klassifizierungen</li>\n</ul>','elisa','2026-01-09 01:07:26','elisa','2026-01-09 01:07:26');
INSERT INTO `manual_ayudas` (`id`, `clave`, `componente`, `idioma`, `ayuda`, `usuario_creacion`, `fecha_creacion`, `usuario_modificacion`, `fecha_modificacion`) VALUES (74,'handle-system','handle_system','es','<!-- ESPAÑOL -->\n<h3>¿Qué es un handle?</h3>\n<p>El campo <code>handle</code> contiene un identificador persistente basado en el Handle System, un sistema distribuido de identificación diseñado para proporcionar nombres únicos y permanentes para recursos digitales en Internet.</p>\n\n<h4>Características del Handle System</h4>\n<p>El Handle System es una infraestructura que proporciona:</p>\n<ul>\n<li><strong>Identificación única</strong>: Cada handle identifica inequívocamente un solo recurso digital</li>\n<li><strong>Persistencia</strong>: El identificador permanece válido incluso si cambia la ubicación del recurso</li>\n<li><strong>Resolución global</strong>: Sistema centralizado que resuelve handles a sus ubicaciones actuales</li>\n<li><strong>Independencia de ubicación</strong>: No depende de URLs que pueden cambiar con el tiempo</li>\n</ul>\n\n<h4>Estructura de un handle</h4>\n<p>Un handle se compone de dos partes separadas por una barra diagonal:</p>\n<pre>prefijo/sufijo</pre>\n<ul>\n<li><strong>Prefijo</strong>: Identifica la autoridad de nombramiento (institución u organización)</li>\n<li><strong>Sufijo</strong>: Describe el nombre local del recurso</li>\n</ul>\n<p><strong>Ejemplo</strong>:</p>\n<pre>11577/3159842</pre>\n<p>En este ejemplo, <code>11577</code> identifica al repositorio institucional y <code>3159842</code> identifica el recurso específico dentro de ese repositorio.</p>\n\n<h4>Relación con DOI</h4>\n<p>El DOI (Digital Object Identifier) es en realidad una implementación especializada del Handle System. Todo DOI es un handle, pero no todo handle es un DOI. Los DOIs añaden:</p>\n<ul>\n<li>Metadata estructurada adicional</li>\n<li>Infraestructura social y de gobernanza específica</li>\n<li>Registro centralizado a través de agencias como Crossref o DataCite</li>\n</ul>\n\n<h4>¿Para qué sirve el handle?</h4>\n<p>En el contexto de artículos científicos, el handle se utiliza para:</p>\n<ul>\n<li><strong>Citación persistente</strong>: Garantizar que las referencias permanezcan válidas a largo plazo</li>\n<li><strong>Acceso permanente</strong>: Permitir localizar el artículo incluso si cambia de servidor o repositorio</li>\n<li><strong>Identificación en repositorios</strong>: Especialmente común en repositorios institucionales que usan software como DSpace</li>\n<li><strong>Interoperabilidad</strong>: Facilitar el intercambio de metadatos entre sistemas</li>\n</ul>\n\n<h4>Formato de entrada</h4>\n<p>El campo debe contener el handle completo en formato <code>prefijo/sufijo</code>.</p>\n<p><strong>Ejemplos correctos</strong>:</p>\n<p>Handle de un repositorio institucional:</p>\n<pre>11577/3159842</pre>\n<p>Handle de un archivo digital:</p>\n<pre>2381/29652</pre>\n\n<h4>Diferencias con otros identificadores persistentes</h4>\n<table border=\"1\" cellpadding=\"5\" cellspacing=\"0\">\n<tr>\n<th>Identificador</th>\n<th>Uso principal</th>\n<th>Gobernanza</th>\n</tr>\n<tr>\n<td><strong>Handle</strong></td>\n<td>Infraestructura base para identificación persistente</td>\n<td>Handle.Net Registry</td>\n</tr>\n<tr>\n<td><strong>DOI</strong></td>\n<td>Publicaciones académicas, datos de investigación</td>\n<td>International DOI Foundation</td>\n</tr>\n<tr>\n<td><strong>ARK</strong></td>\n<td>Objetos digitales en bibliotecas y archivos</td>\n<td>California Digital Library</td>\n</tr>\n<tr>\n<td><strong>URN</strong></td>\n<td>Identificación independiente de ubicación</td>\n<td>IETF</td>\n</tr>\n</table>\n\n<h4>Importancia para revistas académicas</h4>\n<p>Para artículos científicos en repositorios institucionales o sistemas de archivo digital:</p>\n<ul>\n<li><strong>Preservación digital</strong>: Mantiene acceso al contenido a largo plazo</li>\n<li><strong>Trazabilidad</strong>: Permite seguimiento de versiones y cambios</li>\n<li><strong>Cumplimiento normativo</strong>: Satisface requisitos de acceso abierto en muchas instituciones</li>\n<li><strong>Integración con CRIS</strong>: Facilita la integración con sistemas de información de investigación actual</li>\n</ul>\n\n<h4>Uso junto con DOI</h4>\n<p>Es común que un artículo tenga tanto DOI como handle:</p>\n<ul>\n<li><strong>DOI</strong>: Para la citación académica estándar</li>\n<li><strong>Handle</strong>: Para el acceso a través del repositorio institucional</li>\n</ul>\n<p>Ambos identificadores pueden coexistir y apuntar al mismo recurso desde diferentes puntos de acceso.</p>\n','elisa','2026-01-09 07:43:26','elisa','2026-01-09 08:16:10');
INSERT INTO `manual_ayudas` (`id`, `clave`, `componente`, `idioma`, `ayuda`, `usuario_creacion`, `fecha_creacion`, `usuario_modificacion`, `fecha_modificacion`) VALUES (75,'handle-system','handle_system','pt','<!-- PORTUGUÉS -->\n<h3>O que é um handle?</h3>\n<p>O campo <code>handle</code> contém um identificador persistente baseado no Handle System, um sistema distribuído de identificação projetado para fornecer nomes únicos e permanentes para recursos digitais na Internet.</p>\n\n<h4>Características do Handle System</h4>\n<p>O Handle System é uma infraestrutura que fornece:</p>\n<ul>\n<li><strong>Identificação única</strong>: Cada handle identifica inequivocamente um único recurso digital</li>\n<li><strong>Persistência</strong>: O identificador permanece válido mesmo se a localização do recurso mudar</li>\n<li><strong>Resolução global</strong>: Sistema centralizado que resolve handles para suas localizações atuais</li>\n<li><strong>Independência de localização</strong>: Não depende de URLs que podem mudar com o tempo</li>\n</ul>\n\n<h4>Estrutura de um handle</h4>\n<p>Um handle é composto por duas partes separadas por uma barra:</p>\n<pre>prefixo/sufixo</pre>\n<ul>\n<li><strong>Prefixo</strong>: Identifica a autoridade de nomeação (instituição ou organização)</li>\n<li><strong>Sufixo</strong>: Descreve o nome local do recurso</li>\n</ul>\n<p><strong>Exemplo</strong>:</p>\n<pre>11577/3159842</pre>\n<p>Neste exemplo, <code>11577</code> identifica o repositório institucional e <code>3159842</code> identifica o recurso específico dentro desse repositório.</p>\n\n<h4>Relação com DOI</h4>\n<p>O DOI (Digital Object Identifier) é na verdade uma implementação especializada do Handle System. Todo DOI é um handle, mas nem todo handle é um DOI. Os DOIs adicionam:</p>\n<ul>\n<li>Metadados estruturados adicionais</li>\n<li>Infraestrutura social e de governança específica</li>\n<li>Registro centralizado através de agências como Crossref ou DataCite</li>\n</ul>\n\n<h4>Para que serve o handle?</h4>\n<p>No contexto de artigos científicos, o handle é utilizado para:</p>\n<ul>\n<li><strong>Citação persistente</strong>: Garantir que as referências permaneçam válidas a longo prazo</li>\n<li><strong>Acesso permanente</strong>: Permitir localizar o artigo mesmo se mudar de servidor ou repositório</li>\n<li><strong>Identificação em repositórios</strong>: Especialmente comum em repositórios institucionais que usam software como DSpace</li>\n<li><strong>Interoperabilidade</strong>: Facilitar o intercâmbio de metadados entre sistemas</li>\n</ul>\n\n<h4>Formato de entrada</h4>\n<p>O campo deve conter o handle completo no formato <code>prefixo/sufixo</code>.</p>\n<p><strong>Exemplos corretos</strong>:</p>\n<p>Handle de um repositório institucional:</p>\n<pre>11577/3159842</pre>\n<p>Handle de um arquivo digital:</p>\n<pre>2381/29652</pre>\n\n<h4>Diferenças com outros identificadores persistentes</h4>\n<table border=\"1\" cellpadding=\"5\" cellspacing=\"0\">\n<tr>\n<th>Identificador</th>\n<th>Uso principal</th>\n<th>Governança</th>\n</tr>\n<tr>\n<td><strong>Handle</strong></td>\n<td>Infraestrutura base para identificação persistente</td>\n<td>Handle.Net Registry</td>\n</tr>\n<tr>\n<td><strong>DOI</strong></td>\n<td>Publicações acadêmicas, dados de pesquisa</td>\n<td>International DOI Foundation</td>\n</tr>\n<tr>\n<td><strong>ARK</strong></td>\n<td>Objetos digitais em bibliotecas e arquivos</td>\n<td>California Digital Library</td>\n</tr>\n<tr>\n<td><strong>URN</strong></td>\n<td>Identificação independente de localização</td>\n<td>IETF</td>\n</tr>\n</table>\n\n<h4>Importância para revistas acadêmicas</h4>\n<p>Para artigos científicos em repositórios institucionais ou sistemas de arquivo digital:</p>\n<ul>\n<li><strong>Preservação digital</strong>: Mantém acesso ao conteúdo a longo prazo</li>\n<li><strong>Rastreabilidade</strong>: Permite acompanhamento de versões e mudanças</li>\n<li><strong>Cumprimento normativo</strong>: Satisfaz requisitos de acesso aberto em muitas instituições</li>\n<li><strong>Integração com CRIS</strong>: Facilita a integração com sistemas de informação de pesquisa atual</li>\n</ul>\n\n<h4>Uso conjunto com DOI</h4>\n<p>É comum que um artigo tenha tanto DOI quanto handle:</p>\n<ul>\n<li><strong>DOI</strong>: Para a citação acadêmica padrão</li>\n<li><strong>Handle</strong>: Para o acesso através do repositório institucional</li>\n</ul>\n<p>Ambos os identificadores podem coexistir e apontar para o mesmo recurso a partir de diferentes pontos de acesso.</p>\n','elisa','2026-01-09 07:43:26','elisa','2026-01-09 08:16:32');
INSERT INTO `manual_ayudas` (`id`, `clave`, `componente`, `idioma`, `ayuda`, `usuario_creacion`, `fecha_creacion`, `usuario_modificacion`, `fecha_modificacion`) VALUES (76,'handle-system','handle_system','en','<!-- INGLÉS -->\n<h3>What is a handle?</h3>\n<p>The <code>handle</code> field contains a persistent identifier based on the Handle System, a distributed identification system designed to provide unique and permanent names for digital resources on the Internet.</p>\n\n<h4>Handle System characteristics</h4>\n<p>The Handle System is an infrastructure that provides:</p>\n<ul>\n<li><strong>Unique identification</strong>: Each handle unambiguously identifies a single digital resource</li>\n<li><strong>Persistence</strong>: The identifier remains valid even if the resource location changes</li>\n<li><strong>Global resolution</strong>: Centralized system that resolves handles to their current locations</li>\n<li><strong>Location independence</strong>: Does not depend on URLs that may change over time</li>\n</ul>\n\n<h4>Handle structure</h4>\n<p>A handle consists of two parts separated by a forward slash:</p>\n<pre>prefix/suffix</pre>\n<ul>\n<li><strong>Prefix</strong>: Identifies the naming authority (institution or organization)</li>\n<li><strong>Suffix</strong>: Describes the local name of the resource</li>\n</ul>\n<p><strong>Example</strong>:</p>\n<pre>11577/3159842</pre>\n<p>In this example, <code>11577</code> identifies the institutional repository and <code>3159842</code> identifies the specific resource within that repository.</p>\n\n<h4>Relationship with DOI</h4>\n<p>The DOI (Digital Object Identifier) is actually a specialized implementation of the Handle System. Every DOI is a handle, but not every handle is a DOI. DOIs add:</p>\n<ul>\n<li>Additional structured metadata</li>\n<li>Specific social and governance infrastructure</li>\n<li>Centralized registration through agencies such as Crossref or DataCite</li>\n</ul>\n\n<h4>What is the handle used for?</h4>\n<p>In the context of scientific articles, the handle is used for:</p>\n<ul>\n<li><strong>Persistent citation</strong>: Ensuring that references remain valid long-term</li>\n<li><strong>Permanent access</strong>: Allowing the article to be located even if it changes servers or repositories</li>\n<li><strong>Repository identification</strong>: Especially common in institutional repositories using software like DSpace</li>\n<li><strong>Interoperability</strong>: Facilitating metadata exchange between systems</li>\n</ul>\n\n<h4>Input format</h4>\n<p>The field must contain the complete handle in <code>prefix/suffix</code> format.</p>\n<p><strong>Correct examples</strong>:</p>\n<p>Institutional repository handle:</p>\n<pre>11577/3159842</pre>\n<p>Digital archive handle:</p>\n<pre>2381/29652</pre>\n\n<h4>Differences from other persistent identifiers</h4>\n<table border=\"1\" cellpadding=\"5\" cellspacing=\"0\">\n<tr>\n<th>Identifier</th>\n<th>Main use</th>\n<th>Governance</th>\n</tr>\n<tr>\n<td><strong>Handle</strong></td>\n<td>Base infrastructure for persistent identification</td>\n<td>Handle.Net Registry</td>\n</tr>\n<tr>\n<td><strong>DOI</strong></td>\n<td>Academic publications, research data</td>\n<td>International DOI Foundation</td>\n</tr>\n<tr>\n<td><strong>ARK</strong></td>\n<td>Digital objects in libraries and archives</td>\n<td>California Digital Library</td>\n</tr>\n<tr>\n<td><strong>URN</strong></td>\n<td>Location-independent identification</td>\n<td>IETF</td>\n</tr>\n</table>\n\n<h4>Importance for academic journals</h4>\n<p>For scientific articles in institutional repositories or digital archive systems:</p>\n<ul>\n<li><strong>Digital preservation</strong>: Maintains long-term access to content</li>\n<li><strong>Traceability</strong>: Allows tracking of versions and changes</li>\n<li><strong>Regulatory compliance</strong>: Satisfies open access requirements in many institutions</li>\n<li><strong>CRIS integration</strong>: Facilitates integration with current research information systems</li>\n</ul>\n\n<h4>Use alongside DOI</h4>\n<p>It is common for an article to have both DOI and handle:</p>\n<ul>\n<li><strong>DOI</strong>: For standard academic citation</li>\n<li><strong>Handle</strong>: For access through the institutional repository</li>\n</ul>\n<p>Both identifiers can coexist and point to the same resource from different access points.</p>\n','elisa','2026-01-09 07:43:26','elisa','2026-01-09 08:16:50');
INSERT INTO `manual_ayudas` (`id`, `clave`, `componente`, `idioma`, `ayuda`, `usuario_creacion`, `fecha_creacion`, `usuario_modificacion`, `fecha_modificacion`) VALUES (77,'handle-system','handle_system','it','<!-- ITALIANO -->\n<h3>Cos\'è un handle?</h3>\n<p>Il campo <code>handle</code> contiene un identificatore persistente basato sul Handle System, un sistema di identificazione distribuito progettato per fornire nomi unici e permanenti per le risorse digitali su Internet.</p>\n\n<h4>Caratteristiche del Handle System</h4>\n<p>Il Handle System è un\'infrastruttura che fornisce:</p>\n<ul>\n<li><strong>Identificazione unica</strong>: Ogni handle identifica inequivocabilmente una singola risorsa digitale</li>\n<li><strong>Persistenza</strong>: L\'identificatore rimane valido anche se cambia la posizione della risorsa</li>\n<li><strong>Risoluzione globale</strong>: Sistema centralizzato che risolve gli handle alle loro posizioni attuali</li>\n<li><strong>Indipendenza dalla posizione</strong>: Non dipende da URL che possono cambiare nel tempo</li>\n</ul>\n\n<h4>Struttura di un handle</h4>\n<p>Un handle è composto da due parti separate da una barra:</p>\n<pre>prefisso/suffisso</pre>\n<ul>\n<li><strong>Prefisso</strong>: Identifica l\'autorità di denominazione (istituzione o organizzazione)</li>\n<li><strong>Suffisso</strong>: Descrive il nome locale della risorsa</li>\n</ul>\n<p><strong>Esempio</strong>:</p>\n<pre>11577/3159842</pre>\n<p>In questo esempio, <code>11577</code> identifica il repository istituzionale e <code>3159842</code> identifica la risorsa specifica all\'interno di quel repository.</p>\n\n<h4>Relazione con il DOI</h4>\n<p>Il DOI (Digital Object Identifier) è in realtà un\'implementazione specializzata del Handle System. Ogni DOI è un handle, ma non ogni handle è un DOI. I DOI aggiungono:</p>\n<ul>\n<li>Metadati strutturati aggiuntivi</li>\n<li>Infrastruttura sociale e di governance specifica</li>\n<li>Registrazione centralizzata attraverso agenzie come Crossref o DataCite</li>\n</ul>\n\n<h4>A cosa serve l\'handle?</h4>\n<p>Nel contesto di articoli scientifici, l\'handle è utilizzato per:</p>\n<ul>\n<li><strong>Citazione persistente</strong>: Garantire che i riferimenti rimangano validi a lungo termine</li>\n<li><strong>Accesso permanente</strong>: Permettere di localizzare l\'articolo anche se cambia server o repository</li>\n<li><strong>Identificazione nei repository</strong>: Particolarmente comune nei repository istituzionali che utilizzano software come DSpace</li>\n<li><strong>Interoperabilità</strong>: Facilitare lo scambio di metadati tra sistemi</li>\n</ul>\n\n<h4>Formato di inserimento</h4>\n<p>Il campo deve contenere l\'handle completo nel formato <code>prefisso/suffisso</code>.</p>\n<p><strong>Esempi corretti</strong>:</p>\n<p>Handle di un repository istituzionale:</p>\n<pre>11577/3159842</pre>\n<p>Handle di un archivio digitale:</p>\n<pre>2381/29652</pre>\n\n<h4>Differenze con altri identificatori persistenti</h4>\n<table border=\"1\" cellpadding=\"5\" cellspacing=\"0\">\n<tr>\n<th>Identificatore</th>\n<th>Uso principale</th>\n<th>Governance</th>\n</tr>\n<tr>\n<td><strong>Handle</strong></td>\n<td>Infrastruttura base per identificazione persistente</td>\n<td>Handle.Net Registry</td>\n</tr>\n<tr>\n<td><strong>DOI</strong></td>\n<td>Pubblicazioni accademiche, dati di ricerca</td>\n<td>International DOI Foundation</td>\n</tr>\n<tr>\n<td><strong>ARK</strong></td>\n<td>Oggetti digitali in biblioteche e archivi</td>\n<td>California Digital Library</td>\n</tr>\n<tr>\n<td><strong>URN</strong></td>\n<td>Identificazione indipendente dalla posizione</td>\n<td>IETF</td>\n</tr>\n</table>\n\n<h4>Importanza per le riviste accademiche</h4>\n<p>Per articoli scientifici in repository istituzionali o sistemi di archivio digitale:</p>\n<ul>\n<li><strong>Preservazione digitale</strong>: Mantiene l\'accesso al contenuto a lungo termine</li>\n<li><strong>Tracciabilità</strong>: Consente il monitoraggio di versioni e modifiche</li>\n<li><strong>Conformità normativa</strong>: Soddisfa i requisiti di accesso aperto in molte istituzioni</li>\n<li><strong>Integrazione CRIS</strong>: Facilita l\'integrazione con i sistemi informativi di ricerca attuali</li>\n</ul>\n\n<h4>Uso insieme al DOI</h4>\n<p>È comune che un articolo abbia sia DOI che handle:</p>\n<ul>\n<li><strong>DOI</strong>: Per la citazione accademica standard</li>\n<li><strong>Handle</strong>: Per l\'accesso attraverso il repository istituzionale</li>\n</ul>\n<p>Entrambi gli identificatori possono coesistere e puntare alla stessa risorsa da diversi punti di accesso.</p>\n','elisa','2026-01-09 07:43:26','elisa','2026-01-09 08:17:13');
INSERT INTO `manual_ayudas` (`id`, `clave`, `componente`, `idioma`, `ayuda`, `usuario_creacion`, `fecha_creacion`, `usuario_modificacion`, `fecha_modificacion`) VALUES (78,'handle-system','handle_system','fr','<!-- FRANCÉS -->\n<h3>Qu\'est-ce qu\'un handle?</h3>\n<p>Le champ <code>handle</code> contient un identifiant persistant basé sur le Handle System, un système d\'identification distribué conçu pour fournir des noms uniques et permanents aux ressources numériques sur Internet.</p>\n\n<h4>Caractéristiques du Handle System</h4>\n<p>Le Handle System est une infrastructure qui fournit:</p>\n<ul>\n<li><strong>Identification unique</strong>: Chaque handle identifie sans ambiguïté une seule ressource numérique</li>\n<li><strong>Persistance</strong>: L\'identifiant reste valide même si l\'emplacement de la ressource change</li>\n<li><strong>Résolution globale</strong>: Système centralisé qui résout les handles vers leurs emplacements actuels</li>\n<li><strong>Indépendance de localisation</strong>: Ne dépend pas des URL qui peuvent changer avec le temps</li>\n</ul>\n\n<h4>Structure d\'un handle</h4>\n<p>Un handle se compose de deux parties séparées par une barre oblique:</p>\n<pre>préfixe/suffixe</pre>\n<ul>\n<li><strong>Préfixe</strong>: Identifie l\'autorité de nommage (institution ou organisation)</li>\n<li><strong>Suffixe</strong>: Décrit le nom local de la ressource</li>\n</ul>\n<p><strong>Exemple</strong>:</p>\n<pre>11577/3159842</pre>\n<p>Dans cet exemple, <code>11577</code> identifie le dépôt institutionnel et <code>3159842</code> identifie la ressource spécifique au sein de ce dépôt.</p>\n\n<h4>Relation avec le DOI</h4>\n<p>Le DOI (Digital Object Identifier) est en réalité une implémentation spécialisée du Handle System. Tout DOI est un handle, mais tout handle n\'est pas un DOI. Les DOI ajoutent:</p>\n<ul>\n<li>Des métadonnées structurées supplémentaires</li>\n<li>Une infrastructure sociale et de gouvernance spécifique</li>\n<li>Un enregistrement centralisé via des agences comme Crossref ou DataCite</li>\n</ul>\n\n<h4>À quoi sert le handle?</h4>\n<p>Dans le contexte d\'articles scientifiques, le handle est utilisé pour:</p>\n<ul>\n<li><strong>Citation persistante</strong>: Garantir que les références restent valides à long terme</li>\n<li><strong>Accès permanent</strong>: Permettre de localiser l\'article même s\'il change de serveur ou de dépôt</li>\n<li><strong>Identification dans les dépôts</strong>: Particulièrement courant dans les dépôts institutionnels utilisant des logiciels comme DSpace</li>\n<li><strong>Interopérabilité</strong>: Faciliter l\'échange de métadonnées entre systèmes</li>\n</ul>\n\n<h4>Format de saisie</h4>\n<p>Le champ doit contenir le handle complet au format <code>préfixe/suffixe</code>.</p>\n<p><strong>Exemples corrects</strong>:</p>\n<p>Handle d\'un dépôt institutionnel:</p>\n<pre>11577/3159842</pre>\n<p>Handle d\'une archive numérique:</p>\n<pre>2381/29652</pre>\n\n<h4>Différences avec d\'autres identifiants persistants</h4>\n<table border=\"1\" cellpadding=\"5\" cellspacing=\"0\">\n<tr>\n<th>Identifiant</th>\n<th>Usage principal</th>\n<th>Gouvernance</th>\n</tr>\n<tr>\n<td><strong>Handle</strong></td>\n<td>Infrastructure de base pour l\'identification persistante</td>\n<td>Handle.Net Registry</td>\n</tr>\n<tr>\n<td><strong>DOI</strong></td>\n<td>Publications académiques, données de recherche</td>\n<td>International DOI Foundation</td>\n</tr>\n<tr>\n<td><strong>ARK</strong></td>\n<td>Objets numériques dans les bibliothèques et archives</td>\n<td>California Digital Library</td>\n</tr>\n<tr>\n<td><strong>URN</strong></td>\n<td>Identification indépendante de la localisation</td>\n<td>IETF</td>\n</tr>\n</table>\n\n<h4>Importance pour les revues académiques</h4>\n<p>Pour les articles scientifiques dans les dépôts institutionnels ou systèmes d\'archives numériques:</p>\n<ul>\n<li><strong>Préservation numérique</strong>: Maintient l\'accès au contenu à long terme</li>\n<li><strong>Traçabilité</strong>: Permet le suivi des versions et des changements</li>\n<li><strong>Conformité normative</strong>: Satisfait les exigences d\'accès ouvert dans de nombreuses institutions</li>\n<li><strong>Intégration CRIS</strong>: Facilite l\'intégration avec les systèmes d\'information de recherche actuels</li>\n</ul>\n\n<h4>Usage conjoint avec le DOI</h4>\n<p>Il est courant qu\'un article ait à la fois un DOI et un handle:</p>\n<ul>\n<li><strong>DOI</strong>: Pour la citation académique standard</li>\n<li><strong>Handle</strong>: Pour l\'accès via le dépôt institutionnel</li>\n</ul>\n<p>Les deux identifiants peuvent coexister et pointer vers la même ressource depuis différents points d\'accès.</p>\n','elisa','2026-01-09 07:43:26','elisa','2026-01-09 08:17:29');
INSERT INTO `manual_ayudas` (`id`, `clave`, `componente`, `idioma`, `ayuda`, `usuario_creacion`, `fecha_creacion`, `usuario_modificacion`, `fecha_modificacion`) VALUES (79,'handle-system','handle_system','de','<!-- ALEMÁN -->\n<h3>Was ist ein Handle?</h3>\n<p>Das Feld <code>handle</code> enthält einen persistenten Identifikator basierend auf dem Handle System, einem verteilten Identifikationssystem, das entwickelt wurde, um eindeutige und permanente Namen für digitale Ressourcen im Internet bereitzustellen.</p>\n\n<h4>Eigenschaften des Handle Systems</h4>\n<p>Das Handle System ist eine Infrastruktur, die Folgendes bietet:</p>\n<ul>\n<li><strong>Eindeutige Identifikation</strong>: Jeder Handle identifiziert eindeutig eine einzelne digitale Ressource</li>\n<li><strong>Persistenz</strong>: Der Identifikator bleibt gültig, auch wenn sich der Standort der Ressource ändert</li>\n<li><strong>Globale Auflösung</strong>: Zentralisiertes System, das Handles zu ihren aktuellen Standorten auflöst</li>\n<li><strong>Standortunabhängigkeit</strong>: Hängt nicht von URLs ab, die sich im Laufe der Zeit ändern können</li>\n</ul>\n\n<h4>Struktur eines Handles</h4>\n<p>Ein Handle besteht aus zwei Teilen, die durch einen Schrägstrich getrennt sind:</p>\n<pre>Präfix/Suffix</pre>\n<ul>\n<li><strong>Präfix</strong>: Identifiziert die Namensgebungsbehörde (Institution oder Organisation)</li>\n<li><strong>Suffix</strong>: Beschreibt den lokalen Namen der Ressource</li>\n</ul>\n<p><strong>Beispiel</strong>:</p>\n<pre>11577/3159842</pre>\n<p>In diesem Beispiel identifiziert <code>11577</code> das institutionelle Repository und <code>3159842</code> die spezifische Ressource innerhalb dieses Repositorys.</p>\n\n<h4>Beziehung zum DOI</h4>\n<p>Der DOI (Digital Object Identifier) ist tatsächlich eine spezialisierte Implementierung des Handle Systems. Jeder DOI ist ein Handle, aber nicht jeder Handle ist ein DOI. DOIs fügen hinzu:</p>\n<ul>\n<li>Zusätzliche strukturierte Metadaten</li>\n<li>Spezifische soziale und Governance-Infrastruktur</li>\n<li>Zentralisierte Registrierung über Agenturen wie Crossref oder DataCite</li>\n</ul>\n\n<h4>Wozu dient der Handle?</h4>\n<p>Im Kontext wissenschaftlicher Artikel wird der Handle verwendet für:</p>\n<ul>\n<li><strong>Persistente Zitation</strong>: Gewährleistung, dass Referenzen langfristig gültig bleiben</li>\n<li><strong>Permanenter Zugriff</strong>: Ermöglicht das Auffinden des Artikels, auch wenn er Server oder Repository wechselt</li>\n<li><strong>Repository-Identifikation</strong>: Besonders verbreitet in institutionellen Repositorien, die Software wie DSpace verwenden</li>\n<li><strong>Interoperabilität</strong>: Erleichtert den Metadatenaustausch zwischen Systemen</li>\n</ul>\n\n<h4>Eingabeformat</h4>\n<p>Das Feld muss den vollständigen Handle im Format <code>Präfix/Suffix</code> enthalten.</p>\n<p><strong>Korrekte Beispiele</strong>:</p>\n<p>Handle eines institutionellen Repositorys:</p>\n<pre>11577/3159842</pre>\n<p>Handle eines digitalen Archivs:</p>\n<pre>2381/29652</pre>\n\n<h4>Unterschiede zu anderen persistenten Identifikatoren</h4>\n<table border=\"1\" cellpadding=\"5\" cellspacing=\"0\">\n<tr>\n<th>Identifikator</th>\n<th>Hauptverwendung</th>\n<th>Governance</th>\n</tr>\n<tr>\n<td><strong>Handle</strong></td>\n<td>Basisinfrastruktur für persistente Identifikation</td>\n<td>Handle.Net Registry</td>\n</tr>\n<tr>\n<td><strong>DOI</strong></td>\n<td>Akademische Publikationen, Forschungsdaten</td>\n<td>International DOI Foundation</td>\n</tr>\n<tr>\n<td><strong>ARK</strong></td>\n<td>Digitale Objekte in Bibliotheken und Archiven</td>\n<td>California Digital Library</td>\n</tr>\n<tr>\n<td><strong>URN</strong></td>\n<td>Standortunabhängige Identifikation</td>\n<td>IETF</td>\n</tr>\n</table>\n\n<h4>Bedeutung für akademische Zeitschriften</h4>\n<p>Für wissenschaftliche Artikel in institutionellen Repositorien oder digitalen Archivsystemen:</p>\n<ul>\n<li><strong>Digitale Bewahrung</strong>: Erhält langfristigen Zugang zu Inhalten</li>\n<li><strong>Nachverfolgbarkeit</strong>: Ermöglicht Verfolgung von Versionen und Änderungen</li>\n<li><strong>Regulatorische Compliance</strong>: Erfüllt Open-Access-Anforderungen in vielen Institutionen</li>\n<li><strong>CRIS-Integration</strong>: Erleichtert die Integration mit aktuellen Forschungsinformationssystemen</li>\n</ul>\n\n<h4>Verwendung zusammen mit DOI</h4>\n<p>Es ist üblich, dass ein Artikel sowohl DOI als auch Handle hat:</p>\n<ul>\n<li><strong>DOI</strong>: Für die standardmäßige akademische Zitation</li>\n<li><strong>Handle</strong>: Für den Zugriff über das institutionelle Repository</li>\n</ul>\n<p>Beide Identifikatoren können koexistieren und von verschiedenen Zugangspunkten auf dieselbe Ressource verweisen.</p>','elisa','2026-01-09 07:43:26','elisa','2026-01-09 08:17:46');
INSERT INTO `manual_ayudas` (`id`, `clave`, `componente`, `idioma`, `ayuda`, `usuario_creacion`, `fecha_creacion`, `usuario_modificacion`, `fecha_modificacion`) VALUES (80,'arxiv-id','arxiv_id','es','<!-- ESPAÑOL -->\n<h3>¿Qué es arxiv-id?</h3>\n<p>El campo <code>arxiv-id</code> contiene el identificador único asignado por arXiv, el repositorio de preprints científicos más importante del mundo, especializado en física, matemáticas, ciencias de la computación, biología cuantitativa, finanzas cuantitativas, estadística, ingeniería eléctrica y ciencias de sistemas, y economía.</p>\n\n<h4>¿Qué es arXiv?</h4>\n<p>arXiv (pronunciado \"archive\") es un repositorio de acceso abierto operado por la Universidad Cornell que permite a investigadores compartir preprints (versiones preliminares) de artículos científicos antes de su publicación en revistas con revisión por pares.</p>\n\n<h4>Estructura del identificador arXiv</h4>\n<p>El formato del identificador ha cambiado a lo largo del tiempo:</p>\n<p><strong>Formato antiguo (antes de abril 2007)</strong>:</p>\n<pre>archivo/YYMMNNN</pre>\n<p>Ejemplo: <code>math/0703123</code></p>\n<p><strong>Formato nuevo (abril 2007 - diciembre 2014)</strong>:</p>\n<pre>YYMM.NNNN</pre>\n<p>Ejemplo: <code>0704.0001</code> (4 dígitos para el número de secuencia)</p>\n<p><strong>Formato actual (desde enero 2015)</strong>:</p>\n<pre>YYMM.NNNNN</pre>\n<p>Ejemplo: <code>1501.00001</code> (5 dígitos para el número de secuencia)</p>\n<p>Donde:</p>\n<ul>\n<li><strong>YY</strong>: Últimos dos dígitos del año</li>\n<li><strong>MM</strong>: Mes de envío (01-12)</li>\n<li><strong>NNNNN</strong>: Número de secuencia dentro del mes (con ceros a la izquierda)</li>\n</ul>\n\n<h4>Versiones de artículos</h4>\n<p>Los artículos en arXiv pueden tener múltiples versiones. Para referirse a una versión específica, se añade:</p>\n<pre>YYMM.NNNNNvN</pre>\n<p>Ejemplo: <code>2401.12345v2</code> (segunda versión del artículo)</p>\n<p>Sin el número de versión, el identificador se refiere siempre a la versión más reciente.</p>\n\n<h4>Formato de entrada</h4>\n<p>El campo debe contener el identificador arXiv completo, opcionalmente con el prefijo <code>arXiv:</code>.</p>\n<p><strong>Ejemplos correctos</strong>:</p>\n<p>Formato moderno:</p>\n<pre>2401.12345</pre>\n<p>Con prefijo (recomendado para citaciones):</p>\n<pre>arXiv:2401.12345</pre>\n<p>Con versión específica:</p>\n<pre>arXiv:2401.12345v1</pre>\n<p>Formato antiguo:</p>\n<pre>math/0703123</pre>\n\n<h4>Relación con DOI</h4>\n<p>A partir de enero de 2022, arXiv asigna automáticamente un DOI a cada artículo:</p>\n<ul>\n<li><strong>arXiv ID</strong>: <code>arXiv:2202.01037</code></li>\n<li><strong>DOI equivalente</strong>: <code>10.48550/arXiv.2202.01037</code></li>\n</ul>\n<p>Ambos identificadores pueden coexistir:</p>\n<ul>\n<li>El arXiv ID es el identificador nativo del repositorio</li>\n<li>El DOI facilita la interoperabilidad con otros sistemas</li>\n</ul>\n\n<h4>Categorías de arXiv</h4>\n<p>Cada artículo tiene una categoría principal. Algunas categorías principales incluyen:</p>\n<ul>\n<li><strong>physics</strong>: Física (varios subcampos)</li>\n<li><strong>math</strong>: Matemáticas</li>\n<li><strong>cs</strong>: Ciencias de la Computación</li>\n<li><strong>q-bio</strong>: Biología Cuantitativa</li>\n<li><strong>q-fin</strong>: Finanzas Cuantitativas</li>\n<li><strong>stat</strong>: Estadística</li>\n<li><strong>eess</strong>: Ingeniería Eléctrica y Ciencias de Sistemas</li>\n<li><strong>econ</strong>: Economía</li>\n</ul>\n\n<h4>¿Para qué sirve el arxiv-id?</h4>\n<p>En el contexto de metadatos de artículos científicos:</p>\n<ul>\n<li><strong>Citación de preprints</strong>: Permite citar trabajos antes de su publicación formal</li>\n<li><strong>Trazabilidad de versiones</strong>: Identifica inequívocamente cada versión de un manuscrito</li>\n<li><strong>Acceso abierto</strong>: Garantiza acceso libre y permanente al trabajo</li>\n<li><strong>Prioridad de descubrimiento</strong>: Establece fecha de publicación pública del preprint</li>\n<li><strong>Interoperabilidad</strong>: Facilita la conexión con otros sistemas bibliográficos</li>\n</ul>\n\n<h4>Importancia para la comunicación científica</h4>\n<p>El arXiv ID es especialmente relevante en:</p>\n<ul>\n<li><strong>Física y Matemáticas</strong>: Donde arXiv es el repositorio estándar de facto</li>\n<li><strong>Ciencias de la Computación</strong>: Para compartir resultados rápidamente</li>\n<li><strong>Publicación dual</strong>: Muchos artículos existen tanto en arXiv como en revistas con peer review</li>\n<li><strong>Acceso temprano</strong>: Permite a la comunidad científica acceder a resultados antes de la publicación formal</li>\n</ul>\n\n<h4>Uso junto con otros identificadores</h4>\n<p>Es común que un artículo tenga múltiples identificadores:</p>\n<ul>\n<li><strong>arXiv ID</strong>: Para la versión preprint</li>\n<li><strong>DOI de revista</strong>: Para la versión publicada con revisión por pares</li>\n<li><strong>DOI de arXiv</strong>: Asignado automáticamente por arXiv desde 2022</li>\n</ul>\n<p>Todos pueden coexistir y referenciar el mismo trabajo en diferentes etapas de publicación.</p>','elisa','2026-01-09 08:00:24','elisa','2026-01-09 08:00:24');
INSERT INTO `manual_ayudas` (`id`, `clave`, `componente`, `idioma`, `ayuda`, `usuario_creacion`, `fecha_creacion`, `usuario_modificacion`, `fecha_modificacion`) VALUES (81,'arxiv-id','arxiv_id','pt','<!-- PORTUGUÉS -->\n<h3>O que é arxiv-id?</h3>\n<p>O campo <code>arxiv-id</code> contém o identificador único atribuído pelo arXiv, o repositório de preprints científicos mais importante do mundo, especializado em física, matemática, ciências da computação, biologia quantitativa, finanças quantitativas, estatística, engenharia elétrica e ciências de sistemas, e economia.</p>\n\n<h4>O que é arXiv?</h4>\n<p>arXiv (pronunciado \"archive\") é um repositório de acesso aberto operado pela Universidade Cornell que permite aos pesquisadores compartilhar preprints (versões preliminares) de artigos científicos antes de sua publicação em revistas com revisão por pares.</p>\n\n<h4>Estrutura do identificador arXiv</h4>\n<p>O formato do identificador mudou ao longo do tempo:</p>\n<p><strong>Formato antigo (antes de abril 2007)</strong>:</p>\n<pre>arquivo/YYMMNNN</pre>\n<p>Exemplo: <code>math/0703123</code></p>\n<p><strong>Formato novo (abril 2007 - dezembro 2014)</strong>:</p>\n<pre>YYMM.NNNN</pre>\n<p>Exemplo: <code>0704.0001</code> (4 dígitos para o número de sequência)</p>\n<p><strong>Formato atual (desde janeiro 2015)</strong>:</p>\n<pre>YYMM.NNNNN</pre>\n<p>Exemplo: <code>1501.00001</code> (5 dígitos para o número de sequência)</p>\n<p>Onde:</p>\n<ul>\n<li><strong>YY</strong>: Últimos dois dígitos do ano</li>\n<li><strong>MM</strong>: Mês de envio (01-12)</li>\n<li><strong>NNNNN</strong>: Número de sequência dentro do mês (com zeros à esquerda)</li>\n</ul>\n\n<h4>Versões de artigos</h4>\n<p>Os artigos no arXiv podem ter múltiplas versões. Para se referir a uma versão específica, adiciona-se:</p>\n<pre>YYMM.NNNNNvN</pre>\n<p>Exemplo: <code>2401.12345v2</code> (segunda versão do artigo)</p>\n<p>Sem o número de versão, o identificador sempre se refere à versão mais recente.</p>\n\n<h4>Formato de entrada</h4>\n<p>O campo deve conter o identificador arXiv completo, opcionalmente com o prefixo <code>arXiv:</code>.</p>\n<p><strong>Exemplos corretos</strong>:</p>\n<p>Formato moderno:</p>\n<pre>2401.12345</pre>\n<p>Com prefixo (recomendado para citações):</p>\n<pre>arXiv:2401.12345</pre>\n<p>Com versão específica:</p>\n<pre>arXiv:2401.12345v1</pre>\n<p>Formato antigo:</p>\n<pre>math/0703123</pre>\n\n<h4>Relação com DOI</h4>\n<p>A partir de janeiro de 2022, o arXiv atribui automaticamente um DOI a cada artigo:</p>\n<ul>\n<li><strong>arXiv ID</strong>: <code>arXiv:2202.01037</code></li>\n<li><strong>DOI equivalente</strong>: <code>10.48550/arXiv.2202.01037</code></li>\n</ul>\n<p>Ambos os identificadores podem coexistir:</p>\n<ul>\n<li>O arXiv ID é o identificador nativo do repositório</li>\n<li>O DOI facilita a interoperabilidade com outros sistemas</li>\n</ul>\n\n<h4>Categorias do arXiv</h4>\n<p>Cada artigo tem uma categoria principal. Algumas categorias principais incluem:</p>\n<ul>\n<li><strong>physics</strong>: Física (vários subcampos)</li>\n<li><strong>math</strong>: Matemática</li>\n<li><strong>cs</strong>: Ciências da Computação</li>\n<li><strong>q-bio</strong>: Biologia Quantitativa</li>\n<li><strong>q-fin</strong>: Finanças Quantitativas</li>\n<li><strong>stat</strong>: Estatística</li>\n<li><strong>eess</strong>: Engenharia Elétrica e Ciências de Sistemas</li>\n<li><strong>econ</strong>: Economia</li>\n</ul>\n\n<h4>Para que serve o arxiv-id?</h4>\n<p>No contexto de metadados de artigos científicos:</p>\n<ul>\n<li><strong>Citação de preprints</strong>: Permite citar trabalhos antes de sua publicação formal</li>\n<li><strong>Rastreabilidade de versões</strong>: Identifica inequivocamente cada versão de um manuscrito</li>\n<li><strong>Acesso aberto</strong>: Garante acesso livre e permanente ao trabalho</li>\n<li><strong>Prioridade de descoberta</strong>: Estabelece data de publicação pública do preprint</li>\n<li><strong>Interoperabilidade</strong>: Facilita a conexão com outros sistemas bibliográficos</li>\n</ul>\n\n<h4>Importância para a comunicação científica</h4>\n<p>O arXiv ID é especialmente relevante em:</p>\n<ul>\n<li><strong>Física e Matemática</strong>: Onde o arXiv é o repositório padrão de facto</li>\n<li><strong>Ciências da Computação</strong>: Para compartilhar resultados rapidamente</li>\n<li><strong>Publicação dual</strong>: Muitos artigos existem tanto no arXiv quanto em revistas com peer review</li>\n<li><strong>Acesso antecipado</strong>: Permite à comunidade científica acessar resultados antes da publicação formal</li>\n</ul>\n\n<h4>Uso junto com outros identificadores</h4>\n<p>É comum que um artigo tenha múltiplos identificadores:</p>\n<ul>\n<li><strong>arXiv ID</strong>: Para a versão preprint</li>\n<li><strong>DOI de revista</strong>: Para a versão publicada com revisão por pares</li>\n<li><strong>DOI do arXiv</strong>: Atribuído automaticamente pelo arXiv desde 2022</li>\n</ul>\n<p>Todos podem coexistir e referenciar o mesmo trabalho em diferentes etapas de publicação.</p>\n','elisa','2026-01-09 08:00:24','elisa','2026-01-09 08:00:24');
INSERT INTO `manual_ayudas` (`id`, `clave`, `componente`, `idioma`, `ayuda`, `usuario_creacion`, `fecha_creacion`, `usuario_modificacion`, `fecha_modificacion`) VALUES (82,'arxiv-id','arxiv_id','en','<!-- INGLÉS -->\n<h3>What is arxiv-id?</h3>\n<p>The <code>arxiv-id</code> field contains the unique identifier assigned by arXiv, the world\'s most important scientific preprint repository, specializing in physics, mathematics, computer science, quantitative biology, quantitative finance, statistics, electrical engineering and systems science, and economics.</p>\n\n<h4>What is arXiv?</h4>\n<p>arXiv (pronounced \"archive\") is an open access repository operated by Cornell University that allows researchers to share preprints (preliminary versions) of scientific articles before their publication in peer-reviewed journals.</p>\n\n<h4>arXiv identifier structure</h4>\n<p>The identifier format has changed over time:</p>\n<p><strong>Old format (before April 2007)</strong>:</p>\n<pre>archive/YYMMNNN</pre>\n<p>Example: <code>math/0703123</code></p>\n<p><strong>New format (April 2007 - December 2014)</strong>:</p>\n<pre>YYMM.NNNN</pre>\n<p>Example: <code>0704.0001</code> (4 digits for sequence number)</p>\n<p><strong>Current format (since January 2015)</strong>:</p>\n<pre>YYMM.NNNNN</pre>\n<p>Example: <code>1501.00001</code> (5 digits for sequence number)</p>\n<p>Where:</p>\n<ul>\n<li><strong>YY</strong>: Last two digits of the year</li>\n<li><strong>MM</strong>: Submission month (01-12)</li>\n<li><strong>NNNNN</strong>: Sequence number within the month (zero-padded)</li>\n</ul>\n\n<h4>Article versions</h4>\n<p>Articles in arXiv can have multiple versions. To refer to a specific version, add:</p>\n<pre>YYMM.NNNNNvN</pre>\n<p>Example: <code>2401.12345v2</code> (second version of the article)</p>\n<p>Without the version number, the identifier always refers to the most recent version.</p>\n\n<h4>Input format</h4>\n<p>The field must contain the complete arXiv identifier, optionally with the <code>arXiv:</code> prefix.</p>\n<p><strong>Correct examples</strong>:</p>\n<p>Modern format:</p>\n<pre>2401.12345</pre>\n<p>With prefix (recommended for citations):</p>\n<pre>arXiv:2401.12345</pre>\n<p>With specific version:</p>\n<pre>arXiv:2401.12345v1</pre>\n<p>Old format:</p>\n<pre>math/0703123</pre>\n\n<h4>Relationship with DOI</h4>\n<p>Since January 2022, arXiv automatically assigns a DOI to each article:</p>\n<ul>\n<li><strong>arXiv ID</strong>: <code>arXiv:2202.01037</code></li>\n<li><strong>Equivalent DOI</strong>: <code>10.48550/arXiv.2202.01037</code></li>\n</ul>\n<p>Both identifiers can coexist:</p>\n<ul>\n<li>The arXiv ID is the repository\'s native identifier</li>\n<li>The DOI facilitates interoperability with other systems</li>\n</ul>\n\n<h4>arXiv categories</h4>\n<p>Each article has a primary category. Some main categories include:</p>\n<ul>\n<li><strong>physics</strong>: Physics (various subfields)</li>\n<li><strong>math</strong>: Mathematics</li>\n<li><strong>cs</strong>: Computer Science</li>\n<li><strong>q-bio</strong>: Quantitative Biology</li>\n<li><strong>q-fin</strong>: Quantitative Finance</li>\n<li><strong>stat</strong>: Statistics</li>\n<li><strong>eess</strong>: Electrical Engineering and Systems Science</li>\n<li><strong>econ</strong>: Economics</li>\n</ul>\n\n<h4>What is arxiv-id used for?</h4>\n<p>In the context of scientific article metadata:</p>\n<ul>\n<li><strong>Preprint citation</strong>: Allows citing works before formal publication</li>\n<li><strong>Version traceability</strong>: Unambiguously identifies each version of a manuscript</li>\n<li><strong>Open access</strong>: Guarantees free and permanent access to the work</li>\n<li><strong>Discovery priority</strong>: Establishes public publication date of the preprint</li>\n<li><strong>Interoperability</strong>: Facilitates connection with other bibliographic systems</li>\n</ul>\n\n<h4>Importance for scientific communication</h4>\n<p>The arXiv ID is especially relevant in:</p>\n<ul>\n<li><strong>Physics and Mathematics</strong>: Where arXiv is the de facto standard repository</li>\n<li><strong>Computer Science</strong>: For quickly sharing results</li>\n<li><strong>Dual publication</strong>: Many articles exist both in arXiv and in peer-reviewed journals</li>\n<li><strong>Early access</strong>: Allows the scientific community to access results before formal publication</li>\n</ul>\n\n<h4>Use alongside other identifiers</h4>\n<p>It is common for an article to have multiple identifiers:</p>\n<ul>\n<li><strong>arXiv ID</strong>: For the preprint version</li>\n<li><strong>Journal DOI</strong>: For the peer-reviewed published version</li>\n<li><strong>arXiv DOI</strong>: Automatically assigned by arXiv since 2022</li>\n</ul>\n<p>All can coexist and reference the same work at different publication stages.</p>\n','elisa','2026-01-09 08:00:24','elisa','2026-01-09 08:00:24');
INSERT INTO `manual_ayudas` (`id`, `clave`, `componente`, `idioma`, `ayuda`, `usuario_creacion`, `fecha_creacion`, `usuario_modificacion`, `fecha_modificacion`) VALUES (83,'arxiv-id','arxiv_id','it','<!-- ITALIANO -->\n<h3>Cos\'è arxiv-id?</h3>\n<p>Il campo <code>arxiv-id</code> contiene l\'identificatore unico assegnato da arXiv, il più importante repository di preprint scientifici al mondo, specializzato in fisica, matematica, informatica, biologia quantitativa, finanza quantitativa, statistica, ingegneria elettrica e scienze dei sistemi, ed economia.</p>\n\n<h4>Cos\'è arXiv?</h4>\n<p>arXiv (pronunciato \"archive\") è un repository ad accesso aperto gestito dalla Cornell University che permette ai ricercatori di condividere preprint (versioni preliminari) di articoli scientifici prima della loro pubblicazione in riviste con peer review.</p>\n\n<h4>Struttura dell\'identificatore arXiv</h4>\n<p>Il formato dell\'identificatore è cambiato nel tempo:</p>\n<p><strong>Formato vecchio (prima di aprile 2007)</strong>:</p>\n<pre>archivio/YYMMNNN</pre>\n<p>Esempio: <code>math/0703123</code></p>\n<p><strong>Formato nuovo (aprile 2007 - dicembre 2014)</strong>:</p>\n<pre>YYMM.NNNN</pre>\n<p>Esempio: <code>0704.0001</code> (4 cifre per il numero di sequenza)</p>\n<p><strong>Formato attuale (da gennaio 2015)</strong>:</p>\n<pre>YYMM.NNNNN</pre>\n<p>Esempio: <code>1501.00001</code> (5 cifre per il numero di sequenza)</p>\n<p>Dove:</p>\n<ul>\n<li><strong>YY</strong>: Ultime due cifre dell\'anno</li>\n<li><strong>MM</strong>: Mese di invio (01-12)</li>\n<li><strong>NNNNN</strong>: Numero di sequenza nel mese (con zeri iniziali)</li>\n</ul>\n\n<h4>Versioni degli articoli</h4>\n<p>Gli articoli in arXiv possono avere più versioni. Per riferirsi a una versione specifica, si aggiunge:</p>\n<pre>YYMM.NNNNNvN</pre>\n<p>Esempio: <code>2401.12345v2</code> (seconda versione dell\'articolo)</p>\n<p>Senza il numero di versione, l\'identificatore si riferisce sempre alla versione più recente.</p>\n\n<h4>Formato di inserimento</h4>\n<p>Il campo deve contenere l\'identificatore arXiv completo, opzionalmente con il prefisso <code>arXiv:</code>.</p>\n<p><strong>Esempi corretti</strong>:</p>\n<p>Formato moderno:</p>\n<pre>2401.12345</pre>\n<p>Con prefisso (consigliato per le citazioni):</p>\n<pre>arXiv:2401.12345</pre>\n<p>Con versione specifica:</p>\n<pre>arXiv:2401.12345v1</pre>\n<p>Formato vecchio:</p>\n<pre>math/0703123</pre>\n\n<h4>Relazione con il DOI</h4>\n<p>Da gennaio 2022, arXiv assegna automaticamente un DOI a ogni articolo:</p>\n<ul>\n<li><strong>arXiv ID</strong>: <code>arXiv:2202.01037</code></li>\n<li><strong>DOI equivalente</strong>: <code>10.48550/arXiv.2202.01037</code></li>\n</ul>\n<p>Entrambi gli identificatori possono coesistere:</p>\n<ul>\n<li>L\'arXiv ID è l\'identificatore nativo del repository</li>\n<li>Il DOI facilita l\'interoperabilità con altri sistemi</li>\n</ul>\n\n<h4>Categorie di arXiv</h4>\n<p>Ogni articolo ha una categoria principale. Alcune categorie principali includono:</p>\n<ul>\n<li><strong>physics</strong>: Fisica (vari sottocampi)</li>\n<li><strong>math</strong>: Matematica</li>\n<li><strong>cs</strong>: Informatica</li>\n<li><strong>q-bio</strong>: Biologia Quantitativa</li>\n<li><strong>q-fin</strong>: Finanza Quantitativa</li>\n<li><strong>stat</strong>: Statistica</li>\n<li><strong>eess</strong>: Ingegneria Elettrica e Scienze dei Sistemi</li>\n<li><strong>econ</strong>: Economia</li>\n</ul>\n\n<h4>A cosa serve l\'arxiv-id?</h4>\n<p>Nel contesto dei metadati di articoli scientifici:</p>\n<ul>\n<li><strong>Citazione di preprint</strong>: Permette di citare lavori prima della pubblicazione formale</li>\n<li><strong>Tracciabilità delle versioni</strong>: Identifica inequivocabilmente ogni versione di un manoscritto</li>\n<li><strong>Accesso aperto</strong>: Garantisce accesso libero e permanente al lavoro</li>\n<li><strong>Priorità di scoperta</strong>: Stabilisce la data di pubblicazione pubblica del preprint</li>\n<li><strong>Interoperabilità</strong>: Facilita la connessione con altri sistemi bibliografici</li>\n</ul>\n\n<h4>Importanza per la comunicazione scientifica</h4>\n<p>L\'arXiv ID è particolarmente rilevante in:</p>\n<ul>\n<li><strong>Fisica e Matematica</strong>: Dove arXiv è il repository standard de facto</li>\n<li><strong>Informatica</strong>: Per condividere rapidamente i risultati</li>\n<li><strong>Pubblicazione doppia</strong>: Molti articoli esistono sia in arXiv che in riviste con peer review</li>\n<li><strong>Accesso anticipato</strong>: Permette alla comunità scientifica di accedere ai risultati prima della pubblicazione formale</li>\n</ul>\n\n<h4>Uso insieme ad altri identificatori</h4>\n<p>È comune che un articolo abbia più identificatori:</p>\n<ul>\n<li><strong>arXiv ID</strong>: Per la versione preprint</li>\n<li><strong>DOI di rivista</strong>: Per la versione pubblicata con peer review</li>\n<li><strong>DOI di arXiv</strong>: Assegnato automaticamente da arXiv dal 2022</li>\n</ul>\n<p>Tutti possono coesistere e riferirsi allo stesso lavoro in diverse fasi di pubblicazione.</p>\n','elisa','2026-01-09 08:00:24','elisa','2026-01-09 08:00:24');
INSERT INTO `manual_ayudas` (`id`, `clave`, `componente`, `idioma`, `ayuda`, `usuario_creacion`, `fecha_creacion`, `usuario_modificacion`, `fecha_modificacion`) VALUES (84,'arxiv-id','arxiv_id','fr','<!-- FRANCÉS -->\n<h3>Qu\'est-ce que arxiv-id?</h3>\n<p>Le champ <code>arxiv-id</code> contient l\'identifiant unique attribué par arXiv, le dépôt de preprints scientifiques le plus important au monde, spécialisé en physique, mathématiques, informatique, biologie quantitative, finance quantitative, statistiques, ingénierie électrique et sciences des systèmes, et économie.</p>\n\n<h4>Qu\'est-ce qu\'arXiv?</h4>\n<p>arXiv (prononcé \"archive\") est un dépôt en libre accès géré par l\'Université Cornell qui permet aux chercheurs de partager des preprints (versions préliminaires) d\'articles scientifiques avant leur publication dans des revues à comité de lecture.</p>\n\n<h4>Structure de l\'identifiant arXiv</h4>\n<p>Le format de l\'identifiant a changé au fil du temps:</p>\n<p><strong>Ancien format (avant avril 2007)</strong>:</p>\n<pre>archive/YYMMNNN</pre>\n<p>Exemple: <code>math/0703123</code></p>\n<p><strong>Nouveau format (avril 2007 - décembre 2014)</strong>:</p>\n<pre>YYMM.NNNN</pre>\n<p>Exemple: <code>0704.0001</code> (4 chiffres pour le numéro de séquence)</p>\n<p><strong>Format actuel (depuis janvier 2015)</strong>:</p>\n<pre>YYMM.NNNNN</pre>\n<p>Exemple: <code>1501.00001</code> (5 chiffres pour le numéro de séquence)</p>\n<p>Où:</p>\n<ul>\n<li><strong>YY</strong>: Deux derniers chiffres de l\'année</li>\n<li><strong>MM</strong>: Mois de soumission (01-12)</li>\n<li><strong>NNNNN</strong>: Numéro de séquence dans le mois (complété par des zéros)</li>\n</ul>\n\n<h4>Versions d\'articles</h4>\n<p>Les articles dans arXiv peuvent avoir plusieurs versions. Pour faire référence à une version spécifique, on ajoute:</p>\n<pre>YYMM.NNNNNvN</pre>\n<p>Exemple: <code>2401.12345v2</code> (deuxième version de l\'article)</p>\n<p>Sans le numéro de version, l\'identifiant se réfère toujours à la version la plus récente.</p>\n\n<h4>Format de saisie</h4>\n<p>Le champ doit contenir l\'identifiant arXiv complet, optionnellement avec le préfixe <code>arXiv:</code>.</p>\n<p><strong>Exemples corrects</strong>:</p>\n<p>Format moderne:</p>\n<pre>2401.12345</pre>\n<p>Avec préfixe (recommandé pour les citations):</p>\n<pre>arXiv:2401.12345</pre>\n<p>Avec version spécifique:</p>\n<pre>arXiv:2401.12345v1</pre>\n<p>Format ancien:</p>\n<pre>math/0703123</pre>\n\n<h4>Relation avec le DOI</h4>\n<p>Depuis janvier 2022, arXiv attribue automatiquement un DOI à chaque article:</p>\n<ul>\n<li><strong>arXiv ID</strong>: <code>arXiv:2202.01037</code></li>\n<li><strong>DOI équivalent</strong>: <code>10.48550/arXiv.2202.01037</code></li>\n</ul>\n<p>Les deux identifiants peuvent coexister:</p>\n<ul>\n<li>L\'arXiv ID est l\'identifiant natif du dépôt</li>\n<li>Le DOI facilite l\'interopérabilité avec d\'autres systèmes</li>\n</ul>\n\n<h4>Catégories d\'arXiv</h4>\n<p>Chaque article a une catégorie principale. Quelques catégories principales incluent:</p>\n<ul>\n<li><strong>physics</strong>: Physique (plusieurs sous-domaines)</li>\n<li><strong>math</strong>: Mathématiques</li>\n<li><strong>cs</strong>: Informatique</li>\n<li><strong>q-bio</strong>: Biologie Quantitative</li>\n<li><strong>q-fin</strong>: Finance Quantitative</li>\n<li><strong>stat</strong>: Statistiques</li>\n<li><strong>eess</strong>: Ingénierie Électrique et Sciences des Systèmes</li>\n<li><strong>econ</strong>: Économie</li>\n</ul>\n\n<h4>À quoi sert l\'arxiv-id?</h4>\n<p>Dans le contexte des métadonnées d\'articles scientifiques:</p>\n<ul>\n<li><strong>Citation de preprints</strong>: Permet de citer des travaux avant leur publication formelle</li>\n<li><strong>Traçabilité des versions</strong>: Identifie sans ambiguïté chaque version d\'un manuscrit</li>\n<li><strong>Accès ouvert</strong>: Garantit un accès libre et permanent au travail</li>\n<li><strong>Priorité de découverte</strong>: Établit la date de publication publique du preprint</li>\n<li><strong>Interopérabilité</strong>: Facilite la connexion avec d\'autres systèmes bibliographiques</li>\n</ul>\n\n<h4>Importance pour la communication scientifique</h4>\n<p>L\'arXiv ID est particulièrement pertinent dans:</p>\n<ul>\n<li><strong>Physique et Mathématiques</strong>: Où arXiv est le dépôt standard de facto</li>\n<li><strong>Informatique</strong>: Pour partager rapidement les résultats</li>\n<li><strong>Publication double</strong>: De nombreux articles existent à la fois dans arXiv et dans des revues à comité de lecture</li>\n<li><strong>Accès anticipé</strong>: Permet à la communauté scientifique d\'accéder aux résultats avant la publication formelle</li>\n</ul>\n\n<h4>Utilisation avec d\'autres identifiants</h4>\n<p>Il est courant qu\'un article ait plusieurs identifiants:</p>\n<ul>\n<li><strong>arXiv ID</strong>: Pour la version preprint</li>\n<li><strong>DOI de revue</strong>: Pour la version publiée avec révision par les pairs</li>\n<li><strong>DOI d\'arXiv</strong>: Attribué automatiquement par arXiv depuis 2022</li>\n</ul>\n<p>Tous peuvent coexister et référencer le même travail à différentes étapes de publication.</p>\n','elisa','2026-01-09 08:00:24','elisa','2026-01-09 08:00:24');
INSERT INTO `manual_ayudas` (`id`, `clave`, `componente`, `idioma`, `ayuda`, `usuario_creacion`, `fecha_creacion`, `usuario_modificacion`, `fecha_modificacion`) VALUES (85,'arxiv-id','arxiv_id','de','<!-- ALEMÁN -->\n<h3>Was ist arxiv-id?</h3>\n<p>Das Feld <code>arxiv-id</code> enthält die eindeutige Kennung, die von arXiv vergeben wird, dem weltweit wichtigsten wissenschaftlichen Preprint-Repository, spezialisiert auf Physik, Mathematik, Informatik, quantitative Biologie, quantitative Finanzen, Statistik, Elektrotechnik und Systemwissenschaften sowie Wirtschaft.</p>\n\n<h4>Was ist arXiv?</h4>\n<p>arXiv (ausgesprochen \"archive\") ist ein Open-Access-Repository, das von der Cornell University betrieben wird und es Forschern ermöglicht, Preprints (Vorabversionen) wissenschaftlicher Artikel vor ihrer Veröffentlichung in begutachteten Zeitschriften zu teilen.</p>\n\n<h4>Struktur der arXiv-Kennung</h4>\n<p>Das Format der Kennung hat sich im Laufe der Zeit geändert:</p>\n<p><strong>Altes Format (vor April 2007)</strong>:</p>\n<pre>archiv/YYMMNNN</pre>\n<p>Beispiel: <code>math/0703123</code></p>\n<p><strong>Neues Format (April 2007 - Dezember 2014)</strong>:</p>\n<pre>YYMM.NNNN</pre>\n<p>Beispiel: <code>0704.0001</code> (4 Ziffern für die Sequenznummer)</p>\n<p><strong>Aktuelles Format (seit Januar 2015)</strong>:</p>\n<pre>YYMM.NNNNN</pre>\n<p>Beispiel: <code>1501.00001</code> (5 Ziffern für die Sequenznummer)</p>\n<p>Wobei:</p>\n<ul>\n<li><strong>YY</strong>: Letzte zwei Ziffern des Jahres</li>\n<li><strong>MM</strong>: Einreichungsmonat (01-12)</li>\n<li><strong>NNNNN</strong>: Sequenznummer innerhalb des Monats (mit führenden Nullen)</li>\n</ul>\n\n<h4>Artikelversionen</h4>\n<p>Artikel in arXiv können mehrere Versionen haben. Um auf eine bestimmte Version zu verweisen, wird hinzugefügt:</p>\n<pre>YYMM.NNNNNvN</pre>\n<p>Beispiel: <code>2401.12345v2</code> (zweite Version des Artikels)</p>\n<p>Ohne Versionsnummer bezieht sich die Kennung immer auf die neueste Version.</p>\n\n<h4>Eingabeformat</h4>\n<p>Das Feld muss die vollständige arXiv-Kennung enthalten, optional mit dem Präfix <code>arXiv:</code>.</p>\n<p><strong>Korrekte Beispiele</strong>:</p>\n<p>Modernes Format:</p>\n<pre>2401.12345</pre>\n<p>Mit Präfix (empfohlen für Zitationen):</p>\n<pre>arXiv:2401.12345</pre>\n<p>Mit spezifischer Version:</p>\n<pre>arXiv:2401.12345v1</pre>\n<p>Altes Format:</p>\n<pre>math/0703123</pre>\n\n<h4>Beziehung zum DOI</h4>\n<p>Seit Januar 2022 weist arXiv jedem Artikel automatisch einen DOI zu:</p>\n<ul>\n<li><strong>arXiv ID</strong>: <code>arXiv:2202.01037</code></li>\n<li><strong>Äquivalenter DOI</strong>: <code>10.48550/arXiv.2202.01037</code></li>\n</ul>\n<p>Beide Identifikatoren können koexistieren:</p>\n<ul>\n<li>Die arXiv ID ist der native Identifikator des Repositorys</li>\n<li>Der DOI erleichtert die Interoperabilität mit anderen Systemen</li>\n</ul>\n\n<h4>arXiv-Kategorien</h4>\n<p>Jeder Artikel hat eine Hauptkategorie. Einige Hauptkategorien umfassen:</p>\n<ul>\n<li><strong>physics</strong>: Physik (verschiedene Teilgebiete)</li>\n<li><strong>math</strong>: Mathematik</li>\n<li><strong>cs</strong>: Informatik</li>\n<li><strong>q-bio</strong>: Quantitative Biologie</li>\n<li><strong>q-fin</strong>: Quantitative Finanzen</li>\n<li><strong>stat</strong>: Statistik</li>\n<li><strong>eess</strong>: Elektrotechnik und Systemwissenschaften</li>\n<li><strong>econ</strong>: Wirtschaft</li>\n</ul>\n\n<h4>Wozu dient die arxiv-id?</h4>\n<p>Im Kontext wissenschaftlicher Artikelmetadaten:</p>\n<ul>\n<li><strong>Preprint-Zitation</strong>: Ermöglicht das Zitieren von Arbeiten vor formeller Veröffentlichung</li>\n<li><strong>Versionsverfolgung</strong>: Identifiziert eindeutig jede Version eines Manuskripts</li>\n<li><strong>Offener Zugang</strong>: Garantiert freien und permanenten Zugang zur Arbeit</li>\n<li><strong>Entdeckungspriorität</strong>: Legt das öffentliche Veröffentlichungsdatum des Preprints fest</li>\n<li><strong>Interoperabilität</strong>: Erleichtert die Verbindung mit anderen bibliographischen Systemen</li>\n</ul>\n\n<h4>Bedeutung für die wissenschaftliche Kommunikation</h4>\n<p>Die arXiv ID ist besonders relevant in:</p>\n<ul>\n<li><strong>Physik und Mathematik</strong>: Wo arXiv das De-facto-Standard-Repository ist</li>\n<li><strong>Informatik</strong>: Zum schnellen Teilen von Ergebnissen</li>\n<li><strong>Doppelveröffentlichung</strong>: Viele Artikel existieren sowohl in arXiv als auch in begutachteten Zeitschriften</li>\n<li><strong>Früher Zugang</strong>: Ermöglicht der wissenschaftlichen Gemeinschaft Zugang zu Ergebnissen vor formeller Veröffentlichung</li>\n</ul>\n\n<h4>Verwendung zusammen mit anderen Identifikatoren</h4>\n<p>Es ist üblich, dass ein Artikel mehrere Identifikatoren hat:</p>\n<ul>\n<li><strong>arXiv ID</strong>: Für die Preprint-Version</li>\n<li><strong>Journal DOI</strong>: Für die begutachtete veröffentlichte Version</li>\n<li><strong>arXiv DOI</strong>: Automatisch von arXiv seit 2022 zugewiesen</li>\n</ul>\n<p>Alle können koexistieren und auf dieselbe Arbeit in verschiedenen Veröffentlichungsphasen verweisen.</p>','elisa','2026-01-09 08:00:24','elisa','2026-01-09 08:00:24');
INSERT INTO `manual_ayudas` (`id`, `clave`, `componente`, `idioma`, `ayuda`, `usuario_creacion`, `fecha_creacion`, `usuario_modificacion`, `fecha_modificacion`) VALUES (86,'tipo-sujetos-investigación','tipo_sujetos_investigacion','es','<!-- ESPAÑOL -->\n<h3>¿Qué es el tipo de sujeto de investigación?</h3>\n<p>El campo <code>tipo-sujeto-investigacion</code> es un <strong>metadato de clasificación</strong> que especifica de manera general la naturaleza de los sujetos utilizados en el estudio científico. Este campo sirve para indexación, búsquedas y filtrado rápido de artículos, <strong>no reemplaza la descripción detallada</strong> que debe aparecer en la sección de Metodología del artículo.</p>\n\n<h4>Diferencia con otros campos</h4>\n<p><strong>Este campo es para clasificación general</strong>:</p>\n<ul>\n<li>Propósito: Indexación, filtrado, búsquedas en bases de datos</li>\n<li>Contenido: Categoría amplia (Humanos / Animales / In vitro)</li>\n<li>Ubicación: Metadatos del artículo</li>\n</ul>\n<p><strong>La información detallada va en otros campos</strong>:</p>\n<ul>\n<li>Especies exactas, cepas, edades → Sección \"Materiales y Métodos\"</li>\n<li>Aprobaciones éticas → Campo \"Declaraciones éticas\" o \"Ethics statements\"</li>\n<li>Número de sujetos, criterios de inclusión → Sección \"Métodos\"</li>\n<li>Condiciones experimentales → Sección \"Procedimientos\"</li>\n</ul>\n\n<h4>Categorías principales</h4>\n<p>Este campo típicamente acepta valores de una lista controlada:</p>\n<p><strong>Valores comunes</strong>:</p>\n<ul>\n<li><strong>Humanos</strong></li>\n<li><strong>Animales</strong></li>\n<li><strong>In vitro</strong></li>\n<li><strong>In silico</strong> (modelos computacionales)</li>\n<li><strong>Ex vivo</strong> (tejidos fuera del organismo)</li>\n<li><strong>Mixto</strong> (combinación de tipos)</li>\n<li><strong>No aplica</strong> (estudios teóricos, revisiones)</li>\n</ul>\n\n<h4>¿Para qué sirve este campo?</h4>\n<p><strong>Funciones principales</strong>:</p>\n<ol>\n<li><strong>Filtrado de búsquedas</strong>: Permite a investigadores buscar solo estudios con humanos, o solo con modelos animales</li>\n<li><strong>Cumplimiento normativo</strong>: Bases de datos pueden requerir esta clasificación</li>\n<li><strong>Análisis bibliométricos</strong>: Facilita estadísticas sobre tipos de estudios publicados</li>\n<li><strong>Indexación automática</strong>: Sistemas automatizados categorizan el artículo</li>\n<li><strong>Alertas y notificaciones</strong>: Usuarios pueden suscribirse a tipos específicos de estudios</li>\n</ol>\n\n<h4>Formato de entrada</h4>\n<p>El campo generalmente acepta <strong>valores únicos o múltiples</strong> de una lista predefinida.</p>\n<p><strong>Ejemplos correctos</strong>:</p>\n<p>Estudio con sujetos humanos:</p>\n<pre>Humanos</pre>\n<p>Estudio con animales:</p>\n<pre>Animales</pre>\n<p>Estudio con cultivos celulares:</p>\n<pre>In vitro</pre>\n<p>Estudio combinado:</p>\n<pre>Animales; In vitro</pre>\n\n<h4>Relación con otros metadatos</h4>\n<p>Este campo se complementa con:</p>\n<ul>\n<li><strong>Tipo de estudio</strong>: Observacional, experimental, revisión sistemática</li>\n<li><strong>Área temática</strong>: Biomedicina, farmacología, toxicología</li>\n<li><strong>Palabras clave</strong>: Detalles específicos del modelo utilizado</li>\n<li><strong>Resumen/Abstract</strong>: Descripción metodológica breve</li>\n<li><strong>Metodología completa</strong>: Descripción exhaustiva en el texto del artículo</li>\n</ul>\n\n<h4>Importancia para bases de datos</h4>\n<p>Las bases de datos académicas utilizan este campo para:</p>\n<ul>\n<li><strong>PubMed</strong>: Filtro \"Species\" permite buscar por tipo de sujeto</li>\n<li><strong>Scopus</strong>: Clasificación de estudios preclínicos vs clínicos</li>\n<li><strong>Web of Science</strong>: Refinamiento de resultados por metodología</li>\n<li><strong>SciELO</strong>: Categorización de artículos biomédicos</li>\n</ul>\n\n<h4>Nota importante</h4>\n<p><strong>Este campo NO contiene ni reemplaza</strong>:</p>\n<ul>\n<li>Detalles de las especies o cepas utilizadas</li>\n<li>Número de sujetos o tamaño muestral</li>\n<li>Procedimientos experimentales específicos</li>\n<li>Declaraciones de aprobación ética</li>\n<li>Protocolos de manejo de sujetos</li>\n</ul>\n<p>Toda esa información detallada debe estar en las secciones correspondientes del artículo completo.</p>\n','franco','2026-01-09 08:35:02','franco','2026-01-09 08:35:02');
INSERT INTO `manual_ayudas` (`id`, `clave`, `componente`, `idioma`, `ayuda`, `usuario_creacion`, `fecha_creacion`, `usuario_modificacion`, `fecha_modificacion`) VALUES (87,'tipo-sujetos-investigación','tipo_sujetos_investigacion','pt','<!-- PORTUGUÉS -->\n<h3>O que é o tipo de sujeito de pesquisa?</h3>\n<p>O campo <code>tipo-sujeto-investigacion</code> é um <strong>metadado de classificação</strong> que especifica de maneira geral a natureza dos sujeitos utilizados no estudo científico. Este campo serve para indexação, buscas e filtragem rápida de artigos; <strong>não substitui a descrição detalhada</strong> que deve aparecer na seção de Metodologia do artigo.</p>\n\n<h4>Diferença com outros campos</h4>\n<p><strong>Este campo é para classificação geral</strong>:</p>\n<ul>\n<li>Propósito: Indexação, filtragem, buscas em bases de dados</li>\n<li>Conteúdo: Categoria ampla (Humanos / Animais / In vitro)</li>\n<li>Localização: Metadados do artigo</li>\n</ul>\n<p><strong>A informação detalhada vai em outros campos</strong>:</p>\n<ul>\n<li>Espécies exatas, linhagens, idades → Seção \"Materiais e Métodos\"</li>\n<li>Aprovações éticas → Campo \"Declarações éticas\" ou \"Ethics statements\"</li>\n<li>Número de sujeitos, critérios de inclusão → Seção \"Métodos\"</li>\n<li>Condições experimentais → Seção \"Procedimentos\"</li>\n</ul>\n\n<h4>Categorias principais</h4>\n<p>Este campo tipicamente aceita valores de uma lista controlada:</p>\n<p><strong>Valores comuns</strong>:</p>\n<ul>\n<li><strong>Humanos</strong></li>\n<li><strong>Animais</strong></li>\n<li><strong>In vitro</strong></li>\n<li><strong>In silico</strong> (modelos computacionais)</li>\n<li><strong>Ex vivo</strong> (tecidos fora do organismo)</li>\n<li><strong>Misto</strong> (combinação de tipos)</li>\n<li><strong>Não se aplica</strong> (estudos teóricos, revisões)</li>\n</ul>\n\n<h4>Para que serve este campo?</h4>\n<p><strong>Funções principais</strong>:</p>\n<ol>\n<li><strong>Filtragem de buscas</strong>: Permite aos pesquisadores buscar apenas estudos com humanos, ou apenas com modelos animais</li>\n<li><strong>Cumprimento normativo</strong>: Bases de dados podem requerer esta classificação</li>\n<li><strong>Análises bibliométricas</strong>: Facilita estatísticas sobre tipos de estudos publicados</li>\n<li><strong>Indexação automática</strong>: Sistemas automatizados categorizam o artigo</li>\n<li><strong>Alertas e notificações</strong>: Usuários podem se inscrever em tipos específicos de estudos</li>\n</ol>\n\n<h4>Formato de entrada</h4>\n<p>O campo geralmente aceita <strong>valores únicos ou múltiplos</strong> de uma lista predefinida.</p>\n<p><strong>Exemplos corretos</strong>:</p>\n<p>Estudo com sujeitos humanos:</p>\n<pre>Humanos</pre>\n<p>Estudo com animais:</p>\n<pre>Animais</pre>\n<p>Estudo com culturas celulares:</p>\n<pre>In vitro</pre>\n<p>Estudo combinado:</p>\n<pre>Animais; In vitro</pre>\n\n<h4>Relação com outros metadados</h4>\n<p>Este campo se complementa com:</p>\n<ul>\n<li><strong>Tipo de estudo</strong>: Observacional, experimental, revisão sistemática</li>\n<li><strong>Área temática</strong>: Biomedicina, farmacologia, toxicologia</li>\n<li><strong>Palavras-chave</strong>: Detalhes específicos do modelo utilizado</li>\n<li><strong>Resumo/Abstract</strong>: Descrição metodológica breve</li>\n<li><strong>Metodologia completa</strong>: Descrição exaustiva no texto do artigo</li>\n</ul>\n\n<h4>Importância para bases de dados</h4>\n<p>As bases de dados acadêmicas utilizam este campo para:</p>\n<ul>\n<li><strong>PubMed</strong>: Filtro \"Species\" permite buscar por tipo de sujeito</li>\n<li><strong>Scopus</strong>: Classificação de estudos pré-clínicos vs clínicos</li>\n<li><strong>Web of Science</strong>: Refinamento de resultados por metodologia</li>\n<li><strong>SciELO</strong>: Categorização de artigos biomédicos</li>\n</ul>\n\n<h4>Nota importante</h4>\n<p><strong>Este campo NÃO contém nem substitui</strong>:</p>\n<ul>\n<li>Detalhes das espécies ou linhagens utilizadas</li>\n<li>Número de sujeitos ou tamanho amostral</li>\n<li>Procedimentos experimentais específicos</li>\n<li>Declarações de aprovação ética</li>\n<li>Protocolos de manejo de sujeitos</li>\n</ul>\n<p>Toda essa informação detalhada deve estar nas seções correspondentes do artigo completo.</p>\n','franco','2026-01-09 08:35:02','franco','2026-01-09 08:35:02');
INSERT INTO `manual_ayudas` (`id`, `clave`, `componente`, `idioma`, `ayuda`, `usuario_creacion`, `fecha_creacion`, `usuario_modificacion`, `fecha_modificacion`) VALUES (88,'tipo-sujetos-investigación','tipo_sujetos_investigacion','en','<!-- INGLÉS -->\n<h3>What is research subject type?</h3>\n<p>The <code>tipo-sujeto-investigacion</code> field is a <strong>classification metadata</strong> that specifies in general terms the nature of the subjects used in the scientific study. This field serves for indexing, searching, and quick filtering of articles; it <strong>does not replace the detailed description</strong> that should appear in the article\'s Methodology section.</p>\n\n<h4>Difference from other fields</h4>\n<p><strong>This field is for general classification</strong>:</p>\n<ul>\n<li>Purpose: Indexing, filtering, database searches</li>\n<li>Content: Broad category (Humans / Animals / In vitro)</li>\n<li>Location: Article metadata</li>\n</ul>\n<p><strong>Detailed information goes in other fields</strong>:</p>\n<ul>\n<li>Exact species, strains, ages → \"Materials and Methods\" section</li>\n<li>Ethical approvals → \"Ethics statements\" field</li>\n<li>Number of subjects, inclusion criteria → \"Methods\" section</li>\n<li>Experimental conditions → \"Procedures\" section</li>\n</ul>\n\n<h4>Main categories</h4>\n<p>This field typically accepts values from a controlled list:</p>\n<p><strong>Common values</strong>:</p>\n<ul>\n<li><strong>Humans</strong></li>\n<li><strong>Animals</strong></li>\n<li><strong>In vitro</strong></li>\n<li><strong>In silico</strong> (computational models)</li>\n<li><strong>Ex vivo</strong> (tissues outside the organism)</li>\n<li><strong>Mixed</strong> (combination of types)</li>\n<li><strong>Not applicable</strong> (theoretical studies, reviews)</li>\n</ul>\n\n<h4>What is this field used for?</h4>\n<p><strong>Main functions</strong>:</p>\n<ol>\n<li><strong>Search filtering</strong>: Allows researchers to search only for studies with humans, or only with animal models</li>\n<li><strong>Regulatory compliance</strong>: Databases may require this classification</li>\n<li><strong>Bibliometric analysis</strong>: Facilitates statistics on types of studies published</li>\n<li><strong>Automatic indexing</strong>: Automated systems categorize the article</li>\n<li><strong>Alerts and notifications</strong>: Users can subscribe to specific types of studies</li>\n</ol>\n\n<h4>Input format</h4>\n<p>The field generally accepts <strong>single or multiple values</strong> from a predefined list.</p>\n<p><strong>Correct examples</strong>:</p>\n<p>Study with human subjects:</p>\n<pre>Humans</pre>\n<p>Study with animals:</p>\n<pre>Animals</pre>\n<p>Study with cell cultures:</p>\n<pre>In vitro</pre>\n<p>Combined study:</p>\n<pre>Animals; In vitro</pre>\n\n<h4>Relationship with other metadata</h4>\n<p>This field complements:</p>\n<ul>\n<li><strong>Study type</strong>: Observational, experimental, systematic review</li>\n<li><strong>Subject area</strong>: Biomedicine, pharmacology, toxicology</li>\n<li><strong>Keywords</strong>: Specific details of the model used</li>\n<li><strong>Abstract</strong>: Brief methodological description</li>\n<li><strong>Complete methodology</strong>: Exhaustive description in the article text</li>\n</ul>\n\n<h4>Importance for databases</h4>\n<p>Academic databases use this field for:</p>\n<ul>\n<li><strong>PubMed</strong>: \"Species\" filter allows searching by subject type</li>\n<li><strong>Scopus</strong>: Classification of preclinical vs clinical studies</li>\n<li><strong>Web of Science</strong>: Results refinement by methodology</li>\n<li><strong>SciELO</strong>: Categorization of biomedical articles</li>\n</ul>\n\n<h4>Important note</h4>\n<p><strong>This field does NOT contain or replace</strong>:</p>\n<ul>\n<li>Details of species or strains used</li>\n<li>Number of subjects or sample size</li>\n<li>Specific experimental procedures</li>\n<li>Ethical approval declarations</li>\n<li>Subject handling protocols</li>\n</ul>\n<p>All that detailed information must be in the corresponding sections of the complete article.</p>\n','franco','2026-01-09 08:35:02','franco','2026-01-09 08:35:02');
INSERT INTO `manual_ayudas` (`id`, `clave`, `componente`, `idioma`, `ayuda`, `usuario_creacion`, `fecha_creacion`, `usuario_modificacion`, `fecha_modificacion`) VALUES (89,'tipo-sujetos-investigación','tipo_sujetos_investigacion','it','<!-- ITALIANO -->\n<h3>Cos\'è il tipo di soggetto di ricerca?</h3>\n<p>Il campo <code>tipo-sujeto-investigacion</code> è un <strong>metadato di classificazione</strong> che specifica in modo generale la natura dei soggetti utilizzati nello studio scientifico. Questo campo serve per indicizzazione, ricerche e filtro rapido di articoli; <strong>non sostituisce la descrizione dettagliata</strong> che deve apparire nella sezione Metodologia dell\'articolo.</p>\n\n<h4>Differenza con altri campi</h4>\n<p><strong>Questo campo è per la classificazione generale</strong>:</p>\n<ul>\n<li>Scopo: Indicizzazione, filtraggio, ricerche nei database</li>\n<li>Contenuto: Categoria ampia (Umani / Animali / In vitro)</li>\n<li>Posizione: Metadati dell\'articolo</li>\n</ul>\n<p><strong>L\'informazione dettagliata va in altri campi</strong>:</p>\n<ul>\n<li>Specie esatte, ceppi, età → Sezione \"Materiali e Metodi\"</li>\n<li>Approvazioni etiche → Campo \"Dichiarazioni etiche\"</li>\n<li>Numero di soggetti, criteri di inclusione → Sezione \"Metodi\"</li>\n<li>Condizioni sperimentali → Sezione \"Procedure\"</li>\n</ul>\n\n<h4>Categorie principali</h4>\n<p>Questo campo accetta tipicamente valori da una lista controllata:</p>\n<p><strong>Valori comuni</strong>:</p>\n<ul>\n<li><strong>Umani</strong></li>\n<li><strong>Animali</strong></li>\n<li><strong>In vitro</strong></li>\n<li><strong>In silico</strong> (modelli computazionali)</li>\n<li><strong>Ex vivo</strong> (tessuti fuori dall\'organismo)</li>\n<li><strong>Misto</strong> (combinazione di tipi)</li>\n<li><strong>Non applicabile</strong> (studi teorici, revisioni)</li>\n</ul>\n\n<h4>A cosa serve questo campo?</h4>\n<p><strong>Funzioni principali</strong>:</p>\n<ol>\n<li><strong>Filtro delle ricerche</strong>: Permette ai ricercatori di cercare solo studi con umani, o solo con modelli animali</li>\n<li><strong>Conformità normativa</strong>: I database possono richiedere questa classificazione</li>\n<li><strong>Analisi bibliometriche</strong>: Facilita le statistiche sui tipi di studi pubblicati</li>\n<li><strong>Indicizzazione automatica</strong>: I sistemi automatizzati categorizzano l\'articolo</li>\n<li><strong>Avvisi e notifiche</strong>: Gli utenti possono iscriversi a tipi specifici di studi</li>\n</ol>\n\n<h4>Formato di inserimento</h4>\n<p>Il campo generalmente accetta <strong>valori singoli o multipli</strong> da una lista predefinita.</p>\n<p><strong>Esempi corretti</strong>:</p>\n<p>Studio con soggetti umani:</p>\n<pre>Umani</pre>\n<p>Studio con animali:</p>\n<pre>Animali</pre>\n<p>Studio con colture cellulari:</p>\n<pre>In vitro</pre>\n<p>Studio combinato:</p>\n<pre>Animali; In vitro</pre>\n\n<h4>Relazione con altri metadati</h4>\n<p>Questo campo si integra con:</p>\n<ul>\n<li><strong>Tipo di studio</strong>: Osservazionale, sperimentale, revisione sistematica</li>\n<li><strong>Area tematica</strong>: Biomedicina, farmacologia, tossicologia</li>\n<li><strong>Parole chiave</strong>: Dettagli specifici del modello utilizzato</li>\n<li><strong>Abstract</strong>: Descrizione metodologica breve</li>\n<li><strong>Metodologia completa</strong>: Descrizione esaustiva nel testo dell\'articolo</li>\n</ul>\n\n<h4>Importanza per i database</h4>\n<p>I database accademici utilizzano questo campo per:</p>\n<ul>\n<li><strong>PubMed</strong>: Il filtro \"Species\" permette di cercare per tipo di soggetto</li>\n<li><strong>Scopus</strong>: Classificazione di studi preclinici vs clinici</li>\n<li><strong>Web of Science</strong>: Raffinamento dei risultati per metodologia</li>\n<li><strong>SciELO</strong>: Categorizzazione di articoli biomedici</li>\n</ul>\n\n<h4>Nota importante</h4>\n<p><strong>Questo campo NON contiene né sostituisce</strong>:</p>\n<ul>\n<li>Dettagli delle specie o ceppi utilizzati</li>\n<li>Numero di soggetti o dimensione del campione</li>\n<li>Procedure sperimentali specifiche</li>\n<li>Dichiarazioni di approvazione etica</li>\n<li>Protocolli di gestione dei soggetti</li>\n</ul>\n<p>Tutta questa informazione dettagliata deve essere nelle sezioni corrispondenti dell\'articolo completo.</p>\n','franco','2026-01-09 08:35:02','franco','2026-01-09 08:35:02');
INSERT INTO `manual_ayudas` (`id`, `clave`, `componente`, `idioma`, `ayuda`, `usuario_creacion`, `fecha_creacion`, `usuario_modificacion`, `fecha_modificacion`) VALUES (90,'tipo-sujetos-investigación','tipo_sujetos_investigacion','fr','<!-- FRANCÉS -->\n<h3>Qu\'est-ce que le type de sujet de recherche?</h3>\n<p>Le champ <code>tipo-sujeto-investigacion</code> est une <strong>métadonnée de classification</strong> qui spécifie de manière générale la nature des sujets utilisés dans l\'étude scientifique. Ce champ sert à l\'indexation, aux recherches et au filtrage rapide d\'articles; il <strong>ne remplace pas la description détaillée</strong> qui doit apparaître dans la section Méthodologie de l\'article.</p>\n\n<h4>Différence avec d\'autres champs</h4>\n<p><strong>Ce champ est pour la classification générale</strong>:</p>\n<ul>\n<li>Objectif: Indexation, filtrage, recherches dans les bases de données</li>\n<li>Contenu: Catégorie large (Humains / Animaux / In vitro)</li>\n<li>Localisation: Métadonnées de l\'article</li>\n</ul>\n<p><strong>L\'information détaillée va dans d\'autres champs</strong>:</p>\n<ul>\n<li>Espèces exactes, souches, âges → Section \"Matériels et Méthodes\"</li>\n<li>Approbations éthiques → Champ \"Déclarations éthiques\"</li>\n<li>Nombre de sujets, critères d\'inclusion → Section \"Méthodes\"</li>\n<li>Conditions expérimentales → Section \"Procédures\"</li>\n</ul>\n\n<h4>Catégories principales</h4>\n<p>Ce champ accepte typiquement des valeurs d\'une liste contrôlée:</p>\n<p><strong>Valeurs courantes</strong>:</p>\n<ul>\n<li><strong>Humains</strong></li>\n<li><strong>Animaux</strong></li>\n<li><strong>In vitro</strong></li>\n<li><strong>In silico</strong> (modèles informatiques)</li>\n<li><strong>Ex vivo</strong> (tissus en dehors de l\'organisme)</li>\n<li><strong>Mixte</strong> (combinaison de types)</li>\n<li><strong>Non applicable</strong> (études théoriques, revues)</li>\n</ul>\n\n<h4>À quoi sert ce champ?</h4>\n<p><strong>Fonctions principales</strong>:</p>\n<ol>\n<li><strong>Filtrage des recherches</strong>: Permet aux chercheurs de rechercher uniquement des études avec des humains, ou uniquement avec des modèles animaux</li>\n<li><strong>Conformité réglementaire</strong>: Les bases de données peuvent exiger cette classification</li>\n<li><strong>Analyses bibliométriques</strong>: Facilite les statistiques sur les types d\'études publiées</li>\n<li><strong>Indexation automatique</strong>: Les systèmes automatisés catégorisent l\'article</li>\n<li><strong>Alertes et notifications</strong>: Les utilisateurs peuvent s\'abonner à des types spécifiques d\'études</li>\n</ol>\n\n<h4>Format de saisie</h4>\n<p>Le champ accepte généralement des <strong>valeurs uniques ou multiples</strong> d\'une liste prédéfinie.</p>\n<p><strong>Exemples corrects</strong>:</p>\n<p>Étude avec sujets humains:</p>\n<pre>Humains</pre>\n<p>Étude avec animaux:</p>\n<pre>Animaux</pre>\n<p>Étude avec cultures cellulaires:</p>\n<pre>In vitro</pre>\n<p>Étude combinée:</p>\n<pre>Animaux; In vitro</pre>\n\n<h4>Relation avec d\'autres métadonnées</h4>\n<p>Ce champ complète:</p>\n<ul>\n<li><strong>Type d\'étude</strong>: Observationnelle, expérimentale, revue systématique</li>\n<li><strong>Domaine thématique</strong>: Biomédecine, pharmacologie, toxicologie</li>\n<li><strong>Mots-clés</strong>: Détails spécifiques du modèle utilisé</li>\n<li><strong>Résumé/Abstract</strong>: Description méthodologique brève</li>\n<li><strong>Méthodologie complète</strong>: Description exhaustive dans le texte de l\'article</li>\n</ul>\n\n<h4>Importance pour les bases de données</h4>\n<p>Les bases de données académiques utilisent ce champ pour:</p>\n<ul>\n<li><strong>PubMed</strong>: Le filtre \"Species\" permet de rechercher par type de sujet</li>\n<li><strong>Scopus</strong>: Classification des études précliniques vs cliniques</li>\n<li><strong>Web of Science</strong>: Raffinement des résultats par méthodologie</li>\n<li><strong>SciELO</strong>: Catégorisation des articles biomédicaux</li>\n</ul>\n\n<h4>Note importante</h4>\n<p><strong>Ce champ NE contient NI ne remplace</strong>:</p>\n<ul>\n<li>Détails des espèces ou souches utilisées</li>\n<li>Nombre de sujets ou taille de l\'échantillon</li>\n<li>Procédures expérimentales spécifiques</li>\n<li>Déclarations d\'approbation éthique</li>\n<li>Protocoles de manipulation des sujets</li>\n</ul>\n<p>Toute cette information détaillée doit être dans les sections correspondantes de l\'article complet.</p>\n','franco','2026-01-09 08:35:02','franco','2026-01-09 08:35:02');
INSERT INTO `manual_ayudas` (`id`, `clave`, `componente`, `idioma`, `ayuda`, `usuario_creacion`, `fecha_creacion`, `usuario_modificacion`, `fecha_modificacion`) VALUES (91,'tipo-sujetos-investigación','tipo_sujetos_investigacion','de','<!-- ALEMÁN -->\n<h3>Was ist der Forschungssubjekttyp?</h3>\n<p>Das Feld <code>tipo-sujeto-investigacion</code> ist ein <strong>Klassifizierungsmetadatum</strong>, das allgemein die Art der in der wissenschaftlichen Studie verwendeten Subjekte angibt. Dieses Feld dient der Indexierung, Suche und schnellen Filterung von Artikeln; es <strong>ersetzt nicht die detaillierte Beschreibung</strong>, die im Methodikteil des Artikels erscheinen sollte.</p>\n\n<h4>Unterschied zu anderen Feldern</h4>\n<p><strong>Dieses Feld dient der allgemeinen Klassifizierung</strong>:</p>\n<ul>\n<li>Zweck: Indexierung, Filterung, Datenbanksuchen</li>\n<li>Inhalt: Breite Kategorie (Menschen / Tiere / In vitro)</li>\n<li>Position: Artikel-Metadaten</li>\n</ul>\n<p><strong>Detaillierte Informationen gehören in andere Felder</strong>:</p>\n<ul>\n<li>Genaue Arten, Stämme, Alter → Abschnitt \"Material und Methoden\"</li>\n<li>Ethische Genehmigungen → Feld \"Ethikerklärungen\"</li>\n<li>Anzahl der Probanden, Einschlusskriterien → Abschnitt \"Methoden\"</li>\n<li>Experimentelle Bedingungen → Abschnitt \"Verfahren\"</li>\n</ul>\n\n<h4>Hauptkategorien</h4>\n<p>Dieses Feld akzeptiert typischerweise Werte aus einer kontrollierten Liste:</p>\n<p><strong>Häufige Werte</strong>:</p>\n<ul>\n<li><strong>Menschen</strong></li>\n<li><strong>Tiere</strong></li>\n<li><strong>In vitro</strong></li>\n<li><strong>In silico</strong> (Computermodelle)</li>\n<li><strong>Ex vivo</strong> (Gewebe außerhalb des Organismus)</li>\n<li><strong>Gemischt</strong> (Kombination von Typen)</li>\n<li><strong>Nicht zutreffend</strong> (theoretische Studien, Übersichtsarbeiten)</li>\n</ul>\n\n<h4>Wozu dient dieses Feld?</h4>\n<p><strong>Hauptfunktionen</strong>:</p>\n<ol>\n<li><strong>Suchfilterung</strong>: Ermöglicht Forschern, nur nach Studien mit Menschen oder nur mit Tiermodellen zu suchen</li>\n<li><strong>Regulatorische Compliance</strong>: Datenbanken können diese Klassifizierung erfordern</li>\n<li><strong>Bibliometrische Analysen</strong>: Erleichtert Statistiken über veröffentlichte Studientypen</li>\n<li><strong>Automatische Indexierung</strong>: Automatisierte Systeme kategorisieren den Artikel</li>\n<li><strong>Benachrichtigungen</strong>: Benutzer können bestimmte Studientypen abonnieren</li>\n</ol>\n\n<h4>Eingabeformat</h4>\n<p>Das Feld akzeptiert im Allgemeinen <strong>einzelne oder mehrere Werte</strong> aus einer vordefinierten Liste.</p>\n<p><strong>Korrekte Beispiele</strong>:</p>\n<p>Studie mit menschlichen Probanden:</p>\n<pre>Menschen</pre>\n<p>Studie mit Tieren:</p>\n<pre>Tiere</pre>\n<p>Studie mit Zellkulturen:</p>\n<pre>In vitro</pre>\n<p>Kombinierte Studie:</p>\n<pre>Tiere; In vitro</pre>\n\n<h4>Beziehung zu anderen Metadaten</h4>\n<p>Dieses Feld ergänzt:</p>\n<ul>\n<li><strong>Studientyp</strong>: Beobachtend, experimentell, systematische Übersicht</li>\n<li><strong>Themenbereich</strong>: Biomedizin, Pharmakologie, Toxikologie</li>\n<li><strong>Schlüsselwörter</strong>: Spezifische Details des verwendeten Modells</li>\n<li><strong>Abstract</strong>: Kurze methodische Beschreibung</li>\n<li><strong>Vollständige Methodik</strong>: Ausführliche Beschreibung im Artikeltext</li>\n</ul>\n\n<h4>Bedeutung für Datenbanken</h4>\n<p>Akademische Datenbanken verwenden dieses Feld für:</p>\n<ul>\n<li><strong>PubMed</strong>: Der \"Species\"-Filter ermöglicht die Suche nach Subjekttyp</li>\n<li><strong>Scopus</strong>: Klassifizierung von präklinischen vs. klinischen Studien</li>\n<li><strong>Web of Science</strong>: Verfeinerung der Ergebnisse nach Methodik</li>\n<li><strong>SciELO</strong>: Kategorisierung biomedizinischer Artikel</li>\n</ul>\n\n<h4>Wichtiger Hinweis</h4>\n<p><strong>Dieses Feld enthält NICHT und ersetzt NICHT</strong>:</p>\n<ul>\n<li>Details zu verwendeten Arten oder Stämmen</li>\n<li>Anzahl der Probanden oder Stichprobengröße</li>\n<li>Spezifische experimentelle Verfahren</li>\n<li>Erklärungen zur ethischen Genehmigung</li>\n<li>Protokolle zum Umgang mit Probanden</li>\n</ul>\n<p>All diese detaillierten Informationen müssen in den entsprechenden Abschnitten des vollständigen Artikels enthalten sein.</p>','franco','2026-01-09 08:35:02','franco','2026-01-09 08:35:02');
INSERT INTO `consultas` (`id`, `consulta_sistema`, `nombre`, `descripcion`, `editor_consultas`, `comentarios`, `usuario_creador`, `fecha_creacion`) VALUES (14,1,'AUT-REV-001: Pool de revisores disponibles por área','Muestra cantidad de revisores disponibles/no disponibles por área de investigación','SELECT \n    area_investigacion AS \'Área de Investigación\',\n    COUNT(*) AS \'Total Revisores\',\n    SUM(CASE WHEN disponible_revision = 1 THEN 1 ELSE 0 END) AS \'Disponibles\',\n    SUM(CASE WHEN disponible_revision = 0 THEN 1 ELSE 0 END) AS \'No Disponibles\',\n    ROUND(AVG(calificacion_colaboracion), 2) AS \'Calificación Promedio\'\nFROM autores\nWHERE estado_autor = \'activo\'\n    AND area_investigacion IS NOT NULL\nGROUP BY area_investigacion\nORDER BY Disponibles DESC;\n','Asignación rápida de manuscritos, identificación de gaps de cobertura. Frecuencia recomendada: Semanal','sistema','2026-01-31 02:36:08');
INSERT INTO `consultas` (`id`, `consulta_sistema`, `nombre`, `descripcion`, `editor_consultas`, `comentarios`, `usuario_creador`, `fecha_creacion`) VALUES (15,1,'AUT-REV-002: Revisores con expertise específico','Lista de revisores disponibles con sus áreas de expertise detalladas','SELECT \n    apellidos_nombre AS \'Nombre Completo\',\n    email_principal AS \'Email\',\n    afiliacion_actual AS \'Institución\',\n    areas_revision AS \'Áreas de Revisión\',\n    expertise_revision AS \'Expertise Específico\',\n    calificacion_colaboracion AS \'Calificación\'\nFROM autores\nWHERE disponible_revision = 1\n    AND estado_autor = \'activo\'\n    AND areas_revision IS NOT NULL\nORDER BY calificacion_colaboracion DESC, apellidos;\n','Matching preciso de manuscritos con revisores. Frecuencia recomendada: Diaria','sistema','2026-01-31 02:40:33');
INSERT INTO `consultas` (`id`, `consulta_sistema`, `nombre`, `descripcion`, `editor_consultas`, `comentarios`, `usuario_creador`, `fecha_creacion`) VALUES (16,1,'AUT-REV-003: Alertas de áreas críticas','Áreas con menos de 3 revisores disponibles (requiere atención urgente)','SELECT \n    area_investigacion AS \'Área Crítica\',\n    COUNT(*) AS \'Revisores Disponibles\',\n    GROUP_CONCAT(apellidos_nombre SEPARATOR \'; \') AS \'Nombres\'\nFROM autores\nWHERE disponible_revision = 1\n    AND estado_autor = \'activo\'\n    AND area_investigacion IS NOT NULL\nGROUP BY area_investigacion\nHAVING COUNT(*) < 3\nORDER BY COUNT(*), area_investigacion;\n','Planificación de convocatorias, identificación de necesidades. Frecuencia recomendada: Quincenal','sistema','2026-01-31 02:42:17');
INSERT INTO `consultas` (`id`, `consulta_sistema`, `nombre`, `descripcion`, `editor_consultas`, `comentarios`, `usuario_creador`, `fecha_creacion`) VALUES (17,1,'AUT-REV-004: Carga de trabajo de revisores','Revisores activos con cantidad de revisiones asignadas','SELECT \n    a.apellidos_nombre AS \'Revisor\',\n    a.email_principal AS \'Email\',\n    COUNT(ar.id_revision) AS \'Revisiones Activas\',\n    SUM(CASE WHEN ar.decision IS NULL THEN 1 ELSE 0 END) AS \'Pendientes\',\n    SUM(CASE WHEN ar.decision IS NOT NULL THEN 1 ELSE 0 END) AS \'Completadas\',\n    a.calificacion_colaboracion AS \'Calificación\'\nFROM autores a\nLEFT JOIN articulo_revisor ar ON a.id_autor = ar.id_autor\nWHERE a.disponible_revision = 1\n    AND a.estado_autor = \'activo\'\nGROUP BY a.id_autor\nORDER BY COUNT(ar.id_revision) DESC;\n','Balance de carga, identificación de sobrecarga. Frecuencia recomendada: Semanal','sistema','2026-01-31 02:44:19');
INSERT INTO `consultas` (`id`, `consulta_sistema`, `nombre`, `descripcion`, `editor_consultas`, `comentarios`, `usuario_creador`, `fecha_creacion`) VALUES (18,1,'AUT-REV-005: Revisores con conflictos de interés','Lista de revisores con conflictos permanentes registrados','SELECT \n    apellidos_nombre AS \'Revisor\',\n    email_principal AS \'Email\',\n    conflictos_permanentes AS \'Conflictos Registrados\',\n    areas_revision AS \'Áreas de Revisión\'\nFROM autores\nWHERE conflictos_permanentes IS NOT NULL\n    AND conflictos_permanentes != \'\'\n    AND estado_autor = \'activo\'\nORDER BY apellidos;\n','Evitar asignaciones problemáticas. Frecuencia recomendada: Mensual (auditoría)','sistema','2026-01-31 02:45:38');
INSERT INTO `consultas` (`id`, `consulta_sistema`, `nombre`, `descripcion`, `editor_consultas`, `comentarios`, `usuario_creador`, `fecha_creacion`) VALUES (19,1,'AUT-BIB-001: Top 20 autores por h-index','Ranking de autores con mayor impacto académico','SELECT \n    apellidos_nombre AS \'Autor\',\n    h_index AS \'h-index\',\n    i10_index AS \'i10-index\',\n    numero_publicaciones AS \'Publicaciones\',\n    numero_citas AS \'Citas\',\n    afiliacion_actual AS \'Institución\',\n    pais_afiliacion AS \'País\'\nFROM autores\nWHERE h_index IS NOT NULL\n    AND estado_autor = \'activo\'\nORDER BY h_index DESC, numero_citas DESC\nLIMIT 20;\n','Identificar autores líderes para invitaciones especiales. Frecuencia recomendada: Trimestral','sistema','2026-01-31 02:46:56');
INSERT INTO `consultas` (`id`, `consulta_sistema`, `nombre`, `descripcion`, `editor_consultas`, `comentarios`, `usuario_creador`, `fecha_creacion`) VALUES (20,1,'AUT-BIB-002: Distribución por rangos de h-index','Segmentación de autores por nivel de impacto académico','SELECT \n    CASE \n        WHEN h_index BETWEEN 0 AND 5 THEN \'0-5 (Emergentes)\'\n        WHEN h_index BETWEEN 6 AND 10 THEN \'6-10 (Intermedios)\'\n        WHEN h_index BETWEEN 11 AND 20 THEN \'11-20 (Consolidados)\'\n        WHEN h_index > 20 THEN \'21+ (Líderes)\'\n        ELSE \'Sin datos\'\n    END AS \'Rango h-index\',\n    COUNT(*) AS \'Cantidad de Autores\',\n    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM autores WHERE estado_autor = \'activo\'), 2) AS \'Porcentaje\'\nFROM autores\nWHERE estado_autor = \'activo\'\nGROUP BY \n    CASE \n        WHEN h_index BETWEEN 0 AND 5 THEN \'0-5 (Emergentes)\'\n        WHEN h_index BETWEEN 6 AND 10 THEN \'6-10 (Intermedios)\'\n        WHEN h_index BETWEEN 11 AND 20 THEN \'11-20 (Consolidados)\'\n        WHEN h_index > 20 THEN \'21+ (Líderes)\'\n        ELSE \'Sin datos\'\n    END\nORDER BY MIN(COALESCE(h_index, 999));\n','Análisis de perfil de la comunidad de autores. Frecuencia recomendada: Semestral','sistema','2026-01-31 02:48:12');
INSERT INTO `consultas` (`id`, `consulta_sistema`, `nombre`, `descripcion`, `editor_consultas`, `comentarios`, `usuario_creador`, `fecha_creacion`) VALUES (21,1,'AUT-BIB-003: Métricas desactualizadas (GOBERNANZA)','Autores con métricas que necesitan actualización (>6 meses)','SELECT \n    apellidos_nombre AS \'Autor\',\n    h_index AS \'h-index\',\n    fecha_actualizacion_metricas AS \'Última Actualización\',\n    DATEDIFF(CURDATE(), fecha_actualizacion_metricas) AS \'Días Desactualizado\',\n    email_principal AS \'Email\',\n    estado_autor AS \'Estado\'\nFROM autores\nWHERE fecha_actualizacion_metricas < DATE_SUB(CURDATE(), INTERVAL 6 MONTH)\n    AND estado_autor = \'activo\'\n    AND h_index IS NOT NULL\nORDER BY fecha_actualizacion_metricas ASC;\n','Mantenimiento de base de datos, control de calidad. Frecuencia recomendada: Mensual','sistema','2026-01-31 02:50:26');
INSERT INTO `consultas` (`id`, `consulta_sistema`, `nombre`, `descripcion`, `editor_consultas`, `comentarios`, `usuario_creador`, `fecha_creacion`) VALUES (22,1,'AUT-INST-001: Top 20 instituciones por cantidad de autores','Ranking de instituciones más representadas','SELECT \n    afiliacion_actual AS \'Institución\',\n    pais_afiliacion AS \'País\',\n    COUNT(*) AS \'Cantidad de Autores\',\n    COUNT(CASE WHEN ror_id IS NOT NULL AND ror_id != \'\' THEN 1 END) AS \'Con ROR ID\',\n    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM autores WHERE estado_autor = \'activo\'), 2) AS \'Porcentaje\'\nFROM autores\nWHERE estado_autor = \'activo\'\n    AND afiliacion_actual IS NOT NULL\nGROUP BY afiliacion_actual, pais_afiliacion\nORDER BY COUNT(*) DESC\nLIMIT 20;\n','Reportes institucionales, identificación de colaboradores estratégicos. Frecuencia recomendada: Trimestral','sistema','2026-01-31 02:51:41');
INSERT INTO `consultas` (`id`, `consulta_sistema`, `nombre`, `descripcion`, `editor_consultas`, `comentarios`, `usuario_creador`, `fecha_creacion`) VALUES (23,1,'AUT-INST-002: Distribución geográfica','Autores por país de afiliación','SELECT \n    pais_afiliacion AS \'País\',\n    COUNT(*) AS \'Autores\',\n    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM autores WHERE estado_autor = \'activo\'), 2) AS \'Porcentaje del Total\'\nFROM autores\nWHERE estado_autor = \'activo\'\n    AND pais_afiliacion IS NOT NULL\nGROUP BY pais_afiliacion\nORDER BY COUNT(*) DESC;\n','Análisis de alcance geográfico, reportes para indexadores. Frecuencia recomendada: Semestral','sistema','2026-01-31 02:52:42');
INSERT INTO `consultas` (`id`, `consulta_sistema`, `nombre`, `descripcion`, `editor_consultas`, `comentarios`, `usuario_creador`, `fecha_creacion`) VALUES (24,1,'AUT-INST-003: Instituciones sin ROR ID (GOBERNANZA)','Instituciones que necesitan estandarización con ROR','SELECT DISTINCT\n    afiliacion_actual AS \'Institución\',\n    pais_afiliacion AS \'País\',\n    COUNT(*) AS \'Autores Afectados\'\nFROM autores\nWHERE estado_autor = \'activo\'\n    AND afiliacion_actual IS NOT NULL\n    AND (ror_id IS NULL OR ror_id = \'\')\nGROUP BY afiliacion_actual, pais_afiliacion\nORDER BY COUNT(*) DESC;\n','Mejora de calidad de metadatos para indexadores (requisito SciELO/PubMed). Frecuencia recomendada: Mensual','sistema','2026-01-31 02:53:58');
INSERT INTO `consultas` (`id`, `consulta_sistema`, `nombre`, `descripcion`, `editor_consultas`, `comentarios`, `usuario_creador`, `fecha_creacion`) VALUES (25,1,'AUT-DISC-001: Distribución por área UNESCO','Cobertura disciplinaria según clasificación UNESCO (códigos de 2 dígitos)','SELECT \n    SUBSTRING(clasificacion_unesco, 1, 2) AS \'Código UNESCO\',\n    COUNT(*) AS \'Autores\',\n    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM autores WHERE clasificacion_unesco IS NOT NULL AND estado_autor = \'activo\'), 2) AS \'Porcentaje\',\n    GROUP_CONCAT(DISTINCT area_investigacion SEPARATOR \'; \') AS \'Áreas Relacionadas\'\nFROM autores\nWHERE clasificacion_unesco IS NOT NULL\n    AND estado_autor = \'activo\'\nGROUP BY SUBSTRING(clasificacion_unesco, 1, 2)\nORDER BY COUNT(*) DESC;\n','Reportes institucionales, evaluación de alcance temático. Frecuencia recomendada: Semestral','sistema','2026-01-31 02:55:04');
INSERT INTO `consultas` (`id`, `consulta_sistema`, `nombre`, `descripcion`, `editor_consultas`, `comentarios`, `usuario_creador`, `fecha_creacion`) VALUES (26,1,'AUT-DISC-002: Áreas de investigación más frecuentes','Top 15 áreas de investigación','SELECT \n    area_investigacion AS \'Área de Investigación\',\n    COUNT(*) AS \'Autores\',\n    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM autores WHERE estado_autor = \'activo\' AND area_investigacion IS NOT NULL), 2) AS \'Porcentaje\'\nFROM autores\nWHERE estado_autor = \'activo\'\n    AND area_investigacion IS NOT NULL\nGROUP BY area_investigacion\nORDER BY COUNT(*) DESC\nLIMIT 15;\n','Identificar fortalezas temáticas de la revista. Frecuencia recomendada: Trimestral','sistema','2026-01-31 02:56:05');
INSERT INTO `consultas` (`id`, `consulta_sistema`, `nombre`, `descripcion`, `editor_consultas`, `comentarios`, `usuario_creador`, `fecha_creacion`) VALUES (27,1,'AUT-DISC-003: Cobertura por clasificación OECD','Distribución según campos OECD','SELECT \n    clasificacion_oecd AS \'Campo OECD\',\n    COUNT(*) AS \'Autores\',\n    GROUP_CONCAT(DISTINCT pais_afiliacion SEPARATOR \', \') AS \'Países Representados\'\nFROM autores\nWHERE clasificacion_oecd IS NOT NULL\n    AND estado_autor = \'activo\'\nGROUP BY clasificacion_oecd\nORDER BY COUNT(*) DESC;\n','Reportes para agencias de financiamiento. Frecuencia recomendada: Anual','sistema','2026-01-31 02:58:42');
INSERT INTO `consultas` (`id`, `consulta_sistema`, `nombre`, `descripcion`, `editor_consultas`, `comentarios`, `usuario_creador`, `fecha_creacion`) VALUES (28,1,'AUT-ID-001: Autores sin ORCID (GOBERNANZA - CRÍTICO)','Lista de autores activos que necesitan ORCID','SELECT \n    apellidos_nombre AS \'Autor\',\n    email_principal AS \'Email\',\n    afiliacion_actual AS \'Institución\',\n    pais_afiliacion AS \'País\',\n    estado_autor AS \'Estado\'\nFROM autores\nWHERE (orcid IS NULL OR orcid = \'\')\n    AND estado_autor = \'activo\'\nORDER BY apellidos;\n','Cumplimiento de requisitos de indexadores (SciELO, PubMed, DOAJ). Frecuencia recomendada: Semanal','sistema','2026-01-31 02:59:43');
INSERT INTO `consultas` (`id`, `consulta_sistema`, `nombre`, `descripcion`, `editor_consultas`, `comentarios`, `usuario_creador`, `fecha_creacion`) VALUES (29,1,'AUT-ID-002: Cobertura de identificadores persistentes','Porcentaje de autores con cada tipo de ID','SELECT \n    \'ORCID\' AS \'Tipo de Identificador\',\n    COUNT(CASE WHEN orcid IS NOT NULL AND orcid != \'\' THEN 1 END) AS \'Con ID\',\n    COUNT(*) AS \'Total Autores\',\n    ROUND(COUNT(CASE WHEN orcid IS NOT NULL AND orcid != \'\' THEN 1 END) * 100.0 / COUNT(*), 2) AS \'Porcentaje\'\nFROM autores\nWHERE estado_autor = \'activo\'\n\nUNION ALL\n\nSELECT \n    \'Scopus ID\',\n    COUNT(CASE WHEN scopus_id IS NOT NULL AND scopus_id != \'\' THEN 1 END),\n    COUNT(*),\n    ROUND(COUNT(CASE WHEN scopus_id IS NOT NULL AND scopus_id != \'\' THEN 1 END) * 100.0 / COUNT(*), 2)\nFROM autores\nWHERE estado_autor = \'activo\'\n\nUNION ALL\n\nSELECT \n    \'Researcher ID\',\n    COUNT(CASE WHEN researcher_id IS NOT NULL AND researcher_id != \'\' THEN 1 END),\n    COUNT(*),\n    ROUND(COUNT(CASE WHEN researcher_id IS NOT NULL AND researcher_id != \'\' THEN 1 END) * 100.0 / COUNT(*), 2)\nFROM autores\nWHERE estado_autor = \'activo\'\n\nUNION ALL\n\nSELECT \n    \'Google Scholar\',\n    COUNT(CASE WHEN google_scholar_id IS NOT NULL AND google_scholar_id != \'\' THEN 1 END),\n    COUNT(*),\n    ROUND(COUNT(CASE WHEN google_scholar_id IS NOT NULL AND google_scholar_id != \'\' THEN 1 END) * 100.0 / COUNT(*), 2)\nFROM autores\nWHERE estado_autor = \'activo\';\n','Dashboard de calidad de metadatos. Frecuencia recomendada: Mensual','sistema','2026-01-31 03:01:00');
INSERT INTO `consultas` (`id`, `consulta_sistema`, `nombre`, `descripcion`, `editor_consultas`, `comentarios`, `usuario_creador`, `fecha_creacion`) VALUES (30,1,'AUT-CAL-001: Autores sin verificar (GOBERNANZA)','Registros pendientes de verificación','SELECT \n    apellidos_nombre AS \'Autor\',\n    fecha_creacion_registro AS \'Fecha de Creación\',\n    DATEDIFF(CURDATE(), fecha_creacion_registro) AS \'Días sin Verificar\',\n    fuente_registro AS \'Fuente\',\n    usuario_creacion AS \'Creado Por\',\n    email_principal AS \'Email\'\nFROM autores\nWHERE (verificado = 0 OR verificado IS NULL)\n    AND estado_autor = \'activo\'\nORDER BY fecha_creacion_registro DESC;\n','Control de calidad de la base de datos. Frecuencia recomendada: Semanal','sistema','2026-01-31 03:02:49');
INSERT INTO `consultas` (`id`, `consulta_sistema`, `nombre`, `descripcion`, `editor_consultas`, `comentarios`, `usuario_creador`, `fecha_creacion`) VALUES (31,1,'AUT-CAL-002: Registros desactualizados (GOBERNANZA)','Autores con datos no actualizados en más de 1 año','SELECT \n    apellidos_nombre AS \'Autor\',\n    email_principal AS \'Email\',\n    afiliacion_actual AS \'Institución\',\n    fecha_actualizacion_registro AS \'Última Actualización\',\n    DATEDIFF(CURDATE(), fecha_actualizacion_registro) AS \'Días sin Actualizar\',\n    estado_autor AS \'Estado\'\nFROM autores\nWHERE fecha_actualizacion_registro < DATE_SUB(CURDATE(), INTERVAL 1 YEAR)\n    AND estado_autor = \'activo\'\nORDER BY fecha_actualizacion_registro ASC;\n','Planificación de actualización de base de datos. Frecuencia recomendada: Trimestral','sistema','2026-01-31 03:04:10');
INSERT INTO `consultas` (`id`, `consulta_sistema`, `nombre`, `descripcion`, `editor_consultas`, `comentarios`, `usuario_creador`, `fecha_creacion`) VALUES (32,1,'AUT-CAL-003: Campos críticos incompletos (GOBERNANZA)','Autores con datos faltantes en campos esenciales','SELECT \n    apellidos_nombre AS \'Autor\',\n    CASE WHEN email_principal IS NULL OR email_principal = \'\' THEN \'SIN EMAIL\' ELSE \'\' END AS \'Email\',\n    CASE WHEN afiliacion_actual IS NULL OR afiliacion_actual = \'\' THEN \'SIN AFILIACIÓN\' ELSE \'\' END AS \'Afiliación\',\n    CASE WHEN pais_afiliacion IS NULL OR pais_afiliacion = \'\' THEN \'SIN PAÍS\' ELSE \'\' END AS \'País\',\n    CASE WHEN area_investigacion IS NULL OR area_investigacion = \'\' THEN \'SIN ÁREA\' ELSE \'\' END AS \'Área\',\n    CASE WHEN orcid IS NULL OR orcid = \'\' THEN \'SIN ORCID\' ELSE \'\' END AS \'ORCID\',\n    estado_autor AS \'Estado\'\nFROM autores\nWHERE estado_autor = \'activo\'\n    AND (\n        email_principal IS NULL OR email_principal = \'\'\n        OR afiliacion_actual IS NULL OR afiliacion_actual = \'\'\n        OR pais_afiliacion IS NULL OR pais_afiliacion = \'\'\n        OR area_investigacion IS NULL OR area_investigacion = \'\'\n        OR orcid IS NULL OR orcid = \'\'\n    )\nORDER BY apellidos;\n','Identificar registros que necesitan completarse. Frecuencia recomendada: Mensual','sistema','2026-01-31 03:06:44');
INSERT INTO `consultas` (`id`, `consulta_sistema`, `nombre`, `descripcion`, `editor_consultas`, `comentarios`, `usuario_creador`, `fecha_creacion`) VALUES (33,1,'AUT-EST-001: Distribución por estado (GOBERNANZA)','Resumen de autores por estado','SELECT \n    estado_autor AS \'Estado\',\n    COUNT(*) AS \'Cantidad\',\n    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM autores), 2) AS \'Porcentaje\'\nFROM autores\nGROUP BY estado_autor\nORDER BY COUNT(*) DESC;\n','Dashboard general de la base de datos. Frecuencia recomendada: Mensual','sistema','2026-01-31 03:07:42');
INSERT INTO `consultas` (`id`, `consulta_sistema`, `nombre`, `descripcion`, `editor_consultas`, `comentarios`, `usuario_creador`, `fecha_creacion`) VALUES (34,1,'AUT-EST-002: Autores inactivos recientes (GOBERNANZA)','Autores marcados como inactivos en los últimos 6 meses','SELECT \n    apellidos_nombre AS \'Autor\',\n    fecha_inactividad AS \'Fecha Inactividad\',\n    DATEDIFF(CURDATE(), fecha_inactividad) AS \'Días Inactivo\',\n    afiliacion_actual AS \'Última Institución Conocida\',\n    email_principal AS \'Email\'\nFROM autores\nWHERE estado_autor = \'inactivo\'\n    AND fecha_inactividad >= DATE_SUB(CURDATE(), INTERVAL 6 MONTH)\nORDER BY fecha_inactividad DESC;\n','Seguimiento de rotación, auditoría de cambios de estado. Frecuencia recomendada: Mensual','sistema','2026-01-31 03:08:46');
INSERT INTO `consultas` (`id`, `consulta_sistema`, `nombre`, `descripcion`, `editor_consultas`, `comentarios`, `usuario_creador`, `fecha_creacion`) VALUES (35,1,'AUT-ROL-001: Autores con roles duales (GOBERNANZA)','Identificar posibles conflictos de interés (autor + editor)','SELECT \n    apellidos_nombre AS \'Nombre\',\n    tipo_autor AS \'Tipo de Autor\',\n    editor_revista AS \'Editor en Revistas\',\n    comite_editorial AS \'Comités Editoriales\',\n    afiliacion_actual AS \'Institución\'\nFROM autores\nWHERE estado_autor = \'activo\'\n    AND (\n        (editor_revista IS NOT NULL AND editor_revista != \'\')\n        OR (comite_editorial IS NOT NULL AND comite_editorial != \'\')\n    )\nORDER BY apellidos;\n','Transparencia editorial, control de conflictos. Frecuencia recomendada: Por cada número','sistema','2026-01-31 03:09:48');
INSERT INTO `consultas` (`id`, `consulta_sistema`, `nombre`, `descripcion`, `editor_consultas`, `comentarios`, `usuario_creador`, `fecha_creacion`) VALUES (36,1,'AUT-ROL-002: Distribución de tipos de autor','Clasificación de autores por tipo','SELECT \n    tipo_autor AS \'Tipo de Autor\',\n    COUNT(*) AS \'Cantidad\',\n    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM autores WHERE estado_autor = \'activo\'), 2) AS \'Porcentaje\'\nFROM autores\nWHERE estado_autor = \'activo\'\n    AND tipo_autor IS NOT NULL\nGROUP BY tipo_autor\nORDER BY COUNT(*) DESC;\n','Análisis de composición de la comunidad. Frecuencia recomendada: Trimestral','sistema','2026-01-31 03:10:39');
INSERT INTO `consultas` (`id`, `consulta_sistema`, `nombre`, `descripcion`, `editor_consultas`, `comentarios`, `usuario_creador`, `fecha_creacion`) VALUES (37,1,'AUT-FORM-001: Distribución de grados máximos','Autores por nivel de formación','SELECT \n    grado_maximo AS \'Grado Máximo\',\n    COUNT(*) AS \'Cantidad\',\n    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM autores WHERE estado_autor = \'activo\'), 2) AS \'Porcentaje\'\nFROM autores\nWHERE estado_autor = \'activo\'\n    AND grado_maximo IS NOT NULL\nGROUP BY grado_maximo\nORDER BY COUNT(*) DESC;\n','Perfil académico de la comunidad. Frecuencia recomendada: Anual','sistema','2026-01-31 03:11:36');
INSERT INTO `consultas` (`id`, `consulta_sistema`, `nombre`, `descripcion`, `editor_consultas`, `comentarios`, `usuario_creador`, `fecha_creacion`) VALUES (38,1,'AUT-FORM-002: Top universidades de formación doctoral','Instituciones donde se doctoraron los autores','SELECT \n    universidad_doctorado AS \'Universidad\',\n    COUNT(*) AS \'Doctores\',\n    MIN(ano_doctorado) AS \'Año Más Antiguo\',\n    MAX(ano_doctorado) AS \'Año Más Reciente\'\nFROM autores\nWHERE universidad_doctorado IS NOT NULL\n    AND estado_autor = \'activo\'\nGROUP BY universidad_doctorado\nORDER BY COUNT(*) DESC\nLIMIT 15;\n','Redes académicas y prestigio. Frecuencia recomendada: Anual','sistema','2026-01-31 03:13:09');
INSERT INTO `consultas` (`id`, `consulta_sistema`, `nombre`, `descripcion`, `editor_consultas`, `comentarios`, `usuario_creador`, `fecha_creacion`) VALUES (39,1,'ART-WF-001: Estado actual del pipeline editorial','Distribución de artículos por estado','SELECT \n    estado_articulo AS \'Estado\',\n    COUNT(*) AS \'Cantidad\',\n    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM articulos), 2) AS \'Porcentaje\',\n    ROUND(AVG(DATEDIFF(CURDATE(), fecha_creacion_registro)), 0) AS \'Días Promedio en Estado\'\nFROM articulos\nGROUP BY estado_articulo\nORDER BY \n    CASE estado_articulo\n        WHEN \'borrador\' THEN 1\n        WHEN \'en_revision\' THEN 2\n        WHEN \'aceptado\' THEN 3\n        WHEN \'publicado\' THEN 4\n        WHEN \'rechazado\' THEN 5\n        WHEN \'retractado\' THEN 6\n        ELSE 99\n    END;\n','Dashboard ejecutivo, detección de cuellos de botella. Frecuencia recomendada: Diaria','sistema','2026-01-31 03:14:20');
INSERT INTO `consultas` (`id`, `consulta_sistema`, `nombre`, `descripcion`, `editor_consultas`, `comentarios`, `usuario_creador`, `fecha_creacion`) VALUES (40,1,'ART-WF-002: Artículos estancados en revisión (GOBERNANZA - CRÍTICO)','Manuscritos en revisión por más de 60 días','SELECT \n    a.id_articulo AS \'ID\',\n    a.titulo_articulo AS \'Título\',\n    a.fecha_recepcion AS \'Fecha Recepción\',\n    DATEDIFF(CURDATE(), a.fecha_recepcion) AS \'Días en Revisión\',\n    a.responsable_edicion AS \'Editor Responsable\',\n    COUNT(ar.id_revision) AS \'Revisores Asignados\',\n    SUM(CASE WHEN ar.decision IS NOT NULL THEN 1 ELSE 0 END) AS \'Revisiones Completadas\'\nFROM articulos a\nLEFT JOIN articulo_revisor ar ON a.id_articulo = ar.id_articulo\nWHERE a.estado_articulo = \'en_revision\'\n    AND a.fecha_recepcion < DATE_SUB(CURDATE(), INTERVAL 60 DAY)\nGROUP BY a.id_articulo\nORDER BY DATEDIFF(CURDATE(), a.fecha_recepcion) DESC;\n','Identificar retrasos, intervención editorial urgente. Frecuencia recomendada: Semanal','sistema','2026-01-31 03:19:48');
INSERT INTO `consultas` (`id`, `consulta_sistema`, `nombre`, `descripcion`, `editor_consultas`, `comentarios`, `usuario_creador`, `fecha_creacion`) VALUES (41,1,'ART-WF-003: Borradores sin actividad reciente (GOBERNANZA)','Artículos en borrador sin actualización en 30 días','SELECT \n    id_articulo AS \'ID\',\n    titulo_articulo AS \'Título\',\n    responsable_edicion AS \'Responsable\',\n    fecha_creacion_registro AS \'Fecha Creación\',\n    fecha_actualizacion_registro AS \'Última Actualización\',\n    DATEDIFF(CURDATE(), fecha_actualizacion_registro) AS \'Días sin Actividad\'\nFROM articulos\nWHERE estado_articulo = \'borrador\'\n    AND fecha_actualizacion_registro < DATE_SUB(CURDATE(), INTERVAL 30 DAY)\nORDER BY fecha_actualizacion_registro ASC;\n','Limpieza de base de datos, seguimiento con responsables. Frecuencia recomendada: Mensual','sistema','2026-01-31 03:21:05');
INSERT INTO `consultas` (`id`, `consulta_sistema`, `nombre`, `descripcion`, `editor_consultas`, `comentarios`, `usuario_creador`, `fecha_creacion`) VALUES (42,1,'ART-WF-004: Artículos aceptados pendientes de publicación (GOBERNANZA)','Manuscritos aceptados que aún no se publican','SELECT \n    id_articulo AS \'ID\',\n    titulo_articulo AS \'Título\',\n    fecha_aceptacion AS \'Fecha Aceptación\',\n    DATEDIFF(CURDATE(), fecha_aceptacion) AS \'Días desde Aceptación\',\n    tipo_articulo AS \'Tipo\',\n    responsable_edicion AS \'Editor Responsable\',\n    notas_internas AS \'Notas\'\nFROM articulos\nWHERE estado_articulo = \'aceptado\'\n    AND fecha_publicacion_online IS NULL\nORDER BY fecha_aceptacion ASC;\n','Planificación de números, control de backlog. Frecuencia recomendada: Semanal','sistema','2026-01-31 03:22:04');
INSERT INTO `consultas` (`id`, `consulta_sistema`, `nombre`, `descripcion`, `editor_consultas`, `comentarios`, `usuario_creador`, `fecha_creacion`) VALUES (43,1,'ART-WF-005: Trazabilidad de cambios de estado (AUDITORÍA)','Artículos con cambios de estado en el último mes','SELECT \n    id_articulo AS \'ID\',\n    titulo_articulo AS \'Título\',\n    estado_articulo AS \'Estado Actual\',\n    fecha_actualizacion_registro AS \'Fecha Cambio\',\n    responsable_edicion AS \'Responsable\',\n    usuario_creacion AS \'Usuario que Modificó\'\nFROM articulos\nWHERE fecha_actualizacion_registro >= DATE_SUB(CURDATE(), INTERVAL 1 MONTH)\nORDER BY fecha_actualizacion_registro DESC;\n','Auditoría de workflow, registro de decisiones editoriales. Frecuencia recomendada: Mensual','sistema','2026-01-31 03:24:01');
INSERT INTO `consultas` (`id`, `consulta_sistema`, `nombre`, `descripcion`, `editor_consultas`, `comentarios`, `usuario_creador`, `fecha_creacion`) VALUES (44,1,'ART-CAL-001: Artículos sin DOI asignado (CRÍTICO)','Artículos publicados sin DOI','SELECT \n    id_articulo AS \'ID\',\n    titulo_articulo AS \'Título\',\n    estado_articulo AS \'Estado\',\n    fecha_publicacion_online AS \'Fecha Publicación\',\n    responsable_edicion AS \'Editor Responsable\'\nFROM articulos\nWHERE estado_articulo IN (\'aceptado\', \'publicado\')\n    AND (doi IS NULL OR doi = \'\')\nORDER BY fecha_publicacion_online DESC;\n','Cumplimiento de estándares de identificación persistente. Frecuencia recomendada: Semanal','sistema','2026-01-31 03:25:31');
INSERT INTO `consultas` (`id`, `consulta_sistema`, `nombre`, `descripcion`, `editor_consultas`, `comentarios`, `usuario_creador`, `fecha_creacion`) VALUES (45,1,'ART-CAL-002: Validación JATS pendiente (GOBERNANZA)','Artículos sin validación JATS completa','SELECT \n    id_articulo AS \'ID\',\n    titulo_articulo AS \'Título\',\n    estado_articulo AS \'Estado\',\n    validado_jats AS \'Validado JATS\',\n    errores_validacion AS \'Errores\',\n    responsable_edicion AS \'Responsable\'\nFROM articulos\nWHERE estado_articulo IN (\'aceptado\', \'publicado\')\n    AND (validado_jats = 0 OR validado_jats IS NULL)\nORDER BY fecha_aceptacion DESC;\n','Control de calidad técnica para indexadores. Frecuencia recomendada: Por cada número','sistema','2026-01-31 03:26:32');
INSERT INTO `consultas` (`id`, `consulta_sistema`, `nombre`, `descripcion`, `editor_consultas`, `comentarios`, `usuario_creador`, `fecha_creacion`) VALUES (46,1,'ART-CAL-003: Completitud de metadatos (GOBERNANZA)','Artículos con baja completitud de metadatos (<80%)','SELECT \n    id_articulo AS \'ID\',\n    titulo_articulo AS \'Título\',\n    estado_articulo AS \'Estado\',\n    completitud_metadatos AS \'Completitud (%)\',\n    calidad_metadatos AS \'Calidad Score\',\n    responsable_edicion AS \'Responsable\'\nFROM articulos\nWHERE completitud_metadatos < 80\n    AND estado_articulo != \'rechazado\'\nORDER BY completitud_metadatos ASC;\n','Mejora de calidad antes de publicación. Frecuencia recomendada: Por cada número','sistema','2026-01-31 03:29:29');
INSERT INTO `consultas` (`id`, `consulta_sistema`, `nombre`, `descripcion`, `editor_consultas`, `comentarios`, `usuario_creador`, `fecha_creacion`) VALUES (47,1,'ART-CAL-004: Artículos sin autor de correspondencia (CRÍTICO)','Manuscritos sin autor de correspondencia asignado','SELECT \n    a.id_articulo AS \'ID\',\n    a.titulo_articulo AS \'Título\',\n    a.estado_articulo AS \'Estado\',\n    a.responsable_edicion AS \'Editor Responsable\',\n    COUNT(aa.id_autor) AS \'Total Autores\'\nFROM articulos a\nLEFT JOIN articulo_autor aa ON a.id_articulo = aa.id_articulo\nWHERE a.autor_correspondencia IS NULL\n    AND a.estado_articulo IN (\'en_revision\', \'aceptado\', \'publicado\')\nGROUP BY a.id_articulo\nORDER BY a.fecha_aceptacion DESC;\n','Requisito obligatorio para publicación. Frecuencia recomendada: Semanal','sistema','2026-01-31 03:30:44');
INSERT INTO `consultas` (`id`, `consulta_sistema`, `nombre`, `descripcion`, `editor_consultas`, `comentarios`, `usuario_creador`, `fecha_creacion`) VALUES (48,1,'ART-CAL-005: Errores de validación XML (GOBERNANZA)','Artículos con errores de validación XML/JATS','SELECT \n    id_articulo AS \'ID\',\n    titulo_articulo AS \'Título\',\n    errores_validacion AS \'Errores Detectados\',\n    validado_jats AS \'Validado\',\n    responsable_edicion AS \'Responsable\'\nFROM articulos\nWHERE errores_validacion IS NOT NULL\n    AND errores_validacion != \'\'\n    AND estado_articulo != \'rechazado\'\nORDER BY fecha_actualizacion_registro DESC;\n','Corrección técnica antes de envío a indexadores. Frecuencia recomendada: Por cada número','sistema','2026-01-31 03:31:52');
INSERT INTO `consultas` (`id`, `consulta_sistema`, `nombre`, `descripcion`, `editor_consultas`, `comentarios`, `usuario_creador`, `fecha_creacion`) VALUES (49,1,'ART-STD-001: Cumplimiento de guías de reporte','Artículos por tipo de guía cumplida (ARRIVE, CONSORT, etc.)','SELECT \n    \'ARRIVE (Animales)\' AS \'Guía\',\n    SUM(cumple_arrive) AS \'Artículos Cumplen\',\n    COUNT(*) AS \'Total Aplicable\',\n    ROUND(SUM(cumple_arrive) * 100.0 / COUNT(*), 2) AS \'Porcentaje\'\nFROM articulos\nWHERE tipo_sujetos_investigacion IN (\'animales\', \'humanos_y_animales\')\n    AND estado_articulo = \'publicado\'\n\nUNION ALL\n\nSELECT \n    \'CONSORT (Ensayos Clínicos)\',\n    SUM(cumple_consort),\n    COUNT(*),\n    ROUND(SUM(cumple_consort) * 100.0 / COUNT(*), 2)\nFROM articulos\nWHERE tipo_sujetos_investigacion IN (\'humanos\', \'humanos_y_animales\')\n    AND estado_articulo = \'publicado\'\n\nUNION ALL\n\nSELECT \n    \'STROBE (Observacionales)\',\n    SUM(cumple_strobe),\n    COUNT(*),\n    ROUND(SUM(cumple_strobe) * 100.0 / COUNT(*), 2)\nFROM articulos\nWHERE tipo_sujetos_investigacion = \'humanos\'\n    AND estado_articulo = \'publicado\'\n\nUNION ALL\n\nSELECT \n    \'PRISMA (Revisiones)\',\n    SUM(cumple_prisma),\n    COUNT(*),\n    ROUND(SUM(cumple_prisma) * 100.0 / COUNT(*), 2)\nFROM articulos\nWHERE tipo_articulo LIKE \'%revision%\'\n    AND estado_articulo = \'publicado\';\n','Dashboard de transparencia metodológica. Frecuencia recomendada: Trimestral','sistema','2026-01-31 03:33:00');
INSERT INTO `consultas` (`id`, `consulta_sistema`, `nombre`, `descripcion`, `editor_consultas`, `comentarios`, `usuario_creador`, `fecha_creacion`) VALUES (50,1,'ART-STD-002: Artículos con sujetos humanos sin aprobación ética (CRÍTICO)','Estudios con humanos sin aprobación de comité ético','SELECT \n    id_articulo AS \'ID\',\n    titulo_articulo AS \'Título\',\n    tipo_sujetos_investigacion AS \'Tipo Sujetos\',\n    aprobacion_comite_etica AS \'Tiene Aprobación\',\n    numero_aprobacion_etica AS \'Número Aprobación\',\n    consentimiento_informado AS \'Consentimiento\',\n    responsable_edicion AS \'Editor Responsable\'\nFROM articulos\nWHERE tipo_sujetos_investigacion IN (\'humanos\', \'humanos_y_animales\')\n    AND (aprobacion_comite_etica = 0 OR aprobacion_comite_etica IS NULL)\n    AND estado_articulo IN (\'en_revision\', \'aceptado\', \'publicado\')\nORDER BY fecha_recepcion DESC;\n','Control de cumplimiento ético obligatorio. Frecuencia recomendada: Semanal','sistema','2026-01-31 03:33:58');
INSERT INTO `consultas` (`id`, `consulta_sistema`, `nombre`, `descripcion`, `editor_consultas`, `comentarios`, `usuario_creador`, `fecha_creacion`) VALUES (51,1,'ART-STD-003: Artículos con animales sin aprobación CICUAL (CRÍTICO)','Estudios con animales sin aprobación de comité de ética animal','SELECT \n    id_articulo AS \'ID\',\n    titulo_articulo AS \'Título\',\n    estudios_animales_especies AS \'Especies\',\n    numero_animales AS \'N Animales\',\n    aprobacion_comite_animal AS \'Tiene Aprobación\',\n    numero_aprobacion_animal AS \'Número Aprobación\',\n    protocolo_bienestar_animal AS \'Protocolo\',\n    responsable_edicion AS \'Editor Responsable\'\nFROM articulos\nWHERE tipo_sujetos_investigacion IN (\'animales\', \'humanos_y_animales\')\n    AND (aprobacion_comite_animal = 0 OR aprobacion_comite_animal IS NULL)\n    AND estado_articulo IN (\'en_revision\', \'aceptado\', \'publicado\')\nORDER BY fecha_recepcion DESC;\n','Control de cumplimiento normativo obligatorio. Frecuencia recomendada: Semanal','sistema','2026-01-31 03:34:59');
INSERT INTO `consultas` (`id`, `consulta_sistema`, `nombre`, `descripcion`, `editor_consultas`, `comentarios`, `usuario_creador`, `fecha_creacion`) VALUES (52,1,'ART-STD-004: Ensayos clínicos sin registro (CRÍTICO)','Artículos de ensayos clínicos sin número de registro','SELECT \n    id_articulo AS \'ID\',\n    titulo_articulo AS \'Título\',\n    estudios_humanos_tipo AS \'Tipo Estudio\',\n    registro_ensayo_clinico AS \'Registro\',\n    aprobacion_comite_etica AS \'Aprobación Ética\',\n    responsable_edicion AS \'Editor Responsable\'\nFROM articulos\nWHERE estudios_humanos_tipo LIKE \'%ensayo%\'\n    AND (registro_ensayo_clinico IS NULL OR registro_ensayo_clinico = \'\')\n    AND estado_articulo IN (\'en_revision\', \'aceptado\', \'publicado\')\nORDER BY fecha_recepcion DESC;\n','Requisito obligatorio (Declaración de Helsinki). Frecuencia recomendada: Semanal','sistema','2026-01-31 03:35:53');
INSERT INTO `consultas` (`id`, `consulta_sistema`, `nombre`, `descripcion`, `editor_consultas`, `comentarios`, `usuario_creador`, `fecha_creacion`) VALUES (53,1,'ART-PROD-001: Artículos por tipo','Distribución de artículos por tipo de publicación','SELECT \n    tipo_articulo AS \'Tipo de Artículo\',\n    COUNT(*) AS \'Cantidad\',\n    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM articulos WHERE estado_articulo = \'publicado\'), 2) AS \'Porcentaje\'\nFROM articulos\nWHERE estado_articulo = \'publicado\'\n    AND tipo_articulo IS NOT NULL\nGROUP BY tipo_articulo\nORDER BY COUNT(*) DESC;\n','Análisis de composición editorial. Frecuencia recomendada: Trimestral','sistema','2026-01-31 03:36:50');
INSERT INTO `consultas` (`id`, `consulta_sistema`, `nombre`, `descripcion`, `editor_consultas`, `comentarios`, `usuario_creador`, `fecha_creacion`) VALUES (54,1,'ART-PROD-002: Productividad por editor responsable (GOBERNANZA)','Cantidad de artículos gestionados por cada editor','SELECT \n    responsable_edicion AS \'Editor\',\n    COUNT(*) AS \'Total Artículos\',\n    SUM(CASE WHEN estado_articulo = \'publicado\' THEN 1 ELSE 0 END) AS \'Publicados\',\n    SUM(CASE WHEN estado_articulo = \'en_revision\' THEN 1 ELSE 0 END) AS \'En Revisión\',\n    SUM(CASE WHEN estado_articulo = \'aceptado\' THEN 1 ELSE 0 END) AS \'Aceptados\',\n    SUM(CASE WHEN estado_articulo = \'rechazado\' THEN 1 ELSE 0 END) AS \'Rechazados\',\n    ROUND(AVG(DATEDIFF(fecha_aceptacion, fecha_recepcion)), 0) AS \'Días Prom. Decisión\'\nFROM articulos\nWHERE responsable_edicion IS NOT NULL\nGROUP BY responsable_edicion\nORDER BY COUNT(*) DESC;\n','Balance de carga editorial, evaluación de desempeño. Frecuencia recomendada: Trimestral','sistema','2026-01-31 03:39:40');
INSERT INTO `consultas` (`id`, `consulta_sistema`, `nombre`, `descripcion`, `editor_consultas`, `comentarios`, `usuario_creador`, `fecha_creacion`) VALUES (55,1,'ART-PROD-003: Artículos publicados por año','Evolución temporal de la producción editorial','SELECT \n    ano_publicacion AS \'Año\',\n    COUNT(*) AS \'Artículos Publicados\',\n    AVG(numero_paginas) AS \'Páginas Promedio\',\n    SUM(numero_referencias) AS \'Referencias Totales\'\nFROM articulos\nWHERE estado_articulo = \'publicado\'\n    AND ano_publicacion IS NOT NULL\nGROUP BY ano_publicacion\nORDER BY ano_publicacion DESC;\n','Análisis de tendencias. Frecuencia recomendada: Anual','sistema','2026-01-31 03:40:55');
INSERT INTO `consultas` (`id`, `consulta_sistema`, `nombre`, `descripcion`, `editor_consultas`, `comentarios`, `usuario_creador`, `fecha_creacion`) VALUES (56,1,'ART-PROD-004: Tasa de aceptación (GOBERNANZA)','Proporción de artículos aceptados vs rechazados','SELECT \n    YEAR(fecha_recepcion) AS \'Año\',\n    COUNT(*) AS \'Total Manuscritos\',\n    SUM(CASE WHEN estado_articulo = \'publicado\' THEN 1 ELSE 0 END) AS \'Publicados\',\n    SUM(CASE WHEN estado_articulo = \'rechazado\' THEN 1 ELSE 0 END) AS \'Rechazados\',\n    ROUND(SUM(CASE WHEN estado_articulo = \'publicado\' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS \'Tasa Aceptación (%)\'\nFROM articulos\nWHERE estado_articulo IN (\'publicado\', \'rechazado\')\n    AND fecha_recepcion IS NOT NULL\nGROUP BY YEAR(fecha_recepcion)\nORDER BY YEAR(fecha_recepcion) DESC;\n','Indicador de selectividad editorial. Frecuencia recomendada: Semestral','sistema','2026-01-31 03:41:57');
INSERT INTO `consultas` (`id`, `consulta_sistema`, `nombre`, `descripcion`, `editor_consultas`, `comentarios`, `usuario_creador`, `fecha_creacion`) VALUES (57,1,'ART-MET-001: Artículos más vistos/descargados','Top 20 artículos por visualizaciones y descargas','SELECT \n    id_articulo AS \'ID\',\n    titulo_articulo AS \'Título\',\n    visualizaciones AS \'Vistas\',\n    descargas AS \'Descargas\',\n    (visualizaciones + descargas) AS \'Total Interacciones\',\n    fecha_publicacion_online AS \'Fecha Publicación\'\nFROM articulos\nWHERE estado_articulo = \'publicado\'\n    AND (visualizaciones > 0 OR descargas > 0)\nORDER BY (visualizaciones + descargas) DESC\nLIMIT 20;\n','Identificar contenido de alto impacto. Frecuencia recomendada: Mensual','sistema','2026-01-31 03:43:02');
INSERT INTO `consultas` (`id`, `consulta_sistema`, `nombre`, `descripcion`, `editor_consultas`, `comentarios`, `usuario_creador`, `fecha_creacion`) VALUES (58,1,'ART-MET-002: Artículos con mayor impacto altmétrico','Artículos ordenados por Altmetric Score','SELECT \n    id_articulo AS \'ID\',\n    titulo_articulo AS \'Título\',\n    altmetric_score AS \'Altmetric Score\',\n    menciones_redes AS \'Menciones en Redes\',\n    fecha_publicacion_online AS \'Fecha Publicación\',\n    doi AS \'DOI\'\nFROM articulos\nWHERE estado_articulo = \'publicado\'\n    AND altmetric_score IS NOT NULL\nORDER BY altmetric_score DESC\nLIMIT 20;\n','Análisis de impacto en redes sociales y medios. Frecuencia recomendada: Trimestral','sistema','2026-01-31 03:43:56');
INSERT INTO `consultas` (`id`, `consulta_sistema`, `nombre`, `descripcion`, `editor_consultas`, `comentarios`, `usuario_creador`, `fecha_creacion`) VALUES (59,1,'ART-MET-003: Distribución de citas por base de datos','Cobertura de citas en Scopus, WoS y Google Scholar','SELECT \n    \'Scopus\' AS \'Base de Datos\',\n    COUNT(CASE WHEN citas_scopus > 0 THEN 1 END) AS \'Artículos Citados\',\n    SUM(citas_scopus) AS \'Total Citas\',\n    ROUND(AVG(citas_scopus), 2) AS \'Promedio Citas\'\nFROM articulos\nWHERE estado_articulo = \'publicado\'\n\nUNION ALL\n\nSELECT \n    \'Web of Science\',\n    COUNT(CASE WHEN citas_wos > 0 THEN 1 END),\n    SUM(citas_wos),\n    ROUND(AVG(citas_wos), 2)\nFROM articulos\nWHERE estado_articulo = \'publicado\'\n\nUNION ALL\n\nSELECT \n    \'Google Scholar\',\n    COUNT(CASE WHEN citas_google_scholar > 0 THEN 1 END),\n    SUM(citas_google_scholar),\n    ROUND(AVG(citas_google_scholar), 2)\nFROM articulos\nWHERE estado_articulo = \'publicado\';\n','Análisis de indexación y visibilidad. Frecuencia recomendada: Semestral','sistema','2026-01-31 03:44:55');
INSERT INTO `consultas` (`id`, `consulta_sistema`, `nombre`, `descripcion`, `editor_consultas`, `comentarios`, `usuario_creador`, `fecha_creacion`) VALUES (60,1,'ART-REV-001: Revisiones pendientes por revisor (CRÍTICO)','Revisiones asignadas sin completar','SELECT \n    aut.apellidos_nombre AS \'Revisor\',\n    aut.email_principal AS \'Email\',\n    art.id_articulo AS \'ID Artículo\',\n    art.titulo_articulo AS \'Título\',\n    ar.fecha_asignacion AS \'Fecha Asignación\',\n    DATEDIFF(CURDATE(), ar.fecha_asignacion) AS \'Días Asignado\',\n    ar.tipo_revision AS \'Tipo Revisión\',\n    ar.ronda_revision AS \'Ronda\'\nFROM articulo_revisor ar\nJOIN autores aut ON ar.id_autor = aut.id_autor\nJOIN articulos art ON ar.id_articulo = art.id_articulo\nWHERE ar.decision IS NULL\n    AND art.estado_articulo = \'en_revision\'\nORDER BY DATEDIFF(CURDATE(), ar.fecha_asignacion) DESC;\n','Seguimiento a revisores, detección de retrasos. Frecuencia recomendada: Semanal','sistema','2026-01-31 03:45:56');
INSERT INTO `consultas` (`id`, `consulta_sistema`, `nombre`, `descripcion`, `editor_consultas`, `comentarios`, `usuario_creador`, `fecha_creacion`) VALUES (61,1,'ART-REV-002: Tiempo promedio de revisión por revisor (GOBERNANZA)','Performance de revisores (días promedio para completar)','SELECT \n    aut.apellidos_nombre AS \'Revisor\',\n    COUNT(ar.id_revision) AS \'Revisiones Completadas\',\n    ROUND(AVG(DATEDIFF(ar.fecha_revision, ar.fecha_asignacion)), 0) AS \'Días Promedio\',\n    MIN(DATEDIFF(ar.fecha_revision, ar.fecha_asignacion)) AS \'Más Rápida\',\n    MAX(DATEDIFF(ar.fecha_revision, ar.fecha_asignacion)) AS \'Más Lenta\'\nFROM articulo_revisor ar\nJOIN autores aut ON ar.id_autor = aut.id_autor\nWHERE ar.decision IS NOT NULL\n    AND ar.fecha_revision IS NOT NULL\nGROUP BY ar.id_autor\nHAVING COUNT(ar.id_revision) >= 3\nORDER BY AVG(DATEDIFF(ar.fecha_revision, ar.fecha_asignacion)) ASC;\n','Evaluación de revisores, asignación futura. Frecuencia recomendada: Trimestral','sistema','2026-01-31 03:46:52');
INSERT INTO `consultas` (`id`, `consulta_sistema`, `nombre`, `descripcion`, `editor_consultas`, `comentarios`, `usuario_creador`, `fecha_creacion`) VALUES (62,1,'ART-REV-003: Distribución de decisiones de revisores','Tipos de decisión por revisor (aceptar, rechazar, cambios)','SELECT \n    aut.apellidos_nombre AS \'Revisor\',\n    COUNT(*) AS \'Total Revisiones\',\n    SUM(CASE WHEN ar.decision = \'aceptar\' THEN 1 ELSE 0 END) AS \'Aceptar\',\n    SUM(CASE WHEN ar.decision = \'rechazar\' THEN 1 ELSE 0 END) AS \'Rechazar\',\n    SUM(CASE WHEN ar.decision = \'cambios_mayores\' THEN 1 ELSE 0 END) AS \'Cambios Mayores\',\n    SUM(CASE WHEN ar.decision = \'cambios_menores\' THEN 1 ELSE 0 END) AS \'Cambios Menores\',\n    ROUND(SUM(CASE WHEN ar.decision = \'aceptar\' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS \'% Aceptación\'\nFROM articulo_revisor ar\nJOIN autores aut ON ar.id_autor = aut.id_autor\nWHERE ar.decision IS NOT NULL\nGROUP BY ar.id_autor\nHAVING COUNT(*) >= 5\nORDER BY COUNT(*) DESC;\n','Análisis de criterio editorial. Frecuencia recomendada: Semestral','sistema','2026-01-31 03:48:16');
INSERT INTO `consultas` (`id`, `consulta_sistema`, `nombre`, `descripcion`, `editor_consultas`, `comentarios`, `usuario_creador`, `fecha_creacion`) VALUES (63,1,'ART-REV-004: Artículos con múltiples rondas de revisión (GOBERNANZA)','Manuscritos con más de 2 rondas de revisión','SELECT \n    a.id_articulo AS \'ID\',\n    a.titulo_articulo AS \'Título\',\n    MAX(ar.ronda_revision) AS \'Rondas Totales\',\n    a.fecha_recepcion AS \'Fecha Recepción\',\n    DATEDIFF(CURDATE(), a.fecha_recepcion) AS \'Días en Proceso\',\n    a.responsable_edicion AS \'Editor Responsable\'\nFROM articulos a\nJOIN articulo_revisor ar ON a.id_articulo = ar.id_articulo\nWHERE a.estado_articulo = \'en_revision\'\nGROUP BY a.id_articulo\nHAVING MAX(ar.ronda_revision) > 2\nORDER BY MAX(ar.ronda_revision) DESC;\n','Identificar casos problemáticos. Frecuencia recomendada: Mensual','sistema','2026-01-31 03:49:13');
INSERT INTO `consultas` (`id`, `consulta_sistema`, `nombre`, `descripcion`, `editor_consultas`, `comentarios`, `usuario_creador`, `fecha_creacion`) VALUES (64,1,'ART-TIME-001: Tiempo promedio de decisión editorial','Días promedio entre recepción y aceptación/rechazo','SELECT \n    estado_articulo AS \'Decisión\',\n    COUNT(*) AS \'Cantidad\',\n    ROUND(AVG(DATEDIFF(fecha_aceptacion, fecha_recepcion)), 0) AS \'Días Promedio\',\n    MIN(DATEDIFF(fecha_aceptacion, fecha_recepcion)) AS \'Mínimo\',\n    MAX(DATEDIFF(fecha_aceptacion, fecha_recepcion)) AS \'Máximo\'\nFROM articulos\nWHERE fecha_recepcion IS NOT NULL\n    AND fecha_aceptacion IS NOT NULL\n    AND estado_articulo IN (\'aceptado\', \'publicado\')\nGROUP BY estado_articulo;\n','KPI de eficiencia editorial. Frecuencia recomendada: Trimestral','sistema','2026-01-31 03:50:07');
INSERT INTO `consultas` (`id`, `consulta_sistema`, `nombre`, `descripcion`, `editor_consultas`, `comentarios`, `usuario_creador`, `fecha_creacion`) VALUES (65,1,'ART-TIME-002: Tiempo entre aceptación y publicación (GOBERNANZA)','Días entre fecha de aceptación y publicación online','SELECT \n    id_articulo AS \'ID\',\n    titulo_articulo AS \'Título\',\n    fecha_aceptacion AS \'Fecha Aceptación\',\n    fecha_publicacion_online AS \'Fecha Publicación\',\n    DATEDIFF(fecha_publicacion_online, fecha_aceptacion) AS \'Días hasta Publicación\',\n    responsable_edicion AS \'Editor Responsable\'\nFROM articulos\nWHERE estado_articulo = \'publicado\'\n    AND fecha_aceptacion IS NOT NULL\n    AND fecha_publicacion_online IS NOT NULL\nORDER BY DATEDIFF(fecha_publicacion_online, fecha_aceptacion) DESC;\n','Medición de backlog, eficiencia de producción. Frecuencia recomendada: Mensual','sistema','2026-01-31 03:51:37');
INSERT INTO `consultas` (`id`, `consulta_sistema`, `nombre`, `descripcion`, `editor_consultas`, `comentarios`, `usuario_creador`, `fecha_creacion`) VALUES (66,1,'ART-TIME-003: Artículos publicados fuera de plazo objetivo (GOBERNANZA)','Artículos con más de 90 días entre aceptación y publicación','SELECT \n    id_articulo AS \'ID\',\n    titulo_articulo AS \'Título\',\n    fecha_aceptacion AS \'Fecha Aceptación\',\n    fecha_publicacion_online AS \'Fecha Publicación\',\n    DATEDIFF(fecha_publicacion_online, fecha_aceptacion) AS \'Días Retraso\',\n    responsable_edicion AS \'Editor Responsable\',\n    notas_internas AS \'Notas\'\nFROM articulos\nWHERE estado_articulo = \'publicado\'\n    AND fecha_aceptacion IS NOT NULL\n    AND fecha_publicacion_online IS NOT NULL\n    AND DATEDIFF(fecha_publicacion_online, fecha_aceptacion) > 90\nORDER BY DATEDIFF(fecha_publicacion_online, fecha_aceptacion) DESC;\n','Identificar cuellos de botella en producción. Frecuencia recomendada: Mensual','sistema','2026-01-31 03:53:05');
INSERT INTO `consultas` (`id`, `consulta_sistema`, `nombre`, `descripcion`, `editor_consultas`, `comentarios`, `usuario_creador`, `fecha_creacion`) VALUES (67,1,'REV-META-001: Revistas con campos obligatorios incompletos (CRÍTICO)','Identificar revistas con metadatos críticos faltantes','SELECT \n    id_revista AS \'ID\',\n    titulo_revista AS \'Título\',\n    CASE WHEN issn_impreso IS NULL OR issn_impreso = \'\' THEN \'FALTA ISSN IMPRESO\' ELSE \'\' END AS \'ISSN Impreso\',\n    CASE WHEN issn_electronico IS NULL OR issn_electronico = \'\' THEN \'FALTA ISSN ELECTRÓNICO\' ELSE \'\' END AS \'ISSN Electrónico\',\n    CASE WHEN doi_prefix IS NULL OR doi_prefix = \'\' THEN \'FALTA DOI PREFIX\' ELSE \'\' END AS \'DOI Prefix\',\n    CASE WHEN url_revista IS NULL OR url_revista = \'\' THEN \'FALTA URL\' ELSE \'\' END AS \'URL\',\n    CASE WHEN licencia_defecto IS NULL OR licencia_defecto = \'\' THEN \'FALTA LICENCIA\' ELSE \'\' END AS \'Licencia\',\n    estado_publicacion AS \'Estado\'\nFROM revistas_md\nWHERE estado_publicacion = \'activa\'\n    AND (\n        issn_impreso IS NULL OR issn_impreso = \'\'\n        OR issn_electronico IS NULL OR issn_electronico = \'\'\n        OR doi_prefix IS NULL OR doi_prefix = \'\'\n        OR url_revista IS NULL OR url_revista = \'\'\n        OR licencia_defecto IS NULL OR licencia_defecto = \'\'\n    );\n','Control de calidad antes de publicación. Frecuencia recomendada: Mensual','sistema','2026-01-31 04:13:34');
INSERT INTO `consultas` (`id`, `consulta_sistema`, `nombre`, `descripcion`, `editor_consultas`, `comentarios`, `usuario_creador`, `fecha_creacion`) VALUES (68,1,'REV-META-002: Validación de ISSN (GOBERNANZA)','Verificar formato correcto de ISSN (####-####)','SELECT \n    id_revista AS \'ID\',\n    titulo_revista AS \'Título\',\n    issn_impreso AS \'ISSN Impreso\',\n    issn_electronico AS \'ISSN Electrónico\',\n    CASE \n        WHEN issn_impreso NOT REGEXP \'^[0-9]{4}-[0-9]{3}[0-9X]$\' THEN \'FORMATO INVÁLIDO\'\n        ELSE \'OK\'\n    END AS \'Validación Impreso\',\n    CASE \n        WHEN issn_electronico NOT REGEXP \'^[0-9]{4}-[0-9]{3}[0-9X]$\' THEN \'FORMATO INVÁLIDO\'\n        ELSE \'OK\'\n    END AS \'Validación Electrónico\'\nFROM revistas_md\nWHERE estado_publicacion = \'activa\'\n    AND (\n        (issn_impreso IS NOT NULL AND issn_impreso != \'\')\n        OR (issn_electronico IS NOT NULL AND issn_electronico != \'\')\n    );\n','Control de calidad de identificadores. Frecuencia recomendada: Trimestral','sistema','2026-01-31 04:14:59');
INSERT INTO `consultas` (`id`, `consulta_sistema`, `nombre`, `descripcion`, `editor_consultas`, `comentarios`, `usuario_creador`, `fecha_creacion`) VALUES (69,1,'REV-META-003: Revistas sin repositorio de preservación (GOBERNANZA)','Revistas sin estrategia de preservación digital','SELECT \n    id_revista AS \'ID\',\n    titulo_revista AS \'Título\',\n    repositorio_produccion_plataforma AS \'Plataforma Producción\',\n    repositorio_preservacion_plataforma AS \'Plataforma Preservación\',\n    sistema_gestion_contenidos AS \'CMS\',\n    estado_publicacion AS \'Estado\'\nFROM revistas_md\nWHERE estado_publicacion = \'activa\'\n    AND (repositorio_preservacion_url IS NULL OR repositorio_preservacion_url = \'\');\n','Cumplimiento de buenas prácticas. Frecuencia recomendada: Semestral','sistema','2026-01-31 04:15:50');
INSERT INTO `consultas` (`id`, `consulta_sistema`, `nombre`, `descripcion`, `editor_consultas`, `comentarios`, `usuario_creador`, `fecha_creacion`) VALUES (70,1,'REV-STD-001: Revistas con acceso abierto sin licencia CC (CRÍTICO)','Revistas declaradas como acceso abierto sin licencia Creative Commons','SELECT \n    id_revista AS \'ID\',\n    titulo_revista AS \'Título\',\n    tipo_acceso AS \'Tipo Acceso\',\n    licencia_defecto AS \'Licencia\',\n    url_licencia AS \'URL Licencia\',\n    politica_acceso_abierto AS \'Política\'\nFROM revistas_md\nWHERE tipo_acceso IN (\'abierto\', \'mixto\')\n    AND (\n        licencia_defecto IS NULL \n        OR licencia_defecto = \'\'\n        OR licencia_defecto NOT LIKE \'%CC%\'\n    )\n    AND estado_publicacion = \'activa\';\n','Cumplimiento de políticas de acceso abierto. Frecuencia recomendada: Trimestral','sistema','2026-01-31 04:17:13');
INSERT INTO `consultas` (`id`, `consulta_sistema`, `nombre`, `descripcion`, `editor_consultas`, `comentarios`, `usuario_creador`, `fecha_creacion`) VALUES (71,1,'REV-STD-002: Verificación de indexación (GOBERNANZA)','Estado de indexación en bases de datos principales','SELECT \n    titulo_revista AS \'Título\',\n    indexada_en AS \'Indexada en\',\n    categoria_scielo AS \'Categoría SciELO\',\n    categoria_latindex AS \'Categoría Latindex\',\n    cuartil_scimago AS \'Cuartil Scimago\',\n    factor_impacto AS \'Factor Impacto\',\n    estado_publicacion AS \'Estado\'\nFROM revistas_md\nWHERE estado_publicacion = \'activa\'\nORDER BY titulo_revista;\n','Seguimiento de indexación. Frecuencia recomendada: Semestral','sistema','2026-01-31 04:18:05');
INSERT INTO `consultas` (`id`, `consulta_sistema`, `nombre`, `descripcion`, `editor_consultas`, `comentarios`, `usuario_creador`, `fecha_creacion`) VALUES (72,1,'REV-STD-003: Revistas sin OAI-PMH configurado (GOBERNANZA)','Revistas sin URL de OAI-PMH (requisito para SciELO/Redalyc)','SELECT \n    id_revista AS \'ID\',\n    titulo_revista AS \'Título\',\n    url_revista AS \'URL Revista\',\n    url_oai_pmh AS \'OAI-PMH\',\n    sistema_gestion_contenidos AS \'CMS\',\n    indexada_en AS \'Indexada en\'\nFROM revistas_md\nWHERE estado_publicacion = \'activa\'\n    AND (url_oai_pmh IS NULL OR url_oai_pmh = \'\');\n','Preparación para indexadores. Frecuencia recomendada: Trimestral','sistema','2026-01-31 04:19:41');
INSERT INTO `consultas` (`id`, `consulta_sistema`, `nombre`, `descripcion`, `editor_consultas`, `comentarios`, `usuario_creador`, `fecha_creacion`) VALUES (73,1,'REV-EST-001: Distribución de revistas por estado','Resumen de revistas por estado de publicación','SELECT \n    estado_publicacion AS \'Estado\',\n    COUNT(*) AS \'Cantidad\',\n    GROUP_CONCAT(titulo_revista SEPARATOR \'; \') AS \'Títulos\'\nFROM revistas_md\nGROUP BY estado_publicacion;\n','Dashboard ejecutivo. Frecuencia recomendada: Mensual','sistema','2026-01-31 04:20:58');
INSERT INTO `consultas` (`id`, `consulta_sistema`, `nombre`, `descripcion`, `editor_consultas`, `comentarios`, `usuario_creador`, `fecha_creacion`) VALUES (74,1,'REV-EST-002: Revistas suspendidas o finalizadas (AUDITORÍA)','Historial de revistas no activas','SELECT \n    titulo_revista AS \'Título\',\n    estado_publicacion AS \'Estado\',\n    ano_inicio AS \'Año Inicio\',\n    ano_fin AS \'Año Fin\',\n    fecha_actualizacion AS \'Última Actualización\',\n    notas_internas AS \'Notas\'\nFROM revistas_md\nWHERE estado_publicacion IN (\'suspendida\', \'finalizada\')\nORDER BY fecha_actualizacion DESC;\n','Auditoría histórica. Frecuencia recomendada: Anual','sistema','2026-01-31 04:22:00');
INSERT INTO `consultas` (`id`, `consulta_sistema`, `nombre`, `descripcion`, `editor_consultas`, `comentarios`, `usuario_creador`, `fecha_creacion`) VALUES (75,1,'REV-AUD-001: Revistas sin actualización reciente (GOBERNANZA)','Revistas activas sin modificación de metadatos en >6 meses','SELECT \n    id_revista AS \'ID\',\n    titulo_revista AS \'Título\',\n    fecha_actualizacion AS \'Última Actualización\',\n    DATEDIFF(CURDATE(), fecha_actualizacion) AS \'Días sin Actualizar\',\n    usuario_creacion AS \'Usuario Responsable\',\n    estado_publicacion AS \'Estado\'\nFROM revistas_md\nWHERE estado_publicacion = \'activa\'\n    AND fecha_actualizacion < DATE_SUB(CURDATE(), INTERVAL 6 MONTH)\nORDER BY fecha_actualizacion ASC;\n','Control de mantenimiento. Frecuencia recomendada: Trimestral','sistema','2026-01-31 04:23:22');
INSERT INTO `consultas` (`id`, `consulta_sistema`, `nombre`, `descripcion`, `editor_consultas`, `comentarios`, `usuario_creador`, `fecha_creacion`) VALUES (76,1,'REV-AUD-002: Cambios recientes en configuración (AUDITORÍA)','Revistas con modificaciones en el último mes','SELECT \n    titulo_revista AS \'Título\',\n    fecha_actualizacion AS \'Fecha Modificación\',\n    usuario_creacion AS \'Usuario\',\n    estado_publicacion AS \'Estado Actual\',\n    notas_internas AS \'Notas de Cambio\'\nFROM revistas_md\nWHERE fecha_actualizacion >= DATE_SUB(CURDATE(), INTERVAL 1 MONTH)\nORDER BY fecha_actualizacion DESC;\n','Trazabilidad de cambios. Frecuencia recomendada: Mensual','sistema','2026-01-31 04:24:17');
INSERT INTO `consultas` (`id`, `consulta_sistema`, `nombre`, `descripcion`, `editor_consultas`, `comentarios`, `usuario_creador`, `fecha_creacion`) VALUES (77,1,'REV-AUD-003: Coherencia de tipo de acceso y licencia (GOBERNANZA)','Detectar inconsistencias entre tipo de acceso y licencia','SELECT \n    titulo_revista AS \'Título\',\n    tipo_acceso AS \'Tipo Acceso\',\n    licencia_defecto AS \'Licencia\',\n    periodo_embargo AS \'Período Embargo\',\n    CASE \n        WHEN tipo_acceso = \'abierto\' AND (licencia_defecto IS NULL OR licencia_defecto = \'\') THEN \'INCONSISTENTE: Acceso abierto sin licencia\'\n        WHEN tipo_acceso = \'suscripcion\' AND licencia_defecto LIKE \'%CC%\' THEN \'INCONSISTENTE: Suscripción con licencia CC\'\n        WHEN tipo_acceso = \'embargado\' AND (periodo_embargo IS NULL OR periodo_embargo = 0) THEN \'INCONSISTENTE: Embargo sin período\'\n        ELSE \'OK\'\n    END AS \'Validación\'\nFROM revistas_md\nWHERE estado_publicacion = \'activa\'\nHAVING Validación != \'OK\';\n','Control de calidad. Frecuencia recomendada: Trimestral','sistema','2026-01-31 04:25:35');
INSERT INTO `consultas` (`id`, `consulta_sistema`, `nombre`, `descripcion`, `editor_consultas`, `comentarios`, `usuario_creador`, `fecha_creacion`) VALUES (78,1,'CROSS-001: Red de coautorías','Autores que colaboran frecuentemente','SELECT \n    a1.apellidos_nombre AS \'Autor 1\',\n    a2.apellidos_nombre AS \'Autor 2\',\n    COUNT(DISTINCT aa1.id_articulo) AS \'Artículos Conjuntos\',\n    GROUP_CONCAT(DISTINCT art.titulo_articulo SEPARATOR \'; \') AS \'Títulos\'\nFROM articulo_autor aa1\nJOIN articulo_autor aa2 ON aa1.id_articulo = aa2.id_articulo AND aa1.id_autor < aa2.id_autor\nJOIN autores a1 ON aa1.id_autor = a1.id_autor\nJOIN autores a2 ON aa2.id_autor = a2.id_autor\nJOIN articulos art ON aa1.id_articulo = art.id_articulo\nWHERE art.estado_articulo = \'publicado\'\nGROUP BY aa1.id_autor, aa2.id_autor\nHAVING COUNT(DISTINCT aa1.id_articulo) >= 3\nORDER BY COUNT(DISTINCT aa1.id_articulo) DESC;\n','Análisis de redes académicas. Frecuencia recomendada: Anual','sistema','2026-01-31 04:26:31');
INSERT INTO `consultas` (`id`, `consulta_sistema`, `nombre`, `descripcion`, `editor_consultas`, `comentarios`, `usuario_creador`, `fecha_creacion`) VALUES (79,1,'CROSS-002: Autores más prolíficos por revista','Top autores por cantidad de publicaciones','SELECT \n    r.titulo_revista AS \'Revista\',\n    a.apellidos_nombre AS \'Autor\',\n    a.afiliacion_actual AS \'Institución\',\n    COUNT(DISTINCT art.id_articulo) AS \'Publicaciones\',\n    MIN(art.fecha_publicacion_online) AS \'Primera Publicación\',\n    MAX(art.fecha_publicacion_online) AS \'Última Publicación\'\nFROM articulo_autor aa\nJOIN autores a ON aa.id_autor = a.id_autor\nJOIN articulos art ON aa.id_articulo = art.id_articulo\nJOIN revistas_md r ON art.id_revista = r.id_revista\nWHERE art.estado_articulo = \'publicado\'\nGROUP BY r.id_revista, a.id_autor\nHAVING COUNT(DISTINCT art.id_articulo) >= 2\nORDER BY r.titulo_revista, COUNT(DISTINCT art.id_articulo) DESC;\n','Identificar colaboradores clave. Frecuencia recomendada: Anual','sistema','2026-01-31 04:28:02');
INSERT INTO `consultas` (`id`, `consulta_sistema`, `nombre`, `descripcion`, `editor_consultas`, `comentarios`, `usuario_creador`, `fecha_creacion`) VALUES (80,1,'CROSS-003: Colaboración internacional','Artículos con autores de múltiples países','SELECT \n    art.id_articulo AS \'ID\',\n    art.titulo_articulo AS \'Título\',\n    COUNT(DISTINCT a.pais_afiliacion) AS \'Países Diferentes\',\n    GROUP_CONCAT(DISTINCT a.pais_afiliacion SEPARATOR \', \') AS \'Países Participantes\',\n    art.fecha_publicacion_online AS \'Fecha Publicación\'\nFROM articulos art\nJOIN articulo_autor aa ON art.id_articulo = aa.id_articulo\nJOIN autores a ON aa.id_autor = a.id_autor\nWHERE art.estado_articulo = \'publicado\'\n    AND a.pais_afiliacion IS NOT NULL\nGROUP BY art.id_articulo\nHAVING COUNT(DISTINCT a.pais_afiliacion) >= 3\nORDER BY COUNT(DISTINCT a.pais_afiliacion) DESC;\n','Análisis de internacionalización. Frecuencia recomendada: Anual','sistema','2026-01-31 04:28:50');
INSERT INTO `consultas` (`id`, `consulta_sistema`, `nombre`, `descripcion`, `editor_consultas`, `comentarios`, `usuario_creador`, `fecha_creacion`) VALUES (81,1,'CROSS-004: Dashboard ejecutivo completo','Resumen integral de métricas clave','SELECT \n    \'Autores Activos\' AS \'Métrica\',\n    COUNT(*) AS \'Valor\'\nFROM autores\nWHERE estado_autor = \'activo\'\n\nUNION ALL\n\nSELECT \n    \'Revisores Disponibles\',\n    COUNT(*)\nFROM autores\nWHERE disponible_revision = 1 AND estado_autor = \'activo\'\n\nUNION ALL\n\nSELECT \n    \'Artículos en Revisión\',\n    COUNT(*)\nFROM articulos\nWHERE estado_articulo = \'en_revision\'\n\nUNION ALL\n\nSELECT \n    \'Artículos Publicados (Año Actual)\',\n    COUNT(*)\nFROM articulos\nWHERE estado_articulo = \'publicado\' AND YEAR(fecha_publicacion_online) = YEAR(CURDATE())\n\nUNION ALL\n\nSELECT \n    \'Revistas Activas\',\n    COUNT(*)\nFROM revistas_md\nWHERE estado_publicacion = \'activa\'\n\nUNION ALL\n\nSELECT \n    \'Artículos sin ORCID (CRÍTICO)\',\n    COUNT(DISTINCT aa.id_articulo)\nFROM articulo_autor aa\nJOIN autores a ON aa.id_autor = a.id_autor\nJOIN articulos art ON aa.id_articulo = art.id_articulo\nWHERE (a.orcid IS NULL OR a.orcid = \'\')\n    AND art.estado_articulo IN (\'aceptado\', \'publicado\')\n\nUNION ALL\n\nSELECT \n    \'Artículos sin DOI (CRÍTICO)\',\n    COUNT(*)\nFROM articulos\nWHERE estado_articulo IN (\'aceptado\', \'publicado\')\n    AND (doi IS NULL OR doi = \'\');\n','Reporte ejecutivo mensual. Frecuencia recomendada: Mensual','sistema','2026-01-31 04:30:10');
INSERT INTO `consultas` (`id`, `consulta_sistema`, `nombre`, `descripcion`, `editor_consultas`, `comentarios`, `usuario_creador`, `fecha_creacion`) VALUES (82,1,'CROSS-005: Tiempo promedio de proceso por tipo de artículo (GOBERNANZA)','Eficiencia editorial segmentada','SELECT \n    tipo_articulo AS \'Tipo de Artículo\',\n    COUNT(*) AS \'Cantidad\',\n    ROUND(AVG(DATEDIFF(fecha_aceptacion, fecha_recepcion)), 0) AS \'Días Promedio Decisión\',\n    ROUND(AVG(DATEDIFF(fecha_publicacion_online, fecha_aceptacion)), 0) AS \'Días Promedio Publicación\',\n    ROUND(AVG(DATEDIFF(fecha_publicacion_online, fecha_recepcion)), 0) AS \'Días Totales\'\nFROM articulos\nWHERE estado_articulo = \'publicado\'\n    AND fecha_recepcion IS NOT NULL\n    AND fecha_aceptacion IS NOT NULL\n    AND fecha_publicacion_online IS NOT NULL\n    AND tipo_articulo IS NOT NULL\nGROUP BY tipo_articulo\nORDER BY COUNT(*) DESC;\n','Identificar tipos de artículo que requieren más tiempo. Frecuencia recomendada: Trimestral','sistema','2026-01-31 04:31:54');
INSERT INTO `consultas` (`id`, `consulta_sistema`, `nombre`, `descripcion`, `editor_consultas`, `comentarios`, `usuario_creador`, `fecha_creacion`) VALUES (83,1,'CROSS-006: Autores sin artículos publicados (GOBERNANZA)','Autores registrados sin publicaciones en el sistema','SELECT \n    a.apellidos_nombre AS \'Autor\',\n    a.email_principal AS \'Email\',\n    a.afiliacion_actual AS \'Institución\',\n    a.estado_autor AS \'Estado\',\n    a.fecha_creacion_registro AS \'Fecha Creación\',\n    DATEDIFF(CURDATE(), a.fecha_creacion_registro) AS \'Días en Sistema\'\nFROM autores a\nLEFT JOIN articulo_autor aa ON a.id_autor = aa.id_autor\nLEFT JOIN articulos art ON aa.id_articulo = art.id_articulo AND art.estado_articulo = \'publicado\'\nWHERE art.id_articulo IS NULL\n    AND a.estado_autor = \'activo\'\nORDER BY a.fecha_creacion_registro DESC;\n','Limpieza de base de datos. Frecuencia recomendada: Anual','sistema','2026-01-31 04:33:03');
INSERT INTO `consultas` (`id`, `consulta_sistema`, `nombre`, `descripcion`, `editor_consultas`, `comentarios`, `usuario_creador`, `fecha_creacion`) VALUES (84,1,'BIB-001: Distribución por tipo de entrada','Distribución de referencias por tipo de entrada','SELECT \n    tipo_de_entrada AS \'Tipo de Entrada\',\n    COUNT(*) AS \'Cantidad\',\n    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM bibtex), 2) AS \'Porcentaje\'\nFROM bibtex\nGROUP BY tipo_de_entrada\nORDER BY COUNT(*) DESC;\n','Identificar tipos de fuentes más citadas (artículos, libros, conferencias, etc.)','sistema','2026-01-31 04:35:48');
INSERT INTO `consultas` (`id`, `consulta_sistema`, `nombre`, `descripcion`, `editor_consultas`, `comentarios`, `usuario_creador`, `fecha_creacion`) VALUES (85,1,'BIB-002: Distribución temporal de referencias','Distribución temporal de referencias','SELECT \n    COALESCE(SUBSTRING(fd.valor, 1, 4), fy.valor) AS \'Año\',\n    COUNT(*) AS \'Referencias\',\n    b.tipo_de_entrada AS \'Tipo\'\nFROM bibtex b\nLEFT JOIN bibtex_campo fd ON fd.id_bibtex = b.id AND fd.campo = \'date\'\nLEFT JOIN bibtex_campo fy ON fy.id_bibtex = b.id AND fy.campo = \'year\'\nGROUP BY COALESCE(SUBSTRING(fd.valor, 1, 4), fy.valor), b.tipo_de_entrada\nORDER BY COUNT(*) DESC;','Actualidad de las referencias citadas','sistema','2026-01-31 04:43:10');
INSERT INTO `consultas` (`id`, `consulta_sistema`, `nombre`, `descripcion`, `editor_consultas`, `comentarios`, `usuario_creador`, `fecha_creacion`) VALUES (86,1,'BIB-003: Idioma de las referencias','Idioma de las referencias','SELECT \n    COALESCE(fl.valor, fg.valor) AS \'Idioma\',\n    COUNT(*) AS \'Referencias\',\n    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(DISTINCT id_bibtex) FROM bibtex_campo WHERE campo IN (\'langid\', \'language\')), 2) AS \'Porcentaje\'\nFROM bibtex b\nLEFT JOIN bibtex_campo fl ON fl.id_bibtex = b.id AND fl.campo = \'langid\'\nLEFT JOIN bibtex_campo fg ON fg.id_bibtex = b.id AND fg.campo = \'language\'\nWHERE fl.valor IS NOT NULL OR fg.valor IS NOT NULL\nGROUP BY COALESCE(fl.valor, fg.valor)\nORDER BY COUNT(*) DESC;','Diversidad lingüística de fuentes','sistema','2026-01-31 05:06:38');
INSERT INTO `consultas` (`id`, `consulta_sistema`, `nombre`, `descripcion`, `editor_consultas`, `comentarios`, `usuario_creador`, `fecha_creacion`) VALUES (87,1,'BIB-004: Revistas más citadas','Revistas más citadas','SELECT \n    fj.valor AS \'Revista\',\n    COUNT(*) AS \'Veces Citada\',\n    COUNT(DISTINCT b.id_proyecto) AS \'Proyectos que la Citan\'\nFROM bibtex b\nJOIN bibtex_campo fj ON fj.id_bibtex = b.id AND fj.campo = \'journaltitle\'\nGROUP BY fj.valor\nORDER BY COUNT(*) DESC\nLIMIT 10;','Identificar revistas de referencia en la disciplina','sistema','2026-01-31 05:20:20');
INSERT INTO `consultas` (`id`, `consulta_sistema`, `nombre`, `descripcion`, `editor_consultas`, `comentarios`, `usuario_creador`, `fecha_creacion`) VALUES (88,1,'BIB-005: Editoriales más citadas','Editoriales más citadas','SELECT \n    fp.valor AS \'Editorial\',\n    COUNT(*) AS \'Veces Citada\',\n    GROUP_CONCAT(DISTINCT fl.valor SEPARATOR \'; \') AS \'Ubicaciones\'\nFROM bibtex b\nJOIN bibtex_campo fp ON fp.id_bibtex = b.id AND fp.campo = \'publisher\'\nLEFT JOIN bibtex_campo fl ON fl.id_bibtex = b.id AND fl.campo = \'location\'\nGROUP BY fp.valor\nORDER BY COUNT(*) DESC\nLIMIT 10;','Prestigio de editoriales en el campo','sistema','2026-01-31 05:23:03');
INSERT INTO `consultas` (`id`, `consulta_sistema`, `nombre`, `descripcion`, `editor_consultas`, `comentarios`, `usuario_creador`, `fecha_creacion`) VALUES (89,1,'BIB-006: Autores más citados','Autores más citados','SELECT \n    fa.valor AS \'Autor\',\n    COUNT(*) AS \'Veces Citado\',\n    COUNT(DISTINCT b.id_proyecto) AS \'Proyectos que lo Citan\',\n    GROUP_CONCAT(DISTINCT COALESCE(SUBSTRING(fd.valor, 1, 4), fy.valor) ORDER BY COALESCE(SUBSTRING(fd.valor, 1, 4), fy.valor) DESC SEPARATOR \', \') AS \'Años\'\nFROM bibtex b\nJOIN bibtex_campo fa ON fa.id_bibtex = b.id AND fa.campo = \'author\'\nLEFT JOIN bibtex_campo fd ON fd.id_bibtex = b.id AND fd.campo = \'date\'\nLEFT JOIN bibtex_campo fy ON fy.id_bibtex = b.id AND fy.campo = \'year\'\nGROUP BY fa.valor\nORDER BY COUNT(*) DESC\nLIMIT 20;','Identificar autores influyentes en la disciplina','sistema','2026-01-31 05:25:11');
INSERT INTO `consultas` (`id`, `consulta_sistema`, `nombre`, `descripcion`, `editor_consultas`, `comentarios`, `usuario_creador`, `fecha_creacion`) VALUES (90,1,'BIB-CAL-001: Referencias sin DOI','Referencias sin DOI (control de calidad)','SELECT \n    p.nombre AS \'Proyecto\',\n    b.tipo_de_entrada AS \'Tipo\',\n    fa.valor AS \'Autor\',\n    ft.valor AS \'Título\',\n    COALESCE(SUBSTRING(fd.valor, 1, 4), fy.valor) AS \'Año\',\n    COALESCE(fj.valor, fb.valor, fe.valor) AS \'Publicado en\'\nFROM bibtex b\nJOIN proyectos p ON p.id = b.id_proyecto\nLEFT JOIN bibtex_campo fa ON fa.id_bibtex = b.id AND fa.campo = \'author\'\nLEFT JOIN bibtex_campo ft ON ft.id_bibtex = b.id AND ft.campo = \'title\'\nLEFT JOIN bibtex_campo fd ON fd.id_bibtex = b.id AND fd.campo = \'date\'\nLEFT JOIN bibtex_campo fy ON fy.id_bibtex = b.id AND fy.campo = \'year\'\nLEFT JOIN bibtex_campo fj ON fj.id_bibtex = b.id AND fj.campo = \'journaltitle\'\nLEFT JOIN bibtex_campo fb ON fb.id_bibtex = b.id AND fb.campo = \'booktitle\'\nLEFT JOIN bibtex_campo fe ON fe.id_bibtex = b.id AND fe.campo = \'eventtitle\'\nWHERE NOT EXISTS (SELECT 1 FROM bibtex_campo x WHERE x.id_bibtex = b.id AND x.campo = \'doi\')\n    AND b.tipo_de_entrada IN (\'article\', \'inproceedings\', \'incollection\', \'inbook\')\n    AND COALESCE(SUBSTRING(fd.valor, 1, 4), fy.valor) >= \'2010\'\nORDER BY CAST(COALESCE(SUBSTRING(fd.valor, 1, 4), fy.valor) AS UNSIGNED) DESC;','Identificar referencias modernas sin DOI (pérdida de rastreabilidad)','sistema','2026-01-31 05:36:40');
INSERT INTO `consultas` (`id`, `consulta_sistema`, `nombre`, `descripcion`, `editor_consultas`, `comentarios`, `usuario_creador`, `fecha_creacion`) VALUES (92,1,'BIB-CAL-002: Referencias sin año','Referencias sin año','SELECT \n    b.id AS \'ID Referencia\',\n    p.nombre AS \'Proyecto\',\n    b.tipo_de_entrada AS \'Tipo\',\n    fa.valor AS \'Autor\',\n    ft.valor AS \'Título\',\n    fp.valor AS \'Editorial/Revista\'\nFROM bibtex b\nJOIN proyectos p ON p.id = b.id_proyecto\nLEFT JOIN bibtex_campo fa ON fa.id_bibtex = b.id AND fa.campo = \'author\'\nLEFT JOIN bibtex_campo ft ON ft.id_bibtex = b.id AND ft.campo = \'title\'\nLEFT JOIN bibtex_campo fp ON fp.id_bibtex = b.id AND fp.campo = \'publisher\'\nWHERE NOT EXISTS (SELECT 1 FROM bibtex_campo x WHERE x.id_bibtex = b.id AND x.campo IN (\'date\', \'year\'))\nORDER BY p.nombre, b.id;','Control de calidad bibliográfica','sistema','2026-01-31 16:20:26');
INSERT INTO `consultas` (`id`, `consulta_sistema`, `nombre`, `descripcion`, `editor_consultas`, `comentarios`, `usuario_creador`, `fecha_creacion`) VALUES (93,1,'BIB-CAL-003: Referencias sin autor ni editor','Referencias sin autor ni editor','SELECT \n    b.id AS \'ID Referencia\',\n    p.nombre AS \'Proyecto\',\n    b.tipo_de_entrada AS \'Tipo\',\n    ft.valor AS \'Título\',\n    COALESCE(SUBSTRING(fd.valor, 1, 4), fy.valor) AS \'Año\'\nFROM bibtex b\nJOIN proyectos p ON p.id = b.id_proyecto\nLEFT JOIN bibtex_campo ft ON ft.id_bibtex = b.id AND ft.campo = \'title\'\nLEFT JOIN bibtex_campo fd ON fd.id_bibtex = b.id AND fd.campo = \'date\'\nLEFT JOIN bibtex_campo fy ON fy.id_bibtex = b.id AND fy.campo = \'year\'\nWHERE NOT EXISTS (SELECT 1 FROM bibtex_campo x WHERE x.id_bibtex = b.id AND x.campo IN (\'author\', \'editor\'))\nORDER BY p.nombre, b.id;','Identificar referencias incompletas','sistema','2026-01-31 16:31:01');
INSERT INTO `consultas` (`id`, `consulta_sistema`, `nombre`, `descripcion`, `editor_consultas`, `comentarios`, `usuario_creador`, `fecha_creacion`) VALUES (94,1,'BIB-ART-001: Cantidad de referencias por artículo','Cantidad de referencias por artículo','SELECT \n    a.id_articulo AS \'ID\',\n    a.titulo_articulo AS \'Título\',\n    COUNT(b.id) AS \'Referencias\',\n    a.tipo_articulo AS \'Tipo\',\n    a.estado_articulo AS \'Estado\'\nFROM articulos a\nLEFT JOIN bibtex b ON a.id_articulo = b.id_articulo\nGROUP BY a.id_articulo\nORDER BY COUNT(b.id) DESC;\n','Identificar artículos con bibliografía extensa o insuficiente','sistema','2026-01-31 16:33:45');
INSERT INTO `consultas` (`id`, `consulta_sistema`, `nombre`, `descripcion`, `editor_consultas`, `comentarios`, `usuario_creador`, `fecha_creacion`) VALUES (95,1,'BIB-ART-002: Antigüedad promedio de referencias por artículo','Antigüedad promedio de referencias por artículo','SELECT \n    a.id_articulo AS \'ID\',\n    a.titulo_articulo AS \'Título\',\n    COUNT(b.id) AS \'Total Referencias\',\n    ROUND(AVG(CAST(a.ano_publicacion AS SIGNED) - CAST(b.anio_normalizado AS SIGNED)), 1) AS \'Antigüedad Promedio\',\n    MIN(b.anio_normalizado) AS \'Ref. Más Antigua\',\n    MAX(b.anio_normalizado) AS \'Ref. Más Reciente\'\nFROM articulos a\nJOIN (\n    SELECT \n        id,\n        id_articulo,\n        COALESCE(SUBSTRING(date, 1, 4), year) AS anio_normalizado\n    FROM bibtex\n    WHERE (year REGEXP \'^[0-9]{4}$\') OR (date REGEXP \'^[0-9]{4}\')\n) b ON a.id_articulo = b.id_articulo\nWHERE a.ano_publicacion IS NOT NULL\nGROUP BY a.id_articulo\nORDER BY AVG(CAST(a.ano_publicacion AS SIGNED) - CAST(b.anio_normalizado AS SIGNED)) DESC;\n','Evaluar actualidad bibliográfica','sistema','2026-01-31 16:37:30');
INSERT INTO `consultas` (`id`, `consulta_sistema`, `nombre`, `descripcion`, `editor_consultas`, `comentarios`, `usuario_creador`, `fecha_creacion`) VALUES (96,1,'BIB-GEO-001: Ubicación de publicación de referencias','Ubicación de publicación de referencias','SELECT \n    fl.valor AS \'Ubicación\',\n    COUNT(*) AS \'Referencias\',\n    GROUP_CONCAT(DISTINCT fp.valor SEPARATOR \'; \') AS \'Editoriales\'\nFROM bibtex b\nJOIN bibtex_campo fl ON fl.id_bibtex = b.id AND fl.campo = \'location\'\nLEFT JOIN bibtex_campo fp ON fp.id_bibtex = b.id AND fp.campo = \'publisher\'\nGROUP BY fl.valor\nORDER BY COUNT(*) DESC\nLIMIT 20;','Identificar centros de producción académica citados','sistema','2026-01-31 16:40:27');
INSERT INTO `cmb_biblatex` (`id`, `tipo`, `codigo`, `nombre`, `activo`) VALUES (2,'biblatex_tipo','article','Artículo de revista o periódico',1);
INSERT INTO `cmb_biblatex` (`id`, `tipo`, `codigo`, `nombre`, `activo`) VALUES (3,'biblatex_tipo','book','Libro',1);
INSERT INTO `cmb_biblatex` (`id`, `tipo`, `codigo`, `nombre`, `activo`) VALUES (4,'biblatex_tipo','bookinbook','Libro dentro de otro libro',1);
INSERT INTO `cmb_biblatex` (`id`, `tipo`, `codigo`, `nombre`, `activo`) VALUES (5,'biblatex_tipo','booklet','Folleto o cuadernillo sin editor formal',1);
INSERT INTO `cmb_biblatex` (`id`, `tipo`, `codigo`, `nombre`, `activo`) VALUES (6,'biblatex_tipo','collection','Obra colectiva (libro con varios autores)',1);
INSERT INTO `cmb_biblatex` (`id`, `tipo`, `codigo`, `nombre`, `activo`) VALUES (7,'biblatex_tipo','conference','Ponencia o trabajo presentado en congreso (equivalente a inproceedings)',1);
INSERT INTO `cmb_biblatex` (`id`, `tipo`, `codigo`, `nombre`, `activo`) VALUES (8,'biblatex_tipo','inbook','Capítulo o sección de un libro',1);
INSERT INTO `cmb_biblatex` (`id`, `tipo`, `codigo`, `nombre`, `activo`) VALUES (9,'biblatex_tipo','incollection','Capítulo dentro de una obra colectiva',1);
INSERT INTO `cmb_biblatex` (`id`, `tipo`, `codigo`, `nombre`, `activo`) VALUES (10,'biblatex_tipo','inproceedings','Trabajo en actas de congreso',1);
INSERT INTO `cmb_biblatex` (`id`, `tipo`, `codigo`, `nombre`, `activo`) VALUES (11,'biblatex_tipo','inreference','Artículo en una obra de referencia',1);
INSERT INTO `cmb_biblatex` (`id`, `tipo`, `codigo`, `nombre`, `activo`) VALUES (12,'biblatex_tipo','manual','Manual o guía técnica',1);
INSERT INTO `cmb_biblatex` (`id`, `tipo`, `codigo`, `nombre`, `activo`) VALUES (13,'biblatex_tipo','misc','Miscelánea (documento no clasificable en otro tipo)',1);
INSERT INTO `cmb_biblatex` (`id`, `tipo`, `codigo`, `nombre`, `activo`) VALUES (14,'biblatex_tipo','movie','Película o material audiovisual',1);
INSERT INTO `cmb_biblatex` (`id`, `tipo`, `codigo`, `nombre`, `activo`) VALUES (15,'biblatex_tipo','mvbook','Obra en varios volúmenes (libro multivolumen)',1);
INSERT INTO `cmb_biblatex` (`id`, `tipo`, `codigo`, `nombre`, `activo`) VALUES (16,'biblatex_tipo','mvcollection','Colección multivolumen',1);
INSERT INTO `cmb_biblatex` (`id`, `tipo`, `codigo`, `nombre`, `activo`) VALUES (17,'biblatex_tipo','mvproceedings','Actas de congreso en varios volúmenes',1);
INSERT INTO `cmb_biblatex` (`id`, `tipo`, `codigo`, `nombre`, `activo`) VALUES (18,'biblatex_tipo','mvreference','Obra de referencia multivolumen',1);
INSERT INTO `cmb_biblatex` (`id`, `tipo`, `codigo`, `nombre`, `activo`) VALUES (19,'biblatex_tipo','online','Recurso en línea o sitio web',1);
INSERT INTO `cmb_biblatex` (`id`, `tipo`, `codigo`, `nombre`, `activo`) VALUES (20,'biblatex_tipo','patent','Patente',1);
INSERT INTO `cmb_biblatex` (`id`, `tipo`, `codigo`, `nombre`, `activo`) VALUES (21,'biblatex_tipo','periodical','Publicación periódica (revista, boletín, etc.)',1);
INSERT INTO `cmb_biblatex` (`id`, `tipo`, `codigo`, `nombre`, `activo`) VALUES (22,'biblatex_tipo','proceedings','Actas de congreso',1);
INSERT INTO `cmb_biblatex` (`id`, `tipo`, `codigo`, `nombre`, `activo`) VALUES (23,'biblatex_tipo','reference','Obra de referencia (diccionario, enciclopedia, etc.)',1);
INSERT INTO `cmb_biblatex` (`id`, `tipo`, `codigo`, `nombre`, `activo`) VALUES (24,'biblatex_tipo','report','Informe o documento técnico',1);
INSERT INTO `cmb_biblatex` (`id`, `tipo`, `codigo`, `nombre`, `activo`) VALUES (25,'biblatex_tipo','set','Conjunto de obras relacionadas',1);
INSERT INTO `cmb_biblatex` (`id`, `tipo`, `codigo`, `nombre`, `activo`) VALUES (26,'biblatex_tipo','software','Programa informático',1);
INSERT INTO `cmb_biblatex` (`id`, `tipo`, `codigo`, `nombre`, `activo`) VALUES (27,'biblatex_tipo','suppbook','Suplemento de un libro',1);
INSERT INTO `cmb_biblatex` (`id`, `tipo`, `codigo`, `nombre`, `activo`) VALUES (28,'biblatex_tipo','suppcollection','Suplemento de una obra colectiva',1);
INSERT INTO `cmb_biblatex` (`id`, `tipo`, `codigo`, `nombre`, `activo`) VALUES (29,'biblatex_tipo','suppperiodical','Suplemento de una publicación periódica',1);
INSERT INTO `cmb_biblatex` (`id`, `tipo`, `codigo`, `nombre`, `activo`) VALUES (30,'biblatex_tipo','thesis','Tesis',1);
INSERT INTO `cmb_biblatex` (`id`, `tipo`, `codigo`, `nombre`, `activo`) VALUES (31,'biblatex_tipo','unpublished','Material inédito',1);
INSERT INTO `cmb_biblatex` (`id`, `tipo`, `codigo`, `nombre`, `activo`) VALUES (32,'biblatex_tipo','xdata','Datos externos (tipo auxiliar de BibLaTeX, no bibliográfico)',1);
INSERT INTO `cmb_biblatex` (`id`, `tipo`, `codigo`, `nombre`, `activo`) VALUES (33,'editor_type','','',1);
INSERT INTO `cmb_biblatex` (`id`, `tipo`, `codigo`, `nombre`, `activo`) VALUES (34,'editor_type','collaborator','collaborator',1);
INSERT INTO `cmb_biblatex` (`id`, `tipo`, `codigo`, `nombre`, `activo`) VALUES (35,'editor_type','compiler','compiler',1);
INSERT INTO `cmb_biblatex` (`id`, `tipo`, `codigo`, `nombre`, `activo`) VALUES (36,'editor_type','continuator','continuator',1);
INSERT INTO `cmb_biblatex` (`id`, `tipo`, `codigo`, `nombre`, `activo`) VALUES (37,'editor_type','coordinator','coordinator',1);
INSERT INTO `cmb_biblatex` (`id`, `tipo`, `codigo`, `nombre`, `activo`) VALUES (38,'editor_type','direction','direction',1);
INSERT INTO `cmb_biblatex` (`id`, `tipo`, `codigo`, `nombre`, `activo`) VALUES (39,'editor_type','editor','editor',1);
INSERT INTO `cmb_biblatex` (`id`, `tipo`, `codigo`, `nombre`, `activo`) VALUES (41,'editor_type','organizer','organizer',1);
INSERT INTO `cmb_biblatex` (`id`, `tipo`, `codigo`, `nombre`, `activo`) VALUES (42,'editor_type','redactor','redactor',1);
INSERT INTO `cmb_biblatex` (`id`, `tipo`, `codigo`, `nombre`, `activo`) VALUES (43,'editor_type','reviser','reviser',1);
INSERT INTO `cmb_biblatex` (`id`, `tipo`, `codigo`, `nombre`, `activo`) VALUES (56,'pagination','page','page',1);
INSERT INTO `cmb_biblatex` (`id`, `tipo`, `codigo`, `nombre`, `activo`) VALUES (57,'pagination','column','column',1);
INSERT INTO `cmb_biblatex` (`id`, `tipo`, `codigo`, `nombre`, `activo`) VALUES (58,'pagination','line','line',1);
INSERT INTO `cmb_biblatex` (`id`, `tipo`, `codigo`, `nombre`, `activo`) VALUES (59,'pagination','verse','verse',1);
INSERT INTO `cmb_biblatex` (`id`, `tipo`, `codigo`, `nombre`, `activo`) VALUES (60,'pagination','section','section',1);
INSERT INTO `cmb_biblatex` (`id`, `tipo`, `codigo`, `nombre`, `activo`) VALUES (61,'pagination','paragraph','paragraph',1);
INSERT INTO `cmb_biblatex` (`id`, `tipo`, `codigo`, `nombre`, `activo`) VALUES (92,'language','spanish','spanish',1);
INSERT INTO `cmb_biblatex` (`id`, `tipo`, `codigo`, `nombre`, `activo`) VALUES (93,'language','portuguese','portuguese',1);
INSERT INTO `cmb_biblatex` (`id`, `tipo`, `codigo`, `nombre`, `activo`) VALUES (94,'language','english','english',1);
INSERT INTO `cmb_biblatex` (`id`, `tipo`, `codigo`, `nombre`, `activo`) VALUES (95,'language','french','french',1);
INSERT INTO `cmb_biblatex` (`id`, `tipo`, `codigo`, `nombre`, `activo`) VALUES (96,'language','armenian','armenian',1);
INSERT INTO `cmb_biblatex` (`id`, `tipo`, `codigo`, `nombre`, `activo`) VALUES (97,'language','korean','korean',1);
INSERT INTO `cmb_biblatex` (`id`, `tipo`, `codigo`, `nombre`, `activo`) VALUES (98,'language','german','german',1);
INSERT INTO `cmb_biblatex` (`id`, `tipo`, `codigo`, `nombre`, `activo`) VALUES (99,'language','italian','italian',1);
INSERT INTO `cmb_biblatex` (`id`, `tipo`, `codigo`, `nombre`, `activo`) VALUES (100,'language','japanese','japanese',1);
INSERT INTO `cmb_biblatex` (`id`, `tipo`, `codigo`, `nombre`, `activo`) VALUES (101,'language','norwegian','norwegian',1);
INSERT INTO `cmb_biblatex` (`id`, `tipo`, `codigo`, `nombre`, `activo`) VALUES (102,'language','turkish','turkish',1);
INSERT INTO `cmb_biblatex` (`id`, `tipo`, `codigo`, `nombre`, `activo`) VALUES (103,'language','chinese','chinese',1);
INSERT INTO `cmb_biblatex` (`id`, `tipo`, `codigo`, `nombre`, `activo`) VALUES (104,'language','greek','greek',1);
INSERT INTO `cmb_biblatex` (`id`, `tipo`, `codigo`, `nombre`, `activo`) VALUES (105,'language','hebrew','hebrew',1);
INSERT INTO `cmb_biblatex` (`id`, `tipo`, `codigo`, `nombre`, `activo`) VALUES (106,'language','swedish','swedish',1);
INSERT INTO `cmb_biblatex` (`id`, `tipo`, `codigo`, `nombre`, `activo`) VALUES (107,'language','slovak','slovak',1);
INSERT INTO `cmb_biblatex` (`id`, `tipo`, `codigo`, `nombre`, `activo`) VALUES (108,'language','russian','russian',1);
INSERT INTO `cmb_biblatex` (`id`, `tipo`, `codigo`, `nombre`, `activo`) VALUES (109,'language','hindi','hindi',1);
INSERT INTO `cmb_biblatex` (`id`, `tipo`, `codigo`, `nombre`, `activo`) VALUES (110,'language','vietnamese','vietnamese',1);
INSERT INTO `cmb_biblatex` (`id`, `tipo`, `codigo`, `nombre`, `activo`) VALUES (111,'language','latin','latin',1);
INSERT INTO `cmb_biblatex` (`id`, `tipo`, `codigo`, `nombre`, `activo`) VALUES (112,'language','czech','czech',1);
INSERT INTO `cmb_biblatex` (`id`, `tipo`, `codigo`, `nombre`, `activo`) VALUES (113,'language','bulgarian','bulgarian',1);
INSERT INTO `cmb_biblatex` (`id`, `tipo`, `codigo`, `nombre`, `activo`) VALUES (114,'language','romanian','romanian',1);
INSERT INTO `cmb_biblatex` (`id`, `tipo`, `codigo`, `nombre`, `activo`) VALUES (115,'language','slovenian','slovenian',1);
INSERT INTO `cmb_biblatex` (`id`, `tipo`, `codigo`, `nombre`, `activo`) VALUES (116,'language','scottish','scottish',1);
INSERT INTO `cmb_biblatex` (`id`, `tipo`, `codigo`, `nombre`, `activo`) VALUES (117,'language','dutch','dutch',1);
INSERT INTO `cmb_biblatex` (`id`, `tipo`, `codigo`, `nombre`, `activo`) VALUES (118,'language','catalan','catalan',1);
INSERT INTO `cmb_biblatex` (`id`, `tipo`, `codigo`, `nombre`, `activo`) VALUES (119,'language','galician','galician',1);
INSERT INTO `cmb_biblatex` (`id`, `tipo`, `codigo`, `nombre`, `activo`) VALUES (121,'eprint','arXiv','arXiv',1);
INSERT INTO `cmb_biblatex` (`id`, `tipo`, `codigo`, `nombre`, `activo`) VALUES (122,'eprint','PubMed','PubMed',1);
INSERT INTO `cmb_biblatex` (`id`, `tipo`, `codigo`, `nombre`, `activo`) VALUES (123,'eprint','JSTOR','JSTOR',1);
INSERT INTO `cmb_biblatex` (`id`, `tipo`, `codigo`, `nombre`, `activo`) VALUES (124,'eprint','Handle System (HDL)','Handle System (HDL)',1);
INSERT INTO `cmb_biblatex` (`id`, `tipo`, `codigo`, `nombre`, `activo`) VALUES (125,'eprint','URL','URL',1);
INSERT INTO `cmb_biblatex` (`id`, `tipo`, `codigo`, `nombre`, `activo`) VALUES (126,'eprint','DOI','DOI',1);
INSERT INTO `cmb_biblatex` (`id`, `tipo`, `codigo`, `nombre`, `activo`) VALUES (128,'pubstate','mimeograph','mimeograph',1);
INSERT INTO `cmb_biblatex` (`id`, `tipo`, `codigo`, `nombre`, `activo`) VALUES (129,'pubstate','photocopy','photocopy',1);
INSERT INTO `cmb_biblatex` (`id`, `tipo`, `codigo`, `nombre`, `activo`) VALUES (130,'pubstate','digitalprinting','digitalprinting',1);
INSERT INTO `cmb_biblatex` (`id`, `tipo`, `codigo`, `nombre`, `activo`) VALUES (131,'pubstate','inpreparation','Trabajo en desarrollo',1);
INSERT INTO `cmb_biblatex` (`id`, `tipo`, `codigo`, `nombre`, `activo`) VALUES (132,'pubstate','submitted','submitted',1);
INSERT INTO `cmb_biblatex` (`id`, `tipo`, `codigo`, `nombre`, `activo`) VALUES (133,'pubstate','forthcoming','forthcoming',1);
INSERT INTO `cmb_biblatex` (`id`, `tipo`, `codigo`, `nombre`, `activo`) VALUES (134,'pubstate','inpress','Trabajo en prensa',1);
INSERT INTO `cmb_biblatex` (`id`, `tipo`, `codigo`, `nombre`, `activo`) VALUES (135,'pubstate','prepublished','prepublished',1);
INSERT INTO `cmb_biblatex` (`id`, `tipo`, `codigo`, `nombre`, `activo`) VALUES (136,'pubstate','self-published','Edición del autor',1);
INSERT INTO `cmb_biblatex` (`id`, `tipo`, `codigo`, `nombre`, `activo`) VALUES (138,'thesis_type','bachelorthesis','Tesis de Licenciatura',1);
INSERT INTO `cmb_biblatex` (`id`, `tipo`, `codigo`, `nombre`, `activo`) VALUES (139,'thesis_type','candthesis','Trabajo candidato a Tesis',1);
INSERT INTO `cmb_biblatex` (`id`, `tipo`, `codigo`, `nombre`, `activo`) VALUES (140,'thesis_type','engineerthesis','Tesis de Ingeniería',1);
INSERT INTO `cmb_biblatex` (`id`, `tipo`, `codigo`, `nombre`, `activo`) VALUES (141,'thesis_type','specializationthesis','Tesis de Especialización',1);
INSERT INTO `cmb_biblatex` (`id`, `tipo`, `codigo`, `nombre`, `activo`) VALUES (142,'thesis_type','fieldwork','Trabajo de Campo',1);
INSERT INTO `cmb_biblatex` (`id`, `tipo`, `codigo`, `nombre`, `activo`) VALUES (143,'thesis_type','finalessay','Ensayo Final',1);
INSERT INTO `cmb_biblatex` (`id`, `tipo`, `codigo`, `nombre`, `activo`) VALUES (144,'thesis_type','finalmonograph','Monografía Final de Carrera',1);
INSERT INTO `cmb_biblatex` (`id`, `tipo`, `codigo`, `nombre`, `activo`) VALUES (145,'thesis_type','finalproject','Proyecto Final',1);
INSERT INTO `cmb_biblatex` (`id`, `tipo`, `codigo`, `nombre`, `activo`) VALUES (146,'thesis_type','gradothesis','Tesis de Grado',1);
INSERT INTO `cmb_biblatex` (`id`, `tipo`, `codigo`, `nombre`, `activo`) VALUES (147,'thesis_type','integrativefinalwork','Trabajo Integrador Final (TIF)',1);
INSERT INTO `cmb_biblatex` (`id`, `tipo`, `codigo`, `nombre`, `activo`) VALUES (150,'thesis_type','magisterthesis','Tesis de Magíster',1);
INSERT INTO `cmb_biblatex` (`id`, `tipo`, `codigo`, `nombre`, `activo`) VALUES (151,'thesis_type','masterfinalwork','Trabajo Final de Maestría',1);
INSERT INTO `cmb_biblatex` (`id`, `tipo`, `codigo`, `nombre`, `activo`) VALUES (152,'thesis_type','mathesis','Tesis de Maestría',1);
INSERT INTO `cmb_biblatex` (`id`, `tipo`, `codigo`, `nombre`, `activo`) VALUES (153,'thesis_type','phdthesis','Tesis Doctoral',1);
INSERT INTO `cmb_biblatex` (`id`, `tipo`, `codigo`, `nombre`, `activo`) VALUES (155,'thesis_type','postgradthesis','Tesis de Posgrado',1);
INSERT INTO `cmb_biblatex` (`id`, `tipo`, `codigo`, `nombre`, `activo`) VALUES (156,'thesis_type','teacherthesis','Tesis de Profesorado',1);
INSERT INTO `cmb_biblatex` (`id`, `tipo`, `codigo`, `nombre`, `activo`) VALUES (157,'thesis_type','researchproject','Proyecto de Investigación',1);
INSERT INTO `cmb_biblatex` (`id`, `tipo`, `codigo`, `nombre`, `activo`) VALUES (158,'thesis_type','residencyreport','Informe Final de Residencia',1);
INSERT INTO `cmb_biblatex` (`id`, `tipo`, `codigo`, `nombre`, `activo`) VALUES (159,'thesis_type','shortthesis','Tesina',1);
INSERT INTO `cmb_biblatex` (`id`, `tipo`, `codigo`, `nombre`, `activo`) VALUES (161,'thesis_type','technicalreport','Trabajo Final Técnico',1);
INSERT INTO `cmb_biblatex` (`id`, `tipo`, `codigo`, `nombre`, `activo`) VALUES (164,'thesis_type','undergraduatethesis','Trabajo Final de Grado',1);
INSERT INTO `cmb_biblatex` (`id`, `tipo`, `codigo`, `nombre`, `activo`) VALUES (166,'related_type','reprintof','reprintof',1);
INSERT INTO `cmb_biblatex` (`id`, `tipo`, `codigo`, `nombre`, `activo`) VALUES (167,'related_type','translationof','translationof',1);
INSERT INTO `cmb_biblatex` (`id`, `tipo`, `codigo`, `nombre`, `activo`) VALUES (168,'related_type','translatedas','translatedas',1);
INSERT INTO `cmb_biblatex` (`id`, `tipo`, `codigo`, `nombre`, `activo`) VALUES (169,'related_type','multivolume','multivolume',1);
INSERT INTO `cmb_biblatex` (`id`, `tipo`, `codigo`, `nombre`, `activo`) VALUES (170,'pubstate','draft','draft',1);
INSERT INTO `cmb_biblatex` (`id`, `tipo`, `codigo`, `nombre`, `activo`) VALUES (171,'pubstate','manuscript','manuscript',1);
INSERT INTO `cmb_biblatex` (`id`, `tipo`, `codigo`, `nombre`, `activo`) VALUES (172,'pubstate','cancelled','cancelled',1);
INSERT INTO `cmb_biblatex` (`id`, `tipo`, `codigo`, `nombre`, `activo`) VALUES (173,'pubstate','outofprint','outofprint',1);
INSERT INTO `cmb_biblatex` (`id`, `tipo`, `codigo`, `nombre`, `activo`) VALUES (174,'pubstate','archival','archival',1);
INSERT INTO `bibtex_campo_catalogo` (`campo`, `orden`, `literal`, `nombre_anterior`) VALUES ('abstract',1010,0,'abstract');
INSERT INTO `bibtex_campo_catalogo` (`campo`, `orden`, `literal`, `nombre_anterior`) VALUES ('addendum',820,0,'addendum');
INSERT INTO `bibtex_campo_catalogo` (`campo`, `orden`, `literal`, `nombre_anterior`) VALUES ('afterword',100,0,'afterword');
INSERT INTO `bibtex_campo_catalogo` (`campo`, `orden`, `literal`, `nombre_anterior`) VALUES ('annotation',1040,0,'annotation');
INSERT INTO `bibtex_campo_catalogo` (`campo`, `orden`, `literal`, `nombre_anterior`) VALUES ('annotator',150,0,'annotator');
INSERT INTO `bibtex_campo_catalogo` (`campo`, `orden`, `literal`, `nombre_anterior`) VALUES ('author',20,0,'author');
INSERT INTO `bibtex_campo_catalogo` (`campo`, `orden`, `literal`, `nombre_anterior`) VALUES ('bookauthor',60,0,'book_author');
INSERT INTO `bibtex_campo_catalogo` (`campo`, `orden`, `literal`, `nombre_anterior`) VALUES ('bookpagination',610,0,'book_pagination');
INSERT INTO `bibtex_campo_catalogo` (`campo`, `orden`, `literal`, `nombre_anterior`) VALUES ('booktitle',260,0,'book_title');
INSERT INTO `bibtex_campo_catalogo` (`campo`, `orden`, `literal`, `nombre_anterior`) VALUES ('booktitleaddon',270,0,'book_title_addon');
INSERT INTO `bibtex_campo_catalogo` (`campo`, `orden`, `literal`, `nombre_anterior`) VALUES ('chapter',420,0,'chapter');
INSERT INTO `bibtex_campo_catalogo` (`campo`, `orden`, `literal`, `nombre_anterior`) VALUES ('commentator',120,0,'commentator');
INSERT INTO `bibtex_campo_catalogo` (`campo`, `orden`, `literal`, `nombre_anterior`) VALUES ('crossref',910,0,'cross_ref');
INSERT INTO `bibtex_campo_catalogo` (`campo`, `orden`, `literal`, `nombre_anterior`) VALUES ('date',490,0,'date');
INSERT INTO `bibtex_campo_catalogo` (`campo`, `orden`, `literal`, `nombre_anterior`) VALUES ('doi',780,1,'doi');
INSERT INTO `bibtex_campo_catalogo` (`campo`, `orden`, `literal`, `nombre_anterior`) VALUES ('edition',450,0,'edition');
INSERT INTO `bibtex_campo_catalogo` (`campo`, `orden`, `literal`, `nombre_anterior`) VALUES ('editor',30,0,'editor');
INSERT INTO `bibtex_campo_catalogo` (`campo`, `orden`, `literal`, `nombre_anterior`) VALUES ('editora',70,0,'editor_a');
INSERT INTO `bibtex_campo_catalogo` (`campo`, `orden`, `literal`, `nombre_anterior`) VALUES ('editorb',80,0,'editor_b');
INSERT INTO `bibtex_campo_catalogo` (`campo`, `orden`, `literal`, `nombre_anterior`) VALUES ('editorc',90,0,'editor_c');
INSERT INTO `bibtex_campo_catalogo` (`campo`, `orden`, `literal`, `nombre_anterior`) VALUES ('editortype',190,0,'editor_type');
INSERT INTO `bibtex_campo_catalogo` (`campo`, `orden`, `literal`, `nombre_anterior`) VALUES ('editortypea',200,0,'editor_type_a');
INSERT INTO `bibtex_campo_catalogo` (`campo`, `orden`, `literal`, `nombre_anterior`) VALUES ('editortypeb',210,0,'editor_type_b');
INSERT INTO `bibtex_campo_catalogo` (`campo`, `orden`, `literal`, `nombre_anterior`) VALUES ('editortypec',220,0,'editor_type_c');
INSERT INTO `bibtex_campo_catalogo` (`campo`, `orden`, `literal`, `nombre_anterior`) VALUES ('eid',430,0,'eid');
INSERT INTO `bibtex_campo_catalogo` (`campo`, `orden`, `literal`, `nombre_anterior`) VALUES ('entryset',900,0,'entry_set');
INSERT INTO `bibtex_campo_catalogo` (`campo`, `orden`, `literal`, `nombre_anterior`) VALUES ('entrysubtype',830,0,'entry_sub_type');
INSERT INTO `bibtex_campo_catalogo` (`campo`, `orden`, `literal`, `nombre_anterior`) VALUES ('eprint',690,1,'eprint');
INSERT INTO `bibtex_campo_catalogo` (`campo`, `orden`, `literal`, `nombre_anterior`) VALUES ('eprinttype',700,0,'eprint_type');
INSERT INTO `bibtex_campo_catalogo` (`campo`, `orden`, `literal`, `nombre_anterior`) VALUES ('eventdate',480,0,'event_date');
INSERT INTO `bibtex_campo_catalogo` (`campo`, `orden`, `literal`, `nombre_anterior`) VALUES ('eventtitle',340,0,'event_title');
INSERT INTO `bibtex_campo_catalogo` (`campo`, `orden`, `literal`, `nombre_anterior`) VALUES ('eventtitleaddon',350,0,'event_title_addon');
INSERT INTO `bibtex_campo_catalogo` (`campo`, `orden`, `literal`, `nombre_anterior`) VALUES ('file',1050,1,'file');
INSERT INTO `bibtex_campo_catalogo` (`campo`, `orden`, `literal`, `nombre_anterior`) VALUES ('foreword',110,0,'foreword');
INSERT INTO `bibtex_campo_catalogo` (`campo`, `orden`, `literal`, `nombre_anterior`) VALUES ('gender',170,0,'gender');
INSERT INTO `bibtex_campo_catalogo` (`campo`, `orden`, `literal`, `nombre_anterior`) VALUES ('holder',160,0,'holder');
INSERT INTO `bibtex_campo_catalogo` (`campo`, `orden`, `literal`, `nombre_anterior`) VALUES ('howpublished',860,0,'how_published');
INSERT INTO `bibtex_campo_catalogo` (`campo`, `orden`, `literal`, `nombre_anterior`) VALUES ('ids',890,0,'ids');
INSERT INTO `bibtex_campo_catalogo` (`campo`, `orden`, `literal`, `nombre_anterior`) VALUES ('indexsorttitle',1000,0,'index_sort_title');
INSERT INTO `bibtex_campo_catalogo` (`campo`, `orden`, `literal`, `nombre_anterior`) VALUES ('indextitle',360,0,'index_title');
INSERT INTO `bibtex_campo_catalogo` (`campo`, `orden`, `literal`, `nombre_anterior`) VALUES ('institution',640,0,'institution');
INSERT INTO `bibtex_campo_catalogo` (`campo`, `orden`, `literal`, `nombre_anterior`) VALUES ('introduction',130,0,'introduction');
INSERT INTO `bibtex_campo_catalogo` (`campo`, `orden`, `literal`, `nombre_anterior`) VALUES ('isan',760,0,'isan');
INSERT INTO `bibtex_campo_catalogo` (`campo`, `orden`, `literal`, `nombre_anterior`) VALUES ('isbn',720,0,'isbn');
INSERT INTO `bibtex_campo_catalogo` (`campo`, `orden`, `literal`, `nombre_anterior`) VALUES ('ismn',740,0,'ismn');
INSERT INTO `bibtex_campo_catalogo` (`campo`, `orden`, `literal`, `nombre_anterior`) VALUES ('isrn',750,0,'isrn');
INSERT INTO `bibtex_campo_catalogo` (`campo`, `orden`, `literal`, `nombre_anterior`) VALUES ('issn',730,0,'issn');
INSERT INTO `bibtex_campo_catalogo` (`campo`, `orden`, `literal`, `nombre_anterior`) VALUES ('issue',460,0,'issue');
INSERT INTO `bibtex_campo_catalogo` (`campo`, `orden`, `literal`, `nombre_anterior`) VALUES ('issuetitle',320,0,'issue_title');
INSERT INTO `bibtex_campo_catalogo` (`campo`, `orden`, `literal`, `nombre_anterior`) VALUES ('issuetitleaddon',330,0,'issue_title_addon');
INSERT INTO `bibtex_campo_catalogo` (`campo`, `orden`, `literal`, `nombre_anterior`) VALUES ('iswc',770,0,'iswc');
INSERT INTO `bibtex_campo_catalogo` (`campo`, `orden`, `literal`, `nombre_anterior`) VALUES ('journaltitle',300,0,'journal_title');
INSERT INTO `bibtex_campo_catalogo` (`campo`, `orden`, `literal`, `nombre_anterior`) VALUES ('journaltitleaddon',310,0,'journal_title_addon');
INSERT INTO `bibtex_campo_catalogo` (`campo`, `orden`, `literal`, `nombre_anterior`) VALUES ('label',850,0,'label');
INSERT INTO `bibtex_campo_catalogo` (`campo`, `orden`, `literal`, `nombre_anterior`) VALUES ('langid',530,0,'hyphenation');
INSERT INTO `bibtex_campo_catalogo` (`campo`, `orden`, `literal`, `nombre_anterior`) VALUES ('langidopts',560,0,'land_id_opts');
INSERT INTO `bibtex_campo_catalogo` (`campo`, `orden`, `literal`, `nombre_anterior`) VALUES ('language',540,0,'language');
INSERT INTO `bibtex_campo_catalogo` (`campo`, `orden`, `literal`, `nombre_anterior`) VALUES ('library',1030,0,'library');
INSERT INTO `bibtex_campo_catalogo` (`campo`, `orden`, `literal`, `nombre_anterior`) VALUES ('location',620,0,'location');
INSERT INTO `bibtex_campo_catalogo` (`campo`, `orden`, `literal`, `nombre_anterior`) VALUES ('maintitle',280,0,'main_title');
INSERT INTO `bibtex_campo_catalogo` (`campo`, `orden`, `literal`, `nombre_anterior`) VALUES ('maintitleaddon',290,0,'main_title_addon');
INSERT INTO `bibtex_campo_catalogo` (`campo`, `orden`, `literal`, `nombre_anterior`) VALUES ('nameaddon',50,0,'name_addon');
INSERT INTO `bibtex_campo_catalogo` (`campo`, `orden`, `literal`, `nombre_anterior`) VALUES ('note',1020,0,'note');
INSERT INTO `bibtex_campo_catalogo` (`campo`, `orden`, `literal`, `nombre_anterior`) VALUES ('number',410,0,'number');
INSERT INTO `bibtex_campo_catalogo` (`campo`, `orden`, `literal`, `nombre_anterior`) VALUES ('options',840,0,'options');
INSERT INTO `bibtex_campo_catalogo` (`campo`, `orden`, `literal`, `nombre_anterior`) VALUES ('organization',650,0,'organization');
INSERT INTO `bibtex_campo_catalogo` (`campo`, `orden`, `literal`, `nombre_anterior`) VALUES ('origdate',500,0,'orig_date');
INSERT INTO `bibtex_campo_catalogo` (`campo`, `orden`, `literal`, `nombre_anterior`) VALUES ('origlanguage',550,0,'orig_language');
INSERT INTO `bibtex_campo_catalogo` (`campo`, `orden`, `literal`, `nombre_anterior`) VALUES ('origlocation',630,0,'orig_location');
INSERT INTO `bibtex_campo_catalogo` (`campo`, `orden`, `literal`, `nombre_anterior`) VALUES ('origpublisher',670,0,'orig_publisher');
INSERT INTO `bibtex_campo_catalogo` (`campo`, `orden`, `literal`, `nombre_anterior`) VALUES ('pages',580,0,'pages');
INSERT INTO `bibtex_campo_catalogo` (`campo`, `orden`, `literal`, `nombre_anterior`) VALUES ('pagetotal',590,0,'page_total');
INSERT INTO `bibtex_campo_catalogo` (`campo`, `orden`, `literal`, `nombre_anterior`) VALUES ('pagination',600,0,'pagination');
INSERT INTO `bibtex_campo_catalogo` (`campo`, `orden`, `literal`, `nombre_anterior`) VALUES ('part',440,0,'part');
INSERT INTO `bibtex_campo_catalogo` (`campo`, `orden`, `literal`, `nombre_anterior`) VALUES ('presort',940,0,'pre_sort');
INSERT INTO `bibtex_campo_catalogo` (`campo`, `orden`, `literal`, `nombre_anterior`) VALUES ('publisher',660,0,'publisher');
INSERT INTO `bibtex_campo_catalogo` (`campo`, `orden`, `literal`, `nombre_anterior`) VALUES ('pubstate',570,0,'pub_state');
INSERT INTO `bibtex_campo_catalogo` (`campo`, `orden`, `literal`, `nombre_anterior`) VALUES ('related',800,0,'related');
INSERT INTO `bibtex_campo_catalogo` (`campo`, `orden`, `literal`, `nombre_anterior`) VALUES ('relatedstring',810,0,'related_string');
INSERT INTO `bibtex_campo_catalogo` (`campo`, `orden`, `literal`, `nombre_anterior`) VALUES ('relatedtype',790,0,'related_type');
INSERT INTO `bibtex_campo_catalogo` (`campo`, `orden`, `literal`, `nombre_anterior`) VALUES ('reprinttitle',380,0,'reprint_title');
INSERT INTO `bibtex_campo_catalogo` (`campo`, `orden`, `literal`, `nombre_anterior`) VALUES ('series',250,0,'series');
INSERT INTO `bibtex_campo_catalogo` (`campo`, `orden`, `literal`, `nombre_anterior`) VALUES ('shortauthor',180,0,'short_author');
INSERT INTO `bibtex_campo_catalogo` (`campo`, `orden`, `literal`, `nombre_anterior`) VALUES ('shorthand',870,0,'short_hand');
INSERT INTO `bibtex_campo_catalogo` (`campo`, `orden`, `literal`, `nombre_anterior`) VALUES ('shorthandintro',880,0,'short_hand_intro');
INSERT INTO `bibtex_campo_catalogo` (`campo`, `orden`, `literal`, `nombre_anterior`) VALUES ('shorttitle',370,0,'short_title');
INSERT INTO `bibtex_campo_catalogo` (`campo`, `orden`, `literal`, `nombre_anterior`) VALUES ('sortkey',950,0,'sort_key');
INSERT INTO `bibtex_campo_catalogo` (`campo`, `orden`, `literal`, `nombre_anterior`) VALUES ('sortname',960,0,'sort_name');
INSERT INTO `bibtex_campo_catalogo` (`campo`, `orden`, `literal`, `nombre_anterior`) VALUES ('sortshorthand',970,0,'sort_hand');
INSERT INTO `bibtex_campo_catalogo` (`campo`, `orden`, `literal`, `nombre_anterior`) VALUES ('sorttitle',990,0,'sort_title');
INSERT INTO `bibtex_campo_catalogo` (`campo`, `orden`, `literal`, `nombre_anterior`) VALUES ('sortyear',980,0,'sort_year');
INSERT INTO `bibtex_campo_catalogo` (`campo`, `orden`, `literal`, `nombre_anterior`) VALUES ('subtitle',240,0,'sub_title');
INSERT INTO `bibtex_campo_catalogo` (`campo`, `orden`, `literal`, `nombre_anterior`) VALUES ('title',40,0,'title');
INSERT INTO `bibtex_campo_catalogo` (`campo`, `orden`, `literal`, `nombre_anterior`) VALUES ('titleaddon',230,0,'title_addon');
INSERT INTO `bibtex_campo_catalogo` (`campo`, `orden`, `literal`, `nombre_anterior`) VALUES ('translator',140,0,'translator');
INSERT INTO `bibtex_campo_catalogo` (`campo`, `orden`, `literal`, `nombre_anterior`) VALUES ('type',10,0,'tipo_de_tesis');
INSERT INTO `bibtex_campo_catalogo` (`campo`, `orden`, `literal`, `nombre_anterior`) VALUES ('url',710,1,'url');
INSERT INTO `bibtex_campo_catalogo` (`campo`, `orden`, `literal`, `nombre_anterior`) VALUES ('urldate',510,0,'url_date');
INSERT INTO `bibtex_campo_catalogo` (`campo`, `orden`, `literal`, `nombre_anterior`) VALUES ('venue',680,0,'venue');
INSERT INTO `bibtex_campo_catalogo` (`campo`, `orden`, `literal`, `nombre_anterior`) VALUES ('version',520,0,'version');
INSERT INTO `bibtex_campo_catalogo` (`campo`, `orden`, `literal`, `nombre_anterior`) VALUES ('volume',390,0,'volume');
INSERT INTO `bibtex_campo_catalogo` (`campo`, `orden`, `literal`, `nombre_anterior`) VALUES ('volumes',400,0,'volumes');
INSERT INTO `bibtex_campo_catalogo` (`campo`, `orden`, `literal`, `nombre_anterior`) VALUES ('xdata',930,0,'xdata');
INSERT INTO `bibtex_campo_catalogo` (`campo`, `orden`, `literal`, `nombre_anterior`) VALUES ('xref',920,0,'xref');
INSERT INTO `bibtex_campo_catalogo` (`campo`, `orden`, `literal`, `nombre_anterior`) VALUES ('year',470,0,'year');
INSERT INTO `formatos_pdf` (`id_formato_pdf`, `clasificacion`, `nombre_formato`, `ancho`, `alto`, `margen_interior`, `margen_exterior`, `margen_superior`, `margen_inferior`, `comentario`, `origen`, `activo`, `orden`) VALUES (1,'ISO','A6',10.50,14.80,1.49,1.49,1.49,1.49,'Bolsillo, novela ligera','sistema',1,10);
INSERT INTO `formatos_pdf` (`id_formato_pdf`, `clasificacion`, `nombre_formato`, `ancho`, `alto`, `margen_interior`, `margen_exterior`, `margen_superior`, `margen_inferior`, `comentario`, `origen`, `activo`, `orden`) VALUES (2,'ISO','A5',14.80,21.00,2.11,2.11,2.11,2.11,'Muy utilizado en Europa y Latinoamerica','sistema',1,20);
INSERT INTO `formatos_pdf` (`id_formato_pdf`, `clasificacion`, `nombre_formato`, `ancho`, `alto`, `margen_interior`, `margen_exterior`, `margen_superior`, `margen_inferior`, `comentario`, `origen`, `activo`, `orden`) VALUES (3,'ISO','B5 ISO',17.60,25.00,2.51,2.51,2.51,2.51,'Academico, revistas, manuales','sistema',1,30);
INSERT INTO `formatos_pdf` (`id_formato_pdf`, `clasificacion`, `nombre_formato`, `ancho`, `alto`, `margen_interior`, `margen_exterior`, `margen_superior`, `margen_inferior`, `comentario`, `origen`, `activo`, `orden`) VALUES (4,'ISO','A4',21.00,29.70,2.99,2.99,2.99,2.99,'Documentos, manuales tecnicos','sistema',1,40);
INSERT INTO `formatos_pdf` (`id_formato_pdf`, `clasificacion`, `nombre_formato`, `ancho`, `alto`, `margen_interior`, `margen_exterior`, `margen_superior`, `margen_inferior`, `comentario`, `origen`, `activo`, `orden`) VALUES (5,'US','Letter',21.59,27.94,2.94,2.94,2.94,2.94,'EEUU estandar de oficina','sistema',1,10);
INSERT INTO `formatos_pdf` (`id_formato_pdf`, `clasificacion`, `nombre_formato`, `ancho`, `alto`, `margen_interior`, `margen_exterior`, `margen_superior`, `margen_inferior`, `comentario`, `origen`, `activo`, `orden`) VALUES (6,'US','Legal',21.59,35.56,3.32,3.32,3.32,3.32,'EEUU documentos legales','sistema',1,20);
INSERT INTO `formatos_pdf` (`id_formato_pdf`, `clasificacion`, `nombre_formato`, `ancho`, `alto`, `margen_interior`, `margen_exterior`, `margen_superior`, `margen_inferior`, `comentario`, `origen`, `activo`, `orden`) VALUES (7,'US','Executive',18.41,26.67,2.65,2.65,2.65,2.65,'EEUU documentos ejecutivos','sistema',1,30);
INSERT INTO `formatos_pdf` (`id_formato_pdf`, `clasificacion`, `nombre_formato`, `ancho`, `alto`, `margen_interior`, `margen_exterior`, `margen_superior`, `margen_inferior`, `comentario`, `origen`, `activo`, `orden`) VALUES (8,'Editorial','A-Format (UK)',11.00,17.80,1.68,1.68,1.68,1.68,'UK paperback pequeno','sistema',1,10);
INSERT INTO `formatos_pdf` (`id_formato_pdf`, `clasificacion`, `nombre_formato`, `ancho`, `alto`, `margen_interior`, `margen_exterior`, `margen_superior`, `margen_inferior`, `comentario`, `origen`, `activo`, `orden`) VALUES (9,'Editorial','Pocket',11.00,17.80,1.68,1.68,1.68,1.68,'Bolsillo internacional','sistema',1,20);
INSERT INTO `formatos_pdf` (`id_formato_pdf`, `clasificacion`, `nombre_formato`, `ancho`, `alto`, `margen_interior`, `margen_exterior`, `margen_superior`, `margen_inferior`, `comentario`, `origen`, `activo`, `orden`) VALUES (10,'Editorial','Pocket Plus',11.00,18.00,1.69,1.69,1.69,1.69,'Variante de bolsillo','sistema',1,30);
INSERT INTO `formatos_pdf` (`id_formato_pdf`, `clasificacion`, `nombre_formato`, `ancho`, `alto`, `margen_interior`, `margen_exterior`, `margen_superior`, `margen_inferior`, `comentario`, `origen`, `activo`, `orden`) VALUES (11,'Editorial','Tall Mass Market',10.80,19.70,1.75,1.75,1.75,1.75,'Mass Market variante alta','sistema',1,40);
INSERT INTO `formatos_pdf` (`id_formato_pdf`, `clasificacion`, `nombre_formato`, `ancho`, `alto`, `margen_interior`, `margen_exterior`, `margen_superior`, `margen_inferior`, `comentario`, `origen`, `activo`, `orden`) VALUES (12,'Editorial','Mass Market',10.80,17.50,1.65,1.65,1.65,1.65,'Ficcion popular, bolsillo clasico','sistema',1,50);
INSERT INTO `formatos_pdf` (`id_formato_pdf`, `clasificacion`, `nombre_formato`, `ancho`, `alto`, `margen_interior`, `margen_exterior`, `margen_superior`, `margen_inferior`, `comentario`, `origen`, `activo`, `orden`) VALUES (13,'Editorial','B-Format (UK)',12.90,19.80,1.91,1.91,1.91,1.91,'Estandar UK (Penguin Classics)','sistema',1,60);
INSERT INTO `formatos_pdf` (`id_formato_pdf`, `clasificacion`, `nombre_formato`, `ancho`, `alto`, `margen_interior`, `margen_exterior`, `margen_superior`, `margen_inferior`, `comentario`, `origen`, `activo`, `orden`) VALUES (14,'Editorial','Trade Small',12.70,20.30,1.92,1.92,1.92,1.92,'5x8 pulg - novela comercial','sistema',1,70);
INSERT INTO `formatos_pdf` (`id_formato_pdf`, `clasificacion`, `nombre_formato`, `ancho`, `alto`, `margen_interior`, `margen_exterior`, `margen_superior`, `margen_inferior`, `comentario`, `origen`, `activo`, `orden`) VALUES (15,'Editorial','Demi',13.50,21.60,2.04,2.04,2.04,2.04,'5.3x8.5 pulg','sistema',1,80);
INSERT INTO `formatos_pdf` (`id_formato_pdf`, `clasificacion`, `nombre_formato`, `ancho`, `alto`, `margen_interior`, `margen_exterior`, `margen_superior`, `margen_inferior`, `comentario`, `origen`, `activo`, `orden`) VALUES (16,'Editorial','C-Format (UK)',13.50,21.60,2.04,2.04,2.04,2.04,'UK paperback grande','sistema',1,90);
INSERT INTO `formatos_pdf` (`id_formato_pdf`, `clasificacion`, `nombre_formato`, `ancho`, `alto`, `margen_interior`, `margen_exterior`, `margen_superior`, `margen_inferior`, `comentario`, `origen`, `activo`, `orden`) VALUES (17,'Editorial','Digest',14.00,21.60,2.08,2.08,2.08,2.08,'5.5x8.5 pulg - revistas, no ficcion','sistema',1,100);
INSERT INTO `formatos_pdf` (`id_formato_pdf`, `clasificacion`, `nombre_formato`, `ancho`, `alto`, `margen_interior`, `margen_exterior`, `margen_superior`, `margen_inferior`, `comentario`, `origen`, `activo`, `orden`) VALUES (18,'Editorial','Crown Octavo',14.60,22.20,2.16,2.16,2.16,2.16,'5.75x8.75 pulg - clasico editorial','sistema',1,110);
INSERT INTO `formatos_pdf` (`id_formato_pdf`, `clasificacion`, `nombre_formato`, `ancho`, `alto`, `margen_interior`, `margen_exterior`, `margen_superior`, `margen_inferior`, `comentario`, `origen`, `activo`, `orden`) VALUES (19,'Editorial','Trade',15.20,22.90,2.23,2.23,2.23,2.23,'6x9 pulg - novela general','sistema',1,120);
INSERT INTO `formatos_pdf` (`id_formato_pdf`, `clasificacion`, `nombre_formato`, `ancho`, `alto`, `margen_interior`, `margen_exterior`, `margen_superior`, `margen_inferior`, `comentario`, `origen`, `activo`, `orden`) VALUES (20,'Editorial','Royal',15.60,23.40,2.29,2.29,2.29,2.29,'6.14x9.21 pulg - ficcion premium','sistema',1,130);
INSERT INTO `formatos_pdf` (`id_formato_pdf`, `clasificacion`, `nombre_formato`, `ancho`, `alto`, `margen_interior`, `margen_exterior`, `margen_superior`, `margen_inferior`, `comentario`, `origen`, `activo`, `orden`) VALUES (21,'Editorial','Demy',16.00,24.00,2.35,2.35,2.35,2.35,'6.3x9.45 pulg - no ficcion, ensayos','sistema',1,140);
INSERT INTO `formatos_pdf` (`id_formato_pdf`, `clasificacion`, `nombre_formato`, `ancho`, `alto`, `margen_interior`, `margen_exterior`, `margen_superior`, `margen_inferior`, `comentario`, `origen`, `activo`, `orden`) VALUES (22,'Editorial','Comic / Graphic Novel',16.80,26.00,2.50,2.50,2.50,2.50,'6.63x10.25 pulg','sistema',1,150);
INSERT INTO `formatos_pdf` (`id_formato_pdf`, `clasificacion`, `nombre_formato`, `ancho`, `alto`, `margen_interior`, `margen_exterior`, `margen_superior`, `margen_inferior`, `comentario`, `origen`, `activo`, `orden`) VALUES (23,'Editorial','Executive',17.80,25.40,2.55,2.55,2.55,2.55,'7x10 pulg - no ficcion, negocios','sistema',1,160);
INSERT INTO `formatos_pdf` (`id_formato_pdf`, `clasificacion`, `nombre_formato`, `ancho`, `alto`, `margen_interior`, `margen_exterior`, `margen_superior`, `margen_inferior`, `comentario`, `origen`, `activo`, `orden`) VALUES (24,'Editorial','Large Trade',17.00,24.40,2.44,2.44,2.44,2.44,'6.69x9.61 pulg - edicion ampliada','sistema',1,170);
INSERT INTO `formatos_pdf` (`id_formato_pdf`, `clasificacion`, `nombre_formato`, `ancho`, `alto`, `margen_interior`, `margen_exterior`, `margen_superior`, `margen_inferior`, `comentario`, `origen`, `activo`, `orden`) VALUES (25,'Editorial','Crown Quarto',18.90,24.60,2.58,2.58,2.58,2.58,'7.44x9.69 pulg - ilustrado, referencia','sistema',1,180);
INSERT INTO `formatos_pdf` (`id_formato_pdf`, `clasificacion`, `nombre_formato`, `ancho`, `alto`, `margen_interior`, `margen_exterior`, `margen_superior`, `margen_inferior`, `comentario`, `origen`, `activo`, `orden`) VALUES (26,'Editorial','Textbook',19.00,24.50,2.58,2.58,2.58,2.58,'7.5x9.65 pulg - libros de texto','sistema',1,190);
INSERT INTO `formatos_pdf` (`id_formato_pdf`, `clasificacion`, `nombre_formato`, `ancho`, `alto`, `margen_interior`, `margen_exterior`, `margen_superior`, `margen_inferior`, `comentario`, `origen`, `activo`, `orden`) VALUES (27,'Editorial','US Textbook',20.30,25.40,2.72,2.72,2.72,2.72,'8x10 pulg - libros de texto US','sistema',1,200);
INSERT INTO `formatos_pdf` (`id_formato_pdf`, `clasificacion`, `nombre_formato`, `ancho`, `alto`, `margen_interior`, `margen_exterior`, `margen_superior`, `margen_inferior`, `comentario`, `origen`, `activo`, `orden`) VALUES (28,'Editorial','Workbook',21.60,27.90,2.94,2.94,2.94,2.94,'8.5x11 pulg - cuadernos de ejercicios','sistema',1,210);
INSERT INTO `formatos_pdf` (`id_formato_pdf`, `clasificacion`, `nombre_formato`, `ancho`, `alto`, `margen_interior`, `margen_exterior`, `margen_superior`, `margen_inferior`, `comentario`, `origen`, `activo`, `orden`) VALUES (29,'Editorial','Estudio 2A / 01',14.00,20.00,2.00,2.00,2.00,2.00,NULL,'sistema',1,220);
INSERT INTO `formatos_pdf` (`id_formato_pdf`, `clasificacion`, `nombre_formato`, `ancho`, `alto`, `margen_interior`, `margen_exterior`, `margen_superior`, `margen_inferior`, `comentario`, `origen`, `activo`, `orden`) VALUES (30,'Editorial','Estudio 2A / 02',15.00,22.00,2.00,2.00,2.00,2.00,NULL,'sistema',1,230);
INSERT INTO `formatos_pdf` (`id_formato_pdf`, `clasificacion`, `nombre_formato`, `ancho`, `alto`, `margen_interior`, `margen_exterior`, `margen_superior`, `margen_inferior`, `comentario`, `origen`, `activo`, `orden`) VALUES (31,'Editorial','Estudio 2A / 03',17.00,24.00,2.00,2.00,2.00,2.00,NULL,'sistema',1,240);
INSERT INTO `formatos_pdf` (`id_formato_pdf`, `clasificacion`, `nombre_formato`, `ancho`, `alto`, `margen_interior`, `margen_exterior`, `margen_superior`, `margen_inferior`, `comentario`, `origen`, `activo`, `orden`) VALUES (32,'Editorial','Estudio 2A / 04',15.50,23.00,2.00,2.00,2.00,2.00,NULL,'sistema',1,250);
INSERT INTO `formatos_pdf` (`id_formato_pdf`, `clasificacion`, `nombre_formato`, `ancho`, `alto`, `margen_interior`, `margen_exterior`, `margen_superior`, `margen_inferior`, `comentario`, `origen`, `activo`, `orden`) VALUES (33,'Editorial','Estudio 2A / 05',15.50,22.50,2.24,2.24,2.24,2.24,NULL,'sistema',1,260);
INSERT INTO `formatos_pdf` (`id_formato_pdf`, `clasificacion`, `nombre_formato`, `ancho`, `alto`, `margen_interior`, `margen_exterior`, `margen_superior`, `margen_inferior`, `comentario`, `origen`, `activo`, `orden`) VALUES (34,'Cuadrado','Square Small',17.00,17.00,2.04,2.04,2.04,2.04,'Albumes infantiles pequenos','sistema',1,10);
INSERT INTO `formatos_pdf` (`id_formato_pdf`, `clasificacion`, `nombre_formato`, `ancho`, `alto`, `margen_interior`, `margen_exterior`, `margen_superior`, `margen_inferior`, `comentario`, `origen`, `activo`, `orden`) VALUES (35,'Cuadrado','Square Medium',19.00,19.00,2.28,2.28,2.28,2.28,'Fotografia, diseno','sistema',1,20);
INSERT INTO `formatos_pdf` (`id_formato_pdf`, `clasificacion`, `nombre_formato`, `ancho`, `alto`, `margen_interior`, `margen_exterior`, `margen_superior`, `margen_inferior`, `comentario`, `origen`, `activo`, `orden`) VALUES (36,'Cuadrado','Square',21.00,21.00,2.51,2.51,2.51,2.51,'Estandar cuadrado','sistema',1,30);
INSERT INTO `formatos_pdf` (`id_formato_pdf`, `clasificacion`, `nombre_formato`, `ancho`, `alto`, `margen_interior`, `margen_exterior`, `margen_superior`, `margen_inferior`, `comentario`, `origen`, `activo`, `orden`) VALUES (37,'Cuadrado','Square Large',23.00,23.00,2.75,2.75,2.75,2.75,'Fotografia, arte','sistema',1,40);
INSERT INTO `formatos_pdf` (`id_formato_pdf`, `clasificacion`, `nombre_formato`, `ancho`, `alto`, `margen_interior`, `margen_exterior`, `margen_superior`, `margen_inferior`, `comentario`, `origen`, `activo`, `orden`) VALUES (38,'Cuadrado','Coffee Table Square',30.50,30.50,3.65,3.65,3.65,3.65,'12x12 pulg - mesa de centro','sistema',1,50);
INSERT INTO `formatos_pdf` (`id_formato_pdf`, `clasificacion`, `nombre_formato`, `ancho`, `alto`, `margen_interior`, `margen_exterior`, `margen_superior`, `margen_inferior`, `comentario`, `origen`, `activo`, `orden`) VALUES (39,'Arte','8 x 10',20.30,25.40,2.72,2.72,2.72,2.72,'Fotografia, retrato','sistema',1,10);
INSERT INTO `formatos_pdf` (`id_formato_pdf`, `clasificacion`, `nombre_formato`, `ancho`, `alto`, `margen_interior`, `margen_exterior`, `margen_superior`, `margen_inferior`, `comentario`, `origen`, `activo`, `orden`) VALUES (40,'Arte','8.5 x 11',21.59,27.94,2.94,2.94,2.94,2.94,'Letter - arte, portfolio','sistema',1,20);
INSERT INTO `formatos_pdf` (`id_formato_pdf`, `clasificacion`, `nombre_formato`, `ancho`, `alto`, `margen_interior`, `margen_exterior`, `margen_superior`, `margen_inferior`, `comentario`, `origen`, `activo`, `orden`) VALUES (41,'Arte','9 x 12',22.90,30.50,3.16,3.16,3.16,3.16,'Fotografia, ilustracion','sistema',1,30);
INSERT INTO `formatos_pdf` (`id_formato_pdf`, `clasificacion`, `nombre_formato`, `ancho`, `alto`, `margen_interior`, `margen_exterior`, `margen_superior`, `margen_inferior`, `comentario`, `origen`, `activo`, `orden`) VALUES (42,'Arte','10 x 10',25.40,25.40,3.04,3.04,3.04,3.04,'Cuadrado mediano','sistema',1,40);
INSERT INTO `formatos_pdf` (`id_formato_pdf`, `clasificacion`, `nombre_formato`, `ancho`, `alto`, `margen_interior`, `margen_exterior`, `margen_superior`, `margen_inferior`, `comentario`, `origen`, `activo`, `orden`) VALUES (43,'Arte','11 x 14',27.90,35.60,3.77,3.77,3.77,3.77,'Fotografia grande, galeria','sistema',1,50);
INSERT INTO `formatos_pdf` (`id_formato_pdf`, `clasificacion`, `nombre_formato`, `ancho`, `alto`, `margen_interior`, `margen_exterior`, `margen_superior`, `margen_inferior`, `comentario`, `origen`, `activo`, `orden`) VALUES (44,'Arte','Coffee Table (rect)',25.40,30.50,3.33,3.33,3.33,3.33,'10x12 pulg - arte, arquitectura','sistema',1,60);
INSERT INTO `formatos_pdf` (`id_formato_pdf`, `clasificacion`, `nombre_formato`, `ancho`, `alto`, `margen_interior`, `margen_exterior`, `margen_superior`, `margen_inferior`, `comentario`, `origen`, `activo`, `orden`) VALUES (45,'Custom','CUSTOM01',15.00,22.00,2.00,2.00,2.00,2.00,'Colección Archivos','custom',1,10);
INSERT INTO `credit_roles` (`id`, `nombre`, `descripcion`, `uri`) VALUES (1,'Conceptualization','Formulación de las ideas o los objetivos generales de la investigación.','https://credit.niso.org/contributor-roles/conceptualization/');
INSERT INTO `credit_roles` (`id`, `nombre`, `descripcion`, `uri`) VALUES (2,'Methodology','Desarrollo o diseño de la metodología; creación de modelos.','https://credit.niso.org/contributor-roles/methodology/');
INSERT INTO `credit_roles` (`id`, `nombre`, `descripcion`, `uri`) VALUES (3,'Software','Programación, desarrollo de software, validación de código, implementación.','https://credit.niso.org/contributor-roles/software/');
INSERT INTO `credit_roles` (`id`, `nombre`, `descripcion`, `uri`) VALUES (4,'Validation','Verificación de los resultados o de la reproducibilidad de los experimentos.','https://credit.niso.org/contributor-roles/validation/');
INSERT INTO `credit_roles` (`id`, `nombre`, `descripcion`, `uri`) VALUES (5,'Formal analysis','Aplicación de técnicas estadísticas, matemáticas o computacionales.','https://credit.niso.org/contributor-roles/formal-analysis/');
INSERT INTO `credit_roles` (`id`, `nombre`, `descripcion`, `uri`) VALUES (6,'Investigation','Realización de la investigación y proceso de recolección de datos.','https://credit.niso.org/contributor-roles/investigation/');
INSERT INTO `credit_roles` (`id`, `nombre`, `descripcion`, `uri`) VALUES (7,'Resources','Provisión de materiales, reactivos, equipamiento o infraestructura.','https://credit.niso.org/contributor-roles/resources/');
INSERT INTO `credit_roles` (`id`, `nombre`, `descripcion`, `uri`) VALUES (8,'Data curation','Gestión, limpieza y mantenimiento de los datos de investigación.','https://credit.niso.org/contributor-roles/data-curation/');
INSERT INTO `credit_roles` (`id`, `nombre`, `descripcion`, `uri`) VALUES (9,'Writing – original draft','Redacción del borrador inicial del manuscrito.','https://credit.niso.org/contributor-roles/writing-original-draft/');
INSERT INTO `credit_roles` (`id`, `nombre`, `descripcion`, `uri`) VALUES (10,'Writing – review & editing','Revisión crítica y edición del texto.','https://credit.niso.org/contributor-roles/writing-review-editing/');
INSERT INTO `credit_roles` (`id`, `nombre`, `descripcion`, `uri`) VALUES (11,'Visualization','Preparación de gráficos, figuras o visualizaciones de datos.','https://credit.niso.org/contributor-roles/visualization/');
INSERT INTO `credit_roles` (`id`, `nombre`, `descripcion`, `uri`) VALUES (12,'Supervision','Supervisión, dirección o tutoría de la investigación.','https://credit.niso.org/contributor-roles/supervision/');
INSERT INTO `credit_roles` (`id`, `nombre`, `descripcion`, `uri`) VALUES (13,'Project administration','Gestión y coordinación de la planificación del proyecto.','https://credit.niso.org/contributor-roles/project-administration/');
INSERT INTO `credit_roles` (`id`, `nombre`, `descripcion`, `uri`) VALUES (14,'Funding acquisition','Obtención de recursos financieros para la investigación.','https://credit.niso.org/contributor-roles/funding-acquisition/');
INSERT INTO `credit_rol_nombre` (`id_rol`, `idioma`, `nombre`) VALUES (1,'es','Conceptualización');
INSERT INTO `credit_rol_nombre` (`id_rol`, `idioma`, `nombre`) VALUES (1,'pt','Conceitualização');
INSERT INTO `credit_rol_nombre` (`id_rol`, `idioma`, `nombre`) VALUES (2,'es','Metodología');
INSERT INTO `credit_rol_nombre` (`id_rol`, `idioma`, `nombre`) VALUES (2,'pt','Metodologia');
INSERT INTO `credit_rol_nombre` (`id_rol`, `idioma`, `nombre`) VALUES (3,'es','Software');
INSERT INTO `credit_rol_nombre` (`id_rol`, `idioma`, `nombre`) VALUES (3,'pt','Software/programas de computador');
INSERT INTO `credit_rol_nombre` (`id_rol`, `idioma`, `nombre`) VALUES (4,'es','Validación');
INSERT INTO `credit_rol_nombre` (`id_rol`, `idioma`, `nombre`) VALUES (4,'pt','Validação');
INSERT INTO `credit_rol_nombre` (`id_rol`, `idioma`, `nombre`) VALUES (5,'es','Análisis formal');
INSERT INTO `credit_rol_nombre` (`id_rol`, `idioma`, `nombre`) VALUES (5,'pt','Análise formal');
INSERT INTO `credit_rol_nombre` (`id_rol`, `idioma`, `nombre`) VALUES (6,'es','Investigación');
INSERT INTO `credit_rol_nombre` (`id_rol`, `idioma`, `nombre`) VALUES (6,'pt','Investigação');
INSERT INTO `credit_rol_nombre` (`id_rol`, `idioma`, `nombre`) VALUES (7,'es','Recursos');
INSERT INTO `credit_rol_nombre` (`id_rol`, `idioma`, `nombre`) VALUES (7,'pt','Recursos');
INSERT INTO `credit_rol_nombre` (`id_rol`, `idioma`, `nombre`) VALUES (8,'es','Curación de datos');
INSERT INTO `credit_rol_nombre` (`id_rol`, `idioma`, `nombre`) VALUES (8,'pt','Curadoria de dados');
INSERT INTO `credit_rol_nombre` (`id_rol`, `idioma`, `nombre`) VALUES (9,'es','Redacción - borrador original');
INSERT INTO `credit_rol_nombre` (`id_rol`, `idioma`, `nombre`) VALUES (9,'pt','Escrita - esboço original');
INSERT INTO `credit_rol_nombre` (`id_rol`, `idioma`, `nombre`) VALUES (10,'es','Redacción - revisión y edición');
INSERT INTO `credit_rol_nombre` (`id_rol`, `idioma`, `nombre`) VALUES (10,'pt','Escrita - revisão e edição');
INSERT INTO `credit_rol_nombre` (`id_rol`, `idioma`, `nombre`) VALUES (11,'es','Visualización');
INSERT INTO `credit_rol_nombre` (`id_rol`, `idioma`, `nombre`) VALUES (11,'pt','Visualização');
INSERT INTO `credit_rol_nombre` (`id_rol`, `idioma`, `nombre`) VALUES (12,'es','Supervisión');
INSERT INTO `credit_rol_nombre` (`id_rol`, `idioma`, `nombre`) VALUES (12,'pt','Supervisão');
INSERT INTO `credit_rol_nombre` (`id_rol`, `idioma`, `nombre`) VALUES (13,'es','Administración del proyecto');
INSERT INTO `credit_rol_nombre` (`id_rol`, `idioma`, `nombre`) VALUES (13,'pt','Administração do projeto');
INSERT INTO `credit_rol_nombre` (`id_rol`, `idioma`, `nombre`) VALUES (14,'es','Captación de fondos');
INSERT INTO `credit_rol_nombre` (`id_rol`, `idioma`, `nombre`) VALUES (14,'pt','Aquisição de financiamento');
INSERT INTO `idiomas` (`id`, `codigo`, `nombre`, `nombre_ingles`, `babel`, `nivel`, `activo`, `orden`) VALUES (1,'aa','Qafar','Afar','afar',1,0,1000);
INSERT INTO `idiomas` (`id`, `codigo`, `nombre`, `nombre_ingles`, `babel`, `nivel`, `activo`, `orden`) VALUES (2,'ab','Аԥсшәа','Abkhazian','abkhazian',1,0,1000);
INSERT INTO `idiomas` (`id`, `codigo`, `nombre`, `nombre_ingles`, `babel`, `nivel`, `activo`, `orden`) VALUES (3,'ae','𐬎𐬞𐬀𐬯𐬙𐬀𐬎𐬎𐬀𐬐𐬀𐬉𐬥𐬀','Avestan','avestan',1,0,1000);
INSERT INTO `idiomas` (`id`, `codigo`, `nombre`, `nombre_ingles`, `babel`, `nivel`, `activo`, `orden`) VALUES (4,'af','Afrikaans','Afrikaans','afrikaans',1,0,1000);
INSERT INTO `idiomas` (`id`, `codigo`, `nombre`, `nombre_ingles`, `babel`, `nivel`, `activo`, `orden`) VALUES (5,'agq','Aghem','Aghem','aghem',1,0,1000);
INSERT INTO `idiomas` (`id`, `codigo`, `nombre`, `nombre_ingles`, `babel`, `nivel`, `activo`, `orden`) VALUES (6,'ak','Akan','Akan','akan',1,0,1000);
INSERT INTO `idiomas` (`id`, `codigo`, `nombre`, `nombre_ingles`, `babel`, `nivel`, `activo`, `orden`) VALUES (7,'akk','𒀝𒅗𒁺𒌑','Akkadian','akkadian',1,0,1000);
INSERT INTO `idiomas` (`id`, `codigo`, `nombre`, `nombre_ingles`, `babel`, `nivel`, `activo`, `orden`) VALUES (8,'alt','Southern Altai','Southern Altai','southernaltai',1,0,1000);
INSERT INTO `idiomas` (`id`, `codigo`, `nombre`, `nombre_ingles`, `babel`, `nivel`, `activo`, `orden`) VALUES (9,'am','አማርኛ','Amharic','amharic',1,0,1000);
INSERT INTO `idiomas` (`id`, `codigo`, `nombre`, `nombre_ingles`, `babel`, `nivel`, `activo`, `orden`) VALUES (10,'ar','العربية','Arabic','arabic',1,0,1000);
INSERT INTO `idiomas` (`id`, `codigo`, `nombre`, `nombre_ingles`, `babel`, `nivel`, `activo`, `orden`) VALUES (11,'ar-DZ','العربية','Arabic','arabic-algeria',1,0,1000);
INSERT INTO `idiomas` (`id`, `codigo`, `nombre`, `nombre_ingles`, `babel`, `nivel`, `activo`, `orden`) VALUES (12,'ar-EG','العربية','Arabic','arabic-egypt',1,0,1000);
INSERT INTO `idiomas` (`id`, `codigo`, `nombre`, `nombre_ingles`, `babel`, `nivel`, `activo`, `orden`) VALUES (13,'ar-IQ','العربية','Arabic','arabic-iraq',1,0,1000);
INSERT INTO `idiomas` (`id`, `codigo`, `nombre`, `nombre_ingles`, `babel`, `nivel`, `activo`, `orden`) VALUES (14,'ar-JO','العربية','Arabic','arabic-jordan',1,0,1000);
INSERT INTO `idiomas` (`id`, `codigo`, `nombre`, `nombre_ingles`, `babel`, `nivel`, `activo`, `orden`) VALUES (15,'ar-LB','العربية','Arabic','arabic-lebanon',1,0,1000);
INSERT INTO `idiomas` (`id`, `codigo`, `nombre`, `nombre_ingles`, `babel`, `nivel`, `activo`, `orden`) VALUES (16,'ar-MA','العربية','Arabic','arabic-morocco',1,0,1000);
INSERT INTO `idiomas` (`id`, `codigo`, `nombre`, `nombre_ingles`, `babel`, `nivel`, `activo`, `orden`) VALUES (17,'ar-PS','العربية','Arabic','arabic-palestinianterritories',1,0,1000);
INSERT INTO `idiomas` (`id`, `codigo`, `nombre`, `nombre_ingles`, `babel`, `nivel`, `activo`, `orden`) VALUES (18,'ar-SA','العربية','Arabic','arabic-saudiarabia',1,0,1000);
INSERT INTO `idiomas` (`id`, `codigo`, `nombre`, `nombre_ingles`, `babel`, `nivel`, `activo`, `orden`) VALUES (19,'ar-SY','العربية','Arabic','arabic-syria',1,0,1000);
INSERT INTO `idiomas` (`id`, `codigo`, `nombre`, `nombre_ingles`, `babel`, `nivel`, `activo`, `orden`) VALUES (20,'ar-TN','العربية','Arabic','arabic-tunisia',1,0,1000);
INSERT INTO `idiomas` (`id`, `codigo`, `nombre`, `nombre_ingles`, `babel`, `nivel`, `activo`, `orden`) VALUES (21,'arc','𐡀𐡓𐡌𐡉𐡀','Aramaic','aramaic',1,0,1000);
INSERT INTO `idiomas` (`id`, `codigo`, `nombre`, `nombre_ingles`, `babel`, `nivel`, `activo`, `orden`) VALUES (22,'arc-Nbat','Aramaic','Aramaic','aramaic-nabataean',1,0,1000);
INSERT INTO `idiomas` (`id`, `codigo`, `nombre`, `nombre_ingles`, `babel`, `nivel`, `activo`, `orden`) VALUES (23,'arc-Palm','Aramaic','Aramaic','aramaic-palmyrene',1,0,1000);
INSERT INTO `idiomas` (`id`, `codigo`, `nombre`, `nombre_ingles`, `babel`, `nivel`, `activo`, `orden`) VALUES (24,'arz','مصرى','Egyptian Arabic','egyptianarabic',1,0,1000);
INSERT INTO `idiomas` (`id`, `codigo`, `nombre`, `nombre_ingles`, `babel`, `nivel`, `activo`, `orden`) VALUES (25,'as','অসমীয়া','Assamese','assamese',1,0,1000);
INSERT INTO `idiomas` (`id`, `codigo`, `nombre`, `nombre_ingles`, `babel`, `nivel`, `activo`, `orden`) VALUES (26,'asa','Kipare','Asu','asu',1,0,1000);
INSERT INTO `idiomas` (`id`, `codigo`, `nombre`, `nombre_ingles`, `babel`, `nivel`, `activo`, `orden`) VALUES (27,'ast','asturianu','Asturian','asturian',1,0,1000);
INSERT INTO `idiomas` (`id`, `codigo`, `nombre`, `nombre_ingles`, `babel`, `nivel`, `activo`, `orden`) VALUES (28,'awa','अवधी','Awadhi','awadhi',1,0,1000);
INSERT INTO `idiomas` (`id`, `codigo`, `nombre`, `nombre_ingles`, `babel`, `nivel`, `activo`, `orden`) VALUES (29,'ay','aymar aru','Aymara','aymara',1,0,1000);
INSERT INTO `idiomas` (`id`, `codigo`, `nombre`, `nombre_ingles`, `babel`, `nivel`, `activo`, `orden`) VALUES (30,'az','azərbaycan','Azerbaijani','azerbaijani',1,0,1000);
INSERT INTO `idiomas` (`id`, `codigo`, `nombre`, `nombre_ingles`, `babel`, `nivel`, `activo`, `orden`) VALUES (31,'az-Cyrl','азәрбајҹан','Azerbaijani','azerbaijani-cyrillic',1,0,1000);
INSERT INTO `idiomas` (`id`, `codigo`, `nombre`, `nombre_ingles`, `babel`, `nivel`, `activo`, `orden`) VALUES (32,'az-Latn','azərbaycan','Azerbaijani','azerbaijani-latin',1,0,1000);
INSERT INTO `idiomas` (`id`, `codigo`, `nombre`, `nombre_ingles`, `babel`, `nivel`, `activo`, `orden`) VALUES (33,'ba','башҡорт теле','Bashkir','bashkir',1,0,1000);
INSERT INTO `idiomas` (`id`, `codigo`, `nombre`, `nombre_ingles`, `babel`, `nivel`, `activo`, `orden`) VALUES (34,'bal','بلۆچی','Baluchi','baluchi',1,0,1000);
INSERT INTO `idiomas` (`id`, `codigo`, `nombre`, `nombre_ingles`, `babel`, `nivel`, `activo`, `orden`) VALUES (35,'ban','Basa Bali','Balinese','balinese',1,0,1000);
INSERT INTO `idiomas` (`id`, `codigo`, `nombre`, `nombre_ingles`, `babel`, `nivel`, `activo`, `orden`) VALUES (36,'bar','Boarisch','Bavarian','bavarian',1,0,1000);
INSERT INTO `idiomas` (`id`, `codigo`, `nombre`, `nombre_ingles`, `babel`, `nivel`, `activo`, `orden`) VALUES (37,'bas','Ɓàsàa','Basaa','basaa',1,0,1000);
INSERT INTO `idiomas` (`id`, `codigo`, `nombre`, `nombre_ingles`, `babel`, `nivel`, `activo`, `orden`) VALUES (38,'bbc','ᯂᯖ ᯅᯖᯂ᯲ ᯖᯬᯅ','Batak Toba','bataktoba',1,0,1000);
INSERT INTO `idiomas` (`id`, `codigo`, `nombre`, `nombre_ingles`, `babel`, `nivel`, `activo`, `orden`) VALUES (39,'be','беларуская','Belarusian','belarusian',1,0,1000);
INSERT INTO `idiomas` (`id`, `codigo`, `nombre`, `nombre_ingles`, `babel`, `nivel`, `activo`, `orden`) VALUES (40,'bem','Ichibemba','Bemba','bemba',1,0,1000);
INSERT INTO `idiomas` (`id`, `codigo`, `nombre`, `nombre_ingles`, `babel`, `nivel`, `activo`, `orden`) VALUES (41,'bez','Hibena','Bena','bena',1,0,1000);
INSERT INTO `idiomas` (`id`, `codigo`, `nombre`, `nombre_ingles`, `babel`, `nivel`, `activo`, `orden`) VALUES (42,'bg','български','Bulgarian','bulgarian',1,0,1000);
INSERT INTO `idiomas` (`id`, `codigo`, `nombre`, `nombre_ingles`, `babel`, `nivel`, `activo`, `orden`) VALUES (43,'bgc','हरियाणवी','Haryanvi','haryanvi',1,0,1000);
INSERT INTO `idiomas` (`id`, `codigo`, `nombre`, `nombre_ingles`, `babel`, `nivel`, `activo`, `orden`) VALUES (44,'bho','भोजपुरी','Bhojpuri','bhojpuri',1,0,1000);
INSERT INTO `idiomas` (`id`, `codigo`, `nombre`, `nombre_ingles`, `babel`, `nivel`, `activo`, `orden`) VALUES (45,'bm','bamanakan','Bambara','bambara',1,0,1000);
INSERT INTO `idiomas` (`id`, `codigo`, `nombre`, `nombre_ingles`, `babel`, `nivel`, `activo`, `orden`) VALUES (46,'bn','বাংলা','Bangla','bangla',1,0,1000);
INSERT INTO `idiomas` (`id`, `codigo`, `nombre`, `nombre_ingles`, `babel`, `nivel`, `activo`, `orden`) VALUES (47,'bo','བོད་སྐད་','Tibetan','tibetan',1,0,1000);
INSERT INTO `idiomas` (`id`, `codigo`, `nombre`, `nombre_ingles`, `babel`, `nivel`, `activo`, `orden`) VALUES (48,'br','brezhoneg','Breton','breton',1,0,1000);
INSERT INTO `idiomas` (`id`, `codigo`, `nombre`, `nombre_ingles`, `babel`, `nivel`, `activo`, `orden`) VALUES (49,'brx','बर’','Bodo','bodo',1,0,1000);
INSERT INTO `idiomas` (`id`, `codigo`, `nombre`, `nombre_ingles`, `babel`, `nivel`, `activo`, `orden`) VALUES (50,'bs','bosanski','Bosnian','bosnian',1,0,1000);
INSERT INTO `idiomas` (`id`, `codigo`, `nombre`, `nombre_ingles`, `babel`, `nivel`, `activo`, `orden`) VALUES (51,'bs-Cyrl','босански','Bosnian','bosnian-cyrillic',1,0,1000);
INSERT INTO `idiomas` (`id`, `codigo`, `nombre`, `nombre_ingles`, `babel`, `nivel`, `activo`, `orden`) VALUES (52,'bs-Latn','bosanski','Bosnian','bosnian-latin',1,0,1000);
INSERT INTO `idiomas` (`id`, `codigo`, `nombre`, `nombre_ingles`, `babel`, `nivel`, `activo`, `orden`) VALUES (53,'bua','Буряад','Buriat','buriat',1,0,1000);
INSERT INTO `idiomas` (`id`, `codigo`, `nombre`, `nombre_ingles`, `babel`, `nivel`, `activo`, `orden`) VALUES (54,'byn','ብሊን','Blin','blin',1,0,1000);
INSERT INTO `idiomas` (`id`, `codigo`, `nombre`, `nombre_ingles`, `babel`, `nivel`, `activo`, `orden`) VALUES (55,'ca','català','Catalan','catalan',1,1,70);
INSERT INTO `idiomas` (`id`, `codigo`, `nombre`, `nombre_ingles`, `babel`, `nivel`, `activo`, `orden`) VALUES (56,'cch','Atsam','Atsam','atsam',1,0,1000);
INSERT INTO `idiomas` (`id`, `codigo`, `nombre`, `nombre_ingles`, `babel`, `nivel`, `activo`, `orden`) VALUES (57,'ccp','𑄌𑄋𑄴𑄟𑄳𑄦','Chakma','chakma',1,0,1000);
INSERT INTO `idiomas` (`id`, `codigo`, `nombre`, `nombre_ingles`, `babel`, `nivel`, `activo`, `orden`) VALUES (58,'ce','нохчийн','Chechen','chechen',1,0,1000);
INSERT INTO `idiomas` (`id`, `codigo`, `nombre`, `nombre_ingles`, `babel`, `nivel`, `activo`, `orden`) VALUES (59,'ceb','Cebuano','Cebuano','cebuano',1,0,1000);
INSERT INTO `idiomas` (`id`, `codigo`, `nombre`, `nombre_ingles`, `babel`, `nivel`, `activo`, `orden`) VALUES (60,'cgg','Rukiga','Chiga','chiga',1,0,1000);
INSERT INTO `idiomas` (`id`, `codigo`, `nombre`, `nombre_ingles`, `babel`, `nivel`, `activo`, `orden`) VALUES (61,'chr','ᏣᎳᎩ','Cherokee','cherokee',1,0,1000);
INSERT INTO `idiomas` (`id`, `codigo`, `nombre`, `nombre_ingles`, `babel`, `nivel`, `activo`, `orden`) VALUES (62,'ckb','کوردیی ناوەندی','Central Kurdish','sorani',1,0,1000);
INSERT INTO `idiomas` (`id`, `codigo`, `nombre`, `nombre_ingles`, `babel`, `nivel`, `activo`, `orden`) VALUES (63,'ckb-Arab','کوردیی ناوەندی','Central Kurdish','sorani',1,0,1000);
INSERT INTO `idiomas` (`id`, `codigo`, `nombre`, `nombre_ingles`, `babel`, `nivel`, `activo`, `orden`) VALUES (64,'ckb-Latn','Kurdîy nawendî','Central Kurdish','sorani',1,0,1000);
INSERT INTO `idiomas` (`id`, `codigo`, `nombre`, `nombre_ingles`, `babel`, `nivel`, `activo`, `orden`) VALUES (65,'co','corsu','Corsican','corsican',1,0,1000);
INSERT INTO `idiomas` (`id`, `codigo`, `nombre`, `nombre_ingles`, `babel`, `nivel`, `activo`, `orden`) VALUES (66,'cop','ϯⲙⲉⲧⲣⲉⲙⲛ̀ⲭⲏⲙⲓ','Coptic','coptic',1,0,1000);
INSERT INTO `idiomas` (`id`, `codigo`, `nombre`, `nombre_ingles`, `babel`, `nivel`, `activo`, `orden`) VALUES (67,'cs','čeština','Czech','czech',1,0,1000);
INSERT INTO `idiomas` (`id`, `codigo`, `nombre`, `nombre_ingles`, `babel`, `nivel`, `activo`, `orden`) VALUES (68,'cu','црькъвьнословѣньскъ ѩзыкъ','Church Slavic','churchslavic',1,0,1000);
INSERT INTO `idiomas` (`id`, `codigo`, `nombre`, `nombre_ingles`, `babel`, `nivel`, `activo`, `orden`) VALUES (69,'cu-Cyrs','словѣ́ньскъ ѩꙁꙑ́къ','Church Slavic','churchslavic-oldcyrillic',1,0,1000);
INSERT INTO `idiomas` (`id`, `codigo`, `nombre`, `nombre_ingles`, `babel`, `nivel`, `activo`, `orden`) VALUES (70,'cu-Glag','ⰔⰎⰑⰂⰡⰐⰠⰔⰍⰟ ⰧⰈⰟⰊⰍⰟ','Church Slavic','churchslavic-glagolitic',0,0,1000);
INSERT INTO `idiomas` (`id`, `codigo`, `nombre`, `nombre_ingles`, `babel`, `nivel`, `activo`, `orden`) VALUES (71,'cv','чӑваш','Chuvash','chuvash',1,0,1000);
INSERT INTO `idiomas` (`id`, `codigo`, `nombre`, `nombre_ingles`, `babel`, `nivel`, `activo`, `orden`) VALUES (72,'cy','Cymraeg','Welsh','welsh',1,0,1000);
INSERT INTO `idiomas` (`id`, `codigo`, `nombre`, `nombre_ingles`, `babel`, `nivel`, `activo`, `orden`) VALUES (73,'da','dansk','Danish','danish',1,0,1000);
INSERT INTO `idiomas` (`id`, `codigo`, `nombre`, `nombre_ingles`, `babel`, `nivel`, `activo`, `orden`) VALUES (74,'dav','Kitaita','Taita','taita',1,0,1000);
INSERT INTO `idiomas` (`id`, `codigo`, `nombre`, `nombre_ingles`, `babel`, `nivel`, `activo`, `orden`) VALUES (75,'de','Deutsch','German','ngerman',1,1,50);
INSERT INTO `idiomas` (`id`, `codigo`, `nombre`, `nombre_ingles`, `babel`, `nivel`, `activo`, `orden`) VALUES (76,'de-1901','Deutsch','German','german',1,0,1000);
INSERT INTO `idiomas` (`id`, `codigo`, `nombre`, `nombre_ingles`, `babel`, `nivel`, `activo`, `orden`) VALUES (77,'de-1996','Deutsch','German','ngerman',1,0,1000);
INSERT INTO `idiomas` (`id`, `codigo`, `nombre`, `nombre_ingles`, `babel`, `nivel`, `activo`, `orden`) VALUES (78,'de-AT','Österreichisches Deutsch','Austrian German','austrian',1,0,1000);
INSERT INTO `idiomas` (`id`, `codigo`, `nombre`, `nombre_ingles`, `babel`, `nivel`, `activo`, `orden`) VALUES (79,'de-AT-1901','Österreichisches Deutsch','Austrian German','austrian-traditional',1,0,1000);
INSERT INTO `idiomas` (`id`, `codigo`, `nombre`, `nombre_ingles`, `babel`, `nivel`, `activo`, `orden`) VALUES (80,'de-AT-1996','Österreichisches Deutsch','Austrian German','austrian',1,0,1000);
INSERT INTO `idiomas` (`id`, `codigo`, `nombre`, `nombre_ingles`, `babel`, `nivel`, `activo`, `orden`) VALUES (81,'de-CH','Schweizer Hochdeutsch','Swiss High German','german-switzerland',1,0,1000);
INSERT INTO `idiomas` (`id`, `codigo`, `nombre`, `nombre_ingles`, `babel`, `nivel`, `activo`, `orden`) VALUES (82,'de-CH-1901','Schweizer Hochdeutsch','Swiss High German','german-switzerland-traditional',1,0,1000);
INSERT INTO `idiomas` (`id`, `codigo`, `nombre`, `nombre_ingles`, `babel`, `nivel`, `activo`, `orden`) VALUES (83,'de-CH-1996','Schweizer Hochdeutsch','Swiss High German','german-switzerland',1,0,1000);
INSERT INTO `idiomas` (`id`, `codigo`, `nombre`, `nombre_ingles`, `babel`, `nivel`, `activo`, `orden`) VALUES (84,'dje','Zarmaciine','Zarma','zarma',1,0,1000);
INSERT INTO `idiomas` (`id`, `codigo`, `nombre`, `nombre_ingles`, `babel`, `nivel`, `activo`, `orden`) VALUES (85,'doi','डोगरी','Dogri','dogri',1,0,1000);
INSERT INTO `idiomas` (`id`, `codigo`, `nombre`, `nombre_ingles`, `babel`, `nivel`, `activo`, `orden`) VALUES (86,'dsb','dolnoserbšćina','Lower Sorbian','lowersorbian',1,0,1000);
INSERT INTO `idiomas` (`id`, `codigo`, `nombre`, `nombre_ingles`, `babel`, `nivel`, `activo`, `orden`) VALUES (87,'dua','duálá','Duala','duala',1,0,1000);
INSERT INTO `idiomas` (`id`, `codigo`, `nombre`, `nombre_ingles`, `babel`, `nivel`, `activo`, `orden`) VALUES (88,'dv','ދިވެހިބަސް','Divehi','divehi',1,0,1000);
INSERT INTO `idiomas` (`id`, `codigo`, `nombre`, `nombre_ingles`, `babel`, `nivel`, `activo`, `orden`) VALUES (89,'dyo','joola','Jola-Fonyi','jolafonyi',1,0,1000);
INSERT INTO `idiomas` (`id`, `codigo`, `nombre`, `nombre_ingles`, `babel`, `nivel`, `activo`, `orden`) VALUES (90,'dz','རྫོང་ཁ','Dzongkha','dzongkha',1,0,1000);
INSERT INTO `idiomas` (`id`, `codigo`, `nombre`, `nombre_ingles`, `babel`, `nivel`, `activo`, `orden`) VALUES (91,'ebu','Kĩembu','Embu','embu',1,0,1000);
INSERT INTO `idiomas` (`id`, `codigo`, `nombre`, `nombre_ingles`, `babel`, `nivel`, `activo`, `orden`) VALUES (92,'ee','Eʋegbe','Ewe','ewe',1,0,1000);
INSERT INTO `idiomas` (`id`, `codigo`, `nombre`, `nombre_ingles`, `babel`, `nivel`, `activo`, `orden`) VALUES (93,'egy','𓂋𓏺𓈖 𓆎𓅓𓏏𓊖','Ancient Egyptian','ancientegyptian',1,0,1000);
INSERT INTO `idiomas` (`id`, `codigo`, `nombre`, `nombre_ingles`, `babel`, `nivel`, `activo`, `orden`) VALUES (94,'el','Ελληνικά','Greek','greek',1,0,1000);
INSERT INTO `idiomas` (`id`, `codigo`, `nombre`, `nombre_ingles`, `babel`, `nivel`, `activo`, `orden`) VALUES (95,'el-polyton','Ἐλληνικά','Polytonic Greek','polytonicgreek',1,0,1000);
INSERT INTO `idiomas` (`id`, `codigo`, `nombre`, `nombre_ingles`, `babel`, `nivel`, `activo`, `orden`) VALUES (96,'en','English','English','english',1,1,30);
INSERT INTO `idiomas` (`id`, `codigo`, `nombre`, `nombre_ingles`, `babel`, `nivel`, `activo`, `orden`) VALUES (97,'en-AU','Australian English','Australian English','english-australia',1,0,1000);
INSERT INTO `idiomas` (`id`, `codigo`, `nombre`, `nombre_ingles`, `babel`, `nivel`, `activo`, `orden`) VALUES (98,'en-CA','Canadian English','Canadian English','canadian',1,0,1000);
INSERT INTO `idiomas` (`id`, `codigo`, `nombre`, `nombre_ingles`, `babel`, `nivel`, `activo`, `orden`) VALUES (99,'en-GB','British English','British English','british',1,0,1000);
INSERT INTO `idiomas` (`id`, `codigo`, `nombre`, `nombre_ingles`, `babel`, `nivel`, `activo`, `orden`) VALUES (100,'en-NZ','English','English','english-newzealand',1,0,1000);
INSERT INTO `idiomas` (`id`, `codigo`, `nombre`, `nombre_ingles`, `babel`, `nivel`, `activo`, `orden`) VALUES (101,'en-US','American English','American English','american',1,0,1000);
INSERT INTO `idiomas` (`id`, `codigo`, `nombre`, `nombre_ingles`, `babel`, `nivel`, `activo`, `orden`) VALUES (102,'eo','esperanto','Esperanto','esperanto',1,0,1000);
INSERT INTO `idiomas` (`id`, `codigo`, `nombre`, `nombre_ingles`, `babel`, `nivel`, `activo`, `orden`) VALUES (103,'es','español','Spanish','spanish',1,1,10);
INSERT INTO `idiomas` (`id`, `codigo`, `nombre`, `nombre_ingles`, `babel`, `nivel`, `activo`, `orden`) VALUES (104,'es-MX','español de México','Mexican Spanish','mexican',1,0,1000);
INSERT INTO `idiomas` (`id`, `codigo`, `nombre`, `nombre_ingles`, `babel`, `nivel`, `activo`, `orden`) VALUES (105,'et','eesti','Estonian','estonian',1,0,1000);
INSERT INTO `idiomas` (`id`, `codigo`, `nombre`, `nombre_ingles`, `babel`, `nivel`, `activo`, `orden`) VALUES (106,'eu','euskara','Basque','basque',1,1,90);
INSERT INTO `idiomas` (`id`, `codigo`, `nombre`, `nombre_ingles`, `babel`, `nivel`, `activo`, `orden`) VALUES (107,'ewo','ewondo','Ewondo','ewondo',1,0,1000);
INSERT INTO `idiomas` (`id`, `codigo`, `nombre`, `nombre_ingles`, `babel`, `nivel`, `activo`, `orden`) VALUES (108,'fa','فارسی','Persian','persian',1,0,1000);
INSERT INTO `idiomas` (`id`, `codigo`, `nombre`, `nombre_ingles`, `babel`, `nivel`, `activo`, `orden`) VALUES (109,'ff','Pulaar','Fulah','fulah',1,0,1000);
INSERT INTO `idiomas` (`id`, `codigo`, `nombre`, `nombre_ingles`, `babel`, `nivel`, `activo`, `orden`) VALUES (110,'fi','suomi','Finnish','finnish',1,0,1000);
INSERT INTO `idiomas` (`id`, `codigo`, `nombre`, `nombre_ingles`, `babel`, `nivel`, `activo`, `orden`) VALUES (111,'fil','Filipino','Filipino','filipino',1,0,1000);
INSERT INTO `idiomas` (`id`, `codigo`, `nombre`, `nombre_ingles`, `babel`, `nivel`, `activo`, `orden`) VALUES (112,'fo','føroyskt','Faroese','faroese',1,0,1000);
INSERT INTO `idiomas` (`id`, `codigo`, `nombre`, `nombre_ingles`, `babel`, `nivel`, `activo`, `orden`) VALUES (113,'fr','français','French','french',1,1,40);
INSERT INTO `idiomas` (`id`, `codigo`, `nombre`, `nombre_ingles`, `babel`, `nivel`, `activo`, `orden`) VALUES (114,'fr-BE','français','French','french-belgium',1,0,1000);
INSERT INTO `idiomas` (`id`, `codigo`, `nombre`, `nombre_ingles`, `babel`, `nivel`, `activo`, `orden`) VALUES (115,'fr-CA','français canadien','Canadian French','canadien',1,0,1000);
INSERT INTO `idiomas` (`id`, `codigo`, `nombre`, `nombre_ingles`, `babel`, `nivel`, `activo`, `orden`) VALUES (116,'fr-CH','français suisse','Swiss French','french-switzerland',1,0,1000);
INSERT INTO `idiomas` (`id`, `codigo`, `nombre`, `nombre_ingles`, `babel`, `nivel`, `activo`, `orden`) VALUES (117,'fr-LU','français','French','french-luxembourg',1,0,1000);
INSERT INTO `idiomas` (`id`, `codigo`, `nombre`, `nombre_ingles`, `babel`, `nivel`, `activo`, `orden`) VALUES (118,'fr-x-acadian','acadien','Acadian','acadian',1,0,1000);
INSERT INTO `idiomas` (`id`, `codigo`, `nombre`, `nombre_ingles`, `babel`, `nivel`, `activo`, `orden`) VALUES (119,'frr','Nordfriisk','Northern Frisian','northernfrisian',1,0,1000);
INSERT INTO `idiomas` (`id`, `codigo`, `nombre`, `nombre_ingles`, `babel`, `nivel`, `activo`, `orden`) VALUES (120,'fur','furlan','Friulian','friulian',1,0,1000);
INSERT INTO `idiomas` (`id`, `codigo`, `nombre`, `nombre_ingles`, `babel`, `nivel`, `activo`, `orden`) VALUES (121,'fy','Frysk','Western Frisian','westernfrisian',1,0,1000);
INSERT INTO `idiomas` (`id`, `codigo`, `nombre`, `nombre_ingles`, `babel`, `nivel`, `activo`, `orden`) VALUES (122,'ga','Gaeilge','Irish','irish',1,0,1000);
INSERT INTO `idiomas` (`id`, `codigo`, `nombre`, `nombre_ingles`, `babel`, `nivel`, `activo`, `orden`) VALUES (123,'gaa','Gã','Ga','ga',1,0,1000);
INSERT INTO `idiomas` (`id`, `codigo`, `nombre`, `nombre_ingles`, `babel`, `nivel`, `activo`, `orden`) VALUES (124,'gd','Gàidhlig','Scottish Gaelic','scottishgaelic',1,0,1000);
INSERT INTO `idiomas` (`id`, `codigo`, `nombre`, `nombre_ingles`, `babel`, `nivel`, `activo`, `orden`) VALUES (125,'gez','ግዕዝኛ','Geez','geez',1,0,1000);
INSERT INTO `idiomas` (`id`, `codigo`, `nombre`, `nombre_ingles`, `babel`, `nivel`, `activo`, `orden`) VALUES (126,'gl','galego','Galician','galician',1,1,80);
INSERT INTO `idiomas` (`id`, `codigo`, `nombre`, `nombre_ingles`, `babel`, `nivel`, `activo`, `orden`) VALUES (127,'gn','avañe’ẽ','Guarani','guarani',1,1,110);
INSERT INTO `idiomas` (`id`, `codigo`, `nombre`, `nombre_ingles`, `babel`, `nivel`, `activo`, `orden`) VALUES (128,'got','𐌲𐌿𐍄𐌹𐍃𐌺','Gothic','gothic',1,0,1000);
INSERT INTO `idiomas` (`id`, `codigo`, `nombre`, `nombre_ingles`, `babel`, `nivel`, `activo`, `orden`) VALUES (129,'grc','Αρχαία ελληνικά','Ancient Greek','ancientgreek',1,0,1000);
INSERT INTO `idiomas` (`id`, `codigo`, `nombre`, `nombre_ingles`, `babel`, `nivel`, `activo`, `orden`) VALUES (130,'gsw','Schwiizertüütsch','Swiss German','swissgerman',1,0,1000);
INSERT INTO `idiomas` (`id`, `codigo`, `nombre`, `nombre_ingles`, `babel`, `nivel`, `activo`, `orden`) VALUES (131,'gu','ગુજરાતી','Gujarati','gujarati',1,0,1000);
INSERT INTO `idiomas` (`id`, `codigo`, `nombre`, `nombre_ingles`, `babel`, `nivel`, `activo`, `orden`) VALUES (132,'guz','Ekegusii','Gusii','gusii',1,0,1000);
INSERT INTO `idiomas` (`id`, `codigo`, `nombre`, `nombre_ingles`, `babel`, `nivel`, `activo`, `orden`) VALUES (133,'gv','Gaelg','Manx','manx',1,0,1000);
INSERT INTO `idiomas` (`id`, `codigo`, `nombre`, `nombre_ingles`, `babel`, `nivel`, `activo`, `orden`) VALUES (134,'ha','Hausa','Hausa','hausa',1,0,1000);
INSERT INTO `idiomas` (`id`, `codigo`, `nombre`, `nombre_ingles`, `babel`, `nivel`, `activo`, `orden`) VALUES (135,'ha-GH','Hausa','Hausa','hausa-ghana',1,0,1000);
INSERT INTO `idiomas` (`id`, `codigo`, `nombre`, `nombre_ingles`, `babel`, `nivel`, `activo`, `orden`) VALUES (136,'ha-NE','Hausa','Hausa','hausa-niger',1,0,1000);
INSERT INTO `idiomas` (`id`, `codigo`, `nombre`, `nombre_ingles`, `babel`, `nivel`, `activo`, `orden`) VALUES (137,'haw','ʻŌlelo Hawaiʻi','Hawaiian','hawaiian',1,0,1000);
INSERT INTO `idiomas` (`id`, `codigo`, `nombre`, `nombre_ingles`, `babel`, `nivel`, `activo`, `orden`) VALUES (138,'he','עברית','Hebrew','hebrew',1,0,1000);
INSERT INTO `idiomas` (`id`, `codigo`, `nombre`, `nombre_ingles`, `babel`, `nivel`, `activo`, `orden`) VALUES (139,'hi','हिन्दी','Hindi','hindi',1,0,1000);
INSERT INTO `idiomas` (`id`, `codigo`, `nombre`, `nombre_ingles`, `babel`, `nivel`, `activo`, `orden`) VALUES (140,'hnj','𞄀𞄄𞄰𞄩𞄍𞄜𞄰','Hmong Njua','hmongnjua',1,0,1000);
INSERT INTO `idiomas` (`id`, `codigo`, `nombre`, `nombre_ingles`, `babel`, `nivel`, `activo`, `orden`) VALUES (141,'hr','hrvatski','Croatian','croatian',1,0,1000);
INSERT INTO `idiomas` (`id`, `codigo`, `nombre`, `nombre_ingles`, `babel`, `nivel`, `activo`, `orden`) VALUES (142,'hsb','hornjoserbšćina','Upper Sorbian','uppersorbian',1,0,1000);
INSERT INTO `idiomas` (`id`, `codigo`, `nombre`, `nombre_ingles`, `babel`, `nivel`, `activo`, `orden`) VALUES (143,'hu','magyar','Hungarian','hungarian',1,0,1000);
INSERT INTO `idiomas` (`id`, `codigo`, `nombre`, `nombre_ingles`, `babel`, `nivel`, `activo`, `orden`) VALUES (144,'hy','հայերեն','Armenian','armenian',1,0,1000);
INSERT INTO `idiomas` (`id`, `codigo`, `nombre`, `nombre_ingles`, `babel`, `nivel`, `activo`, `orden`) VALUES (145,'ia','Interlingua','Interlingua','interlingua',1,0,1000);
INSERT INTO `idiomas` (`id`, `codigo`, `nombre`, `nombre_ingles`, `babel`, `nivel`, `activo`, `orden`) VALUES (146,'id','Indonesia','Indonesian','indonesian',1,0,1000);
INSERT INTO `idiomas` (`id`, `codigo`, `nombre`, `nombre_ingles`, `babel`, `nivel`, `activo`, `orden`) VALUES (147,'ig','Igbo','Igbo','igbo',1,0,1000);
INSERT INTO `idiomas` (`id`, `codigo`, `nombre`, `nombre_ingles`, `babel`, `nivel`, `activo`, `orden`) VALUES (148,'ii','ꆈꌠꉙ','Sichuan Yi','sichuanyi',1,0,1000);
INSERT INTO `idiomas` (`id`, `codigo`, `nombre`, `nombre_ingles`, `babel`, `nivel`, `activo`, `orden`) VALUES (149,'inh','гӀалгӀай мотт','Ingush','ingush',1,0,1000);
INSERT INTO `idiomas` (`id`, `codigo`, `nombre`, `nombre_ingles`, `babel`, `nivel`, `activo`, `orden`) VALUES (150,'is','íslenska','Icelandic','icelandic',1,0,1000);
INSERT INTO `idiomas` (`id`, `codigo`, `nombre`, `nombre_ingles`, `babel`, `nivel`, `activo`, `orden`) VALUES (151,'it','italiano','Italian','italian',1,1,60);
INSERT INTO `idiomas` (`id`, `codigo`, `nombre`, `nombre_ingles`, `babel`, `nivel`, `activo`, `orden`) VALUES (152,'iu','ᐃᓄᒃᑎᑐᑦ','Inuktitut','inuktitut',1,0,1000);
INSERT INTO `idiomas` (`id`, `codigo`, `nombre`, `nombre_ingles`, `babel`, `nivel`, `activo`, `orden`) VALUES (153,'ja','日本語','Japanese','japanese',1,0,1000);
INSERT INTO `idiomas` (`id`, `codigo`, `nombre`, `nombre_ingles`, `babel`, `nivel`, `activo`, `orden`) VALUES (154,'jgo','Ndaꞌa','Ngomba','ngomba',1,0,1000);
INSERT INTO `idiomas` (`id`, `codigo`, `nombre`, `nombre_ingles`, `babel`, `nivel`, `activo`, `orden`) VALUES (155,'jmc','Kimachame','Machame','machame',1,0,1000);
INSERT INTO `idiomas` (`id`, `codigo`, `nombre`, `nombre_ingles`, `babel`, `nivel`, `activo`, `orden`) VALUES (156,'jv','Jawa','Javanese','javanese',1,0,1000);
INSERT INTO `idiomas` (`id`, `codigo`, `nombre`, `nombre_ingles`, `babel`, `nivel`, `activo`, `orden`) VALUES (157,'ka','ქართული','Georgian','georgian',1,0,1000);
INSERT INTO `idiomas` (`id`, `codigo`, `nombre`, `nombre_ingles`, `babel`, `nivel`, `activo`, `orden`) VALUES (158,'kab','Taqbaylit','Kabyle','kabyle',1,0,1000);
INSERT INTO `idiomas` (`id`, `codigo`, `nombre`, `nombre_ingles`, `babel`, `nivel`, `activo`, `orden`) VALUES (159,'kaj','Kaje','Jju','jju',1,0,1000);
INSERT INTO `idiomas` (`id`, `codigo`, `nombre`, `nombre_ingles`, `babel`, `nivel`, `activo`, `orden`) VALUES (160,'kam','Kikamba','Kamba','kamba',1,0,1000);
INSERT INTO `idiomas` (`id`, `codigo`, `nombre`, `nombre_ingles`, `babel`, `nivel`, `activo`, `orden`) VALUES (161,'kcg','Katab','Tyap','tyap',1,0,1000);
INSERT INTO `idiomas` (`id`, `codigo`, `nombre`, `nombre_ingles`, `babel`, `nivel`, `activo`, `orden`) VALUES (162,'kde','Chimakonde','Makonde','makonde',1,0,1000);
INSERT INTO `idiomas` (`id`, `codigo`, `nombre`, `nombre_ingles`, `babel`, `nivel`, `activo`, `orden`) VALUES (163,'kea','kabuverdianu','Kabuverdianu','kabuverdianu',1,0,1000);
INSERT INTO `idiomas` (`id`, `codigo`, `nombre`, `nombre_ingles`, `babel`, `nivel`, `activo`, `orden`) VALUES (164,'kgp','kanhgág','Kaingang','kaingang',1,0,1000);
INSERT INTO `idiomas` (`id`, `codigo`, `nombre`, `nombre_ingles`, `babel`, `nivel`, `activo`, `orden`) VALUES (165,'khb','ᦅᧄᦺᦑᦟᦹᧉ','Lü','lu',1,0,1000);
INSERT INTO `idiomas` (`id`, `codigo`, `nombre`, `nombre_ingles`, `babel`, `nivel`, `activo`, `orden`) VALUES (166,'khq','Koyra ciini','Koyra Chiini','koyrachiini',1,0,1000);
INSERT INTO `idiomas` (`id`, `codigo`, `nombre`, `nombre_ingles`, `babel`, `nivel`, `activo`, `orden`) VALUES (167,'ki','Gikuyu','Kikuyu','kikuyu',1,0,1000);
INSERT INTO `idiomas` (`id`, `codigo`, `nombre`, `nombre_ingles`, `babel`, `nivel`, `activo`, `orden`) VALUES (168,'kk','қазақ тілі','Kazakh','kazakh',1,0,1000);
INSERT INTO `idiomas` (`id`, `codigo`, `nombre`, `nombre_ingles`, `babel`, `nivel`, `activo`, `orden`) VALUES (169,'kkj','kakɔ','Kako','kako',1,0,1000);
INSERT INTO `idiomas` (`id`, `codigo`, `nombre`, `nombre_ingles`, `babel`, `nivel`, `activo`, `orden`) VALUES (170,'kl','kalaallisut','Kalaallisut','kalaallisut',1,0,1000);
INSERT INTO `idiomas` (`id`, `codigo`, `nombre`, `nombre_ingles`, `babel`, `nivel`, `activo`, `orden`) VALUES (171,'kln','Kalenjin','Kalenjin','kalenjin',1,0,1000);
INSERT INTO `idiomas` (`id`, `codigo`, `nombre`, `nombre_ingles`, `babel`, `nivel`, `activo`, `orden`) VALUES (172,'km','ខ្មែរ','Khmer','khmer',1,0,1000);
INSERT INTO `idiomas` (`id`, `codigo`, `nombre`, `nombre_ingles`, `babel`, `nivel`, `activo`, `orden`) VALUES (173,'kmr','Kurmancî','Northern Kurdish','kurmanji',1,0,1000);
INSERT INTO `idiomas` (`id`, `codigo`, `nombre`, `nombre_ingles`, `babel`, `nivel`, `activo`, `orden`) VALUES (174,'kmr-Arab','کورمانجی','Northern Kurdish','kurmanji',1,0,1000);
INSERT INTO `idiomas` (`id`, `codigo`, `nombre`, `nombre_ingles`, `babel`, `nivel`, `activo`, `orden`) VALUES (175,'kmr-Latn','Kurmancî','Northern Kurdish','kurmanji',1,0,1000);
INSERT INTO `idiomas` (`id`, `codigo`, `nombre`, `nombre_ingles`, `babel`, `nivel`, `activo`, `orden`) VALUES (176,'kn','ಕನ್ನಡ','Kannada','kannada',1,0,1000);
INSERT INTO `idiomas` (`id`, `codigo`, `nombre`, `nombre_ingles`, `babel`, `nivel`, `activo`, `orden`) VALUES (177,'ko','한국어','Korean','korean',1,0,1000);
INSERT INTO `idiomas` (`id`, `codigo`, `nombre`, `nombre_ingles`, `babel`, `nivel`, `activo`, `orden`) VALUES (178,'kok','कोंकणी','Konkani','konkani',1,0,1000);
INSERT INTO `idiomas` (`id`, `codigo`, `nombre`, `nombre_ingles`, `babel`, `nivel`, `activo`, `orden`) VALUES (179,'ks','کٲشُر','Kashmiri','kashmiri',1,0,1000);
INSERT INTO `idiomas` (`id`, `codigo`, `nombre`, `nombre_ingles`, `babel`, `nivel`, `activo`, `orden`) VALUES (180,'ksb','Kishambaa','Shambala','shambala',1,0,1000);
INSERT INTO `idiomas` (`id`, `codigo`, `nombre`, `nombre_ingles`, `babel`, `nivel`, `activo`, `orden`) VALUES (181,'ksf','rikpa','Bafia','bafia',1,0,1000);
INSERT INTO `idiomas` (`id`, `codigo`, `nombre`, `nombre_ingles`, `babel`, `nivel`, `activo`, `orden`) VALUES (182,'ksh','Kölsch','Colognian','colognian',1,0,1000);
INSERT INTO `idiomas` (`id`, `codigo`, `nombre`, `nombre_ingles`, `babel`, `nivel`, `activo`, `orden`) VALUES (183,'kv','коми кыв','Komi','komi',1,0,1000);
INSERT INTO `idiomas` (`id`, `codigo`, `nombre`, `nombre_ingles`, `babel`, `nivel`, `activo`, `orden`) VALUES (184,'kw','kernewek','Cornish','cornish',1,0,1000);
INSERT INTO `idiomas` (`id`, `codigo`, `nombre`, `nombre_ingles`, `babel`, `nivel`, `activo`, `orden`) VALUES (185,'ky','кыргызча','Kyrgyz','kyrgyz',1,0,1000);
INSERT INTO `idiomas` (`id`, `codigo`, `nombre`, `nombre_ingles`, `babel`, `nivel`, `activo`, `orden`) VALUES (186,'la','Latin','Latin','latin',1,1,100);
INSERT INTO `idiomas` (`id`, `codigo`, `nombre`, `nombre_ingles`, `babel`, `nivel`, `activo`, `orden`) VALUES (187,'la-x-classic','Classical Latin','Classical Latin','classicallatin',1,0,1000);
INSERT INTO `idiomas` (`id`, `codigo`, `nombre`, `nombre_ingles`, `babel`, `nivel`, `activo`, `orden`) VALUES (188,'la-x-ecclesia','Ecclesiastical Latin','Ecclesiastical Latin','ecclesiasticallatin',1,0,1000);
INSERT INTO `idiomas` (`id`, `codigo`, `nombre`, `nombre_ingles`, `babel`, `nivel`, `activo`, `orden`) VALUES (189,'la-x-medieval','Medieval Latin','Medieval Latin','medievallatin',1,0,1000);
INSERT INTO `idiomas` (`id`, `codigo`, `nombre`, `nombre_ingles`, `babel`, `nivel`, `activo`, `orden`) VALUES (190,'lab','Linear A','Linear A','lineara',1,0,1000);
INSERT INTO `idiomas` (`id`, `codigo`, `nombre`, `nombre_ingles`, `babel`, `nivel`, `activo`, `orden`) VALUES (191,'lad','Ladino','Ladino','ladino',1,0,1000);
INSERT INTO `idiomas` (`id`, `codigo`, `nombre`, `nombre_ingles`, `babel`, `nivel`, `activo`, `orden`) VALUES (192,'lag','Kɨlaangi','Langi','langi',1,0,1000);
INSERT INTO `idiomas` (`id`, `codigo`, `nombre`, `nombre_ingles`, `babel`, `nivel`, `activo`, `orden`) VALUES (193,'lb','Lëtzebuergesch','Luxembourgish','luxembourgish',1,0,1000);
INSERT INTO `idiomas` (`id`, `codigo`, `nombre`, `nombre_ingles`, `babel`, `nivel`, `activo`, `orden`) VALUES (194,'lep','ᰛᰩᰵᰛᰧᰵᰶ','Lepcha','lepcha',1,0,1000);
INSERT INTO `idiomas` (`id`, `codigo`, `nombre`, `nombre_ingles`, `babel`, `nivel`, `activo`, `orden`) VALUES (195,'lg','Luganda','Ganda','ganda',1,0,1000);
INSERT INTO `idiomas` (`id`, `codigo`, `nombre`, `nombre_ingles`, `babel`, `nivel`, `activo`, `orden`) VALUES (196,'lif','लिम्बु भाषा','Limbu','limbu',1,0,1000);
INSERT INTO `idiomas` (`id`, `codigo`, `nombre`, `nombre_ingles`, `babel`, `nivel`, `activo`, `orden`) VALUES (197,'lif-Limb','ᤕᤠᤰᤌᤢᤱ ᤐᤠᤴ','Limbu','limbu-limbu',1,0,1000);
INSERT INTO `idiomas` (`id`, `codigo`, `nombre`, `nombre_ingles`, `babel`, `nivel`, `activo`, `orden`) VALUES (198,'lij','ligure','Ligurian','ligurian',1,0,1000);
INSERT INTO `idiomas` (`id`, `codigo`, `nombre`, `nombre_ingles`, `babel`, `nivel`, `activo`, `orden`) VALUES (199,'lkt','Lakȟólʼiyapi','Lakota','lakota',1,0,1000);
INSERT INTO `idiomas` (`id`, `codigo`, `nombre`, `nombre_ingles`, `babel`, `nivel`, `activo`, `orden`) VALUES (200,'lmo','lombard','Lombard','lombard',1,0,1000);
INSERT INTO `idiomas` (`id`, `codigo`, `nombre`, `nombre_ingles`, `babel`, `nivel`, `activo`, `orden`) VALUES (201,'ln','lingála','Lingala','lingala',1,0,1000);
INSERT INTO `idiomas` (`id`, `codigo`, `nombre`, `nombre_ingles`, `babel`, `nivel`, `activo`, `orden`) VALUES (202,'lo','ລາວ','Lao','lao',1,0,1000);
INSERT INTO `idiomas` (`id`, `codigo`, `nombre`, `nombre_ingles`, `babel`, `nivel`, `activo`, `orden`) VALUES (203,'lrc','لۊری شومالی','Northern Luri','northernluri',1,0,1000);
INSERT INTO `idiomas` (`id`, `codigo`, `nombre`, `nombre_ingles`, `babel`, `nivel`, `activo`, `orden`) VALUES (204,'lt','lietuvių','Lithuanian','lithuanian',1,0,1000);
INSERT INTO `idiomas` (`id`, `codigo`, `nombre`, `nombre_ingles`, `babel`, `nivel`, `activo`, `orden`) VALUES (205,'lu','Tshiluba','Luba-Katanga','lubakatanga',1,0,1000);
INSERT INTO `idiomas` (`id`, `codigo`, `nombre`, `nombre_ingles`, `babel`, `nivel`, `activo`, `orden`) VALUES (206,'luo','Dholuo','Luo','luo',1,0,1000);
INSERT INTO `idiomas` (`id`, `codigo`, `nombre`, `nombre_ingles`, `babel`, `nivel`, `activo`, `orden`) VALUES (207,'luy','Luluhia','Luyia','luyia',1,0,1000);
INSERT INTO `idiomas` (`id`, `codigo`, `nombre`, `nombre_ingles`, `babel`, `nivel`, `activo`, `orden`) VALUES (208,'lv','latviešu','Latvian','latvian',1,0,1000);
INSERT INTO `idiomas` (`id`, `codigo`, `nombre`, `nombre_ingles`, `babel`, `nivel`, `activo`, `orden`) VALUES (209,'mai','मैथिली','Maithili','maithili',1,0,1000);
INSERT INTO `idiomas` (`id`, `codigo`, `nombre`, `nombre_ingles`, `babel`, `nivel`, `activo`, `orden`) VALUES (210,'mak','basa Mangkasaraʼ','Makasar','makasar',1,0,1000);
INSERT INTO `idiomas` (`id`, `codigo`, `nombre`, `nombre_ingles`, `babel`, `nivel`, `activo`, `orden`) VALUES (211,'mak-Bugi','ᨅᨔ ᨆᨀᨔᨑ','Makasar','makasar-buginese',1,0,1000);
INSERT INTO `idiomas` (`id`, `codigo`, `nombre`, `nombre_ingles`, `babel`, `nivel`, `activo`, `orden`) VALUES (212,'mas','Maa','Masai','masai',1,0,1000);
INSERT INTO `idiomas` (`id`, `codigo`, `nombre`, `nombre_ingles`, `babel`, `nivel`, `activo`, `orden`) VALUES (213,'mer','Kĩmĩrũ','Meru','meru',1,0,1000);
INSERT INTO `idiomas` (`id`, `codigo`, `nombre`, `nombre_ingles`, `babel`, `nivel`, `activo`, `orden`) VALUES (214,'mfe','kreol morisien','Morisyen','morisyen',1,0,1000);
INSERT INTO `idiomas` (`id`, `codigo`, `nombre`, `nombre_ingles`, `babel`, `nivel`, `activo`, `orden`) VALUES (215,'mg','Malagasy','Malagasy','malagasy',1,0,1000);
INSERT INTO `idiomas` (`id`, `codigo`, `nombre`, `nombre_ingles`, `babel`, `nivel`, `activo`, `orden`) VALUES (216,'mgh','Makua','Makhuwa-Meetto','makhuwameetto',1,0,1000);
INSERT INTO `idiomas` (`id`, `codigo`, `nombre`, `nombre_ingles`, `babel`, `nivel`, `activo`, `orden`) VALUES (217,'mgo','metaʼ','Metaʼ','meta',1,0,1000);
INSERT INTO `idiomas` (`id`, `codigo`, `nombre`, `nombre_ingles`, `babel`, `nivel`, `activo`, `orden`) VALUES (218,'mi','Māori','Māori','maori',1,0,1000);
INSERT INTO `idiomas` (`id`, `codigo`, `nombre`, `nombre_ingles`, `babel`, `nivel`, `activo`, `orden`) VALUES (219,'mk','македонски','Macedonian','macedonian',1,0,1000);
INSERT INTO `idiomas` (`id`, `codigo`, `nombre`, `nombre_ingles`, `babel`, `nivel`, `activo`, `orden`) VALUES (220,'ml','മലയാളം','Malayalam','malayalam',1,0,1000);
INSERT INTO `idiomas` (`id`, `codigo`, `nombre`, `nombre_ingles`, `babel`, `nivel`, `activo`, `orden`) VALUES (221,'mn','монгол','Mongolian','mongolian',1,0,1000);
INSERT INTO `idiomas` (`id`, `codigo`, `nombre`, `nombre_ingles`, `babel`, `nivel`, `activo`, `orden`) VALUES (222,'mni','মৈতৈলোন্','Manipuri','manipuri',1,0,1000);
INSERT INTO `idiomas` (`id`, `codigo`, `nombre`, `nombre_ingles`, `babel`, `nivel`, `activo`, `orden`) VALUES (223,'mr','मराठी','Marathi','marathi',1,0,1000);
INSERT INTO `idiomas` (`id`, `codigo`, `nombre`, `nombre_ingles`, `babel`, `nivel`, `activo`, `orden`) VALUES (224,'ms','Melayu','Malay','malay',1,0,1000);
INSERT INTO `idiomas` (`id`, `codigo`, `nombre`, `nombre_ingles`, `babel`, `nivel`, `activo`, `orden`) VALUES (225,'ms-BN','Bahasa Melayu','Malay','malay-brunei',1,0,1000);
INSERT INTO `idiomas` (`id`, `codigo`, `nombre`, `nombre_ingles`, `babel`, `nivel`, `activo`, `orden`) VALUES (226,'ms-SG','Bahasa Melayu','Malay','malay-singapore',1,0,1000);
INSERT INTO `idiomas` (`id`, `codigo`, `nombre`, `nombre_ingles`, `babel`, `nivel`, `activo`, `orden`) VALUES (227,'mt','Malti','Maltese','maltese',1,0,1000);
INSERT INTO `idiomas` (`id`, `codigo`, `nombre`, `nombre_ingles`, `babel`, `nivel`, `activo`, `orden`) VALUES (228,'mua','Mundaŋ','Mundang','mundang',1,0,1000);
INSERT INTO `idiomas` (`id`, `codigo`, `nombre`, `nombre_ingles`, `babel`, `nivel`, `activo`, `orden`) VALUES (229,'mus','Mvskoke','Muscogee','muscogee',1,0,1000);
INSERT INTO `idiomas` (`id`, `codigo`, `nombre`, `nombre_ingles`, `babel`, `nivel`, `activo`, `orden`) VALUES (230,'my','မြန်မာ','Burmese','burmese',1,0,1000);
INSERT INTO `idiomas` (`id`, `codigo`, `nombre`, `nombre_ingles`, `babel`, `nivel`, `activo`, `orden`) VALUES (231,'myv','эрзянь кель','Erzya','erzya',1,0,1000);
INSERT INTO `idiomas` (`id`, `codigo`, `nombre`, `nombre_ingles`, `babel`, `nivel`, `activo`, `orden`) VALUES (232,'myz','ࡓࡀࡈࡍࡀ','Classical Mandaic','classicalmandaic',1,0,1000);
INSERT INTO `idiomas` (`id`, `codigo`, `nombre`, `nombre_ingles`, `babel`, `nivel`, `activo`, `orden`) VALUES (233,'mzn','مازرونی','Mazanderani','mazanderani',1,0,1000);
INSERT INTO `idiomas` (`id`, `codigo`, `nombre`, `nombre_ingles`, `babel`, `nivel`, `activo`, `orden`) VALUES (234,'naq','Khoekhoegowab','Nama','nama',1,0,1000);
INSERT INTO `idiomas` (`id`, `codigo`, `nombre`, `nombre_ingles`, `babel`, `nivel`, `activo`, `orden`) VALUES (235,'nb','norsk bokmål','Norwegian Bokmål','norwegianbokmal',1,0,1000);
INSERT INTO `idiomas` (`id`, `codigo`, `nombre`, `nombre_ingles`, `babel`, `nivel`, `activo`, `orden`) VALUES (236,'nd','isiNdebele','North Ndebele','northndebele',1,0,1000);
INSERT INTO `idiomas` (`id`, `codigo`, `nombre`, `nombre_ingles`, `babel`, `nivel`, `activo`, `orden`) VALUES (237,'nds','Neddersass’sch','Low German','lowgerman',1,0,1000);
INSERT INTO `idiomas` (`id`, `codigo`, `nombre`, `nombre_ingles`, `babel`, `nivel`, `activo`, `orden`) VALUES (238,'ne','नेपाली','Nepali','nepali',1,0,1000);
INSERT INTO `idiomas` (`id`, `codigo`, `nombre`, `nombre_ingles`, `babel`, `nivel`, `activo`, `orden`) VALUES (239,'new','नेवाः भाय्','Newari','newari',1,0,1000);
INSERT INTO `idiomas` (`id`, `codigo`, `nombre`, `nombre_ingles`, `babel`, `nivel`, `activo`, `orden`) VALUES (240,'nl','Nederlands','Dutch','dutch',1,0,1000);
INSERT INTO `idiomas` (`id`, `codigo`, `nombre`, `nombre_ingles`, `babel`, `nivel`, `activo`, `orden`) VALUES (241,'nmg','Kwasio','Kwasio','kwasio',1,0,1000);
INSERT INTO `idiomas` (`id`, `codigo`, `nombre`, `nombre_ingles`, `babel`, `nivel`, `activo`, `orden`) VALUES (242,'nn','norsk nynorsk','Norwegian Nynorsk','nynorsk',1,0,1000);
INSERT INTO `idiomas` (`id`, `codigo`, `nombre`, `nombre_ingles`, `babel`, `nivel`, `activo`, `orden`) VALUES (243,'nnh','Shwóŋò ngiembɔɔn','Ngiemboon','ngiemboon',1,0,1000);
INSERT INTO `idiomas` (`id`, `codigo`, `nombre`, `nombre_ingles`, `babel`, `nivel`, `activo`, `orden`) VALUES (244,'no','norsk','Norwegian','norsk',1,0,1000);
INSERT INTO `idiomas` (`id`, `codigo`, `nombre`, `nombre_ingles`, `babel`, `nivel`, `activo`, `orden`) VALUES (245,'non','norrǿnt mál','Old Norse','oldnorse',1,0,1000);
INSERT INTO `idiomas` (`id`, `codigo`, `nombre`, `nombre_ingles`, `babel`, `nivel`, `activo`, `orden`) VALUES (246,'nqo','ߒߞߏ','N’Ko','nko',1,0,1000);
INSERT INTO `idiomas` (`id`, `codigo`, `nombre`, `nombre_ingles`, `babel`, `nivel`, `activo`, `orden`) VALUES (247,'nr','isiNdebele','South Ndebele','southndebele',1,0,1000);
INSERT INTO `idiomas` (`id`, `codigo`, `nombre`, `nombre_ingles`, `babel`, `nivel`, `activo`, `orden`) VALUES (248,'nso','Sesotho sa Leboa','Northern Sotho','northernsotho',1,0,1000);
INSERT INTO `idiomas` (`id`, `codigo`, `nombre`, `nombre_ingles`, `babel`, `nivel`, `activo`, `orden`) VALUES (249,'nus','Thok Nath','Nuer','nuer',1,0,1000);
INSERT INTO `idiomas` (`id`, `codigo`, `nombre`, `nombre_ingles`, `babel`, `nivel`, `activo`, `orden`) VALUES (250,'nv','Diné Bizaad','Navajo','navajo',1,0,1000);
INSERT INTO `idiomas` (`id`, `codigo`, `nombre`, `nombre_ingles`, `babel`, `nivel`, `activo`, `orden`) VALUES (251,'ny','Nyanja','Nyanja','nyanja',1,0,1000);
INSERT INTO `idiomas` (`id`, `codigo`, `nombre`, `nombre_ingles`, `babel`, `nivel`, `activo`, `orden`) VALUES (252,'nyn','Runyankore','Nyankole','nyankole',1,0,1000);
INSERT INTO `idiomas` (`id`, `codigo`, `nombre`, `nombre_ingles`, `babel`, `nivel`, `activo`, `orden`) VALUES (253,'oc','Occitan','Occitan','occitan',1,0,1000);
INSERT INTO `idiomas` (`id`, `codigo`, `nombre`, `nombre_ingles`, `babel`, `nivel`, `activo`, `orden`) VALUES (254,'om','Oromoo','Oromo','oromo',1,0,1000);
INSERT INTO `idiomas` (`id`, `codigo`, `nombre`, `nombre_ingles`, `babel`, `nivel`, `activo`, `orden`) VALUES (255,'or','ଓଡ଼ିଆ','Odia','odia',1,0,1000);
INSERT INTO `idiomas` (`id`, `codigo`, `nombre`, `nombre_ingles`, `babel`, `nivel`, `activo`, `orden`) VALUES (256,'os','ирон','Ossetic','ossetic',1,0,1000);
INSERT INTO `idiomas` (`id`, `codigo`, `nombre`, `nombre_ingles`, `babel`, `nivel`, `activo`, `orden`) VALUES (257,'pa','ਪੰਜਾਬੀ','Punjabi','punjabi',1,0,1000);
INSERT INTO `idiomas` (`id`, `codigo`, `nombre`, `nombre_ingles`, `babel`, `nivel`, `activo`, `orden`) VALUES (258,'pa-Arab','پنجابی','Punjabi','punjabi-arabic',1,0,1000);
INSERT INTO `idiomas` (`id`, `codigo`, `nombre`, `nombre_ingles`, `babel`, `nivel`, `activo`, `orden`) VALUES (259,'pa-Guru','ਪੰਜਾਬੀ','Punjabi','punjabi-gurmukhi',1,0,1000);
INSERT INTO `idiomas` (`id`, `codigo`, `nombre`, `nombre_ingles`, `babel`, `nivel`, `activo`, `orden`) VALUES (260,'pap','Papiamentu','Papiamento','papiamento',1,0,1000);
INSERT INTO `idiomas` (`id`, `codigo`, `nombre`, `nombre_ingles`, `babel`, `nivel`, `activo`, `orden`) VALUES (261,'pcm','Naijíriá Píjin','Nigerian Pidgin','nigerianpidgin',1,0,1000);
INSERT INTO `idiomas` (`id`, `codigo`, `nombre`, `nombre_ingles`, `babel`, `nivel`, `activo`, `orden`) VALUES (262,'phn','𐤃𐤁𐤓𐤉𐤌 𐤊𐤍𐤏𐤍𐤉𐤌','Phoenician','phoenician',1,0,1000);
INSERT INTO `idiomas` (`id`, `codigo`, `nombre`, `nombre_ingles`, `babel`, `nivel`, `activo`, `orden`) VALUES (263,'pl','polski','Polish','polish',1,0,1000);
INSERT INTO `idiomas` (`id`, `codigo`, `nombre`, `nombre_ingles`, `babel`, `nivel`, `activo`, `orden`) VALUES (264,'pms','Piedmontese','Piedmontese','piedmontese',1,0,1000);
INSERT INTO `idiomas` (`id`, `codigo`, `nombre`, `nombre_ingles`, `babel`, `nivel`, `activo`, `orden`) VALUES (265,'prg','prūsiskan','Prussian','prussian',1,0,1000);
INSERT INTO `idiomas` (`id`, `codigo`, `nombre`, `nombre_ingles`, `babel`, `nivel`, `activo`, `orden`) VALUES (266,'ps','پښتو','Pashto','pashto',1,0,1000);
INSERT INTO `idiomas` (`id`, `codigo`, `nombre`, `nombre_ingles`, `babel`, `nivel`, `activo`, `orden`) VALUES (267,'pt','português','Portuguese','portuguese',1,1,20);
INSERT INTO `idiomas` (`id`, `codigo`, `nombre`, `nombre_ingles`, `babel`, `nivel`, `activo`, `orden`) VALUES (268,'pt-BR','português','Brazilian Portuguese','brazilian',1,0,1000);
INSERT INTO `idiomas` (`id`, `codigo`, `nombre`, `nombre_ingles`, `babel`, `nivel`, `activo`, `orden`) VALUES (269,'pt-PT','português europeu','European Portuguese','portuguese',1,0,1000);
INSERT INTO `idiomas` (`id`, `codigo`, `nombre`, `nombre_ingles`, `babel`, `nivel`, `activo`, `orden`) VALUES (270,'qu','Runasimi','Quechua','quechua',1,1,120);
INSERT INTO `idiomas` (`id`, `codigo`, `nombre`, `nombre_ingles`, `babel`, `nivel`, `activo`, `orden`) VALUES (271,'raj','राजस्थानी','Rajasthani','rajasthani',1,0,1000);
INSERT INTO `idiomas` (`id`, `codigo`, `nombre`, `nombre_ingles`, `babel`, `nivel`, `activo`, `orden`) VALUES (272,'rm','rumantsch','Romansh','romansh',1,0,1000);
INSERT INTO `idiomas` (`id`, `codigo`, `nombre`, `nombre_ingles`, `babel`, `nivel`, `activo`, `orden`) VALUES (273,'rmo','Sintitikes','Sinte Romani','sinteromani',1,0,1000);
INSERT INTO `idiomas` (`id`, `codigo`, `nombre`, `nombre_ingles`, `babel`, `nivel`, `activo`, `orden`) VALUES (274,'rn','Ikirundi','Rundi','rundi',1,0,1000);
INSERT INTO `idiomas` (`id`, `codigo`, `nombre`, `nombre_ingles`, `babel`, `nivel`, `activo`, `orden`) VALUES (275,'ro','română','Romanian','romanian',1,0,1000);
INSERT INTO `idiomas` (`id`, `codigo`, `nombre`, `nombre_ingles`, `babel`, `nivel`, `activo`, `orden`) VALUES (276,'ro-MD','română','Moldavian','moldavian',1,0,1000);
INSERT INTO `idiomas` (`id`, `codigo`, `nombre`, `nombre_ingles`, `babel`, `nivel`, `activo`, `orden`) VALUES (277,'rof','Kihorombo','Rombo','rombo',1,0,1000);
INSERT INTO `idiomas` (`id`, `codigo`, `nombre`, `nombre_ingles`, `babel`, `nivel`, `activo`, `orden`) VALUES (278,'ru','русский','Russian','russian',1,0,1000);
INSERT INTO `idiomas` (`id`, `codigo`, `nombre`, `nombre_ingles`, `babel`, `nivel`, `activo`, `orden`) VALUES (279,'rw','Kinyarwanda','Kinyarwanda','kinyarwanda',1,0,1000);
INSERT INTO `idiomas` (`id`, `codigo`, `nombre`, `nombre_ingles`, `babel`, `nivel`, `activo`, `orden`) VALUES (280,'rwk','Kiruwa','Rwa','rwa',1,0,1000);
INSERT INTO `idiomas` (`id`, `codigo`, `nombre`, `nombre_ingles`, `babel`, `nivel`, `activo`, `orden`) VALUES (281,'sa','Sanskrit','Sanskrit','sanskrit',0,0,1000);
INSERT INTO `idiomas` (`id`, `codigo`, `nombre`, `nombre_ingles`, `babel`, `nivel`, `activo`, `orden`) VALUES (282,'sa-Beng','Sanskrit','Sanskrit','sanskrit',0,0,1000);
INSERT INTO `idiomas` (`id`, `codigo`, `nombre`, `nombre_ingles`, `babel`, `nivel`, `activo`, `orden`) VALUES (283,'sa-Deva','संस्कृत','Sanskrit','sanskrit',1,0,1000);
INSERT INTO `idiomas` (`id`, `codigo`, `nombre`, `nombre_ingles`, `babel`, `nivel`, `activo`, `orden`) VALUES (284,'sa-Gujr','Sanskrit','Sanskrit','sanskrit',0,0,1000);
INSERT INTO `idiomas` (`id`, `codigo`, `nombre`, `nombre_ingles`, `babel`, `nivel`, `activo`, `orden`) VALUES (285,'sa-Knda','Sanskrit','Sanskrit','sanskrit',0,0,1000);
INSERT INTO `idiomas` (`id`, `codigo`, `nombre`, `nombre_ingles`, `babel`, `nivel`, `activo`, `orden`) VALUES (286,'sa-Mlym','Sanskrit','Sanskrit','sanskrit',0,0,1000);
INSERT INTO `idiomas` (`id`, `codigo`, `nombre`, `nombre_ingles`, `babel`, `nivel`, `activo`, `orden`) VALUES (287,'sa-Telu','Sanskrit','Sanskrit','sanskrit',0,0,1000);
INSERT INTO `idiomas` (`id`, `codigo`, `nombre`, `nombre_ingles`, `babel`, `nivel`, `activo`, `orden`) VALUES (288,'sah','саха тыла','Sakha','sakha',1,0,1000);
INSERT INTO `idiomas` (`id`, `codigo`, `nombre`, `nombre_ingles`, `babel`, `nivel`, `activo`, `orden`) VALUES (289,'saq','Kisampur','Samburu','samburu',1,0,1000);
INSERT INTO `idiomas` (`id`, `codigo`, `nombre`, `nombre_ingles`, `babel`, `nivel`, `activo`, `orden`) VALUES (290,'sat','ᱥᱟᱱᱛᱟᱲᱤ','Santali','santali',1,0,1000);
INSERT INTO `idiomas` (`id`, `codigo`, `nombre`, `nombre_ingles`, `babel`, `nivel`, `activo`, `orden`) VALUES (291,'sbp','Ishisangu','Sangu','sangu',1,0,1000);
INSERT INTO `idiomas` (`id`, `codigo`, `nombre`, `nombre_ingles`, `babel`, `nivel`, `activo`, `orden`) VALUES (292,'sc','sardu','Sardinian','sardinian',1,0,1000);
INSERT INTO `idiomas` (`id`, `codigo`, `nombre`, `nombre_ingles`, `babel`, `nivel`, `activo`, `orden`) VALUES (293,'scn','sicilianu','Sicilian','sicilian',1,0,1000);
INSERT INTO `idiomas` (`id`, `codigo`, `nombre`, `nombre_ingles`, `babel`, `nivel`, `activo`, `orden`) VALUES (294,'sd','سنڌي','Sindhi','sindhi',1,0,1000);
INSERT INTO `idiomas` (`id`, `codigo`, `nombre`, `nombre_ingles`, `babel`, `nivel`, `activo`, `orden`) VALUES (295,'sd-Deva','सिन्धी','Sindhi','sindhi-devanagari',1,0,1000);
INSERT INTO `idiomas` (`id`, `codigo`, `nombre`, `nombre_ingles`, `babel`, `nivel`, `activo`, `orden`) VALUES (296,'sd-Khoj','Sindhi','Sindhi','sindhi-khojki',1,0,1000);
INSERT INTO `idiomas` (`id`, `codigo`, `nombre`, `nombre_ingles`, `babel`, `nivel`, `activo`, `orden`) VALUES (297,'sd-Sind','Sindhi','Sindhi','sindhi-khudawadi',1,0,1000);
INSERT INTO `idiomas` (`id`, `codigo`, `nombre`, `nombre_ingles`, `babel`, `nivel`, `activo`, `orden`) VALUES (298,'se','davvisámegiella','Northern Sami','northernsami',1,0,1000);
INSERT INTO `idiomas` (`id`, `codigo`, `nombre`, `nombre_ingles`, `babel`, `nivel`, `activo`, `orden`) VALUES (299,'seh','sena','Sena','sena',1,0,1000);
INSERT INTO `idiomas` (`id`, `codigo`, `nombre`, `nombre_ingles`, `babel`, `nivel`, `activo`, `orden`) VALUES (300,'ses','Koyraboro senni','Koyraboro Senni','koyraborosenni',1,0,1000);
INSERT INTO `idiomas` (`id`, `codigo`, `nombre`, `nombre_ingles`, `babel`, `nivel`, `activo`, `orden`) VALUES (301,'sg','Sängö','Sango','sango',1,0,1000);
INSERT INTO `idiomas` (`id`, `codigo`, `nombre`, `nombre_ingles`, `babel`, `nivel`, `activo`, `orden`) VALUES (302,'shi','ⵜⴰⵛⵍⵃⵉⵜ','Tachelhit','tachelhit',1,0,1000);
INSERT INTO `idiomas` (`id`, `codigo`, `nombre`, `nombre_ingles`, `babel`, `nivel`, `activo`, `orden`) VALUES (303,'shi-Latn','Tashelḥiyt','Tachelhit','tachelhit-latin',1,0,1000);
INSERT INTO `idiomas` (`id`, `codigo`, `nombre`, `nombre_ingles`, `babel`, `nivel`, `activo`, `orden`) VALUES (304,'shi-Tfng','ⵜⴰⵛⵍⵃⵉⵜ','Tachelhit','tachelhit-tifinagh',1,0,1000);
INSERT INTO `idiomas` (`id`, `codigo`, `nombre`, `nombre_ingles`, `babel`, `nivel`, `activo`, `orden`) VALUES (305,'si','සිංහල','Sinhala','sinhala',1,0,1000);
INSERT INTO `idiomas` (`id`, `codigo`, `nombre`, `nombre_ingles`, `babel`, `nivel`, `activo`, `orden`) VALUES (306,'sk','slovenčina','Slovak','slovak',1,0,1000);
INSERT INTO `idiomas` (`id`, `codigo`, `nombre`, `nombre_ingles`, `babel`, `nivel`, `activo`, `orden`) VALUES (307,'skr','سرائیکی','Saraiki','saraiki',1,0,1000);
INSERT INTO `idiomas` (`id`, `codigo`, `nombre`, `nombre_ingles`, `babel`, `nivel`, `activo`, `orden`) VALUES (308,'sl','slovenščina','Slovenian','slovene',1,0,1000);
INSERT INTO `idiomas` (`id`, `codigo`, `nombre`, `nombre_ingles`, `babel`, `nivel`, `activo`, `orden`) VALUES (309,'smn','anarâškielâ','Inari Sami','inarisami',1,0,1000);
INSERT INTO `idiomas` (`id`, `codigo`, `nombre`, `nombre_ingles`, `babel`, `nivel`, `activo`, `orden`) VALUES (310,'smp','ࠏࠁࠓࠉࠕ','Samaritan','samaritan',1,0,1000);
INSERT INTO `idiomas` (`id`, `codigo`, `nombre`, `nombre_ingles`, `babel`, `nivel`, `activo`, `orden`) VALUES (311,'sn','chiShona','Shona','shona',1,0,1000);
INSERT INTO `idiomas` (`id`, `codigo`, `nombre`, `nombre_ingles`, `babel`, `nivel`, `activo`, `orden`) VALUES (312,'so','Soomaali','Somali','somali',1,0,1000);
INSERT INTO `idiomas` (`id`, `codigo`, `nombre`, `nombre_ingles`, `babel`, `nivel`, `activo`, `orden`) VALUES (313,'sq','shqip','Albanian','albanian',1,0,1000);
INSERT INTO `idiomas` (`id`, `codigo`, `nombre`, `nombre_ingles`, `babel`, `nivel`, `activo`, `orden`) VALUES (314,'sr','српски','Serbian','serbianc',1,0,1000);
INSERT INTO `idiomas` (`id`, `codigo`, `nombre`, `nombre_ingles`, `babel`, `nivel`, `activo`, `orden`) VALUES (315,'sr-Cyrl','српски','Serbian','serbian-cyrillic',1,0,1000);
INSERT INTO `idiomas` (`id`, `codigo`, `nombre`, `nombre_ingles`, `babel`, `nivel`, `activo`, `orden`) VALUES (316,'sr-Cyrl-BA','српски','Serbian','serbian-cyrillic-bosniaherzegovina',1,0,1000);
INSERT INTO `idiomas` (`id`, `codigo`, `nombre`, `nombre_ingles`, `babel`, `nivel`, `activo`, `orden`) VALUES (317,'sr-Cyrl-ME','српски','Montenegrin','serbian-cyrillic-montenegro',1,0,1000);
INSERT INTO `idiomas` (`id`, `codigo`, `nombre`, `nombre_ingles`, `babel`, `nivel`, `activo`, `orden`) VALUES (318,'sr-Cyrl-XK','српски','Serbian','serbian-cyrillic-kosovo',1,0,1000);
INSERT INTO `idiomas` (`id`, `codigo`, `nombre`, `nombre_ingles`, `babel`, `nivel`, `activo`, `orden`) VALUES (319,'sr-Latn','srpski','Serbian','serbian-latin',1,0,1000);
INSERT INTO `idiomas` (`id`, `codigo`, `nombre`, `nombre_ingles`, `babel`, `nivel`, `activo`, `orden`) VALUES (320,'sr-Latn-BA','srpski','Serbian','serbian-latin-bosniaherzegovina',1,0,1000);
INSERT INTO `idiomas` (`id`, `codigo`, `nombre`, `nombre_ingles`, `babel`, `nivel`, `activo`, `orden`) VALUES (321,'sr-Latn-ME','srpski','Montenegrin','serbian-latin-montenegro',1,0,1000);
INSERT INTO `idiomas` (`id`, `codigo`, `nombre`, `nombre_ingles`, `babel`, `nivel`, `activo`, `orden`) VALUES (322,'sr-Latn-XK','srpski','Serbian','serbian-latin-kosovo',1,0,1000);
INSERT INTO `idiomas` (`id`, `codigo`, `nombre`, `nombre_ingles`, `babel`, `nivel`, `activo`, `orden`) VALUES (323,'sr-Latn-ijekavsk','srpski','Serbian','serbian-latin-ijekavsk',1,0,1000);
INSERT INTO `idiomas` (`id`, `codigo`, `nombre`, `nombre_ingles`, `babel`, `nivel`, `activo`, `orden`) VALUES (324,'sr-ijekavsk','српски','Serbian','serbian-ijekavsk',1,0,1000);
INSERT INTO `idiomas` (`id`, `codigo`, `nombre`, `nombre_ingles`, `babel`, `nivel`, `activo`, `orden`) VALUES (325,'ss','siSwati','Swati','swati',1,0,1000);
INSERT INTO `idiomas` (`id`, `codigo`, `nombre`, `nombre_ingles`, `babel`, `nivel`, `activo`, `orden`) VALUES (326,'ssy','Saho','Saho','saho',1,0,1000);
INSERT INTO `idiomas` (`id`, `codigo`, `nombre`, `nombre_ingles`, `babel`, `nivel`, `activo`, `orden`) VALUES (327,'st','Sesotho','Southern Sotho','southernsotho',1,0,1000);
INSERT INTO `idiomas` (`id`, `codigo`, `nombre`, `nombre_ingles`, `babel`, `nivel`, `activo`, `orden`) VALUES (328,'su','Basa Sunda','Sundanese','sundanese',1,0,1000);
INSERT INTO `idiomas` (`id`, `codigo`, `nombre`, `nombre_ingles`, `babel`, `nivel`, `activo`, `orden`) VALUES (329,'sv','svenska','Swedish','swedish',1,0,1000);
INSERT INTO `idiomas` (`id`, `codigo`, `nombre`, `nombre_ingles`, `babel`, `nivel`, `activo`, `orden`) VALUES (330,'sw','Kiswahili','Swahili','swahili',1,0,1000);
INSERT INTO `idiomas` (`id`, `codigo`, `nombre`, `nombre_ingles`, `babel`, `nivel`, `activo`, `orden`) VALUES (331,'syr','ܠܫܢܐ ܣܘܪܝܝܐ','Syriac','syriac',1,0,1000);
INSERT INTO `idiomas` (`id`, `codigo`, `nombre`, `nombre_ingles`, `babel`, `nivel`, `activo`, `orden`) VALUES (332,'szl','ślōnski','Silesian','silesian',1,0,1000);
INSERT INTO `idiomas` (`id`, `codigo`, `nombre`, `nombre_ingles`, `babel`, `nivel`, `activo`, `orden`) VALUES (333,'ta','தமிழ்','Tamil','tamil',NULL,0,1000);
INSERT INTO `idiomas` (`id`, `codigo`, `nombre`, `nombre_ingles`, `babel`, `nivel`, `activo`, `orden`) VALUES (334,'tdd','ᥖᥭᥰ ᥘᥫᥴ','Tai Nüa','tainua',1,0,1000);
INSERT INTO `idiomas` (`id`, `codigo`, `nombre`, `nombre_ingles`, `babel`, `nivel`, `activo`, `orden`) VALUES (335,'te','తెలుగు','Telugu','telugu',1,0,1000);
INSERT INTO `idiomas` (`id`, `codigo`, `nombre`, `nombre_ingles`, `babel`, `nivel`, `activo`, `orden`) VALUES (336,'teo','Kiteso','Teso','teso',1,0,1000);
INSERT INTO `idiomas` (`id`, `codigo`, `nombre`, `nombre_ingles`, `babel`, `nivel`, `activo`, `orden`) VALUES (337,'tg','тоҷикӣ','Tajik','tajik',1,0,1000);
INSERT INTO `idiomas` (`id`, `codigo`, `nombre`, `nombre_ingles`, `babel`, `nivel`, `activo`, `orden`) VALUES (338,'th','ไทย','Thai','thai',1,0,1000);
INSERT INTO `idiomas` (`id`, `codigo`, `nombre`, `nombre_ingles`, `babel`, `nivel`, `activo`, `orden`) VALUES (339,'ti','ትግርኛ','Tigrinya','tigrinya',1,0,1000);
INSERT INTO `idiomas` (`id`, `codigo`, `nombre`, `nombre_ingles`, `babel`, `nivel`, `activo`, `orden`) VALUES (340,'tig','ትግረ','Tigre','tigre',1,0,1000);
INSERT INTO `idiomas` (`id`, `codigo`, `nombre`, `nombre_ingles`, `babel`, `nivel`, `activo`, `orden`) VALUES (341,'tk','türkmen dili','Turkmen','turkmen',1,0,1000);
INSERT INTO `idiomas` (`id`, `codigo`, `nombre`, `nombre_ingles`, `babel`, `nivel`, `activo`, `orden`) VALUES (342,'tn','Setswana','Tswana','tswana',1,0,1000);
INSERT INTO `idiomas` (`id`, `codigo`, `nombre`, `nombre_ingles`, `babel`, `nivel`, `activo`, `orden`) VALUES (343,'to','lea fakatonga','Tongan','tongan',1,0,1000);
INSERT INTO `idiomas` (`id`, `codigo`, `nombre`, `nombre_ingles`, `babel`, `nivel`, `activo`, `orden`) VALUES (344,'tpi','Tok Pisin','Tok Pisin','tokpisin',1,0,1000);
INSERT INTO `idiomas` (`id`, `codigo`, `nombre`, `nombre_ingles`, `babel`, `nivel`, `activo`, `orden`) VALUES (345,'tr','Türkçe','Turkish','turkish',1,0,1000);
INSERT INTO `idiomas` (`id`, `codigo`, `nombre`, `nombre_ingles`, `babel`, `nivel`, `activo`, `orden`) VALUES (346,'trv','patas Taroko','Taroko','taroko',1,0,1000);
INSERT INTO `idiomas` (`id`, `codigo`, `nombre`, `nombre_ingles`, `babel`, `nivel`, `activo`, `orden`) VALUES (347,'ts','Xitsonga','Tsonga','tsonga',1,0,1000);
INSERT INTO `idiomas` (`id`, `codigo`, `nombre`, `nombre_ingles`, `babel`, `nivel`, `activo`, `orden`) VALUES (348,'tt','татар','Tatar','tatar',1,0,1000);
INSERT INTO `idiomas` (`id`, `codigo`, `nombre`, `nombre_ingles`, `babel`, `nivel`, `activo`, `orden`) VALUES (349,'twq','Tasawaq senni','Tasawaq','tasawaq',1,0,1000);
INSERT INTO `idiomas` (`id`, `codigo`, `nombre`, `nombre_ingles`, `babel`, `nivel`, `activo`, `orden`) VALUES (350,'txg','𗼇𗟲','Tangut','tangut',1,0,1000);
INSERT INTO `idiomas` (`id`, `codigo`, `nombre`, `nombre_ingles`, `babel`, `nivel`, `activo`, `orden`) VALUES (351,'tzm','Tamaziɣt n laṭlaṣ','Central Atlas Tamazight','centralatlastamazight',1,0,1000);
INSERT INTO `idiomas` (`id`, `codigo`, `nombre`, `nombre_ingles`, `babel`, `nivel`, `activo`, `orden`) VALUES (352,'ug','ئۇيغۇرچە','Uyghur','uyghur',1,0,1000);
INSERT INTO `idiomas` (`id`, `codigo`, `nombre`, `nombre_ingles`, `babel`, `nivel`, `activo`, `orden`) VALUES (353,'uk','українська','Ukrainian','ukrainian',1,0,1000);
INSERT INTO `idiomas` (`id`, `codigo`, `nombre`, `nombre_ingles`, `babel`, `nivel`, `activo`, `orden`) VALUES (354,'ur','اردو','Urdu','urdu',1,0,1000);
INSERT INTO `idiomas` (`id`, `codigo`, `nombre`, `nombre_ingles`, `babel`, `nivel`, `activo`, `orden`) VALUES (355,'uz','o‘zbek','Uzbek','uzbek',1,0,1000);
INSERT INTO `idiomas` (`id`, `codigo`, `nombre`, `nombre_ingles`, `babel`, `nivel`, `activo`, `orden`) VALUES (356,'uz-Arab','اوزبیک','Uzbek','uzbek-arabic',1,0,1000);
INSERT INTO `idiomas` (`id`, `codigo`, `nombre`, `nombre_ingles`, `babel`, `nivel`, `activo`, `orden`) VALUES (357,'uz-Cyrl','ўзбекча','Uzbek','uzbek-cyrillic',1,0,1000);
INSERT INTO `idiomas` (`id`, `codigo`, `nombre`, `nombre_ingles`, `babel`, `nivel`, `activo`, `orden`) VALUES (358,'uz-Latn','o‘zbek','Uzbek','uzbek-latin',1,0,1000);
INSERT INTO `idiomas` (`id`, `codigo`, `nombre`, `nombre_ingles`, `babel`, `nivel`, `activo`, `orden`) VALUES (359,'vai','ꕙꔤ','Vai','vai',1,0,1000);
INSERT INTO `idiomas` (`id`, `codigo`, `nombre`, `nombre_ingles`, `babel`, `nivel`, `activo`, `orden`) VALUES (360,'vai-Latn','Vai','Vai','vai-latin',1,0,1000);
INSERT INTO `idiomas` (`id`, `codigo`, `nombre`, `nombre_ingles`, `babel`, `nivel`, `activo`, `orden`) VALUES (361,'vai-Vaii','ꕙꔤ','Vai','vai-vai',1,0,1000);
INSERT INTO `idiomas` (`id`, `codigo`, `nombre`, `nombre_ingles`, `babel`, `nivel`, `activo`, `orden`) VALUES (362,'ve','Tshivenḓa','Venda','venda',1,0,1000);
INSERT INTO `idiomas` (`id`, `codigo`, `nombre`, `nombre_ingles`, `babel`, `nivel`, `activo`, `orden`) VALUES (363,'vi','Tiếng Việt','Vietnamese','vietnamese',1,0,1000);
INSERT INTO `idiomas` (`id`, `codigo`, `nombre`, `nombre_ingles`, `babel`, `nivel`, `activo`, `orden`) VALUES (364,'vo','Volapük','Volapük','volapuk',1,0,1000);
INSERT INTO `idiomas` (`id`, `codigo`, `nombre`, `nombre_ingles`, `babel`, `nivel`, `activo`, `orden`) VALUES (365,'vun','Kyivunjo','Vunjo','vunjo',1,0,1000);
INSERT INTO `idiomas` (`id`, `codigo`, `nombre`, `nombre_ingles`, `babel`, `nivel`, `activo`, `orden`) VALUES (366,'wae','Walser','Walser','walser',1,0,1000);
INSERT INTO `idiomas` (`id`, `codigo`, `nombre`, `nombre_ingles`, `babel`, `nivel`, `activo`, `orden`) VALUES (367,'wal','ወላይታቱ','Wolaytta','wolaytta',1,0,1000);
INSERT INTO `idiomas` (`id`, `codigo`, `nombre`, `nombre_ingles`, `babel`, `nivel`, `activo`, `orden`) VALUES (368,'war','Waray','Waray','waray',1,0,1000);
INSERT INTO `idiomas` (`id`, `codigo`, `nombre`, `nombre_ingles`, `babel`, `nivel`, `activo`, `orden`) VALUES (369,'wo','Wolof','Wolof','wolof',1,0,1000);
INSERT INTO `idiomas` (`id`, `codigo`, `nombre`, `nombre_ingles`, `babel`, `nivel`, `activo`, `orden`) VALUES (370,'xh','IsiXhosa','Xhosa','xhosa',1,0,1000);
INSERT INTO `idiomas` (`id`, `codigo`, `nombre`, `nombre_ingles`, `babel`, `nivel`, `activo`, `orden`) VALUES (371,'xog','Olusoga','Soga','soga',1,0,1000);
INSERT INTO `idiomas` (`id`, `codigo`, `nombre`, `nombre_ingles`, `babel`, `nivel`, `activo`, `orden`) VALUES (372,'yav','nuasue','Yangben','yangben',1,0,1000);
INSERT INTO `idiomas` (`id`, `codigo`, `nombre`, `nombre_ingles`, `babel`, `nivel`, `activo`, `orden`) VALUES (373,'yi','ייִדיש','Yiddish','yiddish',1,0,1000);
INSERT INTO `idiomas` (`id`, `codigo`, `nombre`, `nombre_ingles`, `babel`, `nivel`, `activo`, `orden`) VALUES (374,'yo','Èdè Yorùbá','Yoruba','yoruba',1,0,1000);
INSERT INTO `idiomas` (`id`, `codigo`, `nombre`, `nombre_ingles`, `babel`, `nivel`, `activo`, `orden`) VALUES (375,'yrl','nheẽgatu','Nheengatu','nheengatu',1,0,1000);
INSERT INTO `idiomas` (`id`, `codigo`, `nombre`, `nombre_ingles`, `babel`, `nivel`, `activo`, `orden`) VALUES (376,'yue','粵語','Cantonese','cantonese',1,0,1000);
INSERT INTO `idiomas` (`id`, `codigo`, `nombre`, `nombre_ingles`, `babel`, `nivel`, `activo`, `orden`) VALUES (377,'zgh','ⵜⴰⵎⴰⵣⵉⵖⵜ','Standard Moroccan Tamazight','standardmoroccantamazight',1,0,1000);
INSERT INTO `idiomas` (`id`, `codigo`, `nombre`, `nombre_ingles`, `babel`, `nivel`, `activo`, `orden`) VALUES (378,'zh','中文','Chinese','chinese',1,0,1000);
INSERT INTO `idiomas` (`id`, `codigo`, `nombre`, `nombre_ingles`, `babel`, `nivel`, `activo`, `orden`) VALUES (379,'zh-Hans','简体中文','Simplified Chinese','chinese-simplified',1,0,1000);
INSERT INTO `idiomas` (`id`, `codigo`, `nombre`, `nombre_ingles`, `babel`, `nivel`, `activo`, `orden`) VALUES (380,'zh-Hans-HK','简体中文','Simplified Chinese','chinese-simplified-hongkongsarchina',1,0,1000);
INSERT INTO `idiomas` (`id`, `codigo`, `nombre`, `nombre_ingles`, `babel`, `nivel`, `activo`, `orden`) VALUES (381,'zh-Hans-MO','简体中文','Simplified Chinese','chinese-simplified-macausarchina',1,0,1000);
INSERT INTO `idiomas` (`id`, `codigo`, `nombre`, `nombre_ingles`, `babel`, `nivel`, `activo`, `orden`) VALUES (382,'zh-Hans-SG','简体中文','Simplified Chinese','chinese-simplified-singapore',1,0,1000);
INSERT INTO `idiomas` (`id`, `codigo`, `nombre`, `nombre_ingles`, `babel`, `nivel`, `activo`, `orden`) VALUES (383,'zh-Hant','繁體中文','Traditional Chinese','chinese-traditional',1,0,1000);
INSERT INTO `idiomas` (`id`, `codigo`, `nombre`, `nombre_ingles`, `babel`, `nivel`, `activo`, `orden`) VALUES (384,'zh-Hant-HK','繁體中文','Traditional Chinese','chinese-traditional-hongkongsarchina',1,0,1000);
INSERT INTO `idiomas` (`id`, `codigo`, `nombre`, `nombre_ingles`, `babel`, `nivel`, `activo`, `orden`) VALUES (385,'zh-Hant-MO','繁體中文','Traditional Chinese','chinese-traditional-macausarchina',1,0,1000);
INSERT INTO `idiomas` (`id`, `codigo`, `nombre`, `nombre_ingles`, `babel`, `nivel`, `activo`, `orden`) VALUES (386,'zu','isiZulu','Zulu','zulu',1,0,1000);
INSERT INTO `pais` (`codigo`, `nombre`, `nombre_en`) VALUES ('AD','Andorra','Andorra');
INSERT INTO `pais` (`codigo`, `nombre`, `nombre_en`) VALUES ('AE','Emiratos Árabes Unidos','United Arab Emirates');
INSERT INTO `pais` (`codigo`, `nombre`, `nombre_en`) VALUES ('AF','Afganistán','Afghanistan');
INSERT INTO `pais` (`codigo`, `nombre`, `nombre_en`) VALUES ('AG','Antigua y Barbuda','Antigua and Barbuda');
INSERT INTO `pais` (`codigo`, `nombre`, `nombre_en`) VALUES ('AI','Anguila','Anguilla');
INSERT INTO `pais` (`codigo`, `nombre`, `nombre_en`) VALUES ('AL','Albania','Albania');
INSERT INTO `pais` (`codigo`, `nombre`, `nombre_en`) VALUES ('AM','Armenia','Armenia');
INSERT INTO `pais` (`codigo`, `nombre`, `nombre_en`) VALUES ('AO','Angola','Angola');
INSERT INTO `pais` (`codigo`, `nombre`, `nombre_en`) VALUES ('AQ','Antártida','Antarctica');
INSERT INTO `pais` (`codigo`, `nombre`, `nombre_en`) VALUES ('AR','Argentina','Argentina');
INSERT INTO `pais` (`codigo`, `nombre`, `nombre_en`) VALUES ('AS','Samoa Estadounidense','American Samoa');
INSERT INTO `pais` (`codigo`, `nombre`, `nombre_en`) VALUES ('AT','Austria','Austria');
INSERT INTO `pais` (`codigo`, `nombre`, `nombre_en`) VALUES ('AU','Australia','Australia');
INSERT INTO `pais` (`codigo`, `nombre`, `nombre_en`) VALUES ('AW','Aruba','Aruba');
INSERT INTO `pais` (`codigo`, `nombre`, `nombre_en`) VALUES ('AX','Islas Äland','Åland Islands');
INSERT INTO `pais` (`codigo`, `nombre`, `nombre_en`) VALUES ('AZ','Azerbaiyán','Azerbaijan');
INSERT INTO `pais` (`codigo`, `nombre`, `nombre_en`) VALUES ('BA','Bosnia y Herzegovina','Bosnia and Herzegovina');
INSERT INTO `pais` (`codigo`, `nombre`, `nombre_en`) VALUES ('BB','Barbados','Barbados');
INSERT INTO `pais` (`codigo`, `nombre`, `nombre_en`) VALUES ('BD','Bangladés','Bangladesh');
INSERT INTO `pais` (`codigo`, `nombre`, `nombre_en`) VALUES ('BE','Bélgica','Belgium');
INSERT INTO `pais` (`codigo`, `nombre`, `nombre_en`) VALUES ('BF','Burquina Faso','Burkina Faso');
INSERT INTO `pais` (`codigo`, `nombre`, `nombre_en`) VALUES ('BG','Bulgaria','Bulgaria');
INSERT INTO `pais` (`codigo`, `nombre`, `nombre_en`) VALUES ('BH','Baréin','Bahrain');
INSERT INTO `pais` (`codigo`, `nombre`, `nombre_en`) VALUES ('BI','Burundi','Burundi');
INSERT INTO `pais` (`codigo`, `nombre`, `nombre_en`) VALUES ('BJ','Benín','Benin');
INSERT INTO `pais` (`codigo`, `nombre`, `nombre_en`) VALUES ('BL','San Bartolomé','Saint Barthélemy');
INSERT INTO `pais` (`codigo`, `nombre`, `nombre_en`) VALUES ('BM','Islas Bermudas','Bermuda');
INSERT INTO `pais` (`codigo`, `nombre`, `nombre_en`) VALUES ('BN','Brunei Darussalam','Brunei Darussalam');
INSERT INTO `pais` (`codigo`, `nombre`, `nombre_en`) VALUES ('BO','Bolivia','Bolivia');
INSERT INTO `pais` (`codigo`, `nombre`, `nombre_en`) VALUES ('BQ','Islas BES (Caribe Neerlandés)','Bonaire, Sint Eustatius and Saba');
INSERT INTO `pais` (`codigo`, `nombre`, `nombre_en`) VALUES ('BR','Brasil','Brazil');
INSERT INTO `pais` (`codigo`, `nombre`, `nombre_en`) VALUES ('BS','Bahamas','Bahamas');
INSERT INTO `pais` (`codigo`, `nombre`, `nombre_en`) VALUES ('BT','Bután','Bhutan');
INSERT INTO `pais` (`codigo`, `nombre`, `nombre_en`) VALUES ('BV','Isla Bouvet','Bouvet Island');
INSERT INTO `pais` (`codigo`, `nombre`, `nombre_en`) VALUES ('BW','Botsuana','Botswana');
INSERT INTO `pais` (`codigo`, `nombre`, `nombre_en`) VALUES ('BY','Bielorrusia','Belarus');
INSERT INTO `pais` (`codigo`, `nombre`, `nombre_en`) VALUES ('BZ','Belice','Belize');
INSERT INTO `pais` (`codigo`, `nombre`, `nombre_en`) VALUES ('CA','Canadá','Canada');
INSERT INTO `pais` (`codigo`, `nombre`, `nombre_en`) VALUES ('CC','Islas Cocos (Keeling)','Cocos (Keeling) Islands');
INSERT INTO `pais` (`codigo`, `nombre`, `nombre_en`) VALUES ('CD','Congo, República Democrática del','Congo, The Democratic Republic of the');
INSERT INTO `pais` (`codigo`, `nombre`, `nombre_en`) VALUES ('CF','República Centroafricana','Central African Republic');
INSERT INTO `pais` (`codigo`, `nombre`, `nombre_en`) VALUES ('CG','Congo','Congo');
INSERT INTO `pais` (`codigo`, `nombre`, `nombre_en`) VALUES ('CH','Suiza','Switzerland');
INSERT INTO `pais` (`codigo`, `nombre`, `nombre_en`) VALUES ('CI','Costa de Marfil','Côte d\'Ivoire');
INSERT INTO `pais` (`codigo`, `nombre`, `nombre_en`) VALUES ('CK','Islas Cook','Cook Islands');
INSERT INTO `pais` (`codigo`, `nombre`, `nombre_en`) VALUES ('CL','Chile','Chile');
INSERT INTO `pais` (`codigo`, `nombre`, `nombre_en`) VALUES ('CM','Camerún','Cameroon');
INSERT INTO `pais` (`codigo`, `nombre`, `nombre_en`) VALUES ('CN','China','China');
INSERT INTO `pais` (`codigo`, `nombre`, `nombre_en`) VALUES ('CO','Colombia','Colombia');
INSERT INTO `pais` (`codigo`, `nombre`, `nombre_en`) VALUES ('CR','Costa Rica','Costa Rica');
INSERT INTO `pais` (`codigo`, `nombre`, `nombre_en`) VALUES ('CU','Cuba','Cuba');
INSERT INTO `pais` (`codigo`, `nombre`, `nombre_en`) VALUES ('CV','Cabo Verde','Cabo Verde');
INSERT INTO `pais` (`codigo`, `nombre`, `nombre_en`) VALUES ('CW','Curazao','Curaçao');
INSERT INTO `pais` (`codigo`, `nombre`, `nombre_en`) VALUES ('CX','Isla de Navidad','Christmas Island');
INSERT INTO `pais` (`codigo`, `nombre`, `nombre_en`) VALUES ('CY','Chipre','Cyprus');
INSERT INTO `pais` (`codigo`, `nombre`, `nombre_en`) VALUES ('CZ','Chequia','Czechia');
INSERT INTO `pais` (`codigo`, `nombre`, `nombre_en`) VALUES ('DE','Alemania','Germany');
INSERT INTO `pais` (`codigo`, `nombre`, `nombre_en`) VALUES ('DJ','Yibuti','Djibouti');
INSERT INTO `pais` (`codigo`, `nombre`, `nombre_en`) VALUES ('DK','Dinamarca','Denmark');
INSERT INTO `pais` (`codigo`, `nombre`, `nombre_en`) VALUES ('DM','Dominica','Dominica');
INSERT INTO `pais` (`codigo`, `nombre`, `nombre_en`) VALUES ('DO','República Dominicana','Dominican Republic');
INSERT INTO `pais` (`codigo`, `nombre`, `nombre_en`) VALUES ('DZ','Algeria','Algeria');
INSERT INTO `pais` (`codigo`, `nombre`, `nombre_en`) VALUES ('EC','Ecuador','Ecuador');
INSERT INTO `pais` (`codigo`, `nombre`, `nombre_en`) VALUES ('EE','Estonia','Estonia');
INSERT INTO `pais` (`codigo`, `nombre`, `nombre_en`) VALUES ('EG','Egipto','Egypt');
INSERT INTO `pais` (`codigo`, `nombre`, `nombre_en`) VALUES ('EH','Sahara Occidental','Western Sahara');
INSERT INTO `pais` (`codigo`, `nombre`, `nombre_en`) VALUES ('ER','Eritrea','Eritrea');
INSERT INTO `pais` (`codigo`, `nombre`, `nombre_en`) VALUES ('ES','España','Spain');
INSERT INTO `pais` (`codigo`, `nombre`, `nombre_en`) VALUES ('ET','Etiopía','Ethiopia');
INSERT INTO `pais` (`codigo`, `nombre`, `nombre_en`) VALUES ('FI','Finlandia','Finland');
INSERT INTO `pais` (`codigo`, `nombre`, `nombre_en`) VALUES ('FJ','Fiyi','Fiji');
INSERT INTO `pais` (`codigo`, `nombre`, `nombre_en`) VALUES ('FK','Islas Falkland (Malvinas)','Falkland Islands (Malvinas)');
INSERT INTO `pais` (`codigo`, `nombre`, `nombre_en`) VALUES ('FM','Micronesia, Estados Federados de','Micronesia, Federated States of');
INSERT INTO `pais` (`codigo`, `nombre`, `nombre_en`) VALUES ('FO','Islas Feroe','Faroe Islands');
INSERT INTO `pais` (`codigo`, `nombre`, `nombre_en`) VALUES ('FR','Francia','France');
INSERT INTO `pais` (`codigo`, `nombre`, `nombre_en`) VALUES ('GA','Gabón','Gabon');
INSERT INTO `pais` (`codigo`, `nombre`, `nombre_en`) VALUES ('GB','Reino Unido','United Kingdom');
INSERT INTO `pais` (`codigo`, `nombre`, `nombre_en`) VALUES ('GD','Granada','Grenada');
INSERT INTO `pais` (`codigo`, `nombre`, `nombre_en`) VALUES ('GE','Georgia','Georgia');
INSERT INTO `pais` (`codigo`, `nombre`, `nombre_en`) VALUES ('GF','Guayana Francesa','French Guiana');
INSERT INTO `pais` (`codigo`, `nombre`, `nombre_en`) VALUES ('GG','Guernsey','Guernsey');
INSERT INTO `pais` (`codigo`, `nombre`, `nombre_en`) VALUES ('GH','Ghana','Ghana');
INSERT INTO `pais` (`codigo`, `nombre`, `nombre_en`) VALUES ('GI','Gibraltar','Gibraltar');
INSERT INTO `pais` (`codigo`, `nombre`, `nombre_en`) VALUES ('GL','Groenlandia','Greenland');
INSERT INTO `pais` (`codigo`, `nombre`, `nombre_en`) VALUES ('GM','Gambia','Gambia');
INSERT INTO `pais` (`codigo`, `nombre`, `nombre_en`) VALUES ('GN','Guinea','Guinea');
INSERT INTO `pais` (`codigo`, `nombre`, `nombre_en`) VALUES ('GP','Guadalupe','Guadeloupe');
INSERT INTO `pais` (`codigo`, `nombre`, `nombre_en`) VALUES ('GQ','Guinea Ecuatorial','Equatorial Guinea');
INSERT INTO `pais` (`codigo`, `nombre`, `nombre_en`) VALUES ('GR','Grecia','Greece');
INSERT INTO `pais` (`codigo`, `nombre`, `nombre_en`) VALUES ('GS','Islas Georgias del Sur y Sándwich del Sur','South Georgia and the South Sandwich Islands');
INSERT INTO `pais` (`codigo`, `nombre`, `nombre_en`) VALUES ('GT','Guatemala','Guatemala');
INSERT INTO `pais` (`codigo`, `nombre`, `nombre_en`) VALUES ('GU','Guam','Guam');
INSERT INTO `pais` (`codigo`, `nombre`, `nombre_en`) VALUES ('GW','Guinea-Bisáu','Guinea-Bissau');
INSERT INTO `pais` (`codigo`, `nombre`, `nombre_en`) VALUES ('GY','Guyana','Guyana');
INSERT INTO `pais` (`codigo`, `nombre`, `nombre_en`) VALUES ('HK','Hong Kong','Hong Kong');
INSERT INTO `pais` (`codigo`, `nombre`, `nombre_en`) VALUES ('HM','Islas Heard y McDonald','Heard Island and McDonald Islands');
INSERT INTO `pais` (`codigo`, `nombre`, `nombre_en`) VALUES ('HN','Honduras','Honduras');
INSERT INTO `pais` (`codigo`, `nombre`, `nombre_en`) VALUES ('HR','Croacia','Croatia');
INSERT INTO `pais` (`codigo`, `nombre`, `nombre_en`) VALUES ('HT','Haití','Haiti');
INSERT INTO `pais` (`codigo`, `nombre`, `nombre_en`) VALUES ('HU','Hungría','Hungary');
INSERT INTO `pais` (`codigo`, `nombre`, `nombre_en`) VALUES ('ID','Indonesia','Indonesia');
INSERT INTO `pais` (`codigo`, `nombre`, `nombre_en`) VALUES ('IE','Irlanda','Ireland');
INSERT INTO `pais` (`codigo`, `nombre`, `nombre_en`) VALUES ('IL','Israel','Israel');
INSERT INTO `pais` (`codigo`, `nombre`, `nombre_en`) VALUES ('IM','Isla de Man','Isle of Man');
INSERT INTO `pais` (`codigo`, `nombre`, `nombre_en`) VALUES ('IN','India','India');
INSERT INTO `pais` (`codigo`, `nombre`, `nombre_en`) VALUES ('IO','Territorio Británico del Océano Índico','British Indian Ocean Territory');
INSERT INTO `pais` (`codigo`, `nombre`, `nombre_en`) VALUES ('IQ','Irak','Iraq');
INSERT INTO `pais` (`codigo`, `nombre`, `nombre_en`) VALUES ('IR','Irán','Iran');
INSERT INTO `pais` (`codigo`, `nombre`, `nombre_en`) VALUES ('IS','Islandia','Iceland');
INSERT INTO `pais` (`codigo`, `nombre`, `nombre_en`) VALUES ('IT','Italia','Italy');
INSERT INTO `pais` (`codigo`, `nombre`, `nombre_en`) VALUES ('JE','Jersey','Jersey');
INSERT INTO `pais` (`codigo`, `nombre`, `nombre_en`) VALUES ('JM','Jamaica','Jamaica');
INSERT INTO `pais` (`codigo`, `nombre`, `nombre_en`) VALUES ('JO','Jordania','Jordan');
INSERT INTO `pais` (`codigo`, `nombre`, `nombre_en`) VALUES ('JP','Japón','Japan');
INSERT INTO `pais` (`codigo`, `nombre`, `nombre_en`) VALUES ('KE','Kenia','Kenya');
INSERT INTO `pais` (`codigo`, `nombre`, `nombre_en`) VALUES ('KG','Kirguistán','Kyrgyzstan');
INSERT INTO `pais` (`codigo`, `nombre`, `nombre_en`) VALUES ('KH','Camboya','Cambodia');
INSERT INTO `pais` (`codigo`, `nombre`, `nombre_en`) VALUES ('KI','Kiribati','Kiribati');
INSERT INTO `pais` (`codigo`, `nombre`, `nombre_en`) VALUES ('KM','Comores, Islas','Comoros');
INSERT INTO `pais` (`codigo`, `nombre`, `nombre_en`) VALUES ('KN','San Cristóbal y Nieves','Saint Kitts and Nevis');
INSERT INTO `pais` (`codigo`, `nombre`, `nombre_en`) VALUES ('KP','Corea del Norte','North Korea');
INSERT INTO `pais` (`codigo`, `nombre`, `nombre_en`) VALUES ('KR','Corea del Sur','South Korea');
INSERT INTO `pais` (`codigo`, `nombre`, `nombre_en`) VALUES ('KW','Kuwait','Kuwait');
INSERT INTO `pais` (`codigo`, `nombre`, `nombre_en`) VALUES ('KY','Islas Caimán','Cayman Islands');
INSERT INTO `pais` (`codigo`, `nombre`, `nombre_en`) VALUES ('KZ','Kazajistán','Kazakhstan');
INSERT INTO `pais` (`codigo`, `nombre`, `nombre_en`) VALUES ('LA','Laos','Laos');
INSERT INTO `pais` (`codigo`, `nombre`, `nombre_en`) VALUES ('LB','Líbano','Lebanon');
INSERT INTO `pais` (`codigo`, `nombre`, `nombre_en`) VALUES ('LC','Santa Lucía','Saint Lucia');
INSERT INTO `pais` (`codigo`, `nombre`, `nombre_en`) VALUES ('LI','Liechtenstein','Liechtenstein');
INSERT INTO `pais` (`codigo`, `nombre`, `nombre_en`) VALUES ('LK','Sri Lanka','Sri Lanka');
INSERT INTO `pais` (`codigo`, `nombre`, `nombre_en`) VALUES ('LR','Liberia','Liberia');
INSERT INTO `pais` (`codigo`, `nombre`, `nombre_en`) VALUES ('LS','Lesoto','Lesotho');
INSERT INTO `pais` (`codigo`, `nombre`, `nombre_en`) VALUES ('LT','Lituania','Lithuania');
INSERT INTO `pais` (`codigo`, `nombre`, `nombre_en`) VALUES ('LU','Luxemburgo','Luxembourg');
INSERT INTO `pais` (`codigo`, `nombre`, `nombre_en`) VALUES ('LV','Letonia','Latvia');
INSERT INTO `pais` (`codigo`, `nombre`, `nombre_en`) VALUES ('LY','Libia','Libya');
INSERT INTO `pais` (`codigo`, `nombre`, `nombre_en`) VALUES ('MA','Marruecos','Morocco');
INSERT INTO `pais` (`codigo`, `nombre`, `nombre_en`) VALUES ('MC','Mónaco','Monaco');
INSERT INTO `pais` (`codigo`, `nombre`, `nombre_en`) VALUES ('MD','Moldavia','Moldova');
INSERT INTO `pais` (`codigo`, `nombre`, `nombre_en`) VALUES ('ME','Montenegro','Montenegro');
INSERT INTO `pais` (`codigo`, `nombre`, `nombre_en`) VALUES ('MF','San Martín (zona francesa)','Saint Martin (French part)');
INSERT INTO `pais` (`codigo`, `nombre`, `nombre_en`) VALUES ('MG','Madagascar','Madagascar');
INSERT INTO `pais` (`codigo`, `nombre`, `nombre_en`) VALUES ('MH','Islas Marshall','Marshall Islands');
INSERT INTO `pais` (`codigo`, `nombre`, `nombre_en`) VALUES ('MK','Macedonia del Norte','North Macedonia');
INSERT INTO `pais` (`codigo`, `nombre`, `nombre_en`) VALUES ('ML','Malí','Mali');
INSERT INTO `pais` (`codigo`, `nombre`, `nombre_en`) VALUES ('MM','Birmania','Myanmar');
INSERT INTO `pais` (`codigo`, `nombre`, `nombre_en`) VALUES ('MN','Mongolia','Mongolia');
INSERT INTO `pais` (`codigo`, `nombre`, `nombre_en`) VALUES ('MO','Macao','Macao');
INSERT INTO `pais` (`codigo`, `nombre`, `nombre_en`) VALUES ('MP','Islas Marianas del Norte','Northern Mariana Islands');
INSERT INTO `pais` (`codigo`, `nombre`, `nombre_en`) VALUES ('MQ','Martinica','Martinique');
INSERT INTO `pais` (`codigo`, `nombre`, `nombre_en`) VALUES ('MR','Mauritania','Mauritania');
INSERT INTO `pais` (`codigo`, `nombre`, `nombre_en`) VALUES ('MS','Montserrat','Montserrat');
INSERT INTO `pais` (`codigo`, `nombre`, `nombre_en`) VALUES ('MT','Malta','Malta');
INSERT INTO `pais` (`codigo`, `nombre`, `nombre_en`) VALUES ('MU','Mauricio','Mauritius');
INSERT INTO `pais` (`codigo`, `nombre`, `nombre_en`) VALUES ('MV','Islas Maldivas','Maldives');
INSERT INTO `pais` (`codigo`, `nombre`, `nombre_en`) VALUES ('MW','Malaui','Malawi');
INSERT INTO `pais` (`codigo`, `nombre`, `nombre_en`) VALUES ('MX','México','Mexico');
INSERT INTO `pais` (`codigo`, `nombre`, `nombre_en`) VALUES ('MY','Malasia','Malaysia');
INSERT INTO `pais` (`codigo`, `nombre`, `nombre_en`) VALUES ('MZ','Mozambique','Mozambique');
INSERT INTO `pais` (`codigo`, `nombre`, `nombre_en`) VALUES ('NA','Namibia','Namibia');
INSERT INTO `pais` (`codigo`, `nombre`, `nombre_en`) VALUES ('NC','Nueva Caledonia','New Caledonia');
INSERT INTO `pais` (`codigo`, `nombre`, `nombre_en`) VALUES ('NE','Niger','Niger');
INSERT INTO `pais` (`codigo`, `nombre`, `nombre_en`) VALUES ('NF','Isla Norfolk','Norfolk Island');
INSERT INTO `pais` (`codigo`, `nombre`, `nombre_en`) VALUES ('NG','Nigeria','Nigeria');
INSERT INTO `pais` (`codigo`, `nombre`, `nombre_en`) VALUES ('NI','Nicaragua','Nicaragua');
INSERT INTO `pais` (`codigo`, `nombre`, `nombre_en`) VALUES ('NL','Países Bajos','Netherlands');
INSERT INTO `pais` (`codigo`, `nombre`, `nombre_en`) VALUES ('NO','Noruega','Norway');
INSERT INTO `pais` (`codigo`, `nombre`, `nombre_en`) VALUES ('NP','Nepal','Nepal');
INSERT INTO `pais` (`codigo`, `nombre`, `nombre_en`) VALUES ('NR','Nauru','Nauru');
INSERT INTO `pais` (`codigo`, `nombre`, `nombre_en`) VALUES ('NU','Niue','Niue');
INSERT INTO `pais` (`codigo`, `nombre`, `nombre_en`) VALUES ('NZ','Nueva Zelanda','New Zealand');
INSERT INTO `pais` (`codigo`, `nombre`, `nombre_en`) VALUES ('OM','Omán','Oman');
INSERT INTO `pais` (`codigo`, `nombre`, `nombre_en`) VALUES ('PA','Panamá','Panama');
INSERT INTO `pais` (`codigo`, `nombre`, `nombre_en`) VALUES ('PE','Perú','Peru');
INSERT INTO `pais` (`codigo`, `nombre`, `nombre_en`) VALUES ('PF','Polinesia Francesa','French Polynesia');
INSERT INTO `pais` (`codigo`, `nombre`, `nombre_en`) VALUES ('PG','Papúa Nueva Guinea','Papua New Guinea');
INSERT INTO `pais` (`codigo`, `nombre`, `nombre_en`) VALUES ('PH','Filipinas','Philippines');
INSERT INTO `pais` (`codigo`, `nombre`, `nombre_en`) VALUES ('PK','Pakistán','Pakistan');
INSERT INTO `pais` (`codigo`, `nombre`, `nombre_en`) VALUES ('PL','Polonia','Poland');
INSERT INTO `pais` (`codigo`, `nombre`, `nombre_en`) VALUES ('PM','San Pedro y Miquelon','Saint Pierre and Miquelon');
INSERT INTO `pais` (`codigo`, `nombre`, `nombre_en`) VALUES ('PN','Pitcairn','Pitcairn');
INSERT INTO `pais` (`codigo`, `nombre`, `nombre_en`) VALUES ('PR','Puerto Rico','Puerto Rico');
INSERT INTO `pais` (`codigo`, `nombre`, `nombre_en`) VALUES ('PS','Palestina, Estado de','Palestine, State of');
INSERT INTO `pais` (`codigo`, `nombre`, `nombre_en`) VALUES ('PT','Portugal','Portugal');
INSERT INTO `pais` (`codigo`, `nombre`, `nombre_en`) VALUES ('PW','Palaos','Palau');
INSERT INTO `pais` (`codigo`, `nombre`, `nombre_en`) VALUES ('PY','Paraguay','Paraguay');
INSERT INTO `pais` (`codigo`, `nombre`, `nombre_en`) VALUES ('QA','Catar','Qatar');
INSERT INTO `pais` (`codigo`, `nombre`, `nombre_en`) VALUES ('RE','Reunión','Réunion');
INSERT INTO `pais` (`codigo`, `nombre`, `nombre_en`) VALUES ('RO','Rumanía','Romania');
INSERT INTO `pais` (`codigo`, `nombre`, `nombre_en`) VALUES ('RS','Serbia','Serbia');
INSERT INTO `pais` (`codigo`, `nombre`, `nombre_en`) VALUES ('RU','Federación Rusa','Russian Federation');
INSERT INTO `pais` (`codigo`, `nombre`, `nombre_en`) VALUES ('RW','Ruanda','Rwanda');
INSERT INTO `pais` (`codigo`, `nombre`, `nombre_en`) VALUES ('SA','Arabia Saudí','Saudi Arabia');
INSERT INTO `pais` (`codigo`, `nombre`, `nombre_en`) VALUES ('SB','Islas Salomón','Solomon Islands');
INSERT INTO `pais` (`codigo`, `nombre`, `nombre_en`) VALUES ('SC','Seychelles','Seychelles');
INSERT INTO `pais` (`codigo`, `nombre`, `nombre_en`) VALUES ('SD','Sudán','Sudan');
INSERT INTO `pais` (`codigo`, `nombre`, `nombre_en`) VALUES ('SE','Suecia','Sweden');
INSERT INTO `pais` (`codigo`, `nombre`, `nombre_en`) VALUES ('SG','Singapur','Singapore');
INSERT INTO `pais` (`codigo`, `nombre`, `nombre_en`) VALUES ('SH','Santa Elena, Ascensión y Tristán de Acuña','Saint Helena, Ascension and Tristan da Cunha');
INSERT INTO `pais` (`codigo`, `nombre`, `nombre_en`) VALUES ('SI','Eslovenia','Slovenia');
INSERT INTO `pais` (`codigo`, `nombre`, `nombre_en`) VALUES ('SJ','Svalbard y Jan Mayen','Svalbard and Jan Mayen');
INSERT INTO `pais` (`codigo`, `nombre`, `nombre_en`) VALUES ('SK','Eslovaquia','Slovakia');
INSERT INTO `pais` (`codigo`, `nombre`, `nombre_en`) VALUES ('SL','Sierra Leona','Sierra Leone');
INSERT INTO `pais` (`codigo`, `nombre`, `nombre_en`) VALUES ('SM','San Marino','San Marino');
INSERT INTO `pais` (`codigo`, `nombre`, `nombre_en`) VALUES ('SN','Senegal','Senegal');
INSERT INTO `pais` (`codigo`, `nombre`, `nombre_en`) VALUES ('SO','Somalia','Somalia');
INSERT INTO `pais` (`codigo`, `nombre`, `nombre_en`) VALUES ('SR','Surinám','Suriname');
INSERT INTO `pais` (`codigo`, `nombre`, `nombre_en`) VALUES ('SS','Sudán del Sur','South Sudan');
INSERT INTO `pais` (`codigo`, `nombre`, `nombre_en`) VALUES ('ST','Santo Tomé y Príncipe','Sao Tome and Principe');
INSERT INTO `pais` (`codigo`, `nombre`, `nombre_en`) VALUES ('SV','El Salvador','El Salvador');
INSERT INTO `pais` (`codigo`, `nombre`, `nombre_en`) VALUES ('SX','Isla de San Martín (zona holandsea)','Sint Maarten (Dutch part)');
INSERT INTO `pais` (`codigo`, `nombre`, `nombre_en`) VALUES ('SY','Siria','Syria');
INSERT INTO `pais` (`codigo`, `nombre`, `nombre_en`) VALUES ('SZ','Esuatini','Eswatini');
INSERT INTO `pais` (`codigo`, `nombre`, `nombre_en`) VALUES ('TC','Islas Turcas y Caicos','Turks and Caicos Islands');
INSERT INTO `pais` (`codigo`, `nombre`, `nombre_en`) VALUES ('TD','Chad','Chad');
INSERT INTO `pais` (`codigo`, `nombre`, `nombre_en`) VALUES ('TF','Territorios Franceses del Sur','French Southern Territories');
INSERT INTO `pais` (`codigo`, `nombre`, `nombre_en`) VALUES ('TG','Togo','Togo');
INSERT INTO `pais` (`codigo`, `nombre`, `nombre_en`) VALUES ('TH','Tailandia','Thailand');
INSERT INTO `pais` (`codigo`, `nombre`, `nombre_en`) VALUES ('TJ','Tayikistán','Tajikistan');
INSERT INTO `pais` (`codigo`, `nombre`, `nombre_en`) VALUES ('TK','Tokelau','Tokelau');
INSERT INTO `pais` (`codigo`, `nombre`, `nombre_en`) VALUES ('TL','Timor Oriental','Timor-Leste');
INSERT INTO `pais` (`codigo`, `nombre`, `nombre_en`) VALUES ('TM','Turkmenistán','Turkmenistan');
INSERT INTO `pais` (`codigo`, `nombre`, `nombre_en`) VALUES ('TN','Tunez','Tunisia');
INSERT INTO `pais` (`codigo`, `nombre`, `nombre_en`) VALUES ('TO','Tonga','Tonga');
INSERT INTO `pais` (`codigo`, `nombre`, `nombre_en`) VALUES ('TR','Turquía','Türkiye');
INSERT INTO `pais` (`codigo`, `nombre`, `nombre_en`) VALUES ('TT','Trinidad y Tobago','Trinidad and Tobago');
INSERT INTO `pais` (`codigo`, `nombre`, `nombre_en`) VALUES ('TV','Tuvalu','Tuvalu');
INSERT INTO `pais` (`codigo`, `nombre`, `nombre_en`) VALUES ('TW','Taiwán','Taiwan');
INSERT INTO `pais` (`codigo`, `nombre`, `nombre_en`) VALUES ('TZ','Tanzania','Tanzania');
INSERT INTO `pais` (`codigo`, `nombre`, `nombre_en`) VALUES ('UA','Ucrania','Ukraine');
INSERT INTO `pais` (`codigo`, `nombre`, `nombre_en`) VALUES ('UG','Uganda','Uganda');
INSERT INTO `pais` (`codigo`, `nombre`, `nombre_en`) VALUES ('UM','Islas Ultramarinas Menores de Estados Unidos','United States Minor Outlying Islands');
INSERT INTO `pais` (`codigo`, `nombre`, `nombre_en`) VALUES ('US','Estados Unidos','United States');
INSERT INTO `pais` (`codigo`, `nombre`, `nombre_en`) VALUES ('UY','Uruguay','Uruguay');
INSERT INTO `pais` (`codigo`, `nombre`, `nombre_en`) VALUES ('UZ','Uzbekistán','Uzbekistan');
INSERT INTO `pais` (`codigo`, `nombre`, `nombre_en`) VALUES ('VA','Santa Sede (Ciudad Estado del Vaticano)','Holy See (Vatican City State)');
INSERT INTO `pais` (`codigo`, `nombre`, `nombre_en`) VALUES ('VC','San Vicente y las Granadinas','Saint Vincent and the Grenadines');
INSERT INTO `pais` (`codigo`, `nombre`, `nombre_en`) VALUES ('VE','Venezuela','Venezuela');
INSERT INTO `pais` (`codigo`, `nombre`, `nombre_en`) VALUES ('VG','Islas Vírgenes, Británicas','Virgin Islands, British');
INSERT INTO `pais` (`codigo`, `nombre`, `nombre_en`) VALUES ('VI','Islas Vírgenes, de EEUU','Virgin Islands, U.S.');
INSERT INTO `pais` (`codigo`, `nombre`, `nombre_en`) VALUES ('VN','Vietnam','Vietnam');
INSERT INTO `pais` (`codigo`, `nombre`, `nombre_en`) VALUES ('VU','Vanuatu','Vanuatu');
INSERT INTO `pais` (`codigo`, `nombre`, `nombre_en`) VALUES ('WF','Wallis y Futuna','Wallis and Futuna');
INSERT INTO `pais` (`codigo`, `nombre`, `nombre_en`) VALUES ('WS','Samoa','Samoa');
INSERT INTO `pais` (`codigo`, `nombre`, `nombre_en`) VALUES ('YE','Yemen','Yemen');
INSERT INTO `pais` (`codigo`, `nombre`, `nombre_en`) VALUES ('YT','Mayotte','Mayotte');
INSERT INTO `pais` (`codigo`, `nombre`, `nombre_en`) VALUES ('ZA','Sudáfrica','South Africa');
INSERT INTO `pais` (`codigo`, `nombre`, `nombre_en`) VALUES ('ZM','Zambia','Zambia');
INSERT INTO `pais` (`codigo`, `nombre`, `nombre_en`) VALUES ('ZW','Zimbabue','Zimbabwe');
INSERT INTO `licencias` (`id`, `etiqueta`, `url`, `spdx`, `abierta`, `para_contenido`, `para_codigo`, `orden`, `activo`) VALUES (1,'CC BY 4.0','https://creativecommons.org/licenses/by/4.0/','CC-BY-4.0',1,1,0,10,1);
INSERT INTO `licencias` (`id`, `etiqueta`, `url`, `spdx`, `abierta`, `para_contenido`, `para_codigo`, `orden`, `activo`) VALUES (2,'CC BY-SA 4.0','https://creativecommons.org/licenses/by-sa/4.0/','CC-BY-SA-4.0',1,1,0,20,1);
INSERT INTO `licencias` (`id`, `etiqueta`, `url`, `spdx`, `abierta`, `para_contenido`, `para_codigo`, `orden`, `activo`) VALUES (3,'CC BY-NC 4.0','https://creativecommons.org/licenses/by-nc/4.0/','CC-BY-NC-4.0',1,1,0,30,1);
INSERT INTO `licencias` (`id`, `etiqueta`, `url`, `spdx`, `abierta`, `para_contenido`, `para_codigo`, `orden`, `activo`) VALUES (4,'CC BY-NC-SA 4.0','https://creativecommons.org/licenses/by-nc-sa/4.0/','CC-BY-NC-SA-4.0',1,1,0,40,1);
INSERT INTO `licencias` (`id`, `etiqueta`, `url`, `spdx`, `abierta`, `para_contenido`, `para_codigo`, `orden`, `activo`) VALUES (5,'CC BY-ND 4.0','https://creativecommons.org/licenses/by-nd/4.0/','CC-BY-ND-4.0',1,1,0,50,1);
INSERT INTO `licencias` (`id`, `etiqueta`, `url`, `spdx`, `abierta`, `para_contenido`, `para_codigo`, `orden`, `activo`) VALUES (6,'CC BY-NC-ND 4.0','https://creativecommons.org/licenses/by-nc-nd/4.0/','CC-BY-NC-ND-4.0',1,1,0,60,1);
INSERT INTO `licencias` (`id`, `etiqueta`, `url`, `spdx`, `abierta`, `para_contenido`, `para_codigo`, `orden`, `activo`) VALUES (7,'CC0 1.0','https://creativecommons.org/publicdomain/zero/1.0/','CC0-1.0',1,1,1,70,1);
INSERT INTO `licencias` (`id`, `etiqueta`, `url`, `spdx`, `abierta`, `para_contenido`, `para_codigo`, `orden`, `activo`) VALUES (8,'MIT','https://opensource.org/licenses/MIT','MIT',1,1,1,80,1);
INSERT INTO `licencias` (`id`, `etiqueta`, `url`, `spdx`, `abierta`, `para_contenido`, `para_codigo`, `orden`, `activo`) VALUES (9,'GPL v3','https://www.gnu.org/licenses/gpl-3.0.html',NULL,1,1,1,90,1);
INSERT INTO `licencias` (`id`, `etiqueta`, `url`, `spdx`, `abierta`, `para_contenido`, `para_codigo`, `orden`, `activo`) VALUES (10,'GPL v2','https://www.gnu.org/licenses/old-licenses/gpl-2.0-standalone.html',NULL,1,0,1,100,1);
INSERT INTO `licencias` (`id`, `etiqueta`, `url`, `spdx`, `abierta`, `para_contenido`, `para_codigo`, `orden`, `activo`) VALUES (11,'Apache 2.0','https://www.apache.org/licenses/LICENSE-2.0','Apache-2.0',1,1,1,110,1);
INSERT INTO `licencias` (`id`, `etiqueta`, `url`, `spdx`, `abierta`, `para_contenido`, `para_codigo`, `orden`, `activo`) VALUES (12,'BSD 2-Clause','https://opensource.org/license/BSD-2-Clause','BSD-2-Clause',1,0,1,120,1);
INSERT INTO `licencias` (`id`, `etiqueta`, `url`, `spdx`, `abierta`, `para_contenido`, `para_codigo`, `orden`, `activo`) VALUES (13,'BSD 3-Clause','https://opensource.org/licenses/BSD-3-Clause','BSD-3-Clause',1,1,1,130,1);
INSERT INTO `licencias` (`id`, `etiqueta`, `url`, `spdx`, `abierta`, `para_contenido`, `para_codigo`, `orden`, `activo`) VALUES (14,'LGPL v3','https://www.gnu.org/licenses/lgpl-3.0-standalone.html',NULL,1,0,1,140,1);
INSERT INTO `licencias` (`id`, `etiqueta`, `url`, `spdx`, `abierta`, `para_contenido`, `para_codigo`, `orden`, `activo`) VALUES (15,'MPL 2.0','https://www.mozilla.org/MPL/2.0/','MPL-2.0',1,0,1,150,1);
INSERT INTO `licencias` (`id`, `etiqueta`, `url`, `spdx`, `abierta`, `para_contenido`, `para_codigo`, `orden`, `activo`) VALUES (16,'AGPL v3','https://www.gnu.org/licenses/agpl.txt',NULL,1,0,1,160,1);
INSERT INTO `licencias` (`id`, `etiqueta`, `url`, `spdx`, `abierta`, `para_contenido`, `para_codigo`, `orden`, `activo`) VALUES (17,'Unlicense','https://unlicense.org/','Unlicense',1,0,1,170,1);
INSERT INTO `licencias` (`id`, `etiqueta`, `url`, `spdx`, `abierta`, `para_contenido`, `para_codigo`, `orden`, `activo`) VALUES (18,'Todos los derechos reservados',NULL,NULL,0,1,0,180,1);
INSERT INTO `licencias` (`id`, `etiqueta`, `url`, `spdx`, `abierta`, `para_contenido`, `para_codigo`, `orden`, `activo`) VALUES (19,'Propietaria',NULL,NULL,0,0,1,190,1);
INSERT INTO `licencia_texto` (`url`, `idioma`, `texto`) VALUES ('https://creativecommons.org/licenses/by-nc-nd/4.0/','es','Se permite el uso y distribución sin fines comerciales, siempre que se cite la obra original y no se realicen obras derivadas.');
INSERT INTO `licencia_texto` (`url`, `idioma`, `texto`) VALUES ('https://creativecommons.org/licenses/by-nc-sa/4.0/','es','Se permite el uso, distribución y reproducción sin fines comerciales, siempre que se cite la obra original y las obras derivadas se distribuyan bajo la misma licencia.');
INSERT INTO `licencia_texto` (`url`, `idioma`, `texto`) VALUES ('https://creativecommons.org/licenses/by-nc/4.0/','es','Se permite el uso, distribución y reproducción sin fines comerciales, siempre que se cite la obra original.');
INSERT INTO `licencia_texto` (`url`, `idioma`, `texto`) VALUES ('https://creativecommons.org/licenses/by-nd/4.0/','es','Se permite el uso y distribución, incluso con fines comerciales, siempre que se cite la obra original y no se realicen obras derivadas.');
INSERT INTO `licencia_texto` (`url`, `idioma`, `texto`) VALUES ('https://creativecommons.org/licenses/by-sa/4.0/','es','Se permite el uso, distribución y reproducción, incluso con fines comerciales, siempre que se cite la obra original y las obras derivadas se distribuyan bajo la misma licencia.');
INSERT INTO `licencia_texto` (`url`, `idioma`, `texto`) VALUES ('https://creativecommons.org/licenses/by/4.0/','es','Se permite el uso, distribución y reproducción sin restricciones, incluso con fines comerciales, siempre que se cite la obra original.');
INSERT INTO `tipo_declaracion` (`codigo`, `etiqueta`, `bloque`, `orden`, `activo`) VALUES ('conflicto_interes','Conflicto de intereses',NULL,20,1);
INSERT INTO `tipo_declaracion` (`codigo`, `etiqueta`, `bloque`, `orden`, `activo`) VALUES ('disponibilidad_datos','Disponibilidad de datos',NULL,15,1);
INSERT INTO `tipo_declaracion` (`codigo`, `etiqueta`, `bloque`, `orden`, `activo`) VALUES ('financiamiento','Declaración de financiamiento',NULL,10,1);

-- ------------------------------------------------------------------
-- 3. CORRECCIONES DE CONSISTENCIA
-- ------------------------------------------------------------------

-- LAS CONSULTAS CANÓNICAS DEBEN QUEDAR MARCADAS COMO DEL SISTEMA PARA
-- QUE LOS PARCHES FUTUROS PUEDAN DISTINGUIRLAS DE LAS QUE GUARDE EL
-- EDITOR EN CADA INSTALACIÓN.
UPDATE `consultas` SET `consulta_sistema` = 1;

-- ------------------------------------------------------------------
-- 4. CONTROL DE VERSIÓN DE ESQUEMA
-- ------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS `esquema_version` (
  `parche`      VARCHAR(50)  NOT NULL,
  `aplicado_en` TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `descripcion` VARCHAR(255) DEFAULT NULL,
  PRIMARY KEY (`parche`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci ROW_FORMAT=DYNAMIC;

INSERT IGNORE INTO `esquema_version` (`parche`, `descripcion`)
VALUES ('baseline-2.0.0', 'Esquema de distribución inicial');

/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;
/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;

-- Baseline 2.0.0 generado el 2026-11-20 20:40:51 — fin del archivo.
