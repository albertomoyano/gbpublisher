#!/usr/bin/env bash
#
# ============================================
# Script    : actualizar-esquema-1.32.0.sh
# Propósito : Actualización 1.32.0 de la base de gbpublisher, sobre una base
#             EN USO. Retira el camino viejo de revistas (SC-98, decisión de
#             Alberto del 18/11/2026):
#               - borra los proyectos de revista del esquema viejo (los que
#                 tienen filas en revistas_md o articulos y no tienen número
#                 del esquema nuevo ni libro). Son todos de prueba. Con
#                 ellos, su grupo de notas: notas, respuestas, vistas y
#                 miembros (claves RESTRICT, GV-111);
#               - borra las tablas articulo_revisor, articulo_autor,
#                 articulos y revistas_md;
#               - borra la columna articulo.id_doaj: la escribía el envío
#                 viejo a DOAJ por API, y la subida a DOAJ es a mano.
#             Los cambios de la tabla bibtex quedan para la 2.0.0.
# Uso       : sudo bash actualizar-esquema-1.32.0.sh
# Reglas    : BBDD_LEEME.md §5 y SC-22. IDEMPOTENTE; respaldo verificado;
#             verificación posterior; sin efecto si ya está aplicado.
#             Exige la 1.31.0 registrada.
# Lote      : m_ConexionBD.ObtenerEsquemaEsperado: salen las cuatro tablas
#             y articulo baja a 31. Va en la misma entrega (bloque 4).
# Volver    : NO ES REVERSIBLE CON UN PARCHE: borra tablas y proyectos. Se
#             vuelve atrás restaurando el respaldo completo que se hace antes
#             (pisa todo lo trabajado después).
#             El respaldo trae articulos (220 columnas): se restaura con
#             --init-command="SET SESSION innodb_strict_mode=0" (GV-67, SC-22),
#             y el comando que muestra el script ya lo lleva.
# Nota      : las carpetas de los proyectos borrados quedan en el disco; la
#             base no las conoce. El script las lista para borrarlas a mano.
# ============================================

set -euo pipefail

# --- 0. CONFIGURACIÓN ---
DB="gbpublisher"
PARCHE="actualizacion-1.32.0"
PREVIO="actualizacion-1.31.0"
DESCRIPCION="Retiro del camino viejo de revistas: tablas revistas_md, articulos, articulo_autor, articulo_revisor y articulo.id_doaj"
DIR_RESPALDO="${HOME}/gbpublisher-respaldos"

# EN ORDEN DE BORRADO: PRIMERO LAS QUE APUNTAN A articulos, AL FINAL revistas_md
VIEJAS=(articulo_revisor articulo_autor articulos revistas_md)
VIEJAS_SQL="'articulo_revisor','articulo_autor','articulos','revistas_md'"

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
echo "${NEGRITA}Actualización del esquema de gbpublisher a 1.32.0${RESET}"
echo "--------------------------------------------------"
echo "Retira el camino viejo de revistas: borra sus tablas, los proyectos de"
echo "prueba que quedaron en él y la columna del envío viejo a DOAJ."
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

