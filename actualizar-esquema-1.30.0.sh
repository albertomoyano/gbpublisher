#!/usr/bin/env bash
#
# ============================================
# Script    : actualizar-esquema-1.30.0.sh
# Propósito : Actualización 1.30.0 de la base de gbpublisher, sobre una base
#             EN USO. El catálogo de países con su código ISO 3166-1
#             (decisión de Alberto del 18/11/2026, F5; claude/salidas-revistas.md):
#               1. tabla pais: código alfa-2, nombre en español y en inglés,
#                  249 filas
#               2. contribuyente_afiliacion.pais_codigo y editorial.pais_codigo,
#                  con clave foránea a pais. El nombre sigue en la columna
#                  pais, por valor, como el término y el identificador de un
#                  vocabulario (SC-23, SC-74)
#               3. la migración: el código se completa donde el texto de pais
#                  coincide con el catálogo (nombre en español o en inglés, o
#                  el código mismo, sin distinguir mayúsculas ni tildes); lo
#                  que no coincide queda sin código y se lista al final
#             SciELO exige country/@country en cada afiliación y JATS4R lo
#             recomienda.
# Fuente    : iso-codes 4.16.0 (Debian): iso_3166-1.json y su traducción al
#             español (iso_3166-1.mo). El nombre en español es el común si
#             iso-codes lo da (Bolivia, Corea del Sur, Taiwán), y si no el
#             oficial corto. Una sola corrección: «Costa de Marfíl» de
#             iso-codes va como «Costa de Marfil».
# Uso       : sudo bash actualizar-esquema-1.30.0.sh
# Reglas    : BBDD_LEEME.md §5 y SC-22. IDEMPOTENTE; respaldo verificado;
#             verificación posterior; sin efecto si ya está aplicado.
#             Exige la 1.29.0 registrada.
# Lote      : m_ConexionBD.ObtenerEsquemaEsperado: pais 3 (nueva),
#             contribuyente_afiliacion 8 → 9, editorial 18 → 19. Va en la
#             misma entrega (entregaF5).
# Volver    : escribe junto al respaldo un .sql que borra las columnas y la
#             tabla.
# ============================================

set -euo pipefail

# --- 0. CONFIGURACIÓN ---
DB="gbpublisher"
PARCHE="actualizacion-1.30.0"
PREVIO="actualizacion-1.29.0"
DESCRIPCION="Catálogo de países ISO 3166-1 para afiliaciones y editorial"
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

# LAS COLUMNAS DESPUÉS DE LA ACTUALIZACIÓN (ObtenerEsquemaEsperado)
COLS_PAIS=3
COLS_AFILIACION=9
COLS_EDITORIAL=19
FILAS_PAIS=249

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
echo "${NEGRITA}Actualización del esquema de gbpublisher a 1.30.0${RESET}"
echo "--------------------------------------------------"
echo "Agrega el catálogo de países (ISO 3166-1) y el código de país a las"
echo "afiliaciones de los artículos y a la editorial."
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

