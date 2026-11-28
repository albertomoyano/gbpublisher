#!/usr/bin/env bash
#
# ============================================
# Script    : actualizar-esquema-2.2.0.sh
# Propósito : Actualización 2.2.0 de la base de gbpublisher, sobre una base
#             EN USO y preservando sus datos. EL LIBRO Y SU EDITORIAL: la
#             deuda que dejó SC-88 («la editorial se vincula solo a revistas
#             por ahora; los libros, después»). Decisiones de Alberto del
#             25/11/2026, claude/crossref-libros.md, «F1»:
#               1. libro_editorial      las editoriales de cada libro, en
#                                       orden: admite coediciones. La de
#                                       orden 1 es la principal: la que
#                                       deposita en Crossref y da el lugar
#                                       de edición
#             MIGRA: una editorial por cada combinación distinta de los cinco
#             datos de identidad del libro (nombre, institución, ROR, ciudad
#             y país), REUSANDO la fila de editorial que ya exista con esos
#             cinco datos (la de una revista, por ejemplo), y vincula cada
#             libro con orden 1. Un libro sin nombre de editorial NO frena:
#             queda sin filas y el informe lo lista (con la tabla hija, la
#             base no puede exigir una editorial por libro; lo exigen los
#             consumidores: Crossref frena, el texto legal da ??).
#             ES ADITIVA: no borra ni cambia ninguna columna ni ningún dato
#             de libros_md. La aplicación anterior sigue funcionando igual.
#             La entrega que pasa los lectores a libro_editorial cambia
#             m_ConexionBD.ObtenerEsquemaEsperado; la 2.3.0 borra las
#             columnas viejas de libros_md y colecciones.doi_prefix, y limpia
#             libros_md.email_editorial cuando es igual al de su editorial.
#             Al final emite un INFORME DE CONTROL, solo de lectura.
# Uso       : sudo bash actualizar-esquema-2.2.0.sh
# Requisitos: MySQL 8.0.16 o posterior (CHECK).
# Reglas    : BBDD_LEEME.md §5 y SC-22. IDEMPOTENTE; respaldo verificado;
#             verificación posterior; sin efecto si ya está aplicado.
#             Exige la 2.1.0 registrada. Qué cambiar lo decide el ESTADO
#             REAL.
# Lote      : m_ConexionBD.ObtenerEsquemaEsperado: sin cambios (una tabla
#             que sobra no la rechaza ValidarEsquemaBD, SC-22 punto 5; la
#             suma la entrega que la empieza a leer).
# ============================================

set -euo pipefail

# --- 0. CONFIGURACIÓN ---
DB="gbpublisher"
PARCHE="actualizacion-2.2.0"
PREVIO="actualizacion-2.1.0"
DESCRIPCION="El libro y sus editoriales: libro_editorial (coediciones), migrada desde libros_md"
# EL RESPALDO VA A LA CARPETA DEL USUARIO QUE PIDIÓ EL PERMISO, NO A LA DE
# root: CON sudo, HOME ES /root (GV-235, MEDIDO EN MINT 22). sudo DEJA
# SUDO_USER Y pkexec DEJA PKEXEC_UID. GBP_DIR_RESPALDOS LO FIJA QUIEN LLAMA
USUARIO_RESPALDO="${SUDO_USER:-}"
if [ -z "$USUARIO_RESPALDO" ] && [ -n "${PKEXEC_UID:-}" ]; then
  USUARIO_RESPALDO="$(id -nu "$PKEXEC_UID" 2>/dev/null || true)"
fi
HOME_RESPALDO="$HOME"
if [ -n "$USUARIO_RESPALDO" ]; then
  HOME_RESPALDO="$(getent passwd "$USUARIO_RESPALDO" | cut -d: -f6 || true)"
  [ -n "$HOME_RESPALDO" ] || HOME_RESPALDO="$HOME"
fi
DIR_RESPALDO="${GBP_DIR_RESPALDOS:-${HOME_RESPALDO}/gbpublisher-respaldos}"

