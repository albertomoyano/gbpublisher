#!/usr/bin/env bash
#
# ============================================
# Script    : actualizar-esquema-1.18.0.sh
# Propósito : Actualización 1.18.0 de la base de gbpublisher, sobre una base
#             EN USO. Siglas de libros (decisiones de Alberto, 31/10;
#             documento de trabajo claude/siglas-glosario.md):
#               1. Tabla nueva sigla_catalogo: catálogo de siglas DE LA
#                  EDITORIAL, común a todos los libros. La clave de cada
#                  entrada NO se guarda: es <id_sigla>-<sigla normalizada>
#                  y se calcula al leer (una columna generada no puede
#                  usar una AUTO_INCREMENT, error 3109 medido en 8.0.46).
#               2. Tabla nueva libro_sigla: las siglas que adopta cada
#                  libro, con copia por valor (SC-23) y la clave fijada al
#                  adoptar. Corregir el catálogo corrige solo los libros
#                  no publicados (SC-71); eso lo hace la aplicación.
#               3. Baja de la tabla siglas: herencia de la época de LaTeX,
#                  sin relaciones y sin uso en la cadena. Sus filas quedan
#                  en el respaldo previo.
#             COLACIONES (medidas en 8.0.46, 31/10):
#               sigla       utf8mb4_0900_as_cs: LyF y LYF son distintas.
#               desarrollo  utf8mb4_0900_as_ci: no distingue mayúsculas,
#                           sí tildes y ñ (como el vocabulario, 1.16.0).
#               clave       ascii_bin, con forma controlada por CHECK.
#             Al final emite un INFORME DE CONTROL, solo de lectura.
# Uso       : sudo bash actualizar-esquema-1.18.0.sh
# Requisitos: MySQL 8.0.16 o posterior (CHECK; colaciones 0900). No corre en
#             MariaDB tal cual (no tiene las colaciones 0900).
# Reglas    : BBDD_LEEME.md §5 y SC-22. IDEMPOTENTE; respaldo verificado;
#             verificación posterior; sin efecto si ya está aplicado.
#             Exige la 1.17.0 registrada. Qué cambiar lo decide el ESTADO
#             REAL (information_schema), tabla por tabla.
# Lote      : m_ConexionBD.ObtenerEsquemaEsperado: sale siglas (11); entran
#             sigla_catalogo 5 y libro_sigla 8. VA JUNTO CON EL .deb QUE
#             RETIRA m_Siglas Y FSiglas: con el .deb anterior la validación
#             del esquema falla y el formulario viejo no abre.
# ============================================

set -euo pipefail

# --- 0. CONFIGURACIÓN ---
DB="gbpublisher"
PARCHE="actualizacion-1.18.0"
PREVIO="actualizacion-1.17.0"
DESCRIPCION="Libros: catálogo de siglas de la editorial (sigla_catalogo) y siglas adoptadas por libro (libro_sigla); baja de siglas"
DIR_RESPALDO="${HOME}/gbpublisher-respaldos"

# COLUMNAS ESPERADAS AL TERMINAR (LAS DE hEsquema)
COLS_CAT=5
COLS_LIB=8
# RESTRICCIONES CHECK AL TERMINAR: 4 EN EL CATÁLOGO + 5 EN EL LIBRO
CHECK_ESPERADAS=9

# «SIN DATO» ES NULL (GV-74): LOS OPCIONALES VAN NULL CON CHECK (<> '').
# LA CLAVE ÚNICA (sigla, desarrollo) DEJA DOS PO CON DISTINTO DESARROLLO.
# (32 + 500) × 4 BYTES = 2128, DEBAJO DEL LÍMITE DE 3072 DE InnoDB DYNAMIC
DDL_CAT="CREATE TABLE IF NOT EXISTS sigla_catalogo (
  id_sigla INT NOT NULL AUTO_INCREMENT,
  sigla VARCHAR(32) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_as_cs NOT NULL COMMENT 'Forma exacta: LyF y LYF son distintas',
  desarrollo VARCHAR(500) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_as_ci NOT NULL COMMENT 'Singular; solo *...* como marca (cursiva)',
  desarrollo_plural VARCHAR(500) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_as_ci NULL DEFAULT NULL COMMENT 'Solo para el texto; no va a la lista',
  idioma VARCHAR(20) NULL DEFAULT NULL COMMENT 'BCP 47; NULL es la lengua del libro',
  PRIMARY KEY (id_sigla),
  UNIQUE KEY uq_sigcat_sigla_desarrollo (sigla, desarrollo),
  CONSTRAINT chk_sigcat_sigla CHECK (sigla <> ''),
  CONSTRAINT chk_sigcat_desarrollo CHECK (desarrollo <> ''),
  CONSTRAINT chk_sigcat_plural CHECK (desarrollo_plural <> ''),
  CONSTRAINT chk_sigcat_idioma CHECK (idioma <> '')
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci ROW_FORMAT=DYNAMIC COMMENT='Catálogo de siglas de la editorial, común a todos los libros';"

