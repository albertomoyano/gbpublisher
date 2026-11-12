#!/usr/bin/env bash
#
# ============================================
# Script    : actualizar-esquema-1.26.0.sh
# Propósito : Actualización 1.26.0 de la base de gbpublisher, sobre una base
#             EN USO y preservando sus datos. La EDITORIAL como entidad
#             propia, madre de sus revistas, y lo que necesita la página
#             legal del número (decisiones de Alberto del 12/11/2026,
#             claude/salidas-revistas.md, «B1»):
#               1. editorial             la editorial o institución: nombre,
#                                        institución, ROR, dirección, ciudad,
#                                        país, portal, email, prefijo DOI,
#                                        licencia y titular por defecto,
#                                        leyenda de distribución y aviso de
#                                        responsabilidad
#               2. editorial_credito     autoridades y producción, una fila
#                                        por persona, con vigencia
#               3. revista.id_editorial  la editorial de la revista
#                  revista.rotulo_volumen «Año», «Vol.»: «Año III»
#               4. revista_organo        los órganos editoriales de cada
#                                        revista, con su nombre
#               5. revista_organo_miembro sus miembros (tabla autores), con
#                                        la afiliación y la vigencia
#               6. numero_pieza          las preliminares declaradas del
#                                        número en fm-00 a fm-09 (tapa,
#                                        legales, sumario), como SC-25
#             MIGRA: una editorial por cada combinación distinta de los
#             datos de editorial de las revistas, y vincula cada revista.
#             LAS COLUMNAS VIEJAS DE revista SE CONSERVAN (decisión de
#             Alberto: dos esquemas). Cada entrega pasa sus lectores a la
#             editorial y la 1.27.0 las borra. email_editorial queda para
#             siempre: es el reemplazo opcional de la revista sobre el
#             email de la editorial.
#             Al final emite un INFORME DE CONTROL, solo de lectura.
# Uso       : sudo bash actualizar-esquema-1.26.0.sh
# Requisitos: MySQL 8.0.16 o posterior (CHECK).
# Reglas    : BBDD_LEEME.md §5 y SC-22. IDEMPOTENTE; respaldo verificado;
#             verificación posterior; sin efecto si ya está aplicado.
#             Exige la 1.25.0 registrada. Qué cambiar lo decide el ESTADO
#             REAL.
# Lote      : m_ConexionBD.ObtenerEsquemaEsperado: sin cambios todavía (lo
#             sube la entrega que empieza a leer las tablas nuevas).
# ============================================

set -euo pipefail

# --- 0. CONFIGURACIÓN ---
DB="gbpublisher"
PARCHE="actualizacion-1.26.0"
PREVIO="actualizacion-1.25.0"
DESCRIPCION="Editorial como entidad, créditos, órganos editoriales y preliminares del número"
DIR_RESPALDO="${HOME}/gbpublisher-respaldos"

# LAS TABLAS NUEVAS, EN ORDEN DE CREACIÓN (LAS CLAVES FORÁNEAS LO EXIGEN) Y
# AL REVÉS PARA VOLVER ATRÁS
TABLAS=(editorial editorial_credito revista_organo revista_organo_miembro numero_pieza)

# LA CLAVE DE AGRUPAMIENTO DE LA MIGRACIÓN: LOS CINCO DATOS DE IDENTIDAD DE
# LA EDITORIAL EN LA REVISTA. COALESCE: DOS NULOS SON LA MISMA EDITORIAL
CLAVE="CONCAT_WS('|', COALESCE(ALIAS.editorial,''), COALESCE(ALIAS.institucion_editora,''), COALESCE(ALIAS.ror_editorial,''), COALESCE(ALIAS.ciudad,''), COALESCE(ALIAS.pais,''))"

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

existe_tabla() {
  valor "SELECT COUNT(*) FROM information_schema.TABLES WHERE TABLE_SCHEMA='${DB}' AND TABLE_NAME='$1';"
}

existe_columna() {
  valor "SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA='${DB}' AND TABLE_NAME='$1' AND COLUMN_NAME='$2';"
}

# LA CLAVE DE AGRUPAMIENTO CON EL ALIAS DE TABLA PEDIDO
clave() {
  printf '%s' "${CLAVE//ALIAS/$1}"
}

# --- 1. DEFINICIONES ---
declare -A DDL