# AL SALIR, POR DONDE SEA, LA CARPETA Y LOS RESPALDOS QUEDAN A NOMBRE DE ESE
# USUARIO: SIN ESTO SERÍAN DE root Y NO LOS PODRÍA ABRIR NI BORRAR
entregar_respaldos() {
  if [ -n "$USUARIO_RESPALDO" ] && [ "$(id -u)" -eq 0 ] && [ -d "$DIR_RESPALDO" ]; then
    chown -R "${USUARIO_RESPALDO}:" "$DIR_RESPALDO" 2>/dev/null || true
  fi
}
trap entregar_respaldos EXIT
TABLA="libro_editorial"

# LAS DOS CLAVES DE IDENTIDAD: LA MISMA EDITORIAL VISTA DESDE EL LIBRO Y
# DESDE LA TABLA editorial. COALESCE: DOS NULOS SON EL MISMO DATO. LA
# COMPARACIÓN USA LA COLACIÓN DE LAS COLUMNAS (utf8mb4_unicode_ci): NO
# DISTINGUE MAYÚSCULAS NI TILDES, QUE ES LO QUE SE QUIERE
CLAVE_LIBRO="CONCAT_WS('|', COALESCE(ALIAS.editorial,''), COALESCE(ALIAS.institucion_editora,''), COALESCE(ALIAS.ror_editorial,''), COALESCE(ALIAS.ciudad_publicacion,''), COALESCE(ALIAS.pais_publicacion,''))"
CLAVE_EDITORIAL="CONCAT_WS('|', COALESCE(ALIAS.nombre,''), COALESCE(ALIAS.institucion,''), COALESCE(ALIAS.ror,''), COALESCE(ALIAS.ciudad,''), COALESCE(ALIAS.pais,''))"

# UN LIBRO ENTRA EN LA MIGRACIÓN SI TIENE NOMBRE DE EDITORIAL Y TODAVÍA NO
# TIENE FILAS EN libro_editorial
CON_NOMBRE="NULLIF(TRIM(ALIAS.editorial), '') IS NOT NULL"

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

# LAS CLAVES Y LA CONDICIÓN CON EL ALIAS DE TABLA PEDIDO
clave_libro()     { printf '%s' "${CLAVE_LIBRO//ALIAS/$1}"; }
clave_editorial() { printf '%s' "${CLAVE_EDITORIAL//ALIAS/$1}"; }
con_nombre()      { printf '%s' "${CON_NOMBRE//ALIAS/$1}"; }

# LOS LIBROS PENDIENTES CON EL ALIAS PEDIDO: SI LA TABLA TODAVÍA NO EXISTE,
# TODOS LOS QUE TIENEN NOMBRE DE EDITORIAL
pendientes() {
  if [ "$(existe_tabla "$TABLA")" = "1" ]; then
    # CALIFICADA CON LA BASE: valor() CORRE SIN BASE SELECCIONADA
    printf '%s AND NOT EXISTS (SELECT 1 FROM `%s`.%s le WHERE le.id_libro = %s.id_libro)' "$(con_nombre "$1")" "$DB" "$TABLA" "$1"
  else
    con_nombre "$1"
  fi
}

# --- 1. DEFINICIÓN ---
# orden: 1 ES LA PRINCIPAL. LOS DOS UNIQUE GARANTIZAN UNA SOLA PRINCIPAL Y
# NINGUNA EDITORIAL REPETIDA EN EL MISMO LIBRO, SIN COLUMNA principal QUE
# CONTROLAR EN EL CÓDIGO. EL FORMULARIO REEMPLAZA LAS FILAS DEL LIBRO
# ENTERAS (SC-73), ASÍ QUE REORDENAR NO CHOCA CON EL UNIQUE DEL ORDEN
DDL="CREATE TABLE IF NOT EXISTS ${TABLA} (
  id_libro_editorial INT NOT NULL AUTO_INCREMENT,
  id_libro INT NOT NULL,
  id_editorial INT NOT NULL,
  orden INT NOT NULL COMMENT '1: la principal (depositante de Crossref, lugar de edición); 2 en adelante, coeditoras',
  PRIMARY KEY (id_libro_editorial),
  UNIQUE KEY uq_libro_editorial_orden (id_libro, orden),
  UNIQUE KEY uq_libro_editorial (id_libro, id_editorial),
  KEY fk_libro_editorial_editorial (id_editorial),
  CONSTRAINT fk_libro_editorial_libro FOREIGN KEY (id_libro) REFERENCES libros_md (id_libro) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT fk_libro_editorial_editorial FOREIGN KEY (id_editorial) REFERENCES editorial (id_editorial) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT chk_libro_editorial_orden CHECK (orden >= 1)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Las editoriales de cada libro, en orden: coediciones (2.2.0)';"

