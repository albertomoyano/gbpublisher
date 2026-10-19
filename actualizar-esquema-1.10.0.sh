#!/usr/bin/env bash
#
# ============================================
# Script    : actualizar-esquema-1.10.0.sh
# Propósito : Actualización 1.10.0 de la base de gbpublisher, sobre una base
#             EN USO y preservando sus datos. Notas internas (rediseño):
#               1. Crea cinco tablas, en orden de dependencia:
#                    notas_grupos      un grupo de notas por proyecto
#                    notas_miembros    altas y bajas de cada grupo
#                    notas             nota 1 a 1 o de grupo, con cierre
#                    notas_respuestas  el hilo de cada nota
#                    notas_vistas      qué vio cada usuario y cuándo
#               2. Migra postits a notas, con el MISMO id: el postit 17 es
#                  la nota 17. Solo si notas está vacía.
#             postits NO SE BORRA: su retiro va en una versión posterior,
#             con el sistema nuevo probado (SC-22, punto 5).
#             Al final emite un INFORME DE CONTROL, solo de lectura.
# Uso       : sudo bash actualizar-esquema-1.10.0.sh
# Requisitos: MySQL 8.0.16 o posterior (aplica las restricciones CHECK);
#             permisos sudo.
# Reglas    : BBDD_LEEME.md §5 y SC-22. IDEMPOTENTE; respaldo verificado;
#             verificación posterior; sin efecto si ya está aplicado.
#             Exige la 1.9.0 registrada: la cadena es ordenada. Sobre esa
#             base, qué crear y qué migrar lo decide el ESTADO REAL.
# Criterio  : por cada tabla nueva, tres estados posibles:
#               - no existe                          -> se crea
#               - existe con las columnas esperadas  -> ya está
#               - existe con otra cantidad           -> ABORTA sin tocar nada
#             Migración: por cada postit, tres estados posibles:
#               - de y para son usuarios, con texto  -> se migra
#               - leido = 1                          -> se migra cerrada
#               - de o para no son usuarios, o texto
#                 vacío                              -> NO se migra; se
#                                                       lista en el informe.
#                                                       No se inventa un
#                                                       usuario.
#             oculto no cierra: en el sistema viejo, una nota oculta y no
#             leída seguía pendiente (FNotaNueva.btnMostrarOcultos).
#             x, y y color no pasan.
# Lote      : en la misma entrega, m_ConexionBD.ObtenerEsquemaEsperado suma
#             las cinco tablas (4, 8, 11, 5 y 3 columnas) y CONSERVA postits;
#             FEstadisticas las excluye; el panel de notas reemplaza a
#             FNotaNueva y FNotasRecibidas. Aplicar el script junto con el
#             lote: la aplicación vieja sigue escribiendo en postits, y lo
#             que escriba después de la migración no pasa a notas.
# Cadena    : la 1.10.0 la toma este cambio; el refactor de bibtex tomará el
#             número que le corresponda (corrige lo anunciado en 1.9.0).
# ============================================

set -euo pipefail

# --- 0. CONFIGURACIÓN ---
DB="gbpublisher"
PARCHE="actualizacion-1.10.0"
PREVIO="actualizacion-1.9.0"
DESCRIPCION="Notas internas: grupos por proyecto, hilo, cierre y vistas; migración de postits"
DIR_RESPALDO="${HOME}/gbpublisher-respaldos"
CIERRE_MIGRACION="migracion-1.10.0"

# LAS CINCO TABLAS EN ORDEN DE DEPENDENCIA, CON SU CANTIDAD DE COLUMNAS.
# LOS CONTEOS SON LOS DE hEsquema EN m_ConexionBD
TABLAS=(notas_grupos notas_miembros notas notas_respuestas notas_vistas)
COLUMNAS=(4 8 11 5 3)
# CLAVES FORÁNEAS Y RESTRICCIONES CHECK QUE TIENE QUE HABER AL TERMINAR
FK_ESPERADAS=14
CHECK_ESPERADAS=5