# LA CADENA ES ORDENADA: 1.32.0 VA SOBRE 1.31.0
if [ "$(valor "SELECT COUNT(*) FROM \`${DB}\`.esquema_version WHERE parche='${PREVIO}';")" != "1" ]; then
  error "Falta la actualización 1.31.0. Aplicala primero (actualizar-esquema-1.31.0.sh)."
  exit 1
fi

for t in proyectos articulo numero; do
  if [ "$(existe_tabla "$t")" != "1" ]; then
    error "No existe la tabla ${t}. No se modificó nada."
    exit 1
  fi
done

# --- 3. ESTADO REAL ---
QUEDAN=0
for t in "${VIEJAS[@]}"; do
  [ "$(existe_tabla "$t")" = "1" ] && QUEDAN=$((QUEDAN + 1))
done
DOAJ="$(existe_columna articulo id_doaj)"
ANTES_ARTICULO="$(columnas_tabla articulo)"

if [ "$QUEDAN" -eq 0 ] && [ "$DOAJ" = "0" ]; then
  ok "Las tablas viejas y articulo.id_doaj ya no están."
  SOLO_INFORME=1
else
  SOLO_INFORME=0
fi

if [ "$SOLO_INFORME" -eq 0 ]; then

  # --- 4. NADA FUERA DEL CAMINO VIEJO APUNTA A SUS TABLAS ---
  # SE CONSULTA LA BASE Y NO UNA LISTA FIJA: UNA ACTUALIZACIÓN INTERMEDIA
  # PUDO AGREGAR UNA CLAVE FORÁNEA. SI HAY ALGUNA, NO SE TOCA NADA
  AJENAS="$(valor "SELECT CONCAT(TABLE_NAME, '.', CONSTRAINT_NAME, ' → ', REFERENCED_TABLE_NAME)
    FROM information_schema.REFERENTIAL_CONSTRAINTS
    WHERE CONSTRAINT_SCHEMA='${DB}' AND REFERENCED_TABLE_NAME IN (${VIEJAS_SQL})
      AND TABLE_NAME NOT IN (${VIEJAS_SQL});")"
  if [ -n "$AJENAS" ]; then
    error "Hay tablas fuera del camino viejo que apuntan a sus tablas:"
    echo "$AJENAS" | sed 's/^/    /' >&2
    error "No se modificó nada. Hay que revisarlo antes de seguir."
    exit 1
  fi

  # --- 5. LOS PROYECTOS DEL ESQUEMA VIEJO ---
  # TIENEN FILAS EN revistas_md O articulos, Y NI NÚMERO NUEVO NI LIBRO. UN
  # PROYECTO CON NÚMERO NUEVO SE CONSERVA: SOLO PIERDE SUS FILAS VIEJAS
  ORIGEN=""
  for t in revistas_md articulos; do
    if [ "$(existe_tabla "$t")" = "1" ]; then
      [ -n "$ORIGEN" ] && ORIGEN="${ORIGEN} UNION "
      ORIGEN="${ORIGEN}SELECT id_proyecto FROM ${t}"
    fi
  done
  IDS=""
  if [ -n "$ORIGEN" ]; then
    IDS="$(mysql_adm "$DB" -N -B -r -e "SELECT GROUP_CONCAT(p.id ORDER BY p.id) FROM proyectos p
      WHERE p.id IN (${ORIGEN})
        AND p.id NOT IN (SELECT id_proyecto FROM numero WHERE id_proyecto IS NOT NULL)
        AND p.id NOT IN (SELECT id_proyecto FROM libros_md WHERE id_proyecto IS NOT NULL);")"
    [ "$IDS" = "NULL" ] && IDS=""
  fi

  # --- 6. NINGUNA OTRA TABLA LOS RETIENE ---
  # LAS CLAVES CON CASCADE O SET NULL SE LIMPIAN SOLAS AL BORRAR EL PROYECTO.
  # UNA RESTRICT CON FILAS DE ESOS PROYECTOS (FUERA DEL CAMINO VIEJO) FRENA.
  # EXCEPCIÓN: EL GRUPO DE NOTAS DEL PROYECTO, QUE EL SCRIPT BORRA CON SUS
  # NOTAS (APARTADO 9): SUS CLAVES SON TODAS RESTRICT (1.10.0, GV-111), Y
  # «NADA SE BORRA» ES PARA EL USO DE LAS NOTAS, NO PARA RETIRAR UN PROYECTO
  # DE PRUEBA (ALBERTO, 18/11/2026)
  if [ -n "$IDS" ]; then
    RETIENEN=""
    while IFS=$'\t' read -r tabla columna; do
      [ -z "$tabla" ] && continue
      n="$(mysql_adm "$DB" -N -B -r -e "SELECT COUNT(*) FROM \`${tabla}\` WHERE \`${columna}\` IN (${IDS});")"
      [ "$n" != "0" ] && RETIENEN="${RETIENEN}    ${tabla}.${columna}: ${n} filas"$'\n'
    done < <(valor "SELECT k.TABLE_NAME, k.COLUMN_NAME
      FROM information_schema.REFERENTIAL_CONSTRAINTS r
      JOIN information_schema.KEY_COLUMN_USAGE k
        ON k.CONSTRAINT_SCHEMA = r.CONSTRAINT_SCHEMA AND k.CONSTRAINT_NAME = r.CONSTRAINT_NAME AND k.TABLE_NAME = r.TABLE_NAME
      WHERE r.CONSTRAINT_SCHEMA='${DB}' AND r.REFERENCED_TABLE_NAME='proyectos'
        AND r.DELETE_RULE IN ('RESTRICT','NO ACTION')
        AND r.TABLE_NAME NOT IN (${VIEJAS_SQL}, 'notas_grupos');")
    if [ -n "$RETIENEN" ]; then
      error "Otras tablas tienen filas de los proyectos a borrar (ids ${IDS}):"
      printf '%s' "$RETIENEN" >&2
      error "No se modificó nada. Hay que revisarlo antes de seguir."
      exit 1
    fi
  fi

  # --- 7. LO QUE SE VA A HACER ---
  if [ -n "$IDS" ]; then
    warn "Se borran estos proyectos del esquema viejo, con todo lo que cuelga de ellos"
    warn "en la base (bibliografía, siglas, tiempos, órdenes de taller):"
    mysql_adm "$DB" -e "SELECT id, nombre, fecha_creacion FROM proyectos WHERE id IN (${IDS}) ORDER BY id;"
    # LOS NOMBRES SE GUARDAN PARA EL AVISO FINAL DE LAS CARPETAS
    NOMBRES="$(mysql_adm "$DB" -N -B -r -e "SELECT nombre FROM proyectos WHERE id IN (${IDS}) ORDER BY id;")"
    if [ "$(existe_tabla notas_grupos)" = "1" ]; then
      GRUPOS="$(mysql_adm "$DB" -N -B -r -e "SELECT COUNT(*) FROM notas_grupos WHERE id_proyecto IN (${IDS});")"
      if [ "$GRUPOS" != "0" ]; then
        warn "Con su grupo de notas (las notas, sus respuestas y sus miembros):"
        mysql_adm "$DB" -e "SELECT g.id AS grupo, p.nombre AS proyecto,
            (SELECT COUNT(*) FROM notas n WHERE n.id_grupo = g.id) AS notas,
            (SELECT COUNT(*) FROM notas_miembros m WHERE m.id_grupo = g.id) AS miembros
          FROM notas_grupos g JOIN proyectos p ON p.id = g.id_proyecto
          WHERE g.id_proyecto IN (${IDS}) ORDER BY g.id;"
      fi
    fi
  else
    info "No hay proyectos del esquema viejo para borrar."
  fi
  for t in "${VIEJAS[@]}"; do
    [ "$(existe_tabla "$t")" = "1" ] && info "Se borra la tabla ${t} ($(valor "SELECT COUNT(*) FROM \`${DB}\`.\`${t}\`;") filas)."
  done
  if [ "$DOAJ" = "1" ]; then
    info "Se borra la columna articulo.id_doaj ($(valor "SELECT COUNT(*) FROM \`${DB}\`.articulo WHERE id_doaj IS NOT NULL AND id_doaj <> '';") artículos con valor)."
  fi
  echo
  warn "Esta actualización borra datos. Se vuelve atrás solo restaurando el respaldo completo."
  read -r -p "Para continuar, escribí SI en mayúsculas: " RESPUESTA
  if [ "$RESPUESTA" != "SI" ]; then
    warn "Cancelado. No se modificó nada."
    exit 0
  fi

  # --- 8. RESPALDO PREVIO VERIFICADO ---
  mkdir -p "$DIR_RESPALDO"
  RESPALDO="${DIR_RESPALDO}/gbpublisher-antes-1.32.0-$(date '+%Y%m%d-%H%M%S').sql"
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
  VERIFICAR=(proyectos articulo)
  for t in "${VIEJAS[@]}"; do
    [ "$(existe_tabla "$t")" = "1" ] && VERIFICAR+=("$t")
  done
  for t in "${VERIFICAR[@]}"; do
    if ! grep -q "CREATE TABLE \`${t}\`" "$RESPALDO"; then
      error "El respaldo no contiene la tabla ${t}. No se modificó nada."
      exit 1
    fi
  done
  ok "Respaldo verificado ($(du -h "$RESPALDO" | cut -f1))."

  # --- 9. EL GRUPO DE NOTAS DE LOS PROYECTOS A BORRAR ---
  # EN EL ORDEN DE LAS CLAVES (TODAS RESTRICT): VISTAS Y RESPUESTAS → NOTAS
  # → MIEMBROS → GRUPO, EN UNA TRANSACCIÓN. VA ANTES DE BORRAR LAS TABLAS:
  # SI FALLA, NO SE TOCÓ NADA MÁS Y LA SEGUNDA CORRIDA ENCUENTRA LOS MISMOS
  # PROYECTOS (SIN LAS TABLAS VIEJAS YA NO PODRÍA IDENTIFICARLOS)
  if [ -n "$IDS" ] && [ "$(existe_tabla notas_grupos)" = "1" ]; then
    mysql_adm "$DB" -e "START TRANSACTION;
      DELETE v FROM notas_vistas v JOIN notas n ON n.id = v.id_nota
        JOIN notas_grupos g ON g.id = n.id_grupo WHERE g.id_proyecto IN (${IDS});
      DELETE r FROM notas_respuestas r JOIN notas n ON n.id = r.id_nota
        JOIN notas_grupos g ON g.id = n.id_grupo WHERE g.id_proyecto IN (${IDS});
      DELETE n FROM notas n JOIN notas_grupos g ON g.id = n.id_grupo WHERE g.id_proyecto IN (${IDS});
      DELETE m FROM notas_miembros m JOIN notas_grupos g ON g.id = m.id_grupo WHERE g.id_proyecto IN (${IDS});
      DELETE FROM notas_grupos WHERE id_proyecto IN (${IDS});
      COMMIT;"
    ok "Grupos de notas de esos proyectos borrados."
  fi

  # --- 10. LAS TABLAS VIEJAS ---
  # EN ORDEN: LAS QUE APUNTAN A articulos PRIMERO; articulos SE APUNTA A SÍ
  # MISMA (CORRECCIÓN, RETRACTACIÓN), LO QUE NO IMPIDE BORRARLA. SIN ELLAS,
  # LAS CLAVES RESTRICT HACIA proyectos DESAPARECEN
  for t in "${VIEJAS[@]}"; do
    if [ "$(existe_tabla "$t")" = "1" ]; then
      mysql_adm "$DB" -e "DROP TABLE \`${t}\`;"
      ok "Tabla ${t} borrada."
    fi
  done

  # --- 11. LOS PROYECTOS DEL ESQUEMA VIEJO ---
  # LO QUE CUELGA CON CASCADE SE VA CON ELLOS; usuarios.id_proyecto_actual
  # QUEDA EN NULL. SU GRUPO DE NOTAS YA SALIÓ (APARTADO 9)
  if [ -n "$IDS" ]; then
    mysql_adm "$DB" -e "DELETE FROM proyectos WHERE id IN (${IDS});"
    ok "Proyectos borrados: ${IDS}."
  fi

  # --- 12. articulo.id_doaj ---
  if [ "$DOAJ" = "1" ]; then
    mysql_adm "$DB" -e "ALTER TABLE articulo DROP COLUMN id_doaj;"
    ok "Columna articulo.id_doaj borrada."
  fi

  # --- 13. VERIFICACIÓN POSTERIOR ---
  # LAS COLUMNAS DE HOY MENOS LA BORRADA: NO DEPENDE DE CUÁNTAS TENGA CADA
  # BASE (ObtenerEsquemaEsperado VERIFICA EL NÚMERO ABSOLUTO AL ARRANCAR)
  FALLA=0
  for t in "${VIEJAS[@]}"; do
    if [ "$(existe_tabla "$t")" != "0" ]; then
      error "La tabla ${t} sigue en la base."
      FALLA=1
    fi
  done
  ESPERADAS=$((ANTES_ARTICULO - DOAJ))
  CANTIDAD="$(columnas_tabla articulo)"
  if [ "$CANTIDAD" != "$ESPERADAS" ]; then
    error "articulo tiene ${CANTIDAD} columnas y se esperaban ${ESPERADAS}."
    FALLA=1
  fi
  if [ -n "$IDS" ] && [ "$(valor "SELECT COUNT(*) FROM \`${DB}\`.proyectos WHERE id IN (${IDS});")" != "0" ]; then
    error "Quedaron proyectos del esquema viejo en la base."
    FALLA=1
  fi
  if [ "$FALLA" = "1" ]; then
    error "NO se registra la actualización. Para volver atrás, restaurar el respaldo:"
    error "  sudo mysql --init-command=\"SET SESSION innodb_strict_mode=0\" ${DB} < ${RESPALDO}"
    exit 1
  fi
  ok "Verificación correcta."

  # --- 14. REGISTRO ---
  mysql_adm "$DB" -e "INSERT IGNORE INTO esquema_version (parche, descripcion) VALUES ('${PARCHE}', '${DESCRIPCION}');"
  ok "Registrado en esquema_version como ${PARCHE}."
  info "Para volver atrás, restaurar el respaldo completo (pisa lo trabajado después):"
  echo "  sudo mysql --init-command=\"SET SESSION innodb_strict_mode=0\" ${DB} < ${RESPALDO}"

else
  # YA ESTABA: SE REGISTRA PARA QUE EL NIVEL DECLARADO REFLEJE EL ESTADO REAL
  if [ "$(valor "SELECT COUNT(*) FROM \`${DB}\`.esquema_version WHERE parche='${PARCHE}';")" = "0" ]; then
    mysql_adm "$DB" -e "INSERT INTO esquema_version (parche, descripcion) VALUES ('${PARCHE}', '${DESCRIPCION}');"
    ok "Ya estaba aplicada; registrado en esquema_version como ${PARCHE}."
  fi
fi

# --- 15. INFORME DE CONTROL (SOLO LECTURA) ---
# LAS CARPETAS DE LOS PROYECTOS BORRADOS SIGUEN EN EL DISCO: LA BASE NO
# GUARDA SU RUTA, ASÍ QUE SE MUESTRAN LOS NOMBRES PARA BUSCARLAS A MANO
if [ "$SOLO_INFORME" -eq 0 ] && [ -n "$IDS" ]; then
  echo
  info "Las carpetas de estos proyectos siguen en el disco; si no se usan, se borran a mano:"
  echo "$NOMBRES" | sed 's/^/    /'
fi
echo
ok "${NEGRITA}Actualización 1.32.0 lista.${RESET}"
