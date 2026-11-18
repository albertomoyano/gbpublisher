#!/usr/bin/env bash
#
# ============================================
# Script    : actualizar-esquema-1.31.0.sh
# Propósito : Actualización 1.31.0 de la base de gbpublisher, sobre una base
#             EN USO. Lleva el catálogo de países de la 1.30.0 a los demás
#             campos de país con formulario propio (decisión de Alberto del
#             18/11/2026, F5b: uniformidad y menos errores de tipeo):
#               autores.pais_afiliacion       → pais_afiliacion_codigo
#               autores.pais_correspondencia  → pais_correspondencia_codigo
#               autores.pais_nacimiento       → pais_nacimiento_codigo
#               libros_md.pais_publicacion    → pais_publicacion_codigo
#             Igual que la 1.30.0: el código ISO 3166-1 con clave foránea a
#             pais, y el nombre por valor en la columna de texto (SC-23,
#             SC-74). La migración completa el código donde el texto coincide
#             con el catálogo y lista lo que no.
#             NO SE TOCAN: autores.nacionalidad (un gentilicio, admite varias
#             separadas por «;»); revistas_md.pais_publicacion (el camino
#             viejo de revistas, que se retira); articulo_autor,
#             capitulo_autor y libro_autor.pais_momento (sin formulario).
# Uso       : sudo bash actualizar-esquema-1.31.0.sh
# Reglas    : BBDD_LEEME.md §5 y SC-22. IDEMPOTENTE; respaldo verificado;
#             verificación posterior; sin efecto si ya está aplicado.
#             Exige la 1.30.0 registrada.
# Lote      : m_ConexionBD.ObtenerEsquemaEsperado: autores +3, libros_md +1.
#             Va en la misma entrega (entregaF5b).
# Volver    : escribe junto al respaldo un .sql que borra las cuatro columnas.
# ============================================

set -euo pipefail

# --- 0. CONFIGURACIÓN ---
DB="gbpublisher"
PARCHE="actualizacion-1.31.0"
PREVIO="actualizacion-1.30.0"
DESCRIPCION="Catálogo de países en autores (afiliación, correspondencia, nacimiento) y libros"
DIR_RESPALDO="${HOME}/gbpublisher-respaldos"

# TABLA:COLUMNA DE TEXTO:COLUMNA DE CÓDIGO NUEVA:NOMBRE DE LA CLAVE FORÁNEA
CAMPOS=(
  "autores:pais_afiliacion:pais_afiliacion_codigo:fk_autor_pais_afiliacion"
  "autores:pais_correspondencia:pais_correspondencia_codigo:fk_autor_pais_correspondencia"
  "autores:pais_nacimiento:pais_nacimiento_codigo:fk_autor_pais_nacimiento"
  "libros_md:pais_publicacion:pais_publicacion_codigo:fk_libro_pais_publicacion"
)

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
echo "${NEGRITA}Actualización del esquema de gbpublisher a 1.31.0${RESET}"
echo "--------------------------------------------------"
echo "Agrega el código de país (ISO 3166-1, del catálogo de la 1.30.0) a los"
echo "países de la ficha del autor y al país de publicación del libro."
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

