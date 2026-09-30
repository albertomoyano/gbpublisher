#!/usr/bin/env bash
#
# ============================================
# Script    : actualizar-esquema-1.2.0.sh
# Propósito : Actualización 1.2.0 de la base de gbpublisher, sobre una base
#             EN USO y preservando sus datos. Lleva a la base el catálogo de
#             licencias que vivía repetido en el código de los formularios:
#               1. tabla licencias
#               2. filas iniciales del catálogo (19 licencias)
#             No modifica articulos, capitulos, libros_md ni revistas_md: cada
#             registro sigue guardando su propio texto y su URL. Al final
#             emite un INFORME DE CONTROL, solo de lectura, con los registros
#             cuya licencia no coincide con el catálogo.
# Uso       : ./actualizar-esquema-1.2.0.sh
# Requisitos: MySQL/MariaDB en ejecución; permisos sudo (cuenta administrativa
#             del servidor: app_user NO puede modificar estructuras).
# Reglas    : BBDD_LEEME.md §5. IDEMPOTENTE: verifica el estado REAL del
#             esquema y aplica solo lo que falta. Respaldo verificado antes de
#             tocar nada; verificación posterior; sin efecto si ya está aplicado.
# Fuentes   : URL e identificadores SPDX de las licencias nuevas verificados
#             en spdx/license-list-data (json/details, 2026-09-27). Las URL de
#             las licencias que ya estaban en el código se conservan tal cual,
#             para que coincidan con los datos existentes.
# ============================================

set -euo pipefail

# --- 0. CONFIGURACIÓN ---
DB="gbpublisher"
PARCHE="actualizacion-1.2.0"
DESCRIPCION="Catálogo de licencias: tabla licencias"
DIR_RESPALDO="${HOME}/gbpublisher-respaldos"
FILAS_CATALOGO=19

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

valor() {
  mysql_adm -N -B -e "$1"
}

# --- 1. BIENVENIDA ---
echo
echo "${NEGRITA}Actualización del esquema de gbpublisher a 1.2.0${RESET}"
echo "-------------------------------------------------"
echo "Crea el catálogo de licencias (tabla licencias). No borra ni modifica"
echo "datos de artículos, capítulos, libros ni revistas."
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

