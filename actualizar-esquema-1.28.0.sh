#!/usr/bin/env bash
#
# ============================================
# Script    : actualizar-esquema-1.28.0.sh
# Propósito : Actualización 1.28.0 de la base de gbpublisher, sobre una base
#             EN USO. Los datos que el PDF de revista necesita en el idioma
#             del artículo, y el logo de cada revista (decisiones de Alberto
#             del 14/11/2026; claude/salidas-revistas.md, «C»):
#               1. credit_roles suma la URI de cada rol (uri). Es la clave con
#                  la que vienen las traducciones y la que va al canónico
#                  (vocab-term-identifier)
#               2. credit_rol_nombre (NUEVA): el nombre de cada rol por
#                  idioma. Se carga con es y pt
#               3. licencia_texto (NUEVA): el texto que describe cada
#                  licencia, por idioma. La clave es la url (SC-23: el
#                  artículo guarda la url, sin clave foránea al catálogo).
#                  Se carga con los seis textos CC 4.0 en castellano de
#                  jats-to-latex.xsl
#               4. revista.logo (MEDIUMBLOB): el logo de la cabecera del
#                  artículo; FRevistas lo carga y el número lo escribe en
#                  media/logo-revista.png
#             Las filas se cargan con INSERT IGNORE: una fila que ya está
#             (quizás editada en Administración) no se pisa.
# Fuentes   : CRediT por idioma: Contributorship Collaboration,
#             github.com/contributorshipcollaboration/credit-translation,
#             translations/es_Latn.json y pt_Latn.json, versión 1.0.0
#             (bajados el 14/11/2026). Traducciones no oficiales: NISO no
#             respalda ninguna. es: Riva Quiroga, Marc Bria Ramirez y Jordi
#             Lacruz Casado. El texto va tal cual (decisión de Alberto):
#             «Redacción - borrador original» lleva guion (U+002D),
#             verificado byte a byte. El repositorio no declara licencia.
#             URIs de los roles: credit.niso.org/contributor-roles/.
#             Textos de las licencias: jats-to-latex.xsl (el camino viejo),
#             plantilla de la columna derecha, variable lic-texto-der.
# Uso       : sudo bash actualizar-esquema-1.28.0.sh
# Reglas    : BBDD_LEEME.md §5 y SC-22. IDEMPOTENTE; respaldo verificado;
#             verificación posterior; sin efecto si ya está aplicado.
#             Exige la 1.27.0 registrada. Qué cambiar lo decide el ESTADO
#             REAL.
# Lote      : m_ConexionBD.ObtenerEsquemaEsperado: credit_roles 3 → 4,
#             revista 16 → 17, credit_rol_nombre 3 y licencia_texto 3
#             (nuevas). Va en la misma entrega (entregaC2a).
# Volver    : escribe junto al respaldo un .sql que deshace los cuatro
#             cambios (ver el apartado 8).
# ============================================

set -euo pipefail

# --- 0. CONFIGURACIÓN ---
DB="gbpublisher"
PARCHE="actualizacion-1.28.0"
PREVIO="actualizacion-1.27.0"
DESCRIPCION="CRediT y licencias por idioma; logo de la revista"
DIR_RESPALDO="${HOME}/gbpublisher-respaldos"

# LAS COLUMNAS DESPUÉS DE LA ACTUALIZACIÓN (ObtenerEsquemaEsperado)
COLS_CREDIT_ROLES=4
COLS_REVISTA=17
COLS_CREDIT_ROL_NOMBRE=3
COLS_LICENCIA_TEXTO=3

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

columnas_tabla() {
  valor "SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA='${DB}' AND TABLE_NAME='$1';"
}

# --- 1. BIENVENIDA ---
echo
echo "${NEGRITA}Actualización del esquema de gbpublisher a 1.28.0${RESET}"
echo "--------------------------------------------------"
echo "Suma los nombres de los roles CRediT y los textos de las licencias por"
echo "idioma, y el logo de cada revista. No borra ni modifica datos existentes."
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

if [ "$(existe_tabla esquema_version)" != "1" ]; then
  error "La base no tiene la tabla esquema_version: no parece instalada desde un baseline."
  exit 1
fi