# LA CADENA ES ORDENADA: 1.31.0 VA SOBRE 1.30.0 (QUE CREA EL CATÁLOGO)
if [ "$(valor "SELECT COUNT(*) FROM \`${DB}\`.esquema_version WHERE parche='${PREVIO}';")" != "1" ]; then
  error "Falta la actualización 1.30.0. Aplicala primero (actualizar-esquema-1.30.0.sh)."
  exit 1
fi

for t in pais autores libros_md; do
  if [ "$(existe_tabla "$t")" != "1" ]; then
    error "No existe la tabla ${t}. No se modificó nada."
    exit 1
  fi
done

# --- 3. ESTADO REAL ---
# CUÁNTAS COLUMNAS FALTAN, Y CUÁNTAS TIENE HOY CADA TABLA: LA VERIFICACIÓN
# POSTERIOR ESPERA LAS DE HOY MÁS LAS QUE SE AGREGAN
FALTAN=0
for c in "${CAMPOS[@]}"; do
  IFS=':' read -r t texto codigo fk <<< "$c"
  if [ "$(existe_columna "$t" "$texto")" != "1" ]; then
    error "No existe ${t}.${texto}. No se modificó nada."
    exit 1
  fi
  [ "$(existe_columna "$t" "$codigo")" = "1" ] || FALTAN=$((FALTAN + 1))
done
ANTES_AUTORES="$(columnas_tabla autores)"
ANTES_LIBROS="$(columnas_tabla libros_md)"

if [ "$FALTAN" -eq 0 ]; then
  ok "Las cuatro columnas de código ya están."
  SOLO_INFORME=1
else
  SOLO_INFORME=0
fi

if [ "$SOLO_INFORME" -eq 0 ]; then

  # --- 4. LO QUE SE VA A HACER ---
  for c in "${CAMPOS[@]}"; do
    IFS=':' read -r t texto codigo fk <<< "$c"
    [ "$(existe_columna "$t" "$codigo")" = "1" ] || info "${t}: columna ${codigo}, con el código de ${texto}."
  done
  echo
  read -r -p "Para continuar, escribí SI en mayúsculas: " RESPUESTA
  if [ "$RESPUESTA" != "SI" ]; then
    warn "Cancelado. No se modificó nada."
    exit 0
  fi

  # --- 5. RESPALDO PREVIO VERIFICADO ---
  mkdir -p "$DIR_RESPALDO"
  RESPALDO="${DIR_RESPALDO}/gbpublisher-antes-1.31.0-$(date '+%Y%m%d-%H%M%S').sql"
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
  for t in autores libros_md pais; do
    if ! grep -q "CREATE TABLE \`${t}\`" "$RESPALDO"; then
      error "El respaldo no contiene la tabla ${t}. No se modificó nada."
      exit 1
    fi
  done
  ok "Respaldo verificado ($(du -h "$RESPALDO" | cut -f1))."

  # --- 6. LAS COLUMNAS, CON SU CLAVE FORÁNEA, Y LA MIGRACIÓN ---
  # LA COLACIÓN ES LA DE pais.codigo: UNA CLAVE FORÁNEA LA EXIGE IGUAL.
  # LA MIGRACIÓN ES LA DE LA 1.30.0: NOMBRE EN ESPAÑOL, EN INGLÉS O EL
  # CÓDIGO, SIN MAYÚSCULAS NI TILDES; SOLO DONDE NO HAY CÓDIGO
  AGREGADAS_AUTORES=0
  AGREGADAS_LIBROS=0
  for c in "${CAMPOS[@]}"; do
    IFS=':' read -r t texto codigo fk <<< "$c"
    if [ "$(existe_columna "$t" "$codigo")" != "1" ]; then
      mysql_adm "$DB" -e "ALTER TABLE ${t}
        ADD COLUMN ${codigo} CHAR(2) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT NULL COMMENT 'ISO 3166-1 alfa-2; el nombre va en ${texto}, por valor (1.31.0)' AFTER ${texto},
        ADD CONSTRAINT ${fk} FOREIGN KEY (${codigo}) REFERENCES pais (codigo) ON DELETE RESTRICT ON UPDATE RESTRICT;"
      ok "${t}.${codigo} creada."
      if [ "$t" = "autores" ]; then AGREGADAS_AUTORES=$((AGREGADAS_AUTORES + 1)); else AGREGADAS_LIBROS=$((AGREGADAS_LIBROS + 1)); fi
    fi
    mysql_adm "$DB" -e "UPDATE ${t} x
      JOIN pais p ON TRIM(x.${texto}) COLLATE utf8mb4_0900_ai_ci = p.nombre COLLATE utf8mb4_0900_ai_ci
                  OR TRIM(x.${texto}) COLLATE utf8mb4_0900_ai_ci = p.nombre_en COLLATE utf8mb4_0900_ai_ci
                  OR TRIM(x.${texto}) COLLATE utf8mb4_0900_ai_ci = p.codigo COLLATE utf8mb4_0900_ai_ci
      SET x.${codigo} = p.codigo
      WHERE x.${codigo} IS NULL AND x.${texto} IS NOT NULL AND TRIM(x.${texto}) <> '';"
  done
  ok "Códigos completados donde el texto coincide con el catálogo."

  # --- 7. VOLVER ATRÁS ---
  VOLVER="${RESPALDO%.sql}-volver-atras.sql"
  cat > "$VOLVER" <<'SQL'
-- VOLVER ATRÁS LA 1.31.0 DE gbpublisher: sudo mysql gbpublisher < ESTE_ARCHIVO
ALTER TABLE autores
  DROP FOREIGN KEY fk_autor_pais_afiliacion, DROP COLUMN pais_afiliacion_codigo,
  DROP FOREIGN KEY fk_autor_pais_correspondencia, DROP COLUMN pais_correspondencia_codigo,
  DROP FOREIGN KEY fk_autor_pais_nacimiento, DROP COLUMN pais_nacimiento_codigo;
ALTER TABLE libros_md DROP FOREIGN KEY fk_libro_pais_publicacion, DROP COLUMN pais_publicacion_codigo;
DELETE FROM esquema_version WHERE parche = 'actualizacion-1.31.0';
SQL
  ok "Para volver atrás: ${VOLVER}"

  # --- 8. VERIFICACIÓN POSTERIOR ---
  # LAS COLUMNAS DE HOY MÁS LAS AGREGADAS: NO DEPENDE DE CUÁNTAS TENGA CADA
  # BASE (ObtenerEsquemaEsperado VERIFICA EL NÚMERO ABSOLUTO AL ARRANCAR)
  FALLA=0
  for par in "autores:$((ANTES_AUTORES + AGREGADAS_AUTORES))" "libros_md:$((ANTES_LIBROS + AGREGADAS_LIBROS))"; do
    t="${par%%:*}"; n="${par##*:}"
    CANTIDAD="$(columnas_tabla "$t")"
    if [ "$CANTIDAD" != "$n" ]; then
      error "${t} tiene ${CANTIDAD} columnas y se esperaban ${n}."
      FALLA=1
    fi
  done
  for c in "${CAMPOS[@]}"; do
    IFS=':' read -r t texto codigo fk <<< "$c"
    if [ "$(existe_columna "$t" "$codigo")" != "1" ]; then
      error "Falta ${t}.${codigo}."
      FALLA=1
    fi
  done
  if [ "$FALLA" = "1" ]; then
    error "NO se registra la actualización. Para volver atrás:"
    error "  sudo mysql ${DB} < ${VOLVER}"
    exit 1
  fi
  ok "Verificación correcta: las cuatro columnas creadas."

  # --- 9. REGISTRO ---
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

# --- 10. INFORME DE CONTROL (SOLO LECTURA) ---
# LO QUE QUEDÓ SIN CÓDIGO: HAY QUE ELEGIR EL PAÍS EN LA FICHA DEL AUTOR O EN
# LOS METADATOS DEL LIBRO
echo
info "Informe de control: los países que quedaron sin código"
mysql_adm "$DB" -e "
  SELECT 'autor: afiliación' AS campo, pais_afiliacion AS texto, COUNT(*) AS veces, GROUP_CONCAT(id_autor ORDER BY id_autor) AS ids
    FROM autores WHERE pais_afiliacion_codigo IS NULL AND TRIM(COALESCE(pais_afiliacion, '')) <> '' GROUP BY pais_afiliacion
  UNION ALL
  SELECT 'autor: correspondencia', pais_correspondencia, COUNT(*), GROUP_CONCAT(id_autor ORDER BY id_autor)
    FROM autores WHERE pais_correspondencia_codigo IS NULL AND TRIM(COALESCE(pais_correspondencia, '')) <> '' GROUP BY pais_correspondencia
  UNION ALL
  SELECT 'autor: nacimiento', pais_nacimiento, COUNT(*), GROUP_CONCAT(id_autor ORDER BY id_autor)
    FROM autores WHERE pais_nacimiento_codigo IS NULL AND TRIM(COALESCE(pais_nacimiento, '')) <> '' GROUP BY pais_nacimiento
  UNION ALL
  SELECT 'libro: publicación', pais_publicacion, COUNT(*), GROUP_CONCAT(id_proyecto ORDER BY id_proyecto)
    FROM libros_md WHERE pais_publicacion_codigo IS NULL AND TRIM(COALESCE(pais_publicacion, '')) <> '' GROUP BY pais_publicacion;"
echo "El informe no modifica nada. Una lista vacía: todo tiene código."
echo "Los ids de autor son id_autor; los de libro, id_proyecto."
echo
ok "${NEGRITA}Actualización 1.31.0 lista.${RESET}"