# LA CLAVE: <id_sigla>-<sigla normalizada> («44-oms», «7-sitrac-sitram»).
# SIN PARTE DE SIGLA SI LA NORMALIZACIÓN LA DEJA VACÍA («44»). REGEXP_LIKE
# EN UN CHECK, CON 'c' (DISTINGUE MAYÚSCULAS), MEDIDO EN 8.0.46 (31/10).
# id_proyecto: CASCADE, COMO LA TABLA siglas. id_sigla: RESTRICT, NO SE BORRA
# DEL CATÁLOGO UNA SIGLA QUE USA ALGÚN LIBRO, PUBLICADO O NO
DDL_LIB="CREATE TABLE IF NOT EXISTS libro_sigla (
  id_libro_sigla INT NOT NULL AUTO_INCREMENT,
  id_proyecto INT NOT NULL,
  id_sigla INT NOT NULL,
  sigla VARCHAR(32) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_as_cs NOT NULL COMMENT 'Copia del catálogo (SC-23)',
  desarrollo VARCHAR(500) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_as_ci NOT NULL COMMENT 'Copia del catálogo (SC-23)',
  desarrollo_plural VARCHAR(500) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_as_ci NULL DEFAULT NULL COMMENT 'Copia del catálogo (SC-23)',
  idioma VARCHAR(20) NULL DEFAULT NULL COMMENT 'Copia del catálogo (SC-23)',
  clave VARCHAR(48) CHARACTER SET ascii COLLATE ascii_bin NOT NULL COMMENT '<id_sigla>-<sigla normalizada>, fija al adoptar',
  PRIMARY KEY (id_libro_sigla),
  UNIQUE KEY uq_libsig_proyecto_sigla (id_proyecto, id_sigla),
  UNIQUE KEY uq_libsig_proyecto_clave (id_proyecto, clave),
  KEY ix_libsig_sigla (id_sigla),
  CONSTRAINT fk_libsig_proyecto FOREIGN KEY (id_proyecto) REFERENCES proyectos (id) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT fk_libsig_sigla FOREIGN KEY (id_sigla) REFERENCES sigla_catalogo (id_sigla) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT chk_libsig_sigla CHECK (sigla <> ''),
  CONSTRAINT chk_libsig_desarrollo CHECK (desarrollo <> ''),
  CONSTRAINT chk_libsig_plural CHECK (desarrollo_plural <> ''),
  CONSTRAINT chk_libsig_idioma CHECK (idioma <> ''),
  CONSTRAINT chk_libsig_clave CHECK (REGEXP_LIKE(clave, '^[0-9]+(-[a-z0-9]+)*\$', 'c'))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci ROW_FORMAT=DYNAMIC COMMENT='Siglas adoptadas por cada libro, con copia por valor';"

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

colacion_de() {
  valor "SELECT COLLATION_NAME FROM information_schema.COLUMNS WHERE TABLE_SCHEMA='${DB}' AND TABLE_NAME='$1' AND COLUMN_NAME='$2';"
}

# REGLA DE BORRADO DE UNA CLAVE FORÁNEA: CASCADE, RESTRICT...
regla_borrado() {
  valor "SELECT DELETE_RULE FROM information_schema.REFERENTIAL_CONSTRAINTS WHERE CONSTRAINT_SCHEMA='${DB}' AND TABLE_NAME='$1' AND CONSTRAINT_NAME='$2';"
}

# --- 1. BIENVENIDA ---
echo
echo "${NEGRITA}Actualización del esquema de gbpublisher a 1.18.0${RESET}"
echo "--------------------------------------------------"
echo "Agrega el catálogo de siglas de la editorial y las siglas de cada libro."
echo "Borra la tabla siglas, heredada de la época de LaTeX: sus filas quedan en el respaldo."
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

if [ "$(valor "SELECT COUNT(*) FROM information_schema.TABLES WHERE TABLE_SCHEMA='${DB}' AND TABLE_NAME='esquema_version';")" != "1" ]; then
  error "La base no tiene la tabla esquema_version: no parece instalada desde un baseline."
  exit 1
fi

VERSION="$(valor "SELECT VERSION();")"
if [ "$(valor "SELECT (CAST(SUBSTRING_INDEX(VERSION(), '.', 1) AS UNSIGNED) * 10000 + CAST(SUBSTRING_INDEX(SUBSTRING_INDEX(VERSION(), '.', 2), '.', -1) AS UNSIGNED) * 100 + CAST(SUBSTRING_INDEX(SUBSTRING_INDEX(SUBSTRING_INDEX(VERSION(), '-', 1), '.', 3), '.', -1) AS UNSIGNED)) >= 80016;")" != "1" ]; then
  error "El servidor es ${VERSION}: hace falta MySQL 8.0.16 o posterior para las restricciones CHECK."
  exit 1
