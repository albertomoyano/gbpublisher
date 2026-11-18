#!/usr/bin/env bash
#
# ============================================
# Script    : actualizar-esquema-1.33.0.sh
# Propósito : Actualización 1.33.0 de la base de gbpublisher, sobre una base
#             EN USO. Retira la orden de taller (SC-99, decisión de Alberto
#             del 18/11/2026): borra la tabla orden_taller.
#             Por qué: la OT supone un circuito de imprenta que no es el de
#             las editoriales reales. Unas no imprimen; otras imprimen en la
#             imprenta de su facultad, con un trámite administrativo propio;
#             otras con talleres externos, casi siempre por licitación
#             pública, también con su trámite. Nada de eso pasa por esta app.
# Uso       : sudo bash actualizar-esquema-1.33.0.sh
# Reglas    : BBDD_LEEME.md §5 y SC-22. IDEMPOTENTE; respaldo verificado;
#             verificación posterior; sin efecto si ya está aplicado.
#             Exige la 1.32.0 registrada.
# Lote      : m_ConexionBD.ObtenerEsquemaEsperado: sale orden_taller. Va en
#             la misma entrega (bloque 6 de SC-97).
# Volver    : NO ES REVERSIBLE CON UN PARCHE: borra una tabla. Se vuelve
#             atrás restaurando el respaldo completo que se hace antes, con
#             --init-command="SET SESSION innodb_strict_mode=0" si el
#             respaldo es anterior a la 1.32.0 (GV-67, SC-22). El script
#             muestra el comando.
# ============================================

set -euo pipefail

# --- 0. CONFIGURACIÓN ---
DB="gbpublisher"
PARCHE="actualizacion-1.33.0"
PREVIO="actualizacion-1.32.0"
DESCRIPCION="Retiro de la orden de taller: tabla orden_taller"
DIR_RESPALDO="${HOME}/gbpublisher-respaldos"
TABLA="orden_taller"

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

# --- 1. BIENVENIDA ---
echo
echo "${NEGRITA}Actualización del esquema de gbpublisher a 1.33.0${RESET}"
echo "--------------------------------------------------"
echo "Retira la orden de taller: borra la tabla orden_taller."
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

# LA CADENA ES ORDENADA: 1.33.0 VA SOBRE 1.32.0
if [ "$(valor "SELECT COUNT(*) FROM \`${DB}\`.esquema_version WHERE parche='${PREVIO}';")" != "1" ]; then
  error "Falta la actualización 1.32.0. Aplicala primero (actualizar-esquema-1.32.0.sh)."
  exit 1
fi

# --- 3. ESTADO REAL ---
if [ "$(existe_tabla "$TABLA")" = "0" ]; then
  ok "La tabla ${TABLA} ya no está."
  SOLO_INFORME=1
else
  SOLO_INFORME=0
fi

if [ "$SOLO_INFORME" -eq 0 ]; then

  # --- 4. NADA APUNTA A orden_taller ---
  # SE CONSULTA LA BASE: UNA ACTUALIZACIÓN INTERMEDIA PUDO AGREGAR UNA CLAVE
  # FORÁNEA HACIA ELLA. SI HAY ALGUNA, NO SE TOCA NADA
  AJENAS="$(valor "SELECT CONCAT(TABLE_NAME, '.', CONSTRAINT_NAME)
    FROM information_schema.REFERENTIAL_CONSTRAINTS
    WHERE CONSTRAINT_SCHEMA='${DB}' AND REFERENCED_TABLE_NAME='${TABLA}';")"
  if [ -n "$AJENAS" ]; then
    error "Hay tablas que apuntan a ${TABLA}:"
    echo "$AJENAS" | sed 's/^/    /' >&2
    error "No se modificó nada. Hay que revisarlo antes de seguir."
    exit 1
  fi

  # --- 5. LO QUE SE VA A HACER ---
  FILAS="$(valor "SELECT COUNT(*) FROM \`${DB}\`.\`${TABLA}\`;")"
  info "Se borra la tabla ${TABLA} (${FILAS} órdenes de taller)."
  if [ "$FILAS" != "0" ]; then
    mysql_adm "$DB" -e "SELECT o.id, p.nombre AS proyecto, o.proveedor_ot AS proveedor, o.copias_ot AS copias
      FROM ${TABLA} o LEFT JOIN proyectos p ON p.id = o.id_proyecto ORDER BY o.id;"
  fi
  echo
  warn "Esta actualización borra datos. Se vuelve atrás solo restaurando el respaldo completo."
  read -r -p "Para continuar, escribí SI en mayúsculas: " RESPUESTA
  if [ "$RESPUESTA" != "SI" ]; then
    warn "Cancelado. No se modificó nada."
    exit 0
  fi

  # --- 6. RESPALDO PREVIO VERIFICADO ---
  mkdir -p "$DIR_RESPALDO"
  RESPALDO="${DIR_RESPALDO}/gbpublisher-antes-1.33.0-$(date '+%Y%m%d-%H%M%S').sql"
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
  for t in "$TABLA" proyectos; do
    if ! grep -q "CREATE TABLE \`${t}\`" "$RESPALDO"; then
      error "El respaldo no contiene la tabla ${t}. No se modificó nada."
      exit 1
    fi
  done
  ok "Respaldo verificado ($(du -h "$RESPALDO" | cut -f1))."

  # --- 7. LA TABLA ---
  mysql_adm "$DB" -e "DROP TABLE \`${TABLA}\`;"
  ok "Tabla ${TABLA} borrada."

  # --- 8. VERIFICACIÓN POSTERIOR ---
  if [ "$(existe_tabla "$TABLA")" != "0" ]; then
    error "La tabla ${TABLA} sigue en la base. NO se registra la actualización."
    error "Para volver atrás, restaurar el respaldo:"
    error "  sudo mysql ${DB} < ${RESPALDO}"
    exit 1
  fi
  ok "Verificación correcta."

  # --- 9. REGISTRO ---
  mysql_adm "$DB" -e "INSERT IGNORE INTO esquema_version (parche, descripcion) VALUES ('${PARCHE}', '${DESCRIPCION}');"
  ok "Registrado en esquema_version como ${PARCHE}."
  info "Para volver atrás, restaurar el respaldo completo (pisa lo trabajado después):"
  echo "  sudo mysql ${DB} < ${RESPALDO}"

else
  # YA ESTABA: SE REGISTRA PARA QUE EL NIVEL DECLARADO REFLEJE EL ESTADO REAL
  if [ "$(valor "SELECT COUNT(*) FROM \`${DB}\`.esquema_version WHERE parche='${PARCHE}';")" = "0" ]; then
    mysql_adm "$DB" -e "INSERT INTO esquema_version (parche, descripcion) VALUES ('${PARCHE}', '${DESCRIPCION}');"
    ok "Ya estaba aplicada; registrado en esquema_version como ${PARCHE}."
  fi
fi

# --- 10. NOTA ---
# LOS PDF DE OT QUE SE HAYAN GENERADO QUEDAN EN salidas/pdf/ DE CADA PROYECTO
echo
info "Los PDF de órdenes de taller que se hayan generado quedan en salidas/pdf/ de cada proyecto."
echo
ok "${NEGRITA}Actualización 1.33.0 lista.${RESET}"
