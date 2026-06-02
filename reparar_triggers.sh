#!/bin/bash
# ============================================================
# reparar_triggers.sh
# ============================================================
# DESCRIPCIÓN : Corrige los triggers de la tabla articulo_autor
#               en instalaciones existentes de gbpublisher.
#               El problema: el dump original exportó los triggers
#               con un DEFINER específico, lo que impide a app_user
#               ejecutar INSERT/UPDATE sobre articulo_autor.
#               Este script los recrea sin DEFINER explícito
#               (queda asignado al usuario que ejecuta, root vía
#               sudo), lo que elimina el bloqueo.
# USO         : bash reparar_triggers.sh
# NOTA        : Requiere acceso sudo para conectar a MySQL como
#               administrador.
# ============================================================

# --- COLORES ---
VERDE='\033[0;32m'
ROJO='\033[0;31m'
AMARILLO='\033[1;33m'
NEGRITA='\033[1m'
RESET='\033[0m'

# --- PARÁMETROS ---
DB_NOMBRE="gbpublisher"

# ============================================================
# INICIO
# ============================================================
clear
echo ""
echo -e "${NEGRITA}  gbpublisher — Reparación de triggers${RESET}"
echo "  $(uname -n)  |  $(date '+%d/%m/%Y %H:%M')"
echo "  ════════════════════════════════════════════════════════════════════"

# ============================================================
# PASO 1 — VERIFICAR QUE MYSQL ESTÁ CORRIENDO
# ============================================================
echo ""
echo -e "${NEGRITA}  Paso 1: Verificando servicio MySQL${RESET}"
echo "  ────────────────────────────────────────────────────────────────────"
if systemctl is-active --quiet mysql; then
  echo -e "  MySQL             ${VERDE}activo${RESET}"
else
  echo -e "  ${ROJO}ERROR: El servicio MySQL no está corriendo.${RESET}"
  echo ""
  exit 1
fi

# ============================================================
# PASO 2 — VERIFICAR QUE LA BASE EXISTE
# ============================================================
echo ""
echo -e "${NEGRITA}  Paso 2: Verificando base de datos${RESET}"
echo "  ────────────────────────────────────────────────────────────────────"
EXISTE=$(sudo mysql -se "SELECT SCHEMA_NAME FROM information_schema.SCHEMATA WHERE SCHEMA_NAME='${DB_NOMBRE}';" 2>/dev/null)
if [ -z "$EXISTE" ]; then
  echo -e "  ${ROJO}ERROR: No se encontró la base de datos '${DB_NOMBRE}'.${RESET}"
  echo ""
  exit 1
fi
echo -e "  ${DB_NOMBRE}        ${VERDE}encontrada${RESET}"

# ============================================================
# PASO 3 — MOSTRAR ESTADO ACTUAL DE LOS TRIGGERS
# ============================================================
echo ""
echo -e "${NEGRITA}  Paso 3: Estado actual de los triggers${RESET}"
echo "  ────────────────────────────────────────────────────────────────────"
TRIGGERS=$(sudo mysql -se "SELECT TRIGGER_NAME, DEFINER FROM information_schema.TRIGGERS WHERE TRIGGER_SCHEMA='${DB_NOMBRE}' AND EVENT_OBJECT_TABLE='articulo_autor';" 2>/dev/null)
if [ -z "$TRIGGERS" ]; then
  echo -e "  ${AMARILLO}No se encontraron triggers en articulo_autor.${RESET}"
  echo "  Nada que reparar."
  echo ""
  exit 0
fi
echo "  $TRIGGERS" | while read -r NOMBRE DEFINER; do
  echo -e "  ${NOMBRE}  →  DEFINER: ${NEGRITA}${DEFINER}${RESET}"
done

# ============================================================
# PASO 4 — CONFIRMAR
# ============================================================
echo ""
echo -e "  ${AMARILLO}Se van a eliminar y recrear los triggers sin DEFINER explícito.${RESET}"
read -rp "  ¿Confirmar? Escribí 'si' para continuar: " CONFIRMAR
if [ "$CONFIRMAR" != "si" ]; then
  echo ""
  echo "  Operación cancelada."
  echo ""
  exit 0
fi

# ============================================================
# PASO 5 — RECREAR TRIGGERS
# ============================================================
echo ""
echo -e "${NEGRITA}  Paso 5: Recreando triggers${RESET}"
echo "  ────────────────────────────────────────────────────────────────────"

sudo mysql "$DB_NOMBRE" <<'EOSQL'
-- ELIMINAR TRIGGERS EXISTENTES
DROP TRIGGER IF EXISTS `trg_solo_un_autor_correspondencia_insert`;
DROP TRIGGER IF EXISTS `trg_solo_un_autor_correspondencia_update`;

-- RECREAR SIN DEFINER EXPLÍCITO (QUEDA COMO CURRENT_USER)
DELIMITER ;;

CREATE TRIGGER `trg_solo_un_autor_correspondencia_insert`
BEFORE INSERT ON `articulo_autor` FOR EACH ROW
BEGIN
  IF NEW.es_autor_correspondencia = 1 THEN
    IF EXISTS (
      SELECT 1 FROM articulo_autor
      WHERE id_articulo = NEW.id_articulo
        AND es_autor_correspondencia = 1
    ) THEN
      SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'Ya existe un autor de correspondencia para este artículo';
    END IF;
  END IF;
END;;

CREATE TRIGGER `trg_solo_un_autor_correspondencia_update`
BEFORE UPDATE ON `articulo_autor` FOR EACH ROW
BEGIN
  IF NEW.es_autor_correspondencia = 1 AND OLD.es_autor_correspondencia = 0 THEN
    IF EXISTS (
      SELECT 1 FROM articulo_autor
      WHERE id_articulo = NEW.id_articulo
        AND es_autor_correspondencia = 1
        AND id_relacion <> NEW.id_relacion
    ) THEN
      SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'Ya existe un autor de correspondencia para este artículo';
    END IF;
  END IF;
END;;

DELIMITER ;
EOSQL

if [ $? -ne 0 ]; then
  echo -e "  ${ROJO}ERROR: Falló la recreación de los triggers.${RESET}"
  echo ""
  exit 1
fi

# ============================================================
# PASO 6 — VERIFICAR RESULTADO
# ============================================================
echo ""
echo -e "${NEGRITA}  Paso 6: Verificación${RESET}"
echo "  ────────────────────────────────────────────────────────────────────"
TRIGGERS_POST=$(sudo mysql -se "SELECT TRIGGER_NAME, DEFINER FROM information_schema.TRIGGERS WHERE TRIGGER_SCHEMA='${DB_NOMBRE}' AND EVENT_OBJECT_TABLE='articulo_autor';" 2>/dev/null)
echo "  $TRIGGERS_POST" | while read -r NOMBRE DEFINER; do
  echo -e "  ${NOMBRE}  →  DEFINER: ${VERDE}${DEFINER}${RESET}"
done

echo ""
echo "  ════════════════════════════════════════════════════════════════════"
echo -e "  ${VERDE}${NEGRITA}Triggers reparados.${RESET}"
echo "  ════════════════════════════════════════════════════════════════════"
echo ""

exit 0