# LA CADENA ES ORDENADA: 1.30.0 VA SOBRE 1.29.0
if [ "$(valor "SELECT COUNT(*) FROM \`${DB}\`.esquema_version WHERE parche='${PREVIO}';")" != "1" ]; then
  error "Falta la actualización 1.29.0. Aplicala primero (actualizar-esquema-1.29.0.sh)."
  exit 1
fi

for t in contribuyente_afiliacion editorial; do
  if [ "$(existe_tabla "$t")" != "1" ]; then
    error "No existe la tabla ${t}. No se modificó nada."
    exit 1
  fi
done

# --- 3. ESTADO REAL ---
FALTA_TABLA=0;      [ "$(existe_tabla pais)" = "1" ]                                   || FALTA_TABLA=1
FALTA_AFILIACION=0; [ "$(existe_columna contribuyente_afiliacion pais_codigo)" = "1" ] || FALTA_AFILIACION=1
FALTA_EDITORIAL=0;  [ "$(existe_columna editorial pais_codigo)" = "1" ]                || FALTA_EDITORIAL=1

if [ $((FALTA_TABLA + FALTA_AFILIACION + FALTA_EDITORIAL)) -eq 0 ]; then
  ok "La tabla pais y las dos columnas ya están."
  SOLO_INFORME=1
else
  SOLO_INFORME=0
fi

if [ "$SOLO_INFORME" -eq 0 ]; then

  # --- 4. LO QUE SE VA A HACER ---
  AFILIACIONES="$(valor "SELECT COUNT(*) FROM \`${DB}\`.contribuyente_afiliacion WHERE pais IS NOT NULL AND pais <> '';")"
  [ "$FALTA_TABLA" -eq 1 ]      && info "Tabla pais con ${FILAS_PAIS} países (ISO 3166-1, iso-codes 4.16.0)."
  [ "$FALTA_AFILIACION" -eq 1 ] && info "contribuyente_afiliacion: columna pais_codigo."
  [ "$FALTA_EDITORIAL" -eq 1 ]  && info "editorial: columna pais_codigo."
  info "Se busca el código de ${AFILIACIONES} afiliación(es) con país y de las editoriales."
  echo
  read -r -p "Para continuar, escribí SI en mayúsculas: " RESPUESTA
  if [ "$RESPUESTA" != "SI" ]; then
    warn "Cancelado. No se modificó nada."
    exit 0
  fi

  # --- 5. RESPALDO PREVIO VERIFICADO ---
  mkdir -p "$DIR_RESPALDO"
  RESPALDO="${DIR_RESPALDO}/gbpublisher-antes-1.30.0-$(date '+%Y%m%d-%H%M%S').sql"
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
  for t in contribuyente_afiliacion editorial; do
    if ! grep -q "CREATE TABLE \`${t}\`" "$RESPALDO"; then
      error "El respaldo no contiene la tabla ${t}. No se modificó nada."
      exit 1
    fi
  done
  ok "Respaldo verificado ($(du -h "$RESPALDO" | cut -f1))."

  # --- 6. EL CATÁLOGO ---
  # LA COLACIÓN DE codigo ES LA DE LAS COLUMNAS QUE LO REFERENCIAN: UNA CLAVE
  # FORÁNEA EXIGE EL MISMO JUEGO DE CARACTERES Y LA MISMA COLACIÓN
  if [ "$FALTA_TABLA" -eq 1 ]; then
    mysql_adm "$DB" <<'SQL'
CREATE TABLE pais (
  codigo    CHAR(2)      CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT 'ISO 3166-1 alfa-2: JATS country/@country',
  nombre    VARCHAR(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT 'Nombre en español (iso-codes)',
  nombre_en VARCHAR(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT 'Nombre en inglés (iso-codes)',
  PRIMARY KEY (codigo),
  CONSTRAINT chk_pais_codigo CHECK (regexp_like(codigo, '^[A-Z]{2}$', 'c'))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Países ISO 3166-1 (1.30.0): catálogo fijo, de iso-codes 4.16.0';
SQL
    mysql_adm "$DB" <<'SQL'
INSERT INTO pais (codigo, nombre, nombre_en) VALUES
  ('AD', 'Andorra', 'Andorra'),
  ('AE', 'Emiratos Árabes Unidos', 'United Arab Emirates'),
  ('AF', 'Afganistán', 'Afghanistan'),
  ('AG', 'Antigua y Barbuda', 'Antigua and Barbuda'),
  ('AI', 'Anguila', 'Anguilla'),
  ('AL', 'Albania', 'Albania'),
  ('AM', 'Armenia', 'Armenia'),
  ('AO', 'Angola', 'Angola'),
  ('AQ', 'Antártida', 'Antarctica'),
  ('AR', 'Argentina', 'Argentina'),
  ('AS', 'Samoa Estadounidense', 'American Samoa'),
  ('AT', 'Austria', 'Austria'),
  ('AU', 'Australia', 'Australia'),
  ('AW', 'Aruba', 'Aruba'),
  ('AX', 'Islas Äland', 'Åland Islands'),
  ('AZ', 'Azerbaiyán', 'Azerbaijan'),
  ('BA', 'Bosnia y Herzegovina', 'Bosnia and Herzegovina'),
  ('BB', 'Barbados', 'Barbados'),
  ('BD', 'Bangladés', 'Bangladesh'),
  ('BE', 'Bélgica', 'Belgium'),
  ('BF', 'Burquina Faso', 'Burkina Faso'),
  ('BG', 'Bulgaria', 'Bulgaria'),
  ('BH', 'Baréin', 'Bahrain'),
  ('BI', 'Burundi', 'Burundi'),
  ('BJ', 'Benín', 'Benin'),
  ('BL', 'San Bartolomé', 'Saint Barthélemy'),
  ('BM', 'Islas Bermudas', 'Bermuda'),
  ('BN', 'Brunei Darussalam', 'Brunei Darussalam'),
  ('BO', 'Bolivia', 'Bolivia'),
  ('BQ', 'Islas BES (Caribe Neerlandés)', 'Bonaire, Sint Eustatius and Saba'),
  ('BR', 'Brasil', 'Brazil'),
  ('BS', 'Bahamas', 'Bahamas'),
  ('BT', 'Bután', 'Bhutan'),
  ('BV', 'Isla Bouvet', 'Bouvet Island'),
  ('BW', 'Botsuana', 'Botswana'),
  ('BY', 'Bielorrusia', 'Belarus'),
  ('BZ', 'Belice', 'Belize'),
  ('CA', 'Canadá', 'Canada'),
  ('CC', 'Islas Cocos (Keeling)', 'Cocos (Keeling) Islands'),
  ('CD', 'Congo, República Democrática del', 'Congo, The Democratic Republic of the'),
  ('CF', 'República Centroafricana', 'Central African Republic'),
  ('CG', 'Congo', 'Congo'),
  ('CH', 'Suiza', 'Switzerland'),
  ('CI', 'Costa de Marfil', 'Côte d''Ivoire'),
  ('CK', 'Islas Cook', 'Cook Islands'),
  ('CL', 'Chile', 'Chile'),
  ('CM', 'Camerún', 'Cameroon'),
  ('CN', 'China', 'China'),
  ('CO', 'Colombia', 'Colombia'),
  ('CR', 'Costa Rica', 'Costa Rica'),
  ('CU', 'Cuba', 'Cuba'),
  ('CV', 'Cabo Verde', 'Cabo Verde'),
  ('CW', 'Curazao', 'Curaçao'),
  ('CX', 'Isla de Navidad', 'Christmas Island'),
  ('CY', 'Chipre', 'Cyprus'),
  ('CZ', 'Chequia', 'Czechia'),
  ('DE', 'Alemania', 'Germany'),
  ('DJ', 'Yibuti', 'Djibouti'),
  ('DK', 'Dinamarca', 'Denmark'),
  ('DM', 'Dominica', 'Dominica'),
  ('DO', 'República Dominicana', 'Dominican Republic'),
  ('DZ', 'Algeria', 'Algeria'),
  ('EC', 'Ecuador', 'Ecuador'),
  ('EE', 'Estonia', 'Estonia'),
  ('EG', 'Egipto', 'Egypt'),
  ('EH', 'Sahara Occidental', 'Western Sahara'),
  ('ER', 'Eritrea', 'Eritrea'),
  ('ES', 'España', 'Spain'),
  ('ET', 'Etiopía', 'Ethiopia'),
  ('FI', 'Finlandia', 'Finland'),
  ('FJ', 'Fiyi', 'Fiji'),
  ('FK', 'Islas Falkland (Malvinas)', 'Falkland Islands (Malvinas)'),
  ('FM', 'Micronesia, Estados Federados de', 'Micronesia, Federated States of'),
  ('FO', 'Islas Feroe', 'Faroe Islands'),
  ('FR', 'Francia', 'France'),
  ('GA', 'Gabón', 'Gabon'),
  ('GB', 'Reino Unido', 'United Kingdom'),
  ('GD', 'Granada', 'Grenada'),
  ('GE', 'Georgia', 'Georgia'),
  ('GF', 'Guayana Francesa', 'French Guiana'),
  ('GG', 'Guernsey', 'Guernsey'),
  ('GH', 'Ghana', 'Ghana'),
  ('GI', 'Gibraltar', 'Gibraltar'),
  ('GL', 'Groenlandia', 'Greenland'),
  ('GM', 'Gambia', 'Gambia'),
  ('GN', 'Guinea', 'Guinea'),
  ('GP', 'Guadalupe', 'Guadeloupe'),
  ('GQ', 'Guinea Ecuatorial', 'Equatorial Guinea'),
  ('GR', 'Grecia', 'Greece'),
  ('GS', 'Islas Georgias del Sur y Sándwich del Sur', 'South Georgia and the South Sandwich Islands'),
  ('GT', 'Guatemala', 'Guatemala'),
  ('GU', 'Guam', 'Guam'),
  ('GW', 'Guinea-Bisáu', 'Guinea-Bissau'),
  ('GY', 'Guyana', 'Guyana'),
  ('HK', 'Hong Kong', 'Hong Kong'),
  ('HM', 'Islas Heard y McDonald', 'Heard Island and McDonald Islands'),
  ('HN', 'Honduras', 'Honduras'),
  ('HR', 'Croacia', 'Croatia'),
  ('HT', 'Haití', 'Haiti'),
  ('HU', 'Hungría', 'Hungary'),
  ('ID', 'Indonesia', 'Indonesia'),
  ('IE', 'Irlanda', 'Ireland'),
  ('IL', 'Israel', 'Israel'),
  ('IM', 'Isla de Man', 'Isle of Man'),
  ('IN', 'India', 'India'),
  ('IO', 'Territorio Británico del Océano Índico', 'British Indian Ocean Territory'),
  ('IQ', 'Irak', 'Iraq'),
  ('IR', 'Irán', 'Iran'),
  ('IS', 'Islandia', 'Iceland'),
  ('IT', 'Italia', 'Italy'),
  ('JE', 'Jersey', 'Jersey'),
  ('JM', 'Jamaica', 'Jamaica'),
  ('JO', 'Jordania', 'Jordan'),
  ('JP', 'Japón', 'Japan'),
  ('KE', 'Kenia', 'Kenya'),
  ('KG', 'Kirguistán', 'Kyrgyzstan'),
  ('KH', 'Camboya', 'Cambodia'),
  ('KI', 'Kiribati', 'Kiribati'),
  ('KM', 'Comores, Islas', 'Comoros'),
  ('KN', 'San Cristóbal y Nieves', 'Saint Kitts and Nevis'),
  ('KP', 'Corea del Norte', 'North Korea'),
  ('KR', 'Corea del Sur', 'South Korea'),
  ('KW', 'Kuwait', 'Kuwait'),
  ('KY', 'Islas Caimán', 'Cayman Islands'),
  ('KZ', 'Kazajistán', 'Kazakhstan'),
  ('LA', 'Laos', 'Laos'),
  ('LB', 'Líbano', 'Lebanon'),
  ('LC', 'Santa Lucía', 'Saint Lucia'),
  ('LI', 'Liechtenstein', 'Liechtenstein'),
  ('LK', 'Sri Lanka', 'Sri Lanka'),
  ('LR', 'Liberia', 'Liberia'),
  ('LS', 'Lesoto', 'Lesotho'),
  ('LT', 'Lituania', 'Lithuania'),
  ('LU', 'Luxemburgo', 'Luxembourg'),
  ('LV', 'Letonia', 'Latvia'),
  ('LY', 'Libia', 'Libya'),
  ('MA', 'Marruecos', 'Morocco'),
  ('MC', 'Mónaco', 'Monaco'),
  ('MD', 'Moldavia', 'Moldova'),
  ('ME', 'Montenegro', 'Montenegro'),
  ('MF', 'San Martín (zona francesa)', 'Saint Martin (French part)'),
  ('MG', 'Madagascar', 'Madagascar'),
  ('MH', 'Islas Marshall', 'Marshall Islands'),
  ('MK', 'Macedonia del Norte', 'North Macedonia'),
  ('ML', 'Malí', 'Mali'),
  ('MM', 'Birmania', 'Myanmar'),
  ('MN', 'Mongolia', 'Mongolia'),
  ('MO', 'Macao', 'Macao'),
  ('MP', 'Islas Marianas del Norte', 'Northern Mariana Islands'),
  ('MQ', 'Martinica', 'Martinique'),
  ('MR', 'Mauritania', 'Mauritania'),
  ('MS', 'Montserrat', 'Montserrat'),
  ('MT', 'Malta', 'Malta'),
  ('MU', 'Mauricio', 'Mauritius'),
  ('MV', 'Islas Maldivas', 'Maldives'),
  ('MW', 'Malaui', 'Malawi'),
  ('MX', 'México', 'Mexico'),
  ('MY', 'Malasia', 'Malaysia'),
  ('MZ', 'Mozambique', 'Mozambique'),
  ('NA', 'Namibia', 'Namibia'),
  ('NC', 'Nueva Caledonia', 'New Caledonia'),
  ('NE', 'Niger', 'Niger'),
  ('NF', 'Isla Norfolk', 'Norfolk Island'),
  ('NG', 'Nigeria', 'Nigeria'),
  ('NI', 'Nicaragua', 'Nicaragua'),
  ('NL', 'Países Bajos', 'Netherlands'),
  ('NO', 'Noruega', 'Norway'),
  ('NP', 'Nepal', 'Nepal'),
  ('NR', 'Nauru', 'Nauru'),
  ('NU', 'Niue', 'Niue'),
  ('NZ', 'Nueva Zelanda', 'New Zealand'),
  ('OM', 'Omán', 'Oman'),
  ('PA', 'Panamá', 'Panama'),
  ('PE', 'Perú', 'Peru'),
  ('PF', 'Polinesia Francesa', 'French Polynesia'),
  ('PG', 'Papúa Nueva Guinea', 'Papua New Guinea'),
  ('PH', 'Filipinas', 'Philippines'),
  ('PK', 'Pakistán', 'Pakistan'),
  ('PL', 'Polonia', 'Poland'),
  ('PM', 'San Pedro y Miquelon', 'Saint Pierre and Miquelon'),
  ('PN', 'Pitcairn', 'Pitcairn'),
  ('PR', 'Puerto Rico', 'Puerto Rico'),
  ('PS', 'Palestina, Estado de', 'Palestine, State of'),
  ('PT', 'Portugal', 'Portugal'),
  ('PW', 'Palaos', 'Palau'),
  ('PY', 'Paraguay', 'Paraguay'),
  ('QA', 'Catar', 'Qatar'),
  ('RE', 'Reunión', 'Réunion'),
  ('RO', 'Rumanía', 'Romania'),
  ('RS', 'Serbia', 'Serbia'),
  ('RU', 'Federación Rusa', 'Russian Federation'),
  ('RW', 'Ruanda', 'Rwanda'),
  ('SA', 'Arabia Saudí', 'Saudi Arabia'),
  ('SB', 'Islas Salomón', 'Solomon Islands'),
  ('SC', 'Seychelles', 'Seychelles'),
  ('SD', 'Sudán', 'Sudan'),
  ('SE', 'Suecia', 'Sweden'),
  ('SG', 'Singapur', 'Singapore'),
  ('SH', 'Santa Elena, Ascensión y Tristán de Acuña', 'Saint Helena, Ascension and Tristan da Cunha'),
  ('SI', 'Eslovenia', 'Slovenia'),
  ('SJ', 'Svalbard y Jan Mayen', 'Svalbard and Jan Mayen'),
  ('SK', 'Eslovaquia', 'Slovakia'),
  ('SL', 'Sierra Leona', 'Sierra Leone'),
  ('SM', 'San Marino', 'San Marino'),
  ('SN', 'Senegal', 'Senegal'),
  ('SO', 'Somalia', 'Somalia'),
  ('SR', 'Surinám', 'Suriname'),
  ('SS', 'Sudán del Sur', 'South Sudan'),
  ('ST', 'Santo Tomé y Príncipe', 'Sao Tome and Principe'),
  ('SV', 'El Salvador', 'El Salvador'),
  ('SX', 'Isla de San Martín (zona holandsea)', 'Sint Maarten (Dutch part)'),
  ('SY', 'Siria', 'Syria'),
  ('SZ', 'Esuatini', 'Eswatini'),
  ('TC', 'Islas Turcas y Caicos', 'Turks and Caicos Islands'),
  ('TD', 'Chad', 'Chad'),
  ('TF', 'Territorios Franceses del Sur', 'French Southern Territories'),
  ('TG', 'Togo', 'Togo'),
  ('TH', 'Tailandia', 'Thailand'),
  ('TJ', 'Tayikistán', 'Tajikistan'),
  ('TK', 'Tokelau', 'Tokelau'),
  ('TL', 'Timor Oriental', 'Timor-Leste'),
  ('TM', 'Turkmenistán', 'Turkmenistan'),
  ('TN', 'Tunez', 'Tunisia'),
  ('TO', 'Tonga', 'Tonga'),
  ('TR', 'Turquía', 'Türkiye'),
  ('TT', 'Trinidad y Tobago', 'Trinidad and Tobago'),
  ('TV', 'Tuvalu', 'Tuvalu'),
  ('TW', 'Taiwán', 'Taiwan'),
  ('TZ', 'Tanzania', 'Tanzania'),
  ('UA', 'Ucrania', 'Ukraine'),
  ('UG', 'Uganda', 'Uganda'),
  ('UM', 'Islas Ultramarinas Menores de Estados Unidos', 'United States Minor Outlying Islands'),
  ('US', 'Estados Unidos', 'United States'),
  ('UY', 'Uruguay', 'Uruguay'),
  ('UZ', 'Uzbekistán', 'Uzbekistan'),
  ('VA', 'Santa Sede (Ciudad Estado del Vaticano)', 'Holy See (Vatican City State)'),
  ('VC', 'San Vicente y las Granadinas', 'Saint Vincent and the Grenadines'),
  ('VE', 'Venezuela', 'Venezuela'),
  ('VG', 'Islas Vírgenes, Británicas', 'Virgin Islands, British'),
  ('VI', 'Islas Vírgenes, de EEUU', 'Virgin Islands, U.S.'),
  ('VN', 'Vietnam', 'Vietnam'),
  ('VU', 'Vanuatu', 'Vanuatu'),
  ('WF', 'Wallis y Futuna', 'Wallis and Futuna'),
  ('WS', 'Samoa', 'Samoa'),
  ('YE', 'Yemen', 'Yemen'),
  ('YT', 'Mayotte', 'Mayotte'),
  ('ZA', 'Sudáfrica', 'South Africa'),
  ('ZM', 'Zambia', 'Zambia'),
  ('ZW', 'Zimbabue', 'Zimbabwe');
SQL
    ok "Tabla pais creada con $(valor "SELECT COUNT(*) FROM \`${DB}\`.pais;") países."
  fi

  # --- 7. LAS COLUMNAS, CON SU CLAVE FORÁNEA ---
  # RESTRICT: UN PAÍS EN USO NO SE BORRA DEL CATÁLOGO
  if [ "$FALTA_AFILIACION" -eq 1 ]; then
    mysql_adm "$DB" -e "ALTER TABLE contribuyente_afiliacion
      ADD COLUMN pais_codigo CHAR(2) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT NULL COMMENT 'ISO 3166-1 alfa-2; el nombre va en pais, por valor (1.30.0)' AFTER pais,
      ADD CONSTRAINT fk_afil_pais FOREIGN KEY (pais_codigo) REFERENCES pais (codigo) ON DELETE RESTRICT ON UPDATE RESTRICT;"
    ok "contribuyente_afiliacion.pais_codigo creada."
  fi
  if [ "$FALTA_EDITORIAL" -eq 1 ]; then
    mysql_adm "$DB" -e "ALTER TABLE editorial
      ADD COLUMN pais_codigo CHAR(2) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT NULL COMMENT 'ISO 3166-1 alfa-2; el nombre va en pais, por valor (1.30.0)' AFTER pais,
      ADD CONSTRAINT fk_editorial_pais FOREIGN KEY (pais_codigo) REFERENCES pais (codigo) ON DELETE RESTRICT ON UPDATE RESTRICT;"
    ok "editorial.pais_codigo creada."
  fi

  # --- 8. LA MIGRACIÓN ---
  # SIN DISTINGUIR MAYÚSCULAS NI TILDES (utf8mb4_0900_ai_ci, COMO LA
  # BÚSQUEDA DE VOCABULARIOS, GV-152): «Mexico» Y «méxico» SON México. SOLO
  # DONDE TODAVÍA NO HAY CÓDIGO: UNA SEGUNDA CORRIDA NO PISA
  for t in contribuyente_afiliacion editorial; do
    mysql_adm "$DB" -e "UPDATE ${t} x
      JOIN pais p ON TRIM(x.pais) COLLATE utf8mb4_0900_ai_ci = p.nombre COLLATE utf8mb4_0900_ai_ci
                  OR TRIM(x.pais) COLLATE utf8mb4_0900_ai_ci = p.nombre_en COLLATE utf8mb4_0900_ai_ci
                  OR TRIM(x.pais) COLLATE utf8mb4_0900_ai_ci = p.codigo COLLATE utf8mb4_0900_ai_ci
      SET x.pais_codigo = p.codigo
      WHERE x.pais_codigo IS NULL AND x.pais IS NOT NULL AND TRIM(x.pais) <> '';"
  done
  ok "Códigos completados donde el texto coincide con el catálogo."

  # --- 9. VOLVER ATRÁS ---
  VOLVER="${RESPALDO%.sql}-volver-atras.sql"
  cat > "$VOLVER" <<'SQL'
-- VOLVER ATRÁS LA 1.30.0 DE gbpublisher: sudo mysql gbpublisher < ESTE_ARCHIVO
ALTER TABLE contribuyente_afiliacion DROP FOREIGN KEY fk_afil_pais, DROP COLUMN pais_codigo;
ALTER TABLE editorial DROP FOREIGN KEY fk_editorial_pais, DROP COLUMN pais_codigo;
DROP TABLE pais;
DELETE FROM esquema_version WHERE parche = 'actualizacion-1.30.0';
SQL
  ok "Para volver atrás: ${VOLVER}"

  # --- 10. VERIFICACIÓN POSTERIOR ---
  FALLA=0
  for par in "pais:${COLS_PAIS}" "contribuyente_afiliacion:${COLS_AFILIACION}" "editorial:${COLS_EDITORIAL}"; do
    t="${par%%:*}"; n="${par##*:}"
    CANTIDAD="$(columnas_tabla "$t")"
    if [ "$CANTIDAD" != "$n" ]; then
      error "${t} tiene ${CANTIDAD} columnas y se esperaban ${n}."
      FALLA=1
    fi
  done
  FILAS="$(valor "SELECT COUNT(*) FROM \`${DB}\`.pais;")"
  if [ "$FILAS" != "$FILAS_PAIS" ]; then
    error "pais tiene ${FILAS} filas y se esperaban ${FILAS_PAIS}."
    FALLA=1
  fi
  if [ "$FALLA" = "1" ]; then
    error "NO se registra la actualización. Para volver atrás:"
    error "  sudo mysql ${DB} < ${VOLVER}"
    exit 1
  fi
  ok "Verificación correcta: catálogo y columnas creados."

  # --- 11. REGISTRO ---
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

# --- 12. INFORME DE CONTROL (SOLO LECTURA) ---
# LO QUE QUEDÓ SIN CÓDIGO: HAY QUE ELEGIR EL PAÍS EN EL ARTÍCULO O EN LA
# EDITORIAL. SIN CÓDIGO, SciELO RECHAZA LA AFILIACIÓN
echo
info "Informe de control: los países que quedaron sin código"
mysql_adm "$DB" -e "SELECT 'afiliación' AS donde, x.pais AS texto, COUNT(*) AS veces,
  GROUP_CONCAT(DISTINCT ac.id_articulo ORDER BY ac.id_articulo) AS articulos
  FROM contribuyente_afiliacion x JOIN articulo_contribuyente ac ON ac.id_contribuyente = x.id_contribuyente
  WHERE x.pais_codigo IS NULL AND x.pais IS NOT NULL AND TRIM(x.pais) <> ''
  GROUP BY x.pais
  UNION ALL
  SELECT 'editorial', e.pais, COUNT(*), GROUP_CONCAT(e.id_editorial ORDER BY e.id_editorial)
  FROM editorial e WHERE e.pais_codigo IS NULL AND e.pais IS NOT NULL AND TRIM(e.pais) <> ''
  GROUP BY e.pais;"
echo "El informe no modifica nada. Una lista vacía: todo tiene código."
echo
ok "${NEGRITA}Actualización 1.30.0 lista.${RESET}"