# --- 2. BIENVENIDA ---
echo
echo "${NEGRITA}Actualización del esquema de gbpublisher a 2.2.0${RESET}"
echo "--------------------------------------------------"
echo "Vincula cada libro con su editorial, en la misma tabla que usan las"
echo "revistas, y admite coediciones. Migra los datos de editorial de cada"
echo "libro. No borra ni cambia ninguna columna: eso lo hace la 2.3.0."
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

# LA CADENA ES ORDENADA: 2.2.0 VA SOBRE 2.1.0
if [ "$(valor "SELECT COUNT(*) FROM \`${DB}\`.esquema_version WHERE parche='${PREVIO}';")" != "1" ]; then
  error "Falta la actualización 2.1.0. Aplíquela primero (actualizar-esquema-2.1.0.sh)."
  exit 1
fi

for t in libros_md editorial; do
  if [ "$(existe_tabla "$t")" != "1" ]; then
    error "No existe la tabla ${t}. No se modificó nada."
    exit 1
  fi
done

# LAS COLUMNAS QUE LA MIGRACIÓN LEE: SI LA 2.3.0 YA LAS BORRÓ, NO HAY NADA
# QUE MIGRAR Y ESTE SCRIPT NO DEBERÍA CORRER (RC-GM-04, EN SQL)
for c in editorial institucion_editora ror_editorial ciudad_publicacion pais_publicacion \
         pais_publicacion_codigo direccion_editorial email_editorial doi_prefix; do
  if [ "$(existe_columna libros_md "$c")" != "1" ]; then
    error "No existe la columna libros_md.${c}: la base no está en el estado que espera la 2.2.0. No se modificó nada."
    exit 1
  fi
done

# --- 4. ESTADO REAL ---
FALTA_TABLA=0
[ "$(existe_tabla "$TABLA")" = "1" ] || FALTA_TABLA=1
PENDIENTES="$(valor "SELECT COUNT(*) FROM \`${DB}\`.libros_md l WHERE $(pendientes l);")"

if [ "$FALTA_TABLA" = "0" ] && [ "$PENDIENTES" = "0" ]; then
  ok "La tabla ${TABLA} ya está y todos los libros con editorial están vinculados."
  SOLO_INFORME=1
else
  SOLO_INFORME=0
fi

# --- 5. LA MIGRACIÓN SE PUEDE HACER ---
# DENTRO DE CADA GRUPO, LOS DATOS QUE PASAN A LA EDITORIAL Y NO SON DE LA
# CLAVE TIENEN QUE COINCIDIR: PREFIJO DOI, DIRECCIÓN Y CÓDIGO DE PAÍS. Y SI
# EL GRUPO REUSA UNA EDITORIAL QUE YA EXISTE, SU PREFIJO NO PUEDE CHOCAR CON
# EL DE ELLA. SE FRENA ANTES DE TOCAR NADA Y SE MUESTRAN LOS LIBROS. UN
# VALOR NULO NO CHOCA CON OTRO (COUNT DISTINCT LOS SALTEA). EL CORREO NO SE
# CONTROLA: EL LIBRO CONSERVA EL SUYO COMO REEMPLAZO (DECISIÓN F1.2)
if [ "$SOLO_INFORME" -eq 0 ] && [ "$PENDIENTES" != "0" ]; then
  if ! CONFLICTOS="$(valor "SELECT $(clave_libro l) AS clave FROM \`${DB}\`.libros_md l WHERE $(pendientes l)
      GROUP BY clave
      HAVING COUNT(DISTINCT NULLIF(TRIM(l.doi_prefix), '')) > 1
          OR COUNT(DISTINCT NULLIF(TRIM(l.direccion_editorial), '')) > 1
          OR COUNT(DISTINCT l.pais_publicacion_codigo) > 1;")"; then
    error "No se pudo hacer el control de los datos de cada grupo. No se modificó nada."
    exit 1
  fi
  if [ -n "$CONFLICTOS" ]; then
    error "Hay libros de la misma editorial con datos distintos que pasan a la editorial"
    error "(prefijo DOI, dirección o código de país). Unifíquelos en los libros antes de"
    error "actualizar. No se modificó nada."
    mysql_adm -t "$DB" -e "SELECT l.id_libro, l.titulo_libro, l.editorial, l.doi_prefix, l.direccion_editorial, l.pais_publicacion_codigo
      FROM libros_md l WHERE $(pendientes l) AND $(clave_libro l) IN (SELECT clave FROM (SELECT $(clave_libro x) AS clave FROM libros_md x
      WHERE $(con_nombre x) GROUP BY clave HAVING COUNT(DISTINCT NULLIF(TRIM(x.doi_prefix), '')) > 1
      OR COUNT(DISTINCT NULLIF(TRIM(x.direccion_editorial), '')) > 1 OR COUNT(DISTINCT x.pais_publicacion_codigo) > 1) c)
      ORDER BY l.editorial, l.id_libro;"
    exit 1
  fi

  if ! CHOQUES="$(valor "SELECT e.id_editorial FROM \`${DB}\`.libros_md l
      JOIN \`${DB}\`.editorial e ON $(clave_editorial e) = $(clave_libro l)
      WHERE $(pendientes l) AND NULLIF(TRIM(l.doi_prefix), '') IS NOT NULL
        AND e.doi_prefix IS NOT NULL AND e.doi_prefix <> TRIM(l.doi_prefix)
      GROUP BY e.id_editorial;")"; then
    error "No se pudo hacer el control de los prefijos contra las editoriales existentes. No se modificó nada."
    exit 1
  fi
  if [ -n "$CHOQUES" ]; then
    error "Hay libros cuyo prefijo DOI no es el de la editorial que ya existe con los"
    error "mismos datos. Corrija el prefijo del libro o el de la editorial antes de"
    error "actualizar. No se modificó nada."
    mysql_adm -t "$DB" -e "SELECT l.id_libro, l.titulo_libro, l.doi_prefix AS prefijo_libro, e.id_editorial, e.nombre, e.doi_prefix AS prefijo_editorial
      FROM libros_md l JOIN editorial e ON $(clave_editorial e) = $(clave_libro l)
      WHERE $(pendientes l) AND NULLIF(TRIM(l.doi_prefix), '') IS NOT NULL
        AND e.doi_prefix IS NOT NULL AND e.doi_prefix <> TRIM(l.doi_prefix)
      ORDER BY e.nombre, l.id_libro;"
    exit 1
  fi
fi

if [ "$SOLO_INFORME" -eq 0 ]; then
  [ "$FALTA_TABLA" = "1" ] && info "Tabla nueva: ${TABLA}"
  [ "$PENDIENTES" != "0" ] && info "Libros a vincular con su editorial: ${PENDIENTES}"
  echo
  if [ "${GBP_SIN_PREGUNTAS:-0}" = "1" ]; then
    # LO LLAMA EL INSTALADOR, QUE YA PIDIÓ LA CONFIRMACIÓN (SC-107)
    RESPUESTA="SI"
  else
    read -r -p "Para continuar, escriba SI en mayúsculas: " RESPUESTA
  fi
  if [ "$RESPUESTA" != "SI" ]; then
    warn "Cancelado. No se modificó nada."
    exit 0
  fi

  # --- 6. RESPALDO PREVIO VERIFICADO ---
  mkdir -p "$DIR_RESPALDO"
  RESPALDO="${DIR_RESPALDO}/gbpublisher-antes-2.2.0-$(date '+%Y%m%d-%H%M%S').sql"
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
  if ! grep -q "CREATE TABLE \`libros_md\`" "$RESPALDO"; then
    error "El respaldo no contiene la tabla libros_md. No se modificó nada."
    exit 1
  fi
  ok "Respaldo verificado ($(du -h "$RESPALDO" | cut -f1))."

  # LAS EDITORIALES QUE EXISTÍAN ANTES: LA VUELTA ATRÁS BORRA SOLO LAS QUE
  # CREÓ ESTA MIGRACIÓN, NO LAS DE LAS REVISTAS
  MAX_EDITORIAL="$(valor "SELECT COALESCE(MAX(id_editorial), 0) FROM \`${DB}\`.editorial;")"

  # VOLVER ATRÁS SIN RESTAURAR TODA LA BASE (SC-22): LA MIGRACIÓN COPIA Y NO
  # BORRA, ASÍ QUE ALCANZA CON QUITAR LO NUEVO. LAS EDITORIALES CREADAS SE
  # BORRAN SOLO SI NINGUNA REVISTA LAS USA (LA CLAVE FORÁNEA LO FRENA)
  VOLVER_ATRAS="sudo mysql ${DB} -e \"DROP TABLE ${TABLA}; DELETE FROM editorial WHERE id_editorial > ${MAX_EDITORIAL};\""

  # --- 7. ESTRUCTURA ---
  if [ "$FALTA_TABLA" = "1" ]; then
    mysql_adm "$DB" -e "$DDL"
    ok "Creada la tabla ${TABLA}."
  fi

  # --- 8. MIGRACIÓN: UNA EDITORIAL POR GRUPO, EN UNA TRANSACCIÓN ---
  # EL GRUPO SE NOMBRA POR SU LIBRO DE id MENOR. SI YA HAY UNA EDITORIAL
  # CON LOS CINCO DATOS DE IDENTIDAD, SE REUSA (LA DE id MENOR, SI HUBIERA
  # MÁS DE UNA) Y SOLO SE COMPLETAN SUS DATOS VACÍOS; SI NO, SE CREA. LOS
  # DATOS QUE PASAN SE TOMAN CON MAX: EL CONTROL DEL APARTADO 5 ASEGURA QUE
  # HAY UNO SOLO (O NULO). EL CORREO DE LA EDITORIAL ES EL MÁS FRECUENTE DEL
  # GRUPO (EMPATE: EL PRIMERO EN ORDEN ALFABÉTICO); EL DE CADA LIBRO QUEDA
  # COMO ESTÁ
  GRUPOS="$(valor "SELECT MIN(l.id_libro) FROM \`${DB}\`.libros_md l WHERE $(pendientes l) GROUP BY $(clave_libro l) ORDER BY 1;")"
  if [ -n "$GRUPOS" ]; then
    SQL="START TRANSACTION;"
    CREADAS=0
    REUSADAS=0
    for lid in $GRUPOS; do
      GRUPO="(SELECT $(clave_libro x) AS k FROM libros_md x WHERE x.id_libro = ${lid})"
      CORREO="(SELECT TRIM(c.email_editorial) FROM libros_md c JOIN ${GRUPO} gc ON $(clave_libro c) = gc.k
        WHERE NULLIF(TRIM(c.email_editorial), '') IS NOT NULL
        GROUP BY TRIM(c.email_editorial) ORDER BY COUNT(*) DESC, TRIM(c.email_editorial) LIMIT 1)"
      EXISTENTE="$(valor "SELECT MIN(e.id_editorial) FROM \`${DB}\`.editorial e JOIN \`${DB}\`.libros_md x ON $(clave_editorial e) = $(clave_libro x) WHERE x.id_libro = ${lid};")"
      if [ -n "$EXISTENTE" ] && [ "$EXISTENTE" != "NULL" ]; then
        # REUSO: SE COMPLETA LO VACÍO, NUNCA SE PISA LO QUE YA TIENE
        SQL+="
SET @id_editorial = ${EXISTENTE};
UPDATE editorial e
  JOIN (SELECT NULLIF(TRIM(MAX(l.doi_prefix)), '') AS prefijo, NULLIF(TRIM(MAX(l.direccion_editorial)), '') AS direccion,
               MAX(l.pais_publicacion_codigo) AS pais_codigo, ${CORREO} AS correo
        FROM libros_md l JOIN ${GRUPO} g ON $(clave_libro l) = g.k WHERE $(pendientes l)) d
  SET e.doi_prefix = COALESCE(e.doi_prefix, d.prefijo),
      e.direccion = COALESCE(e.direccion, d.direccion),
      e.pais_codigo = COALESCE(e.pais_codigo, d.pais_codigo),
      e.email = COALESCE(e.email, d.correo)
  WHERE e.id_editorial = @id_editorial;"
        REUSADAS=$((REUSADAS + 1))
      else
        SQL+="
INSERT INTO editorial (nombre, institucion, ror, direccion, ciudad, pais, pais_codigo, email, doi_prefix)
  SELECT TRIM(MAX(l.editorial)), NULLIF(TRIM(MAX(l.institucion_editora)), ''), NULLIF(TRIM(MAX(l.ror_editorial)), ''),
         NULLIF(TRIM(MAX(l.direccion_editorial)), ''), NULLIF(TRIM(MAX(l.ciudad_publicacion)), ''),
         NULLIF(TRIM(MAX(l.pais_publicacion)), ''), MAX(l.pais_publicacion_codigo),
         ${CORREO}, NULLIF(TRIM(MAX(l.doi_prefix)), '')
  FROM libros_md l JOIN ${GRUPO} g ON $(clave_libro l) = g.k
  WHERE $(pendientes l);
SET @id_editorial = LAST_INSERT_ID();"
        CREADAS=$((CREADAS + 1))
      fi
      # EL VÍNCULO, CON ORDEN 1: ES LA ÚNICA EDITORIAL QUE EL LIBRO TENÍA
      SQL+="
INSERT INTO ${TABLA} (id_libro, id_editorial, orden)
  SELECT l.id_libro, @id_editorial, 1
  FROM libros_md l JOIN ${GRUPO} g ON $(clave_libro l) = g.k
  WHERE $(con_nombre l) AND NOT EXISTS (SELECT 1 FROM ${TABLA} le WHERE le.id_libro = l.id_libro);"
    done
    SQL+="
COMMIT;"
    mysql_adm "$DB" -e "$SQL"
    ok "Editoriales: ${CREADAS} creada(s), ${REUSADAS} reusada(s); libros vinculados con orden 1."
  fi

  # --- 9. VERIFICACIÓN POSTERIOR ---
  FALLA=0
  if [ "$(existe_tabla "$TABLA")" != "1" ]; then
    error "Falta la tabla ${TABLA}."
    FALLA=1
  fi
  RESTAN="$(valor "SELECT COUNT(*) FROM \`${DB}\`.libros_md l WHERE $(pendientes l);")"
  if [ "$RESTAN" != "0" ]; then
    error "Quedaron ${RESTAN} libro(s) con nombre de editorial y sin vincular."
    FALLA=1
  fi
  # CADA LIBRO MIGRADO TIENE QUE TENER SU PRINCIPAL CON SUS CINCO DATOS, Y
  # EL PREFIJO DEL LIBRO, SI LO TENÍA, EN SU EDITORIAL
  DIFIEREN="$(valor "SELECT COUNT(*) FROM \`${DB}\`.libros_md l
    JOIN \`${DB}\`.${TABLA} le ON le.id_libro = l.id_libro AND le.orden = 1
    JOIN \`${DB}\`.editorial e ON e.id_editorial = le.id_editorial
    WHERE $(con_nombre l) AND ($(clave_editorial e) <> $(clave_libro l)
       OR (NULLIF(TRIM(l.doi_prefix), '') IS NOT NULL AND NOT (TRIM(l.doi_prefix) <=> e.doi_prefix)));")"
  if [ "$DIFIEREN" != "0" ]; then
    error "${DIFIEREN} libro(s) quedaron vinculados a una editorial con datos distintos de los suyos."
    FALLA=1
  fi
  if [ "$FALLA" = "1" ]; then
    error "NO se registra la actualización. Para volver atrás:"
    error "  ${VOLVER_ATRAS}"
    exit 1
  fi
  ok "Verificación correcta: cada libro con editorial vinculado a una con sus datos."

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
info "Informe de control: cada editorial y sus libros"
mysql_adm -t "$DB" -e "SELECT e.id_editorial, e.nombre, e.ciudad, e.doi_prefix, e.email,
  COUNT(le.id_libro) AS libros
  FROM editorial e LEFT JOIN ${TABLA} le ON le.id_editorial = e.id_editorial
  GROUP BY e.id_editorial ORDER BY e.nombre;"

SIN_EDITORIAL="$(valor "SELECT COUNT(*) FROM \`${DB}\`.libros_md l WHERE NOT EXISTS (SELECT 1 FROM \`${DB}\`.${TABLA} le WHERE le.id_libro = l.id_libro);")"
if [ "$SIN_EDITORIAL" != "0" ]; then
  echo
  warn "${SIN_EDITORIAL} libro(s) sin editorial: cargala en la ficha del libro cuando la"
  warn "entrega nueva esté instalada. Crossref no deposita un libro sin editorial."
  mysql_adm -t "$DB" -e "SELECT l.id_libro, l.titulo_libro, l.ciudad_publicacion, l.pais_publicacion
    FROM libros_md l WHERE NOT EXISTS (SELECT 1 FROM ${TABLA} le WHERE le.id_libro = l.id_libro)
    ORDER BY l.id_libro;"
fi

# EL CORREO DEL LIBRO QUE NO ES EL DE SU EDITORIAL: QUEDA COMO REEMPLAZO
# DEL LIBRO (LA 2.3.0 BORRA LOS QUE SON IGUALES)
DISTINTOS="$(valor "SELECT COUNT(*) FROM \`${DB}\`.libros_md l
  JOIN \`${DB}\`.${TABLA} le ON le.id_libro = l.id_libro AND le.orden = 1
  JOIN \`${DB}\`.editorial e ON e.id_editorial = le.id_editorial
  WHERE NULLIF(TRIM(l.email_editorial), '') IS NOT NULL AND NOT (TRIM(l.email_editorial) <=> e.email);")"
if [ "$DISTINTOS" != "0" ]; then
  echo
  warn "${DISTINTOS} libro(s) con un correo distinto del de su editorial: queda como"
  warn "reemplazo del libro (depositante de Crossref). Si es un dato de prueba, borralo."
  mysql_adm -t "$DB" -e "SELECT l.id_libro, l.titulo_libro, l.email_editorial AS correo_libro, e.email AS correo_editorial
    FROM libros_md l JOIN ${TABLA} le ON le.id_libro = l.id_libro AND le.orden = 1
    JOIN editorial e ON e.id_editorial = le.id_editorial
    WHERE NULLIF(TRIM(l.email_editorial), '') IS NOT NULL AND NOT (TRIM(l.email_editorial) <=> e.email)
    ORDER BY l.id_libro;"
fi

# LA 2.3.0 BORRA colecciones.doi_prefix: SE AVISA DESDE AHORA SI HAY ALGUNO
if [ "$(existe_columna colecciones doi_prefix)" = "1" ]; then
  COLECCIONES="$(valor "SELECT COUNT(*) FROM \`${DB}\`.colecciones WHERE NULLIF(TRIM(doi_prefix), '') IS NOT NULL;")"
  if [ "$COLECCIONES" != "0" ]; then
    echo
    warn "${COLECCIONES} colección(es) con prefijo DOI propio: la 2.3.0 lo borra. El prefijo"
    warn "es de la editorial (el miembro de Crossref)."
    mysql_adm -t "$DB" -e "SELECT id_coleccion, nombre, editorial, doi_prefix FROM colecciones
      WHERE NULLIF(TRIM(doi_prefix), '') IS NOT NULL ORDER BY nombre;"
  fi
fi
echo "El informe no modifica nada."
echo
ok "${NEGRITA}Actualización 2.2.0 lista.${RESET}"