# LAS COLUMNAS QUE APARECEN EN UN CHECK LLEVAN ON UPDATE RESTRICT Y NO
# CASCADE: MySQL 8.0.46 RECHAZA UN CHECK SOBRE UNA COLUMNA CON ACCIÓN
# REFERENCIAL (ERROR 3823). TODAS LAS DEMÁS VAN IGUAL, POR UNIFORMIDAD: UN id
# NO CAMBIA NUNCA. NINGUNA CLAVE BORRA EN CASCADA: EL REGISTRO NO SE PIERDE
declare -A DDL
DDL[notas_grupos]="CREATE TABLE IF NOT EXISTS notas_grupos (
  id INT NOT NULL AUTO_INCREMENT,
  id_proyecto INT NOT NULL COMMENT 'Un solo grupo por proyecto',
  id_creador INT NOT NULL COMMENT 'Quien creó el grupo; suma y da de baja miembros',
  fecha_creacion DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uq_notas_grupos_proyecto (id_proyecto),
  KEY fk_notas_grupos_creador (id_creador),
  CONSTRAINT fk_notas_grupos_proyecto FOREIGN KEY (id_proyecto) REFERENCES proyectos (id) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT fk_notas_grupos_creador FOREIGN KEY (id_creador) REFERENCES usuarios (id) ON DELETE RESTRICT ON UPDATE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;"

DDL[notas_miembros]="CREATE TABLE IF NOT EXISTS notas_miembros (
  id INT NOT NULL AUTO_INCREMENT,
  id_grupo INT NOT NULL,
  id_usuario INT NOT NULL,
  fecha_alta DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  id_alta_por INT NOT NULL,
  fecha_baja DATETIME NULL DEFAULT NULL COMMENT 'Baja lógica: el registro de lo que vio y respondió queda',
  id_baja_por INT NULL DEFAULT NULL,
  clave_activa TINYINT GENERATED ALWAYS AS (IF(fecha_baja IS NULL, 1, NULL)) STORED COMMENT 'Una sola alta vigente por usuario y grupo',
  PRIMARY KEY (id),
  UNIQUE KEY uq_notas_miembros_activo (id_grupo, id_usuario, clave_activa),
  KEY fk_notas_miembros_usuario (id_usuario),
  KEY fk_notas_miembros_alta (id_alta_por),
  KEY fk_notas_miembros_baja (id_baja_por),
  CONSTRAINT fk_notas_miembros_grupo FOREIGN KEY (id_grupo) REFERENCES notas_grupos (id) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT fk_notas_miembros_usuario FOREIGN KEY (id_usuario) REFERENCES usuarios (id) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT fk_notas_miembros_alta FOREIGN KEY (id_alta_por) REFERENCES usuarios (id) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT fk_notas_miembros_baja FOREIGN KEY (id_baja_por) REFERENCES usuarios (id) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT chk_notas_miembros_baja CHECK ((fecha_baja IS NULL) = (id_baja_por IS NULL))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;"

DDL[notas]="CREATE TABLE IF NOT EXISTS notas (
  id INT NOT NULL AUTO_INCREMENT,
  id_autor INT NOT NULL,
  id_destinatario INT NULL DEFAULT NULL COMMENT 'Nota 1 a 1 (o a uno mismo)',
  id_grupo INT NULL DEFAULT NULL COMMENT 'Nota de proyecto',
  texto TEXT COLLATE utf8mb4_unicode_ci NOT NULL,
  fecha_creacion DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  desde DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'Hora de despacho: antes no la ven los destinatarios',
  ultima_actividad DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) COMMENT 'Alta, respuesta o cierre; la lee el sondeo',
  fecha_cierre DATETIME NULL DEFAULT NULL COMMENT 'Cerrar es archivar',
  id_cierre_por INT NULL DEFAULT NULL COMMENT 'El autor, cuando cierra él',
  cierre_sistema VARCHAR(50) COLLATE utf8mb4_unicode_ci NULL DEFAULT NULL COMMENT 'Usuario de FSysAdmin, o la migración, cuando no cierra el autor',
  PRIMARY KEY (id),
  KEY idx_notas_destinatario (id_destinatario, fecha_cierre),
  KEY idx_notas_grupo (id_grupo, fecha_cierre),
  KEY idx_notas_autor (id_autor, fecha_cierre),
  KEY fk_notas_cierre_por (id_cierre_por),
  CONSTRAINT fk_notas_autor FOREIGN KEY (id_autor) REFERENCES usuarios (id) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT fk_notas_destinatario FOREIGN KEY (id_destinatario) REFERENCES usuarios (id) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT fk_notas_grupo FOREIGN KEY (id_grupo) REFERENCES notas_grupos (id) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT fk_notas_cierre_por FOREIGN KEY (id_cierre_por) REFERENCES usuarios (id) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT chk_notas_destino CHECK ((id_destinatario IS NULL) <> (id_grupo IS NULL)),
  CONSTRAINT chk_notas_texto CHECK (texto <> ''),
  CONSTRAINT chk_notas_cierre CHECK (
    (fecha_cierre IS NULL AND id_cierre_por IS NULL AND cierre_sistema IS NULL)
    OR (fecha_cierre IS NOT NULL AND ((id_cierre_por IS NULL) <> (cierre_sistema IS NULL))))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;"

