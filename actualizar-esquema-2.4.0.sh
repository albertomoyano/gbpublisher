#!/usr/bin/env bash
#
# ============================================
# Script    : actualizar-esquema-2.4.0.sh
# Propósito : Actualización 2.4.0 de la base de gbpublisher. BORRA las
#             columnas que la aplicación dejó de usar con F1 y F2
#             (claude/crossref-libros.md), el segundo paso del camino de
#             1.26.0 y 1.27.0:
#               libros_md: editorial, institucion_editora, ror_editorial,
#                 ciudad_publicacion, pais_publicacion,
#                 pais_publicacion_codigo, direccion_editorial, doi_prefix
#                 (pasaron a editorial por libro_editorial en la 2.2.0)
#               colecciones: doi_prefix (el prefijo es de la editorial)
#               capitulos: crossref_estado, crossref_fecha_deposito (el
#                 depósito es del libro: libros_md.crossref_fecha_deposito,
#                 2.3.0)
#             Y deja en NULL libros_md.email_editorial cuando repite el
#             correo de la editorial principal: el del libro es un reemplazo
#             (email-depositante) y solo tiene sentido si es otro.
# Uso       : sudo bash actualizar-esquema-2.4.0.sh
# Reglas    : BBDD_LEEME.md §5 y SC-22. IDEMPOTENTE; respaldo verificado;
#             verificación posterior; sin efecto si ya está aplicado. Exige
#             la 2.3.0.
# Frenos    : una VIEW que use alguna de las columnas (se rompería); una
#             colección con prefijo DOI (se perdería: va en su editorial).
# Informa   : libros sin editorial que tienen datos en las columnas viejas
#             (se pierden; quedan en el respaldo) y consultas guardadas de
#             Estadísticas que nombran alguna columna (fallarán al correr).
# Orden     : la aplicación NUEVA exige este esquema (m_ConexionBD:
#             libros_md 82, colecciones 19, capitulos 77) y la anterior
#             deja de abrir: se aplica el script y enseguida se instala la
#             aplicación nueva, en todos los puestos.
# Volver    : solo restaurando el respaldo (el script muestra el comando):
#             las columnas borradas no se pueden reconstruir.
# ============================================

set -euo pipefail

# --- 0. CONFIGURACIÓN ---
DB="gbpublisher"
PARCHE="actualizacion-2.4.0"
PREVIO="actualizacion-2.3.0"
DESCRIPCION="Borra las columnas viejas de editorial de libros_md, colecciones.doi_prefix y capitulos.crossref_*; limpia email_editorial repetido"
DIR_RESPALDO="${HOME}/gbpublisher-respaldos"
# TABLA:COLUMNA, EN EL ORDEN EN QUE SE BORRAN
COLUMNAS=(
  libros_md:editorial libros_md:institucion_editora libros_md:ror_editorial
  libros_md:ciudad_publicacion libros_md:pais_publicacion libros_md:pais_publicacion_codigo
  libros_md:direccion_editorial libros_md:doi_prefix
  colecciones:doi_prefix
  capitulos:crossref_estado capitulos:crossref_fecha_deposito
)
# LO QUE DEBE QUEDAR, IGUAL A m_ConexionBD.ObtenerEsquemaEsperado
declare -A ESPERADAS=([libros_md]=82 [colecciones]=19 [capitulos]=77)

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
  valor "SELECT COUNT(*) FROM information_schema.COLUMNS
    WHERE TABLE_SCHEMA='${DB}' AND TABLE_NAME='$1' AND COLUMN_NAME='$2';"
}

columnas() {
  valor "SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA='${DB}' AND TABLE_NAME='$1';"
}

# --- 1. BIENVENIDA ---
echo
echo "${NEGRITA}Actualización del esquema de gbpublisher a 2.4.0${RESET}"
echo "--------------------------------------------------"
echo "Borra columnas que gbpublisher ya no usa (editorial del libro, prefijo de"
echo "la colección, depósito por capítulo). Después hay que instalar la"
echo "aplicación nueva: la anterior no abre con este esquema."
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