DDL[editorial]="CREATE TABLE IF NOT EXISTS editorial (
  id_editorial INT NOT NULL AUTO_INCREMENT,
  nombre VARCHAR(300) NOT NULL COMMENT 'JATS publisher-name: EDUNPAZ, Editorial Universitaria',
  institucion VARCHAR(300) NULL DEFAULT NULL COMMENT 'La institución de la que depende: Universidad Nacional de José C. Paz',
  ror VARCHAR(50) NULL DEFAULT NULL,
  direccion VARCHAR(300) NULL DEFAULT NULL COMMENT 'Página legal: Leandro N. Alem 4731, José C. Paz',
  region VARCHAR(200) NULL DEFAULT NULL COMMENT 'Provincia o estado: Pcia. de Buenos Aires',
  ciudad VARCHAR(200) NULL DEFAULT NULL COMMENT 'JATS publisher-loc',
  pais VARCHAR(100) NULL DEFAULT NULL,
  url_portal VARCHAR(500) NULL DEFAULT NULL,
  email VARCHAR(200) NULL DEFAULT NULL COMMENT 'Contacto y depositante de Crossref; la revista lo puede reemplazar (revista.email_editorial)',
  doi_prefix VARCHAR(50) NULL DEFAULT NULL COMMENT 'El prefijo del miembro de Crossref',
  licencia_defecto VARCHAR(100) NULL DEFAULT NULL COMMENT 'Lo heredan los artículos hasta publicar',
  url_licencia_defecto VARCHAR(500) NULL DEFAULT NULL COMMENT 'Lo heredan los artículos hasta publicar',
  titular_copyright_defecto VARCHAR(300) NULL DEFAULT NULL COMMENT 'Lo heredan los artículos hasta publicar',
  leyenda_distribucion VARCHAR(300) NULL DEFAULT NULL COMMENT 'Página legal: Publicación electrónica - distribución gratuita',
  aviso_responsabilidad TEXT NULL DEFAULT NULL COMMENT 'Página legal: Las opiniones expresadas en los artículos...',
  fecha_creacion DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  fecha_actualizacion TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id_editorial)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='La editorial o institución, madre de sus revistas';"

DDL[editorial_credito]="CREATE TABLE IF NOT EXISTS editorial_credito (
  id_credito INT NOT NULL AUTO_INCREMENT,
  id_editorial INT NOT NULL,
  cargo VARCHAR(200) NOT NULL COMMENT 'Rector, Corrección de estilo...: las filas del mismo cargo se agrupan al componer',
  nombre VARCHAR(300) NOT NULL COMMENT 'Una persona por fila',
  orden INT NOT NULL DEFAULT 0,
  desde DATE NOT NULL,
  hasta DATE NULL DEFAULT NULL COMMENT 'Nulo: vigente',
  PRIMARY KEY (id_credito),
  KEY fk_credito_editorial (id_editorial),
  CONSTRAINT fk_credito_editorial FOREIGN KEY (id_editorial) REFERENCES editorial (id_editorial) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT chk_credito_vigencia CHECK (hasta IS NULL OR hasta >= desde)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Autoridades y producción de la editorial, con vigencia (página legal)';"

DDL[revista_organo]="CREATE TABLE IF NOT EXISTS revista_organo (
  id_organo INT NOT NULL AUTO_INCREMENT,
  id_revista INT NOT NULL,
  nombre VARCHAR(200) NOT NULL COMMENT 'Como lo llama la revista: Comité editorial, Coordinadora editorial...',
  orden INT NOT NULL DEFAULT 0,
  activo TINYINT(1) NOT NULL DEFAULT 1,
  PRIMARY KEY (id_organo),
  KEY fk_organo_revista (id_revista),
  CONSTRAINT fk_organo_revista FOREIGN KEY (id_revista) REFERENCES revista (id_revista) ON DELETE RESTRICT ON UPDATE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Órganos editoriales de la revista (página legal)';"

DDL[revista_organo_miembro]="CREATE TABLE IF NOT EXISTS revista_organo_miembro (
  id_miembro INT NOT NULL AUTO_INCREMENT,
  id_organo INT NOT NULL,
  id_autor INT NOT NULL,
  afiliacion VARCHAR(300) NULL DEFAULT NULL COMMENT 'La que se muestra: IESCODE-UNPAZ/CONICET, Argentina. Va en la membresía: cambia con el tiempo',
  orden INT NOT NULL DEFAULT 0,
  desde DATE NOT NULL,
  hasta DATE NULL DEFAULT NULL COMMENT 'Nulo: vigente',
  PRIMARY KEY (id_miembro),
  KEY fk_miembro_organo (id_organo),
  KEY fk_miembro_autor (id_autor),
  CONSTRAINT fk_miembro_organo FOREIGN KEY (id_organo) REFERENCES revista_organo (id_organo) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT fk_miembro_autor FOREIGN KEY (id_autor) REFERENCES autores (id_autor) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT chk_miembro_vigencia CHECK (hasta IS NULL OR hasta >= desde)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Miembros de un órgano editorial, con vigencia';"