DDL[notas_respuestas]="CREATE TABLE IF NOT EXISTS notas_respuestas (
  id INT NOT NULL AUTO_INCREMENT,
  id_nota INT NOT NULL,
  id_autor INT NOT NULL,
  texto TEXT COLLATE utf8mb4_unicode_ci NOT NULL,
  fecha DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  KEY fk_notas_respuestas_nota (id_nota),
  KEY fk_notas_respuestas_autor (id_autor),
  CONSTRAINT fk_notas_respuestas_nota FOREIGN KEY (id_nota) REFERENCES notas (id) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT fk_notas_respuestas_autor FOREIGN KEY (id_autor) REFERENCES usuarios (id) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT chk_notas_respuestas_texto CHECK (texto <> '')
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;"

DDL[notas_vistas]="CREATE TABLE IF NOT EXISTS notas_vistas (
  id_nota INT NOT NULL,
  id_usuario INT NOT NULL,
  fecha_vista DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) COMMENT 'Última vez que el usuario abrió la nota',
  PRIMARY KEY (id_nota, id_usuario),
  KEY fk_notas_vistas_usuario (id_usuario),
  CONSTRAINT fk_notas_vistas_nota FOREIGN KEY (id_nota) REFERENCES notas (id) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT fk_notas_vistas_usuario FOREIGN KEY (id_usuario) REFERENCES usuarios (id) ON DELETE RESTRICT ON UPDATE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;"