NIVEL="$(valor "SELECT GROUP_CONCAT(parche ORDER BY aplicado_en SEPARATOR ', ') FROM \`${DB}\`.esquema_version;")"
info "Nivel registrado: ${NIVEL}"

# LA CADENA DE ACTUALIZACIONES ES ORDENADA: 1.2.0 VA SOBRE 1.1.0
if [ "$(valor "SELECT COUNT(*) FROM \`${DB}\`.esquema_version WHERE parche='actualizacion-1.1.0';")" != "1" ]; then
  error "Falta la actualización 1.1.0. Aplicala primero (actualizar-esquema-1.1.0.sh)."
  exit 1
fi

# --- 3. ESTADO REAL DEL ESQUEMA ---
existe_tabla() {
  valor "SELECT COUNT(*) FROM information_schema.TABLES WHERE TABLE_SCHEMA='${DB}' AND TABLE_NAME='licencias';"
}

columnas_tabla() {
  valor "SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA='${DB}' AND TABLE_NAME='licencias';"
}

# FILAS DEL CATÁLOGO INICIAL QUE YA ESTÁN (POR ETIQUETA)
filas_presentes() {
  valor "SELECT COUNT(*) FROM \`${DB}\`.licencias WHERE etiqueta IN ('CC BY 4.0','CC BY-SA 4.0','CC BY-NC 4.0','CC BY-NC-SA 4.0','CC BY-ND 4.0','CC BY-NC-ND 4.0','CC0 1.0','MIT','GPL v3','GPL v2','Apache 2.0','BSD 2-Clause','BSD 3-Clause','LGPL v3','MPL 2.0','AGPL v3','Unlicense','Todos los derechos reservados','Propietaria');"
}

FALTA_TABLA=0; FALTAN_FILAS=0
if [ "$(existe_tabla)" = "0" ]; then
  FALTA_TABLA=1
  FALTAN_FILAS=$FILAS_CATALOGO
else
  FALTAN_FILAS=$((FILAS_CATALOGO - $(filas_presentes)))
fi

if [ "$FALTA_TABLA" -eq 0 ] && [ "$FALTAN_FILAS" -eq 0 ]; then
  ok "El esquema ya tiene todo lo de 1.2.0. No hay nada que modificar."
  SOLO_INFORME=1
else
  SOLO_INFORME=0
  info "Pendiente:"
  [ "$FALTA_TABLA" -eq 1 ] && echo "    - tabla licencias"
  echo "    - ${FALTAN_FILAS} de ${FILAS_CATALOGO} filas del catálogo inicial"
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
  RESPALDO="${DIR_RESPALDO}/gbpublisher-antes-1.2.0-$(date '+%Y%m%d-%H%M%S').sql"
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
  if ! grep -q "CREATE TABLE \`articulos\`" "$RESPALDO"; then
    error "El respaldo no contiene la tabla articulos. No se modificó nada."
    exit 1
  fi
  ok "Respaldo verificado ($(du -h "$RESPALDO" | cut -f1))."

  # --- 5. APLICACIÓN ---

  # 5.1 TABLA. MISMO JUEGO DE CARACTERES Y COLACIÓN QUE EL RESTO DE LA BASE:
  # EL INFORME COMPARA etiqueta Y url CONTRA COLUMNAS utf8mb4_unicode_ci.
  # tinyint(1) PARA LOS BOOLEANOS, COMO cmb_biblatex.activo
  if [ "$FALTA_TABLA" -eq 1 ]; then
    mysql_adm "$DB" <<'SQL'
CREATE TABLE IF NOT EXISTS `licencias` (
  `id` int NOT NULL AUTO_INCREMENT,
  `etiqueta` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT 'Texto del combo y del registro (CC BY 4.0)',
  `url` varchar(500) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'URL canónica; NULL si no tiene',
  `spdx` varchar(50) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'Identificador SPDX; NULL si la etiqueta es ambigua',
  `abierta` tinyint(1) NOT NULL DEFAULT '0' COMMENT 'Acceso abierto: license-type de JATS',
  `para_contenido` tinyint(1) NOT NULL DEFAULT '0' COMMENT 'Aparece en licencia de artículos, capítulos, libros y revistas',
  `para_codigo` tinyint(1) NOT NULL DEFAULT '0' COMMENT 'Aparece en licencia del repositorio de código',
  `orden` int NOT NULL DEFAULT '0',
  `activo` tinyint(1) NOT NULL DEFAULT '1',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_licencias_etiqueta` (`etiqueta`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Catálogo de licencias (actualización 1.2.0)';
SQL
    ok "Tabla licencias creada."
  fi

  # 5.2 FILAS INICIALES. INSERT IGNORE SOBRE LA CLAVE ÚNICA etiqueta: UNA FILA
  # QUE YA EXISTE (QUIZÁS EDITADA A MANO) NO SE PISA.
  # MIT, GPL v3 Y Apache 2.0 QUEDAN EN LOS DOS ÁMBITOS: HOY APARECEN EN LA LISTA
  # DE CONTENIDO Y EN LA DE CÓDIGO. «Otra» NO VA: EL COMBO ES EDITABLE.
  # spdx NULL EN GPL/LGPL/AGPL: LA ETIQUETA NO DICE SI ES «only» U «or-later»
  mysql_adm "$DB" <<'SQL'
INSERT IGNORE INTO `licencias` (`etiqueta`, `url`, `spdx`, `abierta`, `para_contenido`, `para_codigo`, `orden`) VALUES
('CC BY 4.0',                     'https://creativecommons.org/licenses/by/4.0/',                         'CC-BY-4.0',        1, 1, 0,  10),
('CC BY-SA 4.0',                  'https://creativecommons.org/licenses/by-sa/4.0/',                      'CC-BY-SA-4.0',     1, 1, 0,  20),
('CC BY-NC 4.0',                  'https://creativecommons.org/licenses/by-nc/4.0/',                      'CC-BY-NC-4.0',     1, 1, 0,  30),
('CC BY-NC-SA 4.0',               'https://creativecommons.org/licenses/by-nc-sa/4.0/',                   'CC-BY-NC-SA-4.0',  1, 1, 0,  40),
('CC BY-ND 4.0',                  'https://creativecommons.org/licenses/by-nd/4.0/',                      'CC-BY-ND-4.0',     1, 1, 0,  50),
('CC BY-NC-ND 4.0',               'https://creativecommons.org/licenses/by-nc-nd/4.0/',                   'CC-BY-NC-ND-4.0',  1, 1, 0,  60),
('CC0 1.0',                       'https://creativecommons.org/publicdomain/zero/1.0/',                   'CC0-1.0',          1, 1, 1,  70),
('MIT',                           'https://opensource.org/licenses/MIT',                                  'MIT',              1, 1, 1,  80),
('GPL v3',                        'https://www.gnu.org/licenses/gpl-3.0.html',                            NULL,               1, 1, 1,  90),
('GPL v2',                        'https://www.gnu.org/licenses/old-licenses/gpl-2.0-standalone.html',    NULL,               1, 0, 1, 100),
('Apache 2.0',                    'https://www.apache.org/licenses/LICENSE-2.0',                          'Apache-2.0',       1, 1, 1, 110),
('BSD 2-Clause',                  'https://opensource.org/license/BSD-2-Clause',                          'BSD-2-Clause',     1, 0, 1, 120),
('BSD 3-Clause',                  'https://opensource.org/licenses/BSD-3-Clause',                         'BSD-3-Clause',     1, 1, 1, 130),
('LGPL v3',                       'https://www.gnu.org/licenses/lgpl-3.0-standalone.html',                NULL,               1, 0, 1, 140),
('MPL 2.0',                       'https://www.mozilla.org/MPL/2.0/',                                     'MPL-2.0',          1, 0, 1, 150),
('AGPL v3',                       'https://www.gnu.org/licenses/agpl.txt',                                NULL,               1, 0, 1, 160),
('Unlicense',                     'https://unlicense.org/',                                               'Unlicense',        1, 0, 1, 170),
('Todos los derechos reservados', NULL,                                                                   NULL,               0, 1, 0, 180),
('Propietaria',                   NULL,                                                                   NULL,               0, 0, 1, 190);
SQL
  ok "Filas del catálogo inicial cargadas (las existentes no se tocaron)."

  # --- 6. VERIFICACIÓN POSTERIOR ---
  FALLAS=0
  [ "$(existe_tabla)" = "1" ]    || { error "Falta la tabla licencias."; FALLAS=1; }
  [ "$(columnas_tabla)" = "9" ]  || { error "La tabla licencias no tiene 9 columnas."; FALLAS=1; }
  [ "$(filas_presentes)" = "${FILAS_CATALOGO}" ] || { error "Faltan filas del catálogo inicial."; FALLAS=1; }

  if [ "$FALLAS" -ne 0 ]; then
    error "La verificación falló. NO se registra la actualización."
    error "Para volver atrás: sudo mysql ${DB} < ${RESPALDO}"
    exit 1
  fi
  ok "Verificación correcta: tabla con 9 columnas y ${FILAS_CATALOGO} licencias."

  # --- 7. REGISTRO ---
  mysql_adm "$DB" -e "INSERT IGNORE INTO esquema_version (parche, descripcion) VALUES ('${PARCHE}', '${DESCRIPCION}');"
  ok "Registrado en esquema_version como ${PARCHE}."
fi

# --- 8. INFORME DE CONTROL (SOLO LECTURA) ---
# COMPARACIÓN POR URL, NO POR NOMBRE: UN NOMBRE LARGO CON LA URL CORRECTA ES
# CORRECTO. SIN LICENCIA NI URL NO SE INFORMA (NO ES UN ERROR DE CATÁLOGO)
echo
info "Informe de control: registros cuya licencia no coincide con el catálogo"
mysql_adm "$DB" -t <<'SQL'
SELECT r.tabla, r.id, LEFT(r.etiqueta, 50) AS etiqueta, LEFT(r.url, 60) AS url, r.motivo
FROM (
  SELECT t.tabla, t.id, t.etiqueta, t.url,
    CASE
      WHEN COALESCE(TRIM(t.etiqueta), '') = '' AND COALESCE(TRIM(t.url), '') = '' THEN NULL
      WHEN COALESCE(TRIM(t.url), '') <> ''
           AND EXISTS (SELECT 1 FROM licencias l WHERE l.url = TRIM(t.url) AND l.etiqueta = TRIM(t.etiqueta)) THEN NULL
      WHEN COALESCE(TRIM(t.url), '') <> ''
           AND EXISTS (SELECT 1 FROM licencias l WHERE l.url = TRIM(t.url)) THEN 'informativo: URL del catálogo con otro nombre'
      WHEN COALESCE(TRIM(t.url), '') = ''
           AND EXISTS (SELECT 1 FROM licencias l WHERE l.url IS NULL AND l.etiqueta = TRIM(t.etiqueta)) THEN NULL
      WHEN COALESCE(TRIM(t.url), '') = ''
           AND EXISTS (SELECT 1 FROM licencias l WHERE l.etiqueta = TRIM(t.etiqueta)) THEN 'falta la URL (el catálogo la tiene)'
      WHEN COALESCE(TRIM(t.url), '') = '' THEN 'sin URL y nombre fuera del catálogo'
      ELSE 'URL fuera del catálogo'
    END AS motivo
  FROM (
    SELECT 'articulos' AS tabla, id_articulo AS id, licencia AS etiqueta, url_licencia AS url FROM articulos
    UNION ALL SELECT 'capitulos', id_capitulo, licencia, url_licencia FROM capitulos
    UNION ALL SELECT 'libros_md', id_libro, licencia_defecto, url_licencia FROM libros_md
    UNION ALL SELECT 'revistas_md', id_revista, licencia_defecto, url_licencia FROM revistas_md
  ) t
  UNION ALL
  SELECT 'articulos (código)', a.id_articulo, a.repositorio_codigo_licencia, NULL, 'nombre fuera del catálogo de código'
  FROM articulos a
  WHERE COALESCE(TRIM(a.repositorio_codigo_licencia), '') <> ''
    AND NOT EXISTS (SELECT 1 FROM licencias l WHERE l.para_codigo = 1 AND l.etiqueta = TRIM(a.repositorio_codigo_licencia))
) r
WHERE r.motivo IS NOT NULL
ORDER BY r.tabla, r.id;
SQL
echo "Si la tabla no aparece, no hay discordancias. El informe no modifica nada:"
echo "cada caso se corrige a mano desde el formulario correspondiente."
echo
ok "${NEGRITA}Actualización 1.2.0 lista.${RESET}"