DDL[numero_pieza]="CREATE TABLE IF NOT EXISTS numero_pieza (
  id_pieza INT NOT NULL AUTO_INCREMENT,
  id_numero INT NOT NULL,
  nombre_archivo VARCHAR(100) NOT NULL COMMENT 'Espacio reservado fm-00 a fm-09: el nombre da la posición (SC-25)',
  tipo ENUM('tapa','legales','sumario') NOT NULL,
  PRIMARY KEY (id_pieza),
  UNIQUE KEY uq_pieza_nombre (id_numero, nombre_archivo),
  UNIQUE KEY uq_pieza_tipo (id_numero, tipo),
  CONSTRAINT fk_pieza_numero FOREIGN KEY (id_numero) REFERENCES numero (id_numero) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT chk_pieza_nombre CHECK (REGEXP_LIKE(nombre_archivo, '^fm-0[0-9](-[a-z0-9-]+)?\$', 'c'))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Preliminares declaradas del número: piezas sin cuerpo (como SC-25)';"

# --- 2. BIENVENIDA ---
echo
echo "${NEGRITA}Actualización del esquema de gbpublisher a 1.26.0${RESET}"
echo "--------------------------------------------------"
echo "Crea la editorial como entidad propia, sus créditos, los órganos"
echo "editoriales de las revistas y las preliminares del número. Migra los"
echo "datos de editorial de cada revista a una editorial y la vincula. No"
echo "borra ninguna columna: eso lo hace la 1.27.0."
echo

# --- 3. VERIFICACIONES PREVIAS ---
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

if [ "$(existe_tabla esquema_version)" != "1" ]; then
  error "La base no tiene la tabla esquema_version: no parece instalada desde un baseline."
  exit 1
fi

VERSION="$(valor "SELECT VERSION();")"
if [ "$(valor "SELECT (CAST(SUBSTRING_INDEX(VERSION(), '.', 1) AS UNSIGNED) * 10000 + CAST(SUBSTRING_INDEX(SUBSTRING_INDEX(VERSION(), '.', 2), '.', -1) AS UNSIGNED) * 100 + CAST(SUBSTRING_INDEX(SUBSTRING_INDEX(SUBSTRING_INDEX(VERSION(), '-', 1), '.', 3), '.', -1) AS UNSIGNED)) >= 80016;")" != "1" ]; then
  error "El servidor es ${VERSION}: hace falta MySQL 8.0.16 o posterior para las restricciones CHECK."
  exit 1
fi
info "Servidor: ${VERSION}"