# LA CADENA ES ORDENADA: 1.28.0 VA SOBRE 1.27.0
if [ "$(valor "SELECT COUNT(*) FROM \`${DB}\`.esquema_version WHERE parche='${PREVIO}';")" != "1" ]; then
  error "Falta la actualización 1.27.0. Aplicala primero (actualizar-esquema-1.27.0.sh)."
  exit 1
fi

for t in credit_roles licencias revista; do
  if [ "$(existe_tabla "$t")" != "1" ]; then
    error "No existe la tabla ${t}. No se modificó nada."
    exit 1
  fi
done

# --- 3. ESTADO REAL ---
FALTA_URI=0;      [ "$(existe_columna credit_roles uri)" = "1" ]  || FALTA_URI=1
FALTA_NOMBRES=0;  [ "$(existe_tabla credit_rol_nombre)" = "1" ]  || FALTA_NOMBRES=1
FALTA_TEXTOS=0;   [ "$(existe_tabla licencia_texto)" = "1" ]     || FALTA_TEXTOS=1
FALTA_LOGO=0;     [ "$(existe_columna revista logo)" = "1" ]     || FALTA_LOGO=1

if [ $((FALTA_URI + FALTA_NOMBRES + FALTA_TEXTOS + FALTA_LOGO)) -eq 0 ]; then
  ok "Las cuatro estructuras ya están."
  SOLO_INFORME=1
else
  SOLO_INFORME=0
fi

if [ "$SOLO_INFORME" -eq 0 ]; then

  # --- 4. LO QUE SE VA A HACER ---
  [ "$FALTA_URI" -eq 1 ]     && info "credit_roles: columna uri, con la URI de los 14 roles."
  [ "$FALTA_NOMBRES" -eq 1 ] && info "Tabla nueva credit_rol_nombre, con los nombres en es y pt."
  [ "$FALTA_TEXTOS" -eq 1 ]  && info "Tabla nueva licencia_texto, con los seis textos CC 4.0 en castellano."
  [ "$FALTA_LOGO" -eq 1 ]    && info "revista: columna logo (vacía en todas las revistas)."
  echo
  read -r -p "Para continuar, escribí SI en mayúsculas: " RESPUESTA
  if [ "$RESPUESTA" != "SI" ]; then
    warn "Cancelado. No se modificó nada."
    exit 0
  fi

  # --- 5. RESPALDO PREVIO VERIFICADO ---
  mkdir -p "$DIR_RESPALDO"
  RESPALDO="${DIR_RESPALDO}/gbpublisher-antes-1.28.0-$(date '+%Y%m%d-%H%M%S').sql"
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
  for t in credit_roles revista; do
    if ! grep -q "CREATE TABLE \`${t}\`" "$RESPALDO"; then
      error "El respaldo no contiene la tabla ${t}. No se modificó nada."
      exit 1
    fi
  done
  ok "Respaldo verificado ($(du -h "$RESPALDO" | cut -f1))."

  # --- 6. ESTRUCTURA ---
  # 6.1 LA URI DEL ROL. NULL PARA UN ROL QUE NO SEA DE CRediT (EL CATÁLOGO
  # ES EDITABLE): EL CANÓNICO LO ESCRIBE SIN vocab (datos-a-front-jats.xsl)
  if [ "$FALTA_URI" -eq 1 ]; then
    mysql_adm "$DB" -e "ALTER TABLE credit_roles ADD COLUMN uri VARCHAR(200) COLLATE utf8mb4_unicode_ci NULL DEFAULT NULL COMMENT 'URI del rol en credit.niso.org (1.28.0)' AFTER descripcion;"
    ok "credit_roles.uri creada."
  fi

  # 6.2 EL NOMBRE POR IDIOMA. id_rol ES int unsigned COMO credit_roles.id.
  # BORRAR UN ROL BORRA SUS NOMBRES: NO TIENEN SENTIDO SOLOS. LO PUBLICADO NO
  # SE TOCA: EL ARTÍCULO GUARDA EL TÉRMINO EN INGLÉS (SC-23)
  if [ "$FALTA_NOMBRES" -eq 1 ]; then
    mysql_adm "$DB" <<'SQL'
CREATE TABLE IF NOT EXISTS `credit_rol_nombre` (
  `id_rol` int unsigned NOT NULL,
  `idioma` varchar(20) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT 'Código BCP 47 (SC-23)',
  `nombre` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  PRIMARY KEY (`id_rol`, `idioma`),
  CONSTRAINT `fk_credit_rol_nombre_rol` FOREIGN KEY (`id_rol`) REFERENCES `credit_roles` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Nombre de cada rol CRediT por idioma (1.28.0)';
SQL
    ok "Tabla credit_rol_nombre creada."
  fi

  # 6.3 EL TEXTO DE LA LICENCIA POR IDIOMA. LA CLAVE ES LA url, NO EL id DEL
  # CATÁLOGO (SC-23). 500 COMO licencias.url; LA CLAVE PRIMARIA ENTRA EN EL
  # LÍMITE DE InnoDB (3072 BYTES: 500×4 + 20×4)
  if [ "$FALTA_TEXTOS" -eq 1 ]; then
    mysql_adm "$DB" <<'SQL'
CREATE TABLE IF NOT EXISTS `licencia_texto` (
  `url` varchar(500) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT 'licencias.url y articulo.url_licencia',
  `idioma` varchar(20) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT 'Código BCP 47 (SC-23)',
  `texto` text COLLATE utf8mb4_unicode_ci NOT NULL COMMENT 'license-p del canónico',
  PRIMARY KEY (`url`, `idioma`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Texto de cada licencia por idioma (1.28.0)';
SQL
    ok "Tabla licencia_texto creada."
  fi

  # 6.4 EL LOGO. MEDIUMBLOB: HASTA 16 MB. AL FINAL, PARA NO CORRER LAS
  # DEMÁS COLUMNAS
  if [ "$FALTA_LOGO" -eq 1 ]; then
    mysql_adm "$DB" -e "ALTER TABLE revista ADD COLUMN logo MEDIUMBLOB NULL DEFAULT NULL COMMENT 'PNG de la cabecera del artículo; vacío, el genérico (1.28.0)';"
    ok "revista.logo creada."
  fi

  # --- 7. DATOS ---
  # 7.1 LAS URIS, POR EL NOMBRE EXACTO (LIKE BINARY: LA 1.17.0 CORRIGIÓ
  # MAYÚSCULAS Y ESO IMPORTA). SOLO DONDE uri ESTÁ VACÍA
  mysql_adm "$DB" <<'SQL'
UPDATE credit_roles r JOIN (
  SELECT 'Conceptualization' AS n, 'https://credit.niso.org/contributor-roles/conceptualization/' AS u
  UNION ALL SELECT 'Data curation', 'https://credit.niso.org/contributor-roles/data-curation/'
  UNION ALL SELECT 'Formal analysis', 'https://credit.niso.org/contributor-roles/formal-analysis/'
  UNION ALL SELECT 'Funding acquisition', 'https://credit.niso.org/contributor-roles/funding-acquisition/'
  UNION ALL SELECT 'Investigation', 'https://credit.niso.org/contributor-roles/investigation/'
  UNION ALL SELECT 'Methodology', 'https://credit.niso.org/contributor-roles/methodology/'
  UNION ALL SELECT 'Project administration', 'https://credit.niso.org/contributor-roles/project-administration/'
  UNION ALL SELECT 'Resources', 'https://credit.niso.org/contributor-roles/resources/'
  UNION ALL SELECT 'Software', 'https://credit.niso.org/contributor-roles/software/'
  UNION ALL SELECT 'Supervision', 'https://credit.niso.org/contributor-roles/supervision/'
  UNION ALL SELECT 'Validation', 'https://credit.niso.org/contributor-roles/validation/'
  UNION ALL SELECT 'Visualization', 'https://credit.niso.org/contributor-roles/visualization/'
  UNION ALL SELECT 'Writing – original draft', 'https://credit.niso.org/contributor-roles/writing-original-draft/'
  UNION ALL SELECT 'Writing – review & editing', 'https://credit.niso.org/contributor-roles/writing-review-editing/'
) t ON r.nombre LIKE BINARY t.n
SET r.uri = t.u
WHERE r.uri IS NULL;
SQL
  ok "URIs de los roles cargadas (las que ya estaban no se tocaron)."

  # 7.2 LOS NOMBRES, UNIDOS POR LA URI: ES LA CLAVE DE LOS ARCHIVOS DE LA
  # FUENTE. pt ES pt_Latn (PORTUGUÉS DE BRASIL, SEGÚN SU translationProcedure);
  # EL VOLCADO BUSCA EL IDIOMA EXACTO Y DESPUÉS SU SUBETIQUETA PRIMARIA
  mysql_adm "$DB" <<'SQL'
INSERT IGNORE INTO credit_rol_nombre (id_rol, idioma, nombre)
SELECT r.id, t.idioma, t.nombre FROM credit_roles r JOIN (
  SELECT 'conceptualization' AS c, 'es' AS idioma, 'Conceptualización' AS nombre
  UNION ALL SELECT 'data-curation', 'es', 'Curación de datos'
  UNION ALL SELECT 'formal-analysis', 'es', 'Análisis formal'
  UNION ALL SELECT 'funding-acquisition', 'es', 'Captación de fondos'
  UNION ALL SELECT 'investigation', 'es', 'Investigación'
  UNION ALL SELECT 'methodology', 'es', 'Metodología'
  UNION ALL SELECT 'project-administration', 'es', 'Administración del proyecto'
  UNION ALL SELECT 'resources', 'es', 'Recursos'
  UNION ALL SELECT 'software', 'es', 'Software'
  UNION ALL SELECT 'supervision', 'es', 'Supervisión'
  UNION ALL SELECT 'validation', 'es', 'Validación'
  UNION ALL SELECT 'visualization', 'es', 'Visualización'
  UNION ALL SELECT 'writing-original-draft', 'es', 'Redacción - borrador original'
  UNION ALL SELECT 'writing-review-editing', 'es', 'Redacción - revisión y edición'
  UNION ALL SELECT 'conceptualization', 'pt', 'Conceitualização'
  UNION ALL SELECT 'data-curation', 'pt', 'Curadoria de dados'
  UNION ALL SELECT 'formal-analysis', 'pt', 'Análise formal'
  UNION ALL SELECT 'funding-acquisition', 'pt', 'Aquisição de financiamento'
  UNION ALL SELECT 'investigation', 'pt', 'Investigação'
  UNION ALL SELECT 'methodology', 'pt', 'Metodologia'
  UNION ALL SELECT 'project-administration', 'pt', 'Administração do projeto'
  UNION ALL SELECT 'resources', 'pt', 'Recursos'
  UNION ALL SELECT 'software', 'pt', 'Software/programas de computador'
  UNION ALL SELECT 'supervision', 'pt', 'Supervisão'
  UNION ALL SELECT 'validation', 'pt', 'Validação'
  UNION ALL SELECT 'visualization', 'pt', 'Visualização'
  UNION ALL SELECT 'writing-original-draft', 'pt', 'Escrita - esboço original'
  UNION ALL SELECT 'writing-review-editing', 'pt', 'Escrita - revisão e edição'
) t ON r.uri = CONCAT('https://credit.niso.org/contributor-roles/', t.c, '/');
SQL
  ok "Nombres de los roles en es y pt cargados (los que ya estaban no se tocaron)."

  # 7.3 LOS TEXTOS: LOS DE jats-to-latex.xsl, CON LA url DEL CATÁLOGO
  # (actualizar-esquema-1.2.0.sh)
  mysql_adm "$DB" <<'SQL'
INSERT IGNORE INTO licencia_texto (url, idioma, texto) VALUES
('https://creativecommons.org/licenses/by/4.0/', 'es', 'Se permite el uso, distribución y reproducción sin restricciones, incluso con fines comerciales, siempre que se cite la obra original.'),
('https://creativecommons.org/licenses/by-sa/4.0/', 'es', 'Se permite el uso, distribución y reproducción, incluso con fines comerciales, siempre que se cite la obra original y las obras derivadas se distribuyan bajo la misma licencia.'),
('https://creativecommons.org/licenses/by-nc/4.0/', 'es', 'Se permite el uso, distribución y reproducción sin fines comerciales, siempre que se cite la obra original.'),
('https://creativecommons.org/licenses/by-nc-sa/4.0/', 'es', 'Se permite el uso, distribución y reproducción sin fines comerciales, siempre que se cite la obra original y las obras derivadas se distribuyan bajo la misma licencia.'),
('https://creativecommons.org/licenses/by-nd/4.0/', 'es', 'Se permite el uso y distribución, incluso con fines comerciales, siempre que se cite la obra original y no se realicen obras derivadas.'),
('https://creativecommons.org/licenses/by-nc-nd/4.0/', 'es', 'Se permite el uso y distribución sin fines comerciales, siempre que se cite la obra original y no se realicen obras derivadas.');
SQL
  ok "Textos de las seis licencias CC 4.0 en castellano cargados (los que ya estaban no se tocaron)."

  # --- 8. VOLVER ATRÁS ---
  # BORRA LAS DOS TABLAS Y LAS DOS COLUMNAS. LO QUE SE HAYA EDITADO DESPUÉS
  # SE PIERDE; ESTÁ EN EL RESPALDO DE ANTES SOLO LO QUE HABÍA ANTES
  VOLVER="${RESPALDO%.sql}-volver-atras.sql"
  cat > "$VOLVER" <<'SQL'
-- VOLVER ATRÁS LA 1.28.0 DE gbpublisher: sudo mysql gbpublisher < ESTE_ARCHIVO
DROP TABLE IF EXISTS credit_rol_nombre;
DROP TABLE IF EXISTS licencia_texto;
ALTER TABLE credit_roles DROP COLUMN uri;
ALTER TABLE revista DROP COLUMN logo;
DELETE FROM esquema_version WHERE parche = 'actualizacion-1.28.0';
SQL
  ok "Para volver atrás: ${VOLVER}"

  # --- 9. VERIFICACIÓN POSTERIOR ---
  FALLA=0
  for par in "credit_roles:${COLS_CREDIT_ROLES}" "revista:${COLS_REVISTA}" \
             "credit_rol_nombre:${COLS_CREDIT_ROL_NOMBRE}" "licencia_texto:${COLS_LICENCIA_TEXTO}"; do
    t="${par%%:*}"; n="${par##*:}"
    CANTIDAD="$(columnas_tabla "$t")"
    if [ "$CANTIDAD" != "$n" ]; then
      error "${t} tiene ${CANTIDAD} columnas y se esperaban ${n}."
      FALLA=1
    fi
  done
  # LOS 14 ROLES DE CRediT TIENEN SU URI Y SUS DOS NOMBRES. UN ROL QUE
  # FALTA EN EL CATÁLOGO O QUE TIENE OTRO NOMBRE QUEDA EN EL INFORME
  CON_URI="$(valor "SELECT COUNT(*) FROM \`${DB}\`.credit_roles WHERE uri LIKE 'https://credit.niso.org/contributor-roles/%';")"
  if [ "$CON_URI" != "14" ]; then
    warn "Solo ${CON_URI} de los 14 roles de CRediT quedaron con su URI: revisá el informe."
  fi
  if [ "$FALLA" = "1" ]; then
    error "NO se registra la actualización. Para volver atrás:"
    error "  sudo mysql ${DB} < ${VOLVER}"
    exit 1
  fi
  ok "Verificación correcta: estructuras creadas, ${CON_URI} roles con URI."

  # --- 10. REGISTRO ---
  mysql_adm "$DB" -e "INSERT IGNORE INTO esquema_version (parche, descripcion) VALUES ('${PARCHE}', '${DESCRIPCION}');"
  ok "Registrado en esquema_version como ${PARCHE}."
  info "Para volver atrás (respaldo en ${RESPALDO}):"
  echo "  sudo mysql ${DB} < ${VOLVER}"

else
  # YA ESTABA: SE REGISTRA PARA QUE EL NIVEL DECLARADO REFLEJE EL ESTADO REAL
  if [ "$(valor "SELECT COUNT(*) FROM \`${DB}\`.esquema_version WHERE parche='${PARCHE}';")" = "0" ]; then
    mysql_adm "$DB" -e "INSERT INTO esquema_version (parche, descripcion) VALUES ('${PARCHE}', '${DESCRIPCION}');"
    ok "Ya estaba aplicada; registrado en esquema_version como ${PARCHE}."
  fi
fi

# --- 11. INFORME DE CONTROL (SOLO LECTURA) ---
echo
info "Informe de control: los roles y sus nombres (vacío = sale el inglés)"
mysql_adm "$DB" -e "SELECT r.id, r.nombre, r.uri IS NOT NULL AS con_uri,
  (SELECT n.nombre FROM credit_rol_nombre n WHERE n.id_rol = r.id AND n.idioma = 'es') AS es,
  (SELECT n.nombre FROM credit_rol_nombre n WHERE n.id_rol = r.id AND n.idioma = 'pt') AS pt
  FROM credit_roles r ORDER BY r.nombre;"
info "Las licencias de contenido y sus textos (vacío = sale la etiqueta)"
mysql_adm "$DB" -e "SELECT l.etiqueta,
  (SELECT GROUP_CONCAT(t.idioma ORDER BY t.idioma) FROM licencia_texto t WHERE t.url = l.url) AS idiomas
  FROM licencias l WHERE l.para_contenido = 1 ORDER BY l.orden;"
echo "El informe no modifica nada."
echo
ok "${NEGRITA}Actualización 1.28.0 lista.${RESET}"