if [ "$(valor "SELECT COUNT(*) FROM \`${DB}\`.esquema_version WHERE parche='${PREVIO}';")" = "0" ]; then
  error "Falta la 2.3.0. Aplicá primero actualizar-esquema-2.3.0.sh."
  exit 1
fi

# --- 3. ESTADO REAL: LAS COLUMNAS QUE QUEDAN POR BORRAR ---
PENDIENTES=()
for tc in "${COLUMNAS[@]}"; do
  if [ "$(existe_columna "${tc%%:*}" "${tc##*:}")" = "1" ]; then
    PENDIENTES+=("$tc")
  fi
done

if [ "${#PENDIENTES[@]}" -eq 0 ]; then
  ok "Las columnas ya no están."
else
  info "Columnas por borrar: ${#PENDIENTES[@]}"
  for tc in "${PENDIENTES[@]}"; do echo "    ${tc/:/.}"; done

  # --- 4. FRENOS ---
  # UNA VIEW QUE USE UNA COLUMNA BORRADA QUEDA ROTA (ERROR 1356 AL LEERLA)
  FRENO=0
  for tc in "${PENDIENTES[@]}"; do
    VISTAS="$(valor "SELECT GROUP_CONCAT(TABLE_NAME) FROM information_schema.VIEWS
      WHERE TABLE_SCHEMA='${DB}' AND VIEW_DEFINITION LIKE '%\`${tc%%:*}\`.\`${tc##*:}\`%';")"
    if [ -n "$VISTAS" ] && [ "$VISTAS" != "NULL" ]; then
      error "La columna ${tc/:/.} la usa: ${VISTAS}"
      FRENO=1
    fi
  done
  # EL PREFIJO DE UNA COLECCIÓN SE PERDERÍA: ES DE LA EDITORIAL
  if [ "$(existe_columna colecciones doi_prefix)" = "1" ]; then
    CON_PREFIJO="$(valor "SELECT COUNT(*) FROM \`${DB}\`.colecciones WHERE NULLIF(TRIM(doi_prefix), '') IS NOT NULL;")"
    if [ "$CON_PREFIJO" != "0" ]; then
      error "Hay ${CON_PREFIJO} colección(es) con prefijo DOI. Cargalo en su editorial (gbpublisher admin) y vaciá el de la colección:"
      mysql_adm -t "$DB" -e "SELECT id_coleccion, nombre, doi_prefix FROM colecciones WHERE NULLIF(TRIM(doi_prefix), '') IS NOT NULL;"
      FRENO=1
    fi
  fi
  if [ "$FRENO" = "1" ]; then
    error "No se modificó nada."
    exit 1
  fi

  # --- 5. INFORME: LO QUE SE PIERDE Y LO QUE VA A FALLAR ---
  # LIBROS SIN EDITORIAL CON DATOS VIEJOS: LA 2.2.0 NO LOS MIGRÓ (SIN NOMBRE
  # NO HAY EDITORIAL); QUEDAN SOLO EN EL RESPALDO
  if [ "$(existe_columna libros_md editorial)" = "1" ]; then
    SIN_EDITORIAL="$(valor "SELECT COUNT(*) FROM \`${DB}\`.libros_md l
      WHERE NOT EXISTS (SELECT 1 FROM \`${DB}\`.libro_editorial le WHERE le.id_libro = l.id_libro)
        AND CONCAT_WS('', NULLIF(TRIM(l.institucion_editora), ''), NULLIF(TRIM(l.ror_editorial), ''),
          NULLIF(TRIM(l.ciudad_publicacion), ''), NULLIF(TRIM(l.pais_publicacion), ''),
          NULLIF(TRIM(l.direccion_editorial), ''), NULLIF(TRIM(l.doi_prefix), '')) <> '';")"
    if [ "$SIN_EDITORIAL" != "0" ]; then
      warn "${SIN_EDITORIAL} libro(s) sin editorial tienen datos en las columnas viejas. Se pierden (quedan en el respaldo):"
      mysql_adm -t "$DB" -e "SELECT l.id_libro, LEFT(l.titulo_libro, 50) AS titulo, l.ciudad_publicacion, l.pais_publicacion, l.doi_prefix
        FROM libros_md l WHERE NOT EXISTS (SELECT 1 FROM libro_editorial le WHERE le.id_libro = l.id_libro)
        AND CONCAT_WS('', NULLIF(TRIM(l.institucion_editora), ''), NULLIF(TRIM(l.ror_editorial), ''),
          NULLIF(TRIM(l.ciudad_publicacion), ''), NULLIF(TRIM(l.pais_publicacion), ''),
          NULLIF(TRIM(l.direccion_editorial), ''), NULLIF(TRIM(l.doi_prefix), '')) <> '';"
    else
      ok "Ningún libro sin editorial tiene datos en las columnas viejas."
    fi
  fi
  # LAS CONSULTAS GUARDADAS DE Estadísticas: SU TEXTO NO SE TOCA, PERO LAS
  # QUE NOMBRAN UNA COLUMNA BORRADA VAN A FALLAR. LA BÚSQUEDA ES POR NOMBRE:
  # PUEDE TRAER ALGUNA QUE NO LA USA (editorial ES TAMBIÉN UNA TABLA)
  if [ "$(existe_tabla consultas)" = "1" ]; then
    PATRON="institucion_editora|ror_editorial|ciudad_publicacion|pais_publicacion|direccion_editorial|doi_prefix|crossref_estado|crossref_fecha_deposito|libros_md\\.editorial|l\\.editorial"
    N_CONSULTAS="$(valor "SELECT COUNT(*) FROM \`${DB}\`.consultas WHERE editor_consultas REGEXP '${PATRON}';")"
    if [ "$N_CONSULTAS" != "0" ]; then
      warn "${N_CONSULTAS} consulta(s) guardada(s) nombran columnas que se borran. Revisalas en Estadísticas:"
      mysql_adm -t "$DB" -e "SELECT id, nombre FROM consultas WHERE editor_consultas REGEXP '${PATRON}';"
    else
      ok "Ninguna consulta guardada nombra las columnas que se borran."
    fi
  fi

  # --- 6. CONFIRMACIÓN ---
  echo
  read -r -p "Para continuar, escribí SI en mayúsculas: " RESPUESTA
  if [ "$RESPUESTA" != "SI" ]; then
    warn "Cancelado. No se modificó nada."
    exit 0
  fi

  # --- 7. RESPALDO PREVIO VERIFICADO ---
  mkdir -p "$DIR_RESPALDO"
  RESPALDO="${DIR_RESPALDO}/gbpublisher-antes-2.4.0-$(date '+%Y%m%d-%H%M%S').sql"
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
  for t in libros_md colecciones capitulos; do
    if ! grep -q "CREATE TABLE \`${t}\`" "$RESPALDO"; then
      error "El respaldo no contiene la tabla ${t}. No se modificó nada."
      exit 1
    fi
  done
  ok "Respaldo verificado ($(du -h "$RESPALDO" | cut -f1))."

  declare -A FILAS_ANTES=()
  for t in libros_md colecciones capitulos; do
    FILAS_ANTES[$t]="$(valor "SELECT COUNT(*) FROM \`${DB}\`.${t};")"
  done

  # --- 8. EL CORREO DEL LIBRO QUE REPITE EL DE LA EDITORIAL ---
  # SOLO TIENE SENTIDO SI ES OTRO (email-depositante). SIN DISTINGUIR
  # MAYÚSCULAS: LA COLACIÓN DE LAS COLUMNAS (utf8mb4_unicode_ci). TAMBIÉN EL
  # VACÍO PASA A NULL
  LIMPIOS="$(valor "UPDATE \`${DB}\`.libros_md l
      JOIN \`${DB}\`.libro_editorial le ON le.id_libro = l.id_libro AND le.orden = 1
      JOIN \`${DB}\`.editorial e ON e.id_editorial = le.id_editorial
    SET l.email_editorial = NULL
    WHERE l.email_editorial IS NOT NULL AND TRIM(l.email_editorial) = TRIM(e.email);
    SELECT ROW_COUNT();")"
  VACIOS="$(valor "UPDATE \`${DB}\`.libros_md SET email_editorial = NULL WHERE email_editorial IS NOT NULL AND TRIM(email_editorial) = '';
    SELECT ROW_COUNT();")"
  ok "Correos del libro iguales al de la editorial: ${LIMPIOS} en NULL; vacíos: ${VACIOS}."

  # --- 9. LAS COLUMNAS ---
  # UN ALTER POR TABLA, CON TODAS SUS COLUMNAS: CADA TABLA QUEDA ENTERA DE UN
  # SOLO PASO. ANTES, EN EL MISMO ALTER, LAS CLAVES FORÁNEAS Y LOS CHECK QUE
  # LAS USAN: MySQL NO BORRA UNA COLUMNA QUE LOS SOSTIENE (ERROR 1828,
  # libros_md.pais_publicacion_codigo → fk_libro_pais_publicacion, MEDIDO)
  for t in libros_md colecciones capitulos; do
    DROPS=""
    for tc in "${PENDIENTES[@]}"; do
      if [ "${tc%%:*}" = "$t" ]; then
        for fk in $(valor "SELECT DISTINCT CONSTRAINT_NAME FROM information_schema.KEY_COLUMN_USAGE
            WHERE TABLE_SCHEMA='${DB}' AND TABLE_NAME='${t}' AND COLUMN_NAME='${tc##*:}'
              AND REFERENCED_TABLE_NAME IS NOT NULL;"); do
          DROPS="${DROPS:+${DROPS}, }DROP FOREIGN KEY \`${fk}\`"
        done
        for ck in $(valor "SELECT cc.CONSTRAINT_NAME FROM information_schema.CHECK_CONSTRAINTS cc
            JOIN information_schema.TABLE_CONSTRAINTS tc USING (CONSTRAINT_SCHEMA, CONSTRAINT_NAME)
            WHERE cc.CONSTRAINT_SCHEMA='${DB}' AND tc.TABLE_NAME='${t}'
              AND cc.CHECK_CLAUSE LIKE '%\`${tc##*:}\`%';"); do
          DROPS="${DROPS:+${DROPS}, }DROP CHECK \`${ck}\`"
        done
      fi
    done
    for tc in "${PENDIENTES[@]}"; do
      if [ "${tc%%:*}" = "$t" ]; then
        DROPS="${DROPS:+${DROPS}, }DROP COLUMN \`${tc##*:}\`"
      fi
    done
    if [ -n "$DROPS" ]; then
      mysql_adm "$DB" -e "ALTER TABLE \`${t}\` ${DROPS};"
      ok "${t}: ${DROPS}"
    fi
  done

  # --- 10. VERIFICACIÓN POSTERIOR ---
  for t in libros_md colecciones capitulos; do
    if [ "$(columnas "$t")" != "${ESPERADAS[$t]}" ]; then
      error "${t} quedó con $(columnas "$t") columnas y se esperaban ${ESPERADAS[$t]}. NO se registra la actualización."
      echo "  Para volver: sudo mysql ${DB} < ${RESPALDO}"
      exit 1
    fi
    if [ "$(valor "SELECT COUNT(*) FROM \`${DB}\`.${t};")" != "${FILAS_ANTES[$t]}" ]; then
      error "${t} cambió de cantidad de filas. NO se registra la actualización."
      echo "  Para volver: sudo mysql ${DB} < ${RESPALDO}"
      exit 1
    fi
  done
  # LAS VIEW SIGUEN LEYÉNDOSE
  for v in $(valor "SELECT TABLE_NAME FROM information_schema.VIEWS WHERE TABLE_SCHEMA='${DB}';"); do
    if ! mysql_adm "$DB" -e "SELECT 1 FROM \`${v}\` LIMIT 1;" >/dev/null 2>&1; then
      error "La vista ${v} quedó rota. NO se registra la actualización."
      echo "  Para volver: sudo mysql ${DB} < ${RESPALDO}"
      exit 1
    fi
  done
  ok "Verificación correcta: libros_md ${ESPERADAS[libros_md]}, colecciones ${ESPERADAS[colecciones]}, capitulos ${ESPERADAS[capitulos]} columnas; filas y vistas intactas."
  echo
  info "Para volver atrás (solo con el respaldo):"
  echo "  sudo mysql ${DB} < ${RESPALDO}"
fi

# --- 11. REGISTRO ---
if [ "$(valor "SELECT COUNT(*) FROM \`${DB}\`.esquema_version WHERE parche='${PARCHE}';")" = "0" ]; then
  mysql_adm "$DB" -e "INSERT INTO esquema_version (parche, descripcion) VALUES ('${PARCHE}', '${DESCRIPCION}');"
  ok "Registrado en esquema_version como ${PARCHE}."
fi

echo
ok "${NEGRITA}Actualización 2.4.0 lista. Instalá ahora la aplicación nueva.${RESET}"