# LA CADENA ES ORDENADA: 1.26.0 VA SOBRE 1.25.0
if [ "$(valor "SELECT COUNT(*) FROM \`${DB}\`.esquema_version WHERE parche='${PREVIO}';")" != "1" ]; then
  error "Falta la actualización 1.25.0. Aplicala primero (actualizar-esquema-1.25.0.sh)."
  exit 1
fi

for t in revista numero autores; do
  if [ "$(existe_tabla "$t")" != "1" ]; then
    error "No existe la tabla ${t}. No se modificó nada."
    exit 1
  fi
done

# --- 4. ESTADO REAL ---
FALTAN_TABLAS=()
for t in "${TABLAS[@]}"; do
  [ "$(existe_tabla "$t")" = "1" ] || FALTAN_TABLAS+=("$t")
done
FALTA_ID_EDITORIAL=0
[ "$(existe_columna revista id_editorial)" = "1" ] || FALTA_ID_EDITORIAL=1
FALTA_ROTULO=0
[ "$(existe_columna revista rotulo_volumen)" = "1" ] || FALTA_ROTULO=1

# LAS REVISTAS SIN EDITORIAL: SI LA COLUMNA NO EXISTE, TODAS
if [ "$FALTA_ID_EDITORIAL" = "1" ]; then
  SIN_EDITORIAL="$(valor "SELECT COUNT(*) FROM \`${DB}\`.revista;")"
else
  SIN_EDITORIAL="$(valor "SELECT COUNT(*) FROM \`${DB}\`.revista WHERE id_editorial IS NULL;")"
fi

if [ ${#FALTAN_TABLAS[@]} -eq 0 ] && [ "$FALTA_ID_EDITORIAL" = "0" ] && [ "$FALTA_ROTULO" = "0" ] && [ "$SIN_EDITORIAL" = "0" ]; then
  ok "La estructura ya está y todas las revistas tienen editorial."
  SOLO_INFORME=1
else
  SOLO_INFORME=0
fi

# --- 5. LA MIGRACIÓN SE PUEDE HACER: LOS DATOS QUE PASAN A LA EDITORIAL
#        TIENEN QUE COINCIDIR DENTRO DE CADA EDITORIAL ---
# DOS REVISTAS DE LA MISMA EDITORIAL CON PREFIJO DOI, LICENCIA O TITULAR
# DISTINTOS NO SE PUEDEN JUNTAR SIN ELEGIR UNO: SE FRENA ANTES DE TOCAR NADA
# Y SE MUESTRAN. UN VALOR NULO NO CHOCA CON OTRO (COUNT DISTINCT LOS SALTEA).
# EL EMAIL NO SE CONTROLA: LA REVISTA CONSERVA EL SUYO COMO REEMPLAZO
if [ "$SOLO_INFORME" -eq 0 ] && [ "$SIN_EDITORIAL" != "0" ]; then
  FILTRO="1=1"
  [ "$FALTA_ID_EDITORIAL" = "1" ] || FILTRO="r.id_editorial IS NULL"
  CONFLICTOS="$(valor "SELECT $(clave r) AS clave FROM \`${DB}\`.revista r WHERE ${FILTRO}
    GROUP BY clave
    HAVING COUNT(DISTINCT r.doi_prefix) > 1 OR COUNT(DISTINCT r.licencia_defecto) > 1
        OR COUNT(DISTINCT r.url_licencia_defecto) > 1 OR COUNT(DISTINCT r.titular_copyright_defecto) > 1;")"
  if [ -n "$CONFLICTOS" ]; then
    error "Hay revistas de la misma editorial con datos distintos que pasan a la editorial"
    error "(prefijo DOI, licencia, URL de la licencia o titular). Unificalos en las"
    error "revistas antes de actualizar. No se modificó nada."
    mysql_adm "$DB" -e "SELECT r.id_revista, r.titulo, r.editorial, r.doi_prefix, r.licencia_defecto, r.url_licencia_defecto, r.titular_copyright_defecto
      FROM revista r WHERE ${FILTRO} AND $(clave r) IN (SELECT clave FROM (SELECT $(clave x) AS clave FROM revista x
      GROUP BY clave HAVING COUNT(DISTINCT x.doi_prefix) > 1 OR COUNT(DISTINCT x.licencia_defecto) > 1
      OR COUNT(DISTINCT x.url_licencia_defecto) > 1 OR COUNT(DISTINCT x.titular_copyright_defecto) > 1) c)
      ORDER BY r.editorial, r.id_revista;"
    exit 1
  fi
fi

if [ "$SOLO_INFORME" -eq 0 ]; then
  [ ${#FALTAN_TABLAS[@]} -gt 0 ] && info "Tablas nuevas: ${FALTAN_TABLAS[*]}"
  [ "$FALTA_ID_EDITORIAL" = "1" ] && info "Columna nueva: revista.id_editorial"
  [ "$FALTA_ROTULO" = "1" ] && info "Columna nueva: revista.rotulo_volumen"
  [ "$SIN_EDITORIAL" != "0" ] && info "Revistas a vincular con su editorial: ${SIN_EDITORIAL}"
  echo
  read -r -p "Para continuar, escribí SI en mayúsculas: " RESPUESTA
  if [ "$RESPUESTA" != "SI" ]; then
    warn "Cancelado. No se modificó nada."
    exit 0
  fi

  # --- 6. RESPALDO PREVIO VERIFICADO ---
  mkdir -p "$DIR_RESPALDO"
  RESPALDO="${DIR_RESPALDO}/gbpublisher-antes-1.26.0-$(date '+%Y%m%d-%H%M%S').sql"
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
  if ! grep -q "CREATE TABLE \`revista\`" "$RESPALDO"; then
    error "El respaldo no contiene la tabla revista. No se modificó nada."
    exit 1
  fi
  ok "Respaldo verificado ($(du -h "$RESPALDO" | cut -f1))."

  # VOLVER ATRÁS SIN RESTAURAR TODA LA BASE (SC-22): LA MIGRACIÓN COPIA Y NO
  # BORRA, ASÍ QUE ALCANZA CON QUITAR LO NUEVO. SE PUEDE MIENTRAS NADIE HAYA
  # CARGADO CRÉDITOS, ÓRGANOS O PRELIMINARES (LAS CLAVES FORÁNEAS LO FRENAN
  # SI LOS HAY: ESOS DATOS SE PERDERÍAN)
  VOLVER_ATRAS="sudo mysql ${DB} -e \"ALTER TABLE revista DROP FOREIGN KEY fk_revista_editorial, DROP COLUMN id_editorial, DROP COLUMN rotulo_volumen; DROP TABLE numero_pieza, revista_organo_miembro, revista_organo, editorial_credito, editorial;\""

  # --- 7. ESTRUCTURA ---
  for t in "${TABLAS[@]}"; do
    if [ "$(existe_tabla "$t")" != "1" ]; then
      mysql_adm "$DB" -e "${DDL[$t]}"
      ok "Creada la tabla ${t}."
    fi
  done
  if [ "$FALTA_ID_EDITORIAL" = "1" ]; then
    # NULA HASTA LA 1.27.0: EL FORMULARIO DE REVISTAS ACTUAL TODAVÍA DA DE
    # ALTA REVISTAS SIN EDITORIAL
    mysql_adm "$DB" -e "ALTER TABLE revista
      ADD COLUMN id_editorial INT NULL DEFAULT NULL COMMENT 'La editorial de la revista (1.26.0)' AFTER titulo_abreviado,
      ADD KEY fk_revista_editorial (id_editorial),
      ADD CONSTRAINT fk_revista_editorial FOREIGN KEY (id_editorial) REFERENCES editorial (id_editorial) ON DELETE RESTRICT ON UPDATE RESTRICT;"
    ok "Agregada la columna revista.id_editorial."
  fi
  if [ "$FALTA_ROTULO" = "1" ]; then
    mysql_adm "$DB" -e "ALTER TABLE revista
      ADD COLUMN rotulo_volumen VARCHAR(30) NULL DEFAULT NULL COMMENT 'Cómo se muestra el volumen: Año, Vol., Tomo (Año III)' AFTER modelo_paginacion;"
    ok "Agregada la columna revista.rotulo_volumen."
  fi

  # --- 8. MIGRACIÓN: UNA EDITORIAL POR GRUPO, EN UNA TRANSACCIÓN ---
  # EL GRUPO SE NOMBRA POR SU REVISTA DE id MENOR. LOS DATOS QUE PASAN SE
  # TOMAN CON MAX: EL CONTROL DEL APARTADO 5 ASEGURA QUE HAY UNO SOLO (O
  # NULO). EL NOMBRE NO PUEDE SER NULO: SI LA REVISTA NO TIENE EDITORIAL NI
  # INSTITUCIÓN, «Editorial de <título>», QUE EL INFORME MUESTRA PARA CORREGIR
  GRUPOS="$(valor "SELECT MIN(r.id_revista) FROM \`${DB}\`.revista r WHERE r.id_editorial IS NULL GROUP BY $(clave r) ORDER BY 1;")"
  if [ -n "$GRUPOS" ]; then
    SQL="START TRANSACTION;"
    for rid in $GRUPOS; do
      SQL+="
INSERT INTO editorial (nombre, institucion, ror, ciudad, pais, email, doi_prefix, licencia_defecto, url_licencia_defecto, titular_copyright_defecto)
  SELECT COALESCE(NULLIF(MAX(r.editorial), ''), NULLIF(MAX(r.institucion_editora), ''), CONCAT('Editorial de ', MIN(r.titulo))),
         MAX(r.institucion_editora), MAX(r.ror_editorial), MAX(r.ciudad), MAX(r.pais),
         IF(COUNT(DISTINCT r.email_editorial) = 1, MAX(r.email_editorial), NULL),
         MAX(r.doi_prefix), MAX(r.licencia_defecto), MAX(r.url_licencia_defecto), MAX(r.titular_copyright_defecto)
  FROM revista r JOIN (SELECT $(clave x) AS k FROM revista x WHERE x.id_revista = ${rid}) g ON $(clave r) = g.k
  WHERE r.id_editorial IS NULL;
SET @id_editorial = LAST_INSERT_ID();
UPDATE revista r JOIN (SELECT $(clave x) AS k FROM revista x WHERE x.id_revista = ${rid}) g ON $(clave r) = g.k
  SET r.id_editorial = @id_editorial
  WHERE r.id_editorial IS NULL;"
    done
    SQL+="
COMMIT;"
    mysql_adm "$DB" -e "$SQL"
    ok "Migradas $(echo "$GRUPOS" | wc -w) editorial(es) y vinculadas sus revistas."
  fi

  # --- 9. VERIFICACIÓN POSTERIOR ---
  FALLA=0
  for t in "${TABLAS[@]}"; do
    if [ "$(existe_tabla "$t")" != "1" ]; then
      error "Falta la tabla ${t}."
      FALLA=1
    fi
  done
  if [ "$(valor "SELECT COUNT(*) FROM \`${DB}\`.revista WHERE id_editorial IS NULL;")" != "0" ]; then
    error "Quedaron revistas sin editorial."
    FALLA=1
  fi
  # CADA DATO QUE PASÓ TIENE QUE SER EL DE LA REVISTA (O NULO EN ELLA)
  DIFIEREN="$(valor "SELECT COUNT(*) FROM \`${DB}\`.revista r JOIN \`${DB}\`.editorial e ON e.id_editorial = r.id_editorial
    WHERE NOT (r.institucion_editora <=> e.institucion) OR NOT (r.ror_editorial <=> e.ror)
       OR NOT (r.ciudad <=> e.ciudad) OR NOT (r.pais <=> e.pais)
       OR (r.doi_prefix IS NOT NULL AND NOT (r.doi_prefix <=> e.doi_prefix))
       OR (r.licencia_defecto IS NOT NULL AND NOT (r.licencia_defecto <=> e.licencia_defecto))
       OR (r.url_licencia_defecto IS NOT NULL AND NOT (r.url_licencia_defecto <=> e.url_licencia_defecto))
       OR (r.titular_copyright_defecto IS NOT NULL AND NOT (r.titular_copyright_defecto <=> e.titular_copyright_defecto));")"
  if [ "$DIFIEREN" != "0" ]; then
    error "${DIFIEREN} revista(s) quedaron con datos distintos de los de su editorial."
    FALLA=1
  fi
  if [ "$FALLA" = "1" ]; then
    error "NO se registra la actualización. Para volver atrás:"
    error "  ${VOLVER_ATRAS}"
    exit 1
  fi
  ok "Verificación correcta: estructura completa y cada revista con su editorial y sus datos."

  # --- 10. REGISTRO ---
  mysql_adm "$DB" -e "INSERT IGNORE INTO esquema_version (parche, descripcion) VALUES ('${PARCHE}', '${DESCRIPCION}');"
  ok "Registrado en esquema_version como ${PARCHE}."
  info "Para volver atrás (respaldo en ${RESPALDO}):"
  echo "  ${VOLVER_ATRAS}"

else
  # YA ESTABA: SE REGISTRA PARA QUE EL NIVEL DECLARADO REFLEJE EL ESTADO REAL
  if [ "$(valor "SELECT COUNT(*) FROM \`${DB}\`.esquema_version WHERE parche='${PARCHE}';")" = "0" ]; then
    mysql_adm "$DB" -e "INSERT INTO esquema_version (parche, descripcion) VALUES ('${PARCHE}', '${DESCRIPCION}');"
    ok "Ya estaba aplicada; registrado en esquema_version como ${PARCHE}."
  fi
fi

# --- 11. INFORME DE CONTROL (SOLO LECTURA) ---
echo
info "Informe de control: cada editorial y sus revistas"
mysql_adm "$DB" -e "SELECT e.id_editorial, e.nombre, e.ciudad, e.doi_prefix, e.licencia_defecto, e.email,
  GROUP_CONCAT(r.titulo ORDER BY r.titulo SEPARATOR ' / ') AS revistas
  FROM editorial e LEFT JOIN revista r ON r.id_editorial = e.id_editorial
  GROUP BY e.id_editorial ORDER BY e.nombre;"
if [ "$(valor "SELECT COUNT(*) FROM \`${DB}\`.editorial WHERE nombre LIKE 'Editorial de %';")" != "0" ]; then
  warn "Las editoriales «Editorial de …» se crearon con el título de la revista porque"
  warn "no tenía editorial ni institución: corregí el nombre en el formulario."
fi
echo "El informe no modifica nada."
echo
ok "${NEGRITA}Actualización 1.26.0 lista.${RESET}"