fi

info "Servidor: ${VERSION}"

# LA CADENA ES ORDENADA: 1.18.0 VA SOBRE 1.17.0
if [ "$(valor "SELECT COUNT(*) FROM \`${DB}\`.esquema_version WHERE parche='${PREVIO}';")" != "1" ]; then
  error "Falta la actualización 1.17.0. Aplicala primero (actualizar-esquema-1.17.0.sh)."
  exit 1
fi

# LAS TRES COLACIONES QUE USA ESTA ACTUALIZACIÓN SON DE MySQL 8
if [ "$(valor "SELECT COUNT(*) FROM information_schema.COLLATIONS WHERE COLLATION_NAME IN ('utf8mb4_0900_as_cs','utf8mb4_0900_as_ci','utf8mb4_0900_ai_ci');")" != "3" ]; then
  error "El servidor no tiene las colaciones utf8mb4_0900_as_cs / _as_ci / _ai_ci (hace falta MySQL 8)."
  exit 1
fi

# libro_sigla APUNTA A proyectos: SIN ELLA NO HAY NADA QUE HACER
if [ "$(valor "SELECT COUNT(*) FROM information_schema.TABLES WHERE TABLE_SCHEMA='${DB}' AND TABLE_NAME='proyectos';")" != "1" ]; then
  error "La base no tiene la tabla proyectos. No se modificó nada."
  exit 1
fi

# --- 3. ESTADO REAL, TABLA POR TABLA ---
CREAR_CAT=0
N="$(columnas_de sigla_catalogo)"
if [ "$N" = "0" ]; then
  CREAR_CAT=1
elif [ "$N" != "${COLS_CAT}" ]; then
  error "La tabla sigla_catalogo tiene una forma inesperada (${N} columnas). Revisala a mano. No se modificó nada."
  exit 1
fi

CREAR_LIB=0
N="$(columnas_de libro_sigla)"
if [ "$N" = "0" ]; then
  CREAR_LIB=1
elif [ "$N" != "${COLS_LIB}" ]; then
  error "La tabla libro_sigla tiene una forma inesperada (${N} columnas). Revisala a mano. No se modificó nada."
  exit 1
fi

# LA TABLA VIEJA SE BORRA SOLO SI TIENE LA FORMA CONOCIDA (11 COLUMNAS DEL
# BASELINE 1.0.0): OTRA FORMA ES ALGO QUE ESTE SCRIPT NO CONOCE
BORRAR_VIEJA=0
FILAS_VIEJAS=0
N="$(columnas_de siglas)"
if [ "$N" = "11" ]; then
  BORRAR_VIEJA=1
  FILAS_VIEJAS="$(valor "SELECT COUNT(*) FROM \`${DB}\`.siglas;")"
elif [ "$N" != "0" ]; then
  error "La tabla siglas tiene una forma inesperada (${N} columnas). Revisala a mano. No se modificó nada."
  exit 1
fi

if [ "$CREAR_CAT" -eq 0 ] && [ "$CREAR_LIB" -eq 0 ] && [ "$BORRAR_VIEJA" -eq 0 ]; then
  ok "No hay nada que agregar ni borrar."
  SOLO_INFORME=1
else
  SOLO_INFORME=0
  [ "$CREAR_CAT" -eq 1 ] && info "Se crea sigla_catalogo."
  [ "$CREAR_LIB" -eq 1 ] && info "Se crea libro_sigla."
  [ "$BORRAR_VIEJA" -eq 1 ] && warn "Se borra la tabla siglas (${FILAS_VIEJAS} filas heredadas de LaTeX; quedan en el respaldo)."
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
  RESPALDO="${DIR_RESPALDO}/gbpublisher-antes-1.18.0-$(date '+%Y%m%d-%H%M%S').sql"
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
  # LA TABLA QUE SE BORRA TIENE QUE ESTAR EN EL RESPALDO
  if [ "$BORRAR_VIEJA" -eq 1 ] && ! grep -q "CREATE TABLE \`siglas\`" "$RESPALDO"; then
    error "El respaldo no contiene la tabla siglas. No se modificó nada."
    exit 1
  fi
  ok "Respaldo verificado ($(du -h "$RESPALDO" | cut -f1))."

  # --- 5. CAMBIOS ---
  # EL CATÁLOGO VA PRIMERO: libro_sigla LO REFERENCIA
  if [ "$CREAR_CAT" -eq 1 ]; then
    mysql_adm "$DB" -e "${DDL_CAT}"
    ok "Creada sigla_catalogo."
  fi
  if [ "$CREAR_LIB" -eq 1 ]; then
    mysql_adm "$DB" -e "${DDL_LIB}"
    ok "Creada libro_sigla."
  fi
  # ÚLTIMO PASO: SI ALGO DE ARRIBA FALLA, LA TABLA VIEJA SIGUE EN SU LUGAR
  if [ "$BORRAR_VIEJA" -eq 1 ]; then
    mysql_adm "$DB" -e "DROP TABLE siglas;"
    ok "Borrada siglas."
  fi

  # --- 6. VERIFICACIÓN POSTERIOR ---
  FALLA=0
  if [ "$(columnas_de sigla_catalogo)" != "${COLS_CAT}" ]; then
    error "La tabla sigla_catalogo no quedó como se esperaba."
    FALLA=1
  fi
  if [ "$(columnas_de libro_sigla)" != "${COLS_LIB}" ]; then
    error "La tabla libro_sigla no quedó como se esperaba."
    FALLA=1
  fi
  if [ "$(columnas_de siglas)" != "0" ]; then
    error "La tabla siglas sigue en la base."
    FALLA=1
  fi
  # LAS COLACIONES SON LA DECISIÓN: SE CONTROLAN UNA POR UNA
  for T in sigla_catalogo libro_sigla; do
    if [ "$(colacion_de "$T" sigla)" != "utf8mb4_0900_as_cs" ] || [ "$(colacion_de "$T" desarrollo)" != "utf8mb4_0900_as_ci" ] || [ "$(colacion_de "$T" desarrollo_plural)" != "utf8mb4_0900_as_ci" ]; then
      error "${T}: las colaciones de sigla y desarrollo no quedaron como se esperaba."
      FALLA=1
    fi
  done
  if [ "$(colacion_de libro_sigla clave)" != "ascii_bin" ]; then
    error "libro_sigla.clave no quedó con la colación ascii_bin."
    FALLA=1
  fi
  if [ "$(regla_borrado libro_sigla fk_libsig_proyecto)" != "CASCADE" ] || [ "$(regla_borrado libro_sigla fk_libsig_sigla)" != "RESTRICT" ]; then
    error "libro_sigla: las claves foráneas no quedaron como se esperaba (proyecto CASCADE, sigla RESTRICT)."
    FALLA=1
  fi
  CHK="$(valor "SELECT COUNT(*) FROM information_schema.TABLE_CONSTRAINTS WHERE CONSTRAINT_SCHEMA='${DB}' AND CONSTRAINT_TYPE='CHECK' AND TABLE_NAME IN ('sigla_catalogo','libro_sigla');")"
  if [ "$CHK" != "$CHECK_ESPERADAS" ]; then
    error "Hay ${CHK} restricciones CHECK en las tablas de siglas (se esperaban ${CHECK_ESPERADAS})."
    FALLA=1
  fi

  if [ "$FALLA" -ne 0 ]; then
    error "NO se registra la actualización."
    # SIN innodb_strict_mode=0 LA RESTAURACIÓN FALLA EN articulos (GV-67)
    error "Para volver atrás: sudo mysql --init-command=\"SET SESSION innodb_strict_mode=0\" ${DB} < ${RESPALDO}"
    exit 1
  fi
  ok "Verificación correcta: dos tablas nuevas, colaciones, claves foráneas y ${CHK} restricciones CHECK; siglas fuera."

  # --- 7. REGISTRO ---
  mysql_adm "$DB" -e "INSERT IGNORE INTO esquema_version (parche, descripcion) VALUES ('${PARCHE}', '${DESCRIPCION}');"
  ok "Registrado en esquema_version como ${PARCHE}."
  info "Para volver atrás: sudo mysql --init-command=\"SET SESSION innodb_strict_mode=0\" ${DB} < ${RESPALDO}"

else
  # YA ESTABA: SE REGISTRA PARA QUE EL NIVEL DECLARADO REFLEJE EL ESTADO REAL
  if [ "$(valor "SELECT COUNT(*) FROM \`${DB}\`.esquema_version WHERE parche='${PARCHE}';")" = "0" ]; then
    mysql_adm "$DB" -e "INSERT INTO esquema_version (parche, descripcion) VALUES ('${PARCHE}', '${DESCRIPCION}');"
    ok "Ya estaba aplicada; registrado en esquema_version como ${PARCHE}."
  fi
fi

# --- 8. INFORME DE CONTROL (SOLO LECTURA) ---
echo
info "Informe de control: siglas en el catálogo y en los libros"
mysql_adm "$DB" -e "SELECT (SELECT COUNT(*) FROM sigla_catalogo) AS catalogo, (SELECT COUNT(*) FROM libro_sigla) AS adoptadas, (SELECT COUNT(DISTINCT id_proyecto) FROM libro_sigla) AS libros;"
echo "El informe no modifica nada."
echo
ok "${NEGRITA}Actualización 1.18.0 lista.${RESET}"