# LA CONDICIÓN DE UN POSTIT MIGRABLE, EN UN SOLO LUGAR: LA USAN EL PLAN, LA
# MIGRACIÓN, LA VERIFICACIÓN Y EL INFORME
DESDE_POSTITS="FROM \`${DB}\`.postits p
  JOIN \`${DB}\`.usuarios ua ON ua.usuario = p.de
  JOIN \`${DB}\`.usuarios ud ON ud.usuario = p.para
  WHERE p.texto IS NOT NULL AND TRIM(p.texto) <> ''"

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

# --- 1. BIENVENIDA ---
echo
echo "${NEGRITA}Actualización del esquema de gbpublisher a 1.10.0${RESET}"
echo "--------------------------------------------------"
echo "Crea las tablas del sistema nuevo de notas internas y migra las notas viejas (postits)."
echo "No borra postits ni toca datos editoriales."
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

# LAS TRES TABLAS DE LAS QUE DEPENDEN LAS NUEVAS
for T in usuarios proyectos postits; do
  if [ "$(valor "SELECT COUNT(*) FROM information_schema.TABLES WHERE TABLE_SCHEMA='${DB}' AND TABLE_NAME='${T}';")" != "1" ]; then
    error "No existe la tabla ${T}."
    exit 1
  fi
done

# LAS RESTRICCIONES CHECK SE APLICAN DESDE MySQL 8.0.16; ANTES SE ACEPTAN Y
# SE IGNORAN EN SILENCIO, Y LA BASE QUEDARÍA SIN LAS REGLAS DE LAS NOTAS
VERSION="$(valor "SELECT VERSION();")"
if [ "$(valor "SELECT (CAST(SUBSTRING_INDEX(VERSION(), '.', 1) AS UNSIGNED) * 10000 + CAST(SUBSTRING_INDEX(SUBSTRING_INDEX(VERSION(), '.', 2), '.', -1) AS UNSIGNED) * 100 + CAST(SUBSTRING_INDEX(SUBSTRING_INDEX(SUBSTRING_INDEX(VERSION(), '-', 1), '.', 3), '.', -1) AS UNSIGNED)) >= 80016;")" != "1" ]; then
  error "El servidor es ${VERSION}: hace falta MySQL 8.0.16 o posterior para las restricciones CHECK."
  exit 1
fi

NIVEL="$(valor "SELECT GROUP_CONCAT(parche ORDER BY aplicado_en SEPARATOR ', ') FROM \`${DB}\`.esquema_version;")"
info "Servidor: ${VERSION}"
info "Nivel registrado: ${NIVEL}"

# LA CADENA ES ORDENADA: 1.10.0 VA SOBRE 1.9.0
if [ "$(valor "SELECT COUNT(*) FROM \`${DB}\`.esquema_version WHERE parche='${PREVIO}';")" != "1" ]; then
  error "Falta la actualización 1.9.0. Aplicala primero (actualizar-esquema-1.9.0.sh)."
  exit 1
fi

# --- 3. ESTADO REAL ---
# SE DECIDE POR information_schema, NUNCA POR LAS FILAS DE esquema_version
A_CREAR=()
for i in "${!TABLAS[@]}"; do
  T="${TABLAS[$i]}"
  N="$(columnas_de "$T")"
  if [ "$N" = "0" ]; then
    A_CREAR+=("$T")
  elif [ "$N" != "${COLUMNAS[$i]}" ]; then
    # UNA TABLA CON OTRA FORMA ES UNA INTERVENCIÓN MANUAL: NO SE PISA
    error "La tabla ${T} existe con ${N} columnas (se esperaban ${COLUMNAS[$i]})."
    error "Revisala a mano antes de volver a correr el script. No se modificó nada."
    exit 1
  fi
done

# MIGRAR SOLO SI notas NO EXISTE TODAVÍA O ESTÁ VACÍA: UNA notas CON FILAS
# YA ESTÁ EN USO (O YA SE MIGRÓ) Y NO SE TOCA
NOTAS_FILAS=0
if [ "$(columnas_de notas)" != "0" ]; then
  NOTAS_FILAS="$(valor "SELECT COUNT(*) FROM \`${DB}\`.notas;")"
fi
MIGRABLES="$(valor "SELECT COUNT(*) ${DESDE_POSTITS};")"
POSTITS_TOTAL="$(valor "SELECT COUNT(*) FROM \`${DB}\`.postits;")"
MIGRAR=0
if [ "$NOTAS_FILAS" = "0" ] && [ "$MIGRABLES" -gt 0 ]; then
  MIGRAR=1
fi

if [ "${#A_CREAR[@]}" -eq 0 ] && [ "$MIGRAR" -eq 0 ]; then
  ok "No hay nada que crear ni migrar."
  SOLO_INFORME=1
else
  SOLO_INFORME=0
  if [ "${#A_CREAR[@]}" -gt 0 ]; then
    info "Tablas a crear: ${A_CREAR[*]}"
  fi
  if [ "$MIGRAR" -eq 1 ]; then
    info "Notas viejas a migrar: ${MIGRABLES} de ${POSTITS_TOTAL} (las demás se listan en el informe)."
  else
    info "No se migran notas viejas (notas ya tiene filas, o postits no tiene nada migrable)."
  fi
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
  RESPALDO="${DIR_RESPALDO}/gbpublisher-antes-1.10.0-$(date '+%Y%m%d-%H%M%S').sql"
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
  # LA TABLA TESTIGO ES LA QUE SE MIGRA
  if ! grep -q "CREATE TABLE \`postits\`" "$RESPALDO"; then
    error "El respaldo no contiene la tabla postits. No se modificó nada."
    exit 1
  fi
  ok "Respaldo verificado ($(du -h "$RESPALDO" | cut -f1))."

  # --- 5. CREACIÓN DE LAS TABLAS QUE FALTAN ---
  # EN ORDEN DE DEPENDENCIA. CADA CREATE ES UN COMMIT IMPLÍCITO DE MySQL: SI
  # SE CORTA A MITAD, LA CORRIDA SIGUIENTE CREA SOLO LAS QUE FALTAN
  for T in "${A_CREAR[@]}"; do
    mysql_adm "$DB" -e "${DDL[$T]}"
    ok "Creada ${T}."
  done

  # --- 6. MIGRACIÓN DE postits, EN UNA SOLA TRANSACCIÓN ---
  # O SE MIGRA TODO O NADA: SI SE CORTA, notas QUEDA VACÍA Y LA CORRIDA
  # SIGUIENTE VUELVE A MIGRAR. EL id SE CONSERVA, Y AUTO_INCREMENT SIGUE
  # DESDE EL MAYOR. EL AUTOR VIO SU PROPIA NOTA AL ESCRIBIRLA; EL
  # DESTINATARIO, SOLO SI LA HABÍA MARCADO COMO LEÍDA
  if [ "$MIGRAR" -eq 1 ]; then
    mysql_adm "$DB" -e "START TRANSACTION;
INSERT INTO notas (id, id_autor, id_destinatario, id_grupo, texto, fecha_creacion, desde, ultima_actividad, fecha_cierre, id_cierre_por, cierre_sistema)
  SELECT p.id, ua.id, ud.id, NULL, p.texto,
         COALESCE(p.fecha, NOW()),
         COALESCE(p.desde, p.fecha, NOW()),
         COALESCE(p.fecha, NOW()),
         IF(IFNULL(p.leido, 0) = 1, NOW(), NULL),
         NULL,
         IF(IFNULL(p.leido, 0) = 1, '${CIERRE_MIGRACION}', NULL)
  ${DESDE_POSTITS}
  ORDER BY p.id;
INSERT INTO notas_vistas (id_nota, id_usuario, fecha_vista)
  SELECT p.id, ua.id, COALESCE(p.fecha, NOW())
  ${DESDE_POSTITS};
INSERT INTO notas_vistas (id_nota, id_usuario, fecha_vista)
  SELECT p.id, ud.id, COALESCE(p.fecha, NOW())
  ${DESDE_POSTITS} AND IFNULL(p.leido, 0) = 1 AND ud.id <> ua.id;
COMMIT;"
    ok "Notas viejas migradas."
  fi

  # LAS NOTAS NUEVAS NUMERAN DESPUÉS DEL ÚLTIMO postit: ASÍ UN postit QUE NO
  # SE MIGRÓ NUNCA COMPARTE id CON UNA NOTA, Y EL INFORME LO SIGUE LISTANDO.
  # ES DDL (COMMIT IMPLÍCITO): VA DESPUÉS DE LA TRANSACCIÓN. MySQL NO DEJA
  # BAJARLO POR DEBAJO DEL MAYOR id QUE YA EXISTE
  PROXIMO="$(valor "SELECT IFNULL(MAX(id), 0) + 1 FROM \`${DB}\`.postits;")"
  if [ "$NOTAS_FILAS" = "0" ]; then
    mysql_adm "$DB" -e "ALTER TABLE notas AUTO_INCREMENT = ${PROXIMO};"
    ok "Las notas nuevas se numeran desde ${PROXIMO}."
  fi

  # --- 7. VERIFICACIÓN POSTERIOR ---
  FALLA=0
  for i in "${!TABLAS[@]}"; do
    N="$(columnas_de "${TABLAS[$i]}")"
    if [ "$N" != "${COLUMNAS[$i]}" ]; then
      error "La tabla ${TABLAS[$i]} tiene ${N} columnas (se esperaban ${COLUMNAS[$i]})."
      FALLA=1
    fi
  done

  LISTA_SQL="'notas_grupos','notas_miembros','notas','notas_respuestas','notas_vistas'"
  FK="$(valor "SELECT COUNT(*) FROM information_schema.REFERENTIAL_CONSTRAINTS WHERE CONSTRAINT_SCHEMA='${DB}' AND TABLE_NAME IN (${LISTA_SQL});")"
  if [ "$FK" != "$FK_ESPERADAS" ]; then
    error "Hay ${FK} claves foráneas en las tablas nuevas (se esperaban ${FK_ESPERADAS})."
    FALLA=1
  fi
  CHK="$(valor "SELECT COUNT(*) FROM information_schema.TABLE_CONSTRAINTS WHERE CONSTRAINT_SCHEMA='${DB}' AND CONSTRAINT_TYPE='CHECK' AND TABLE_NAME IN (${LISTA_SQL});")"
  if [ "$CHK" != "$CHECK_ESPERADAS" ]; then
    error "Hay ${CHK} restricciones CHECK en las tablas nuevas (se esperaban ${CHECK_ESPERADAS})."
    FALLA=1
  fi

  if [ "$MIGRAR" -eq 1 ]; then
    # CADA POSTIT MIGRABLE TIENE SU NOTA CON EL MISMO id, Y CERRADA SI Y SOLO
    # SI ESTABA LEÍDA
    FALTAN="$(valor "SELECT COUNT(*) ${DESDE_POSTITS} AND NOT EXISTS (SELECT 1 FROM \`${DB}\`.notas n WHERE n.id = p.id AND n.id_autor = ua.id AND n.id_destinatario = ud.id AND (n.fecha_cierre IS NOT NULL) = (IFNULL(p.leido, 0) = 1));")"
    if [ "$FALTAN" != "0" ]; then
      error "Hay ${FALTAN} notas viejas que no quedaron migradas como se esperaba."
      FALLA=1
    fi
  fi

  if [ "$FALLA" -ne 0 ]; then
    error "NO se registra la actualización."
    # SIN innodb_strict_mode=0 LA RESTAURACIÓN FALLA EN articulos (GV-67)
    error "Para volver atrás: sudo mysql --init-command=\"SET SESSION innodb_strict_mode=0\" ${DB} < ${RESPALDO}"
    exit 1
  fi
  ok "Verificación correcta: cinco tablas, ${FK} claves foráneas y ${CHK} restricciones CHECK."

  # --- 8. REGISTRO ---
  mysql_adm "$DB" -e "INSERT IGNORE INTO esquema_version (parche, descripcion) VALUES ('${PARCHE}', '${DESCRIPCION}');"
  ok "Registrado en esquema_version como ${PARCHE}."
  info "Para volver atrás: sudo mysql --init-command=\"SET SESSION innodb_strict_mode=0\" ${DB} < ${RESPALDO}"

else
  # YA ESTABA: SE REGISTRA PARA QUE EL NIVEL DECLARADO REFLEJE EL ESTADO REAL
  if [ "$(valor "SELECT COUNT(*) FROM \`${DB}\`.esquema_version WHERE parche='${PARCHE}';")" = "0" ]; then
    mysql_adm "$DB" -e "INSERT INTO esquema_version (parche, descripcion) VALUES ('${PARCHE}', '${DESCRIPCION}');"
    ok "Las tablas ya estaban; registrado en esquema_version como ${PARCHE}."
  fi
fi

# --- 9. INFORME DE CONTROL (SOLO LECTURA) ---
echo
info "Informe de control: notas"
mysql_adm "$DB" -e "SELECT
  (SELECT COUNT(*) FROM notas) AS notas,
  (SELECT COUNT(*) FROM notas WHERE fecha_cierre IS NULL) AS abiertas,
  (SELECT COUNT(*) FROM notas WHERE cierre_sistema = '${CIERRE_MIGRACION}') AS cerradas_en_migracion,
  (SELECT COUNT(*) FROM notas_grupos) AS grupos,
  (SELECT COUNT(*) FROM postits) AS postits;"

NO_MIGRADOS="$(valor "SELECT COUNT(*) FROM \`${DB}\`.postits p WHERE NOT EXISTS (SELECT 1 FROM \`${DB}\`.notas n WHERE n.id = p.id);")"
if [ "$NO_MIGRADOS" != "0" ]; then
  # NO SE CORRIGEN: SE LISTAN PARA QUE LOS REVISE QUIEN ADMINISTRA
  warn "Notas viejas que no tienen nota nueva con el mismo id (${NO_MIGRADOS}):"
  mysql_adm "$DB" -e "SELECT p.id, p.de, p.para, p.fecha,
    CASE
      WHEN p.texto IS NULL OR TRIM(p.texto) = '' THEN 'texto vacío'
      WHEN NOT EXISTS (SELECT 1 FROM usuarios u WHERE u.usuario = p.de) THEN 'de no es un usuario'
      WHEN NOT EXISTS (SELECT 1 FROM usuarios u WHERE u.usuario = p.para) THEN 'para no es un usuario'
      ELSE 'escrita después de la migración'
    END AS motivo
  FROM postits p WHERE NOT EXISTS (SELECT 1 FROM notas n WHERE n.id = p.id) ORDER BY p.id;"
fi
echo "postits se conserva: su retiro va en una actualización posterior."
echo "El informe no modifica nada."
echo
ok "${NEGRITA}Actualización 1.10.0 lista.${RESET}"
