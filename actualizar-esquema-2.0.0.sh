#!/usr/bin/env bash
#
# ============================================
# Script    : actualizar-esquema-2.0.0.sh
# Propósito : Actualización 2.0.0 de la base de gbpublisher, sobre una base
#             EN USO. Es el PUNTO DE RUPTURA de SC-22: con ella se genera el
#             baseline 2.0.0. Refactoriza la bibliografía (decisión de
#             Alberto del 19/11/2026):
#               - bibtex queda como la ENTRADA: id, id_proyecto,
#                 tipo_de_entrada, clave_bibtex, id_origen y
#                 fecha_modificacion;
#               - bibtex_campo guarda los DATOS: un par campo/valor por cada
#                 campo con dato, con el nombre de biblatex. Un campo sin
#                 dato no tiene fila;
#               - bibtex_campo_catalogo: los 105 campos de biblatex que
#                 admite gbpublisher, en el orden en que salen en el .bib
#                 (el de las columnas viejas) y marcados si son literales.
#             Además:
#               - hyphenation y lang_id, que salían los dos como langid, se
#                 unen en un solo par. Gana hyphenation, como en
#                 ExportarBibTeX;
#               - se corrigen los langid abreviados: eng → english y
#                 span → spanish (decisión de Alberto del 20/11/2026);
#               - sale id_articulo: apuntaba a la tabla articulos, que se
#                 retiró en la 1.32.0;
#               - formatos_pdf pasa a utf8mb4_unicode_ci si quedó con otra
#                 colación (la base de desarrollo tenía utf8mb4_0900_ai_ci;
#                 el baseline 1.0.0 ya la normalizaba): con la 2.0.0 todas
#                 las bases quedan iguales al baseline 2.0.0.
# Uso       : sudo bash actualizar-esquema-2.0.0.sh
# Reglas    : BBDD_LEEME.md §5 y SC-22. IDEMPOTENTE; respaldo verificado;
#             verificación posterior; sin efecto si ya está aplicado.
#             Exige la 1.34.0 registrada.
# Prueba    : ANTES de borrar las columnas viejas, para cada proyecto se arma
#             el contenido del .bib (entradas por clave, campos en orden)
#             desde las columnas viejas y desde los pares, y se comparan las
#             huellas sha256. Si un proyecto difiere, no se borra nada.
# Lote      : la aplicación nueva (m_Bibtex, m_BuscarBib, m_AplicarBib,
#             m_Json, FRelacionarBib, FCandidatosBib, FCorregirBibTeX,
#             m_FuncionesGenericas, FMain y m_ConexionBD) va en la misma
#             entrega. Este script se aplica DESPUÉS de instalarla: la
#             versión anterior no arranca sin las columnas viejas.
# Volver    : borrar las dos tablas nuevas y restaurar el respaldo que se
#             hace antes (pisa todo lo trabajado después). El script muestra
#             los dos comandos. Desde la 1.32.0 el respaldo se restaura sin
#             relajar innodb_strict_mode (GV-67, medido el 19/11/2026).
# ============================================

set -euo pipefail

# --- 0. CONFIGURACIÓN ---
DB="gbpublisher"
PARCHE="actualizacion-2.0.0"
PREVIO="actualizacion-1.34.0"
DESCRIPCION="Bibliografía en entrada y pares campo/valor: bibtex, bibtex_campo y bibtex_campo_catalogo"
DIR_RESPALDO="${HOME}/gbpublisher-respaldos"

# LAS COLUMNAS QUE QUEDAN EN bibtex. EL RESTO SE VA
QUEDAN_SQL="'id','id_proyecto','tipo_de_entrada','clave_bibtex','id_origen','fecha_modificacion'"
QUEDAN_N=6

# EL CATÁLOGO: campo biblatex | literal | columna vieja. EL ORDEN DE LAS
# LÍNEAS ES EL DE LAS COLUMNAS VIEJAS, QUE ES EL ORDEN EN QUE ExportarBibTeX
# ESCRIBE LOS CAMPOS: CON ÉL, EL .bib SALE IGUAL BYTE A BYTE. EL orden SE
# GUARDA DE 10 EN 10 PARA PODER INTERCALAR UN CAMPO SIN RENUMERAR.
# lang_id NO ESTÁ: SE UNE A langid (APARTADO 9).
CATALOGO="
type|0|tipo_de_tesis
author|0|author
editor|0|editor
title|0|title
nameaddon|0|name_addon
bookauthor|0|book_author
editora|0|editor_a
editorb|0|editor_b
editorc|0|editor_c
afterword|0|afterword
foreword|0|foreword
commentator|0|commentator
introduction|0|introduction
translator|0|translator
annotator|0|annotator
holder|0|holder
gender|0|gender
shortauthor|0|short_author
editortype|0|editor_type
editortypea|0|editor_type_a
editortypeb|0|editor_type_b
editortypec|0|editor_type_c
titleaddon|0|title_addon
subtitle|0|sub_title
series|0|series
booktitle|0|book_title
booktitleaddon|0|book_title_addon
maintitle|0|main_title
maintitleaddon|0|main_title_addon
journaltitle|0|journal_title
journaltitleaddon|0|journal_title_addon
issuetitle|0|issue_title
issuetitleaddon|0|issue_title_addon
eventtitle|0|event_title
eventtitleaddon|0|event_title_addon
indextitle|0|index_title
shorttitle|0|short_title
reprinttitle|0|reprint_title
volume|0|volume
volumes|0|volumes
number|0|number
chapter|0|chapter
eid|0|eid
part|0|part
edition|0|edition
issue|0|issue
year|0|year
eventdate|0|event_date
date|0|date
origdate|0|orig_date
urldate|0|url_date
version|0|version
langid|0|hyphenation
language|0|language
origlanguage|0|orig_language
langidopts|0|land_id_opts
pubstate|0|pub_state
pages|0|pages
pagetotal|0|page_total
pagination|0|pagination
bookpagination|0|book_pagination
location|0|location
origlocation|0|orig_location
institution|0|institution
organization|0|organization
publisher|0|publisher
origpublisher|0|orig_publisher
venue|0|venue
eprint|1|eprint
eprinttype|0|eprint_type
url|1|url
isbn|0|isbn
issn|0|issn
ismn|0|ismn
isrn|0|isrn
isan|0|isan
iswc|0|iswc
doi|1|doi
relatedtype|0|related_type
related|0|related
relatedstring|0|related_string
addendum|0|addendum
entrysubtype|0|entry_sub_type
options|0|options
label|0|label
howpublished|0|how_published
shorthand|0|short_hand
shorthandintro|0|short_hand_intro
ids|0|ids
entryset|0|entry_set
crossref|0|cross_ref
xref|0|xref
xdata|0|xdata
presort|0|pre_sort
sortkey|0|sort_key
sortname|0|sort_name
sortshorthand|0|sort_hand
sortyear|0|sort_year
sorttitle|0|sort_title
indexsorttitle|0|index_sort_title
abstract|0|abstract
note|0|note
library|0|library
annotation|0|annotation
file|1|file
"
CATALOGO_N=105

# LAS CONSULTAS CANÓNICAS DE BIBLIOGRAFÍA (TABLA consultas) QUE LEÍAN COLUMNAS
# DE bibtex, REESCRITAS PARA LOS PARES: nombre | SQL EN BASE64 (ASÍ VIAJAN
# LAS COMILLAS Y LOS ACENTOS SIN ESCAPES). SE IDENTIFICAN POR EL PREFIJO DEL
# NOMBRE («BIB-002:»), NO POR EL id. DONDE LA VIEJA USABA id_articulo (QUE
# VALÍA 0), LA NUEVA USA EL PROYECTO. BIB-001 NO CAMBIA: SOLO USA
# tipo_de_entrada. BIB-ART-001 Y BIB-ART-002 NO SE TOCAN: DEPENDEN DE LA
# TABLA articulos, RETIRADA EN LA 1.32.0, IGUAL QUE OTRAS CONSULTAS DE
# REVISTAS (VER EL INFORME DE CONTROL)
CONSULTAS_BIB="
BIB-002|U0VMRUNUIAogICAgQ09BTEVTQ0UoU1VCU1RSSU5HKGZkLnZhbG9yLCAxLCA0KSwgZnkudmFsb3IpIEFTICdBw7FvJywKICAgIENPVU5UKCopIEFTICdSZWZlcmVuY2lhcycsCiAgICBiLnRpcG9fZGVfZW50cmFkYSBBUyAnVGlwbycKRlJPTSBiaWJ0ZXggYgpMRUZUIEpPSU4gYmlidGV4X2NhbXBvIGZkIE9OIGZkLmlkX2JpYnRleCA9IGIuaWQgQU5EIGZkLmNhbXBvID0gJ2RhdGUnCkxFRlQgSk9JTiBiaWJ0ZXhfY2FtcG8gZnkgT04gZnkuaWRfYmlidGV4ID0gYi5pZCBBTkQgZnkuY2FtcG8gPSAneWVhcicKR1JPVVAgQlkgQ09BTEVTQ0UoU1VCU1RSSU5HKGZkLnZhbG9yLCAxLCA0KSwgZnkudmFsb3IpLCBiLnRpcG9fZGVfZW50cmFkYQpPUkRFUiBCWSBDT1VOVCgqKSBERVNDOw==
BIB-003|U0VMRUNUIAogICAgQ09BTEVTQ0UoZmwudmFsb3IsIGZnLnZhbG9yKSBBUyAnSWRpb21hJywKICAgIENPVU5UKCopIEFTICdSZWZlcmVuY2lhcycsCiAgICBST1VORChDT1VOVCgqKSAqIDEwMC4wIC8gKFNFTEVDVCBDT1VOVChESVNUSU5DVCBpZF9iaWJ0ZXgpIEZST00gYmlidGV4X2NhbXBvIFdIRVJFIGNhbXBvIElOICgnbGFuZ2lkJywgJ2xhbmd1YWdlJykpLCAyKSBBUyAnUG9yY2VudGFqZScKRlJPTSBiaWJ0ZXggYgpMRUZUIEpPSU4gYmlidGV4X2NhbXBvIGZsIE9OIGZsLmlkX2JpYnRleCA9IGIuaWQgQU5EIGZsLmNhbXBvID0gJ2xhbmdpZCcKTEVGVCBKT0lOIGJpYnRleF9jYW1wbyBmZyBPTiBmZy5pZF9iaWJ0ZXggPSBiLmlkIEFORCBmZy5jYW1wbyA9ICdsYW5ndWFnZScKV0hFUkUgZmwudmFsb3IgSVMgTk9UIE5VTEwgT1IgZmcudmFsb3IgSVMgTk9UIE5VTEwKR1JPVVAgQlkgQ09BTEVTQ0UoZmwudmFsb3IsIGZnLnZhbG9yKQpPUkRFUiBCWSBDT1VOVCgqKSBERVNDOw==
BIB-004|U0VMRUNUIAogICAgZmoudmFsb3IgQVMgJ1JldmlzdGEnLAogICAgQ09VTlQoKikgQVMgJ1ZlY2VzIENpdGFkYScsCiAgICBDT1VOVChESVNUSU5DVCBiLmlkX3Byb3llY3RvKSBBUyAnUHJveWVjdG9zIHF1ZSBsYSBDaXRhbicKRlJPTSBiaWJ0ZXggYgpKT0lOIGJpYnRleF9jYW1wbyBmaiBPTiBmai5pZF9iaWJ0ZXggPSBiLmlkIEFORCBmai5jYW1wbyA9ICdqb3VybmFsdGl0bGUnCkdST1VQIEJZIGZqLnZhbG9yCk9SREVSIEJZIENPVU5UKCopIERFU0MKTElNSVQgMTA7
BIB-005|U0VMRUNUIAogICAgZnAudmFsb3IgQVMgJ0VkaXRvcmlhbCcsCiAgICBDT1VOVCgqKSBBUyAnVmVjZXMgQ2l0YWRhJywKICAgIEdST1VQX0NPTkNBVChESVNUSU5DVCBmbC52YWxvciBTRVBBUkFUT1IgJzsgJykgQVMgJ1ViaWNhY2lvbmVzJwpGUk9NIGJpYnRleCBiCkpPSU4gYmlidGV4X2NhbXBvIGZwIE9OIGZwLmlkX2JpYnRleCA9IGIuaWQgQU5EIGZwLmNhbXBvID0gJ3B1Ymxpc2hlcicKTEVGVCBKT0lOIGJpYnRleF9jYW1wbyBmbCBPTiBmbC5pZF9iaWJ0ZXggPSBiLmlkIEFORCBmbC5jYW1wbyA9ICdsb2NhdGlvbicKR1JPVVAgQlkgZnAudmFsb3IKT1JERVIgQlkgQ09VTlQoKikgREVTQwpMSU1JVCAxMDs=
BIB-006|U0VMRUNUIAogICAgZmEudmFsb3IgQVMgJ0F1dG9yJywKICAgIENPVU5UKCopIEFTICdWZWNlcyBDaXRhZG8nLAogICAgQ09VTlQoRElTVElOQ1QgYi5pZF9wcm95ZWN0bykgQVMgJ1Byb3llY3RvcyBxdWUgbG8gQ2l0YW4nLAogICAgR1JPVVBfQ09OQ0FUKERJU1RJTkNUIENPQUxFU0NFKFNVQlNUUklORyhmZC52YWxvciwgMSwgNCksIGZ5LnZhbG9yKSBPUkRFUiBCWSBDT0FMRVNDRShTVUJTVFJJTkcoZmQudmFsb3IsIDEsIDQpLCBmeS52YWxvcikgREVTQyBTRVBBUkFUT1IgJywgJykgQVMgJ0HDsW9zJwpGUk9NIGJpYnRleCBiCkpPSU4gYmlidGV4X2NhbXBvIGZhIE9OIGZhLmlkX2JpYnRleCA9IGIuaWQgQU5EIGZhLmNhbXBvID0gJ2F1dGhvcicKTEVGVCBKT0lOIGJpYnRleF9jYW1wbyBmZCBPTiBmZC5pZF9iaWJ0ZXggPSBiLmlkIEFORCBmZC5jYW1wbyA9ICdkYXRlJwpMRUZUIEpPSU4gYmlidGV4X2NhbXBvIGZ5IE9OIGZ5LmlkX2JpYnRleCA9IGIuaWQgQU5EIGZ5LmNhbXBvID0gJ3llYXInCkdST1VQIEJZIGZhLnZhbG9yCk9SREVSIEJZIENPVU5UKCopIERFU0MKTElNSVQgMjA7
BIB-CAL-001|U0VMRUNUIAogICAgcC5ub21icmUgQVMgJ1Byb3llY3RvJywKICAgIGIudGlwb19kZV9lbnRyYWRhIEFTICdUaXBvJywKICAgIGZhLnZhbG9yIEFTICdBdXRvcicsCiAgICBmdC52YWxvciBBUyAnVMOtdHVsbycsCiAgICBDT0FMRVNDRShTVUJTVFJJTkcoZmQudmFsb3IsIDEsIDQpLCBmeS52YWxvcikgQVMgJ0HDsW8nLAogICAgQ09BTEVTQ0UoZmoudmFsb3IsIGZiLnZhbG9yLCBmZS52YWxvcikgQVMgJ1B1YmxpY2FkbyBlbicKRlJPTSBiaWJ0ZXggYgpKT0lOIHByb3llY3RvcyBwIE9OIHAuaWQgPSBiLmlkX3Byb3llY3RvCkxFRlQgSk9JTiBiaWJ0ZXhfY2FtcG8gZmEgT04gZmEuaWRfYmlidGV4ID0gYi5pZCBBTkQgZmEuY2FtcG8gPSAnYXV0aG9yJwpMRUZUIEpPSU4gYmlidGV4X2NhbXBvIGZ0IE9OIGZ0LmlkX2JpYnRleCA9IGIuaWQgQU5EIGZ0LmNhbXBvID0gJ3RpdGxlJwpMRUZUIEpPSU4gYmlidGV4X2NhbXBvIGZkIE9OIGZkLmlkX2JpYnRleCA9IGIuaWQgQU5EIGZkLmNhbXBvID0gJ2RhdGUnCkxFRlQgSk9JTiBiaWJ0ZXhfY2FtcG8gZnkgT04gZnkuaWRfYmlidGV4ID0gYi5pZCBBTkQgZnkuY2FtcG8gPSAneWVhcicKTEVGVCBKT0lOIGJpYnRleF9jYW1wbyBmaiBPTiBmai5pZF9iaWJ0ZXggPSBiLmlkIEFORCBmai5jYW1wbyA9ICdqb3VybmFsdGl0bGUnCkxFRlQgSk9JTiBiaWJ0ZXhfY2FtcG8gZmIgT04gZmIuaWRfYmlidGV4ID0gYi5pZCBBTkQgZmIuY2FtcG8gPSAnYm9va3RpdGxlJwpMRUZUIEpPSU4gYmlidGV4X2NhbXBvIGZlIE9OIGZlLmlkX2JpYnRleCA9IGIuaWQgQU5EIGZlLmNhbXBvID0gJ2V2ZW50dGl0bGUnCldIRVJFIE5PVCBFWElTVFMgKFNFTEVDVCAxIEZST00gYmlidGV4X2NhbXBvIHggV0hFUkUgeC5pZF9iaWJ0ZXggPSBiLmlkIEFORCB4LmNhbXBvID0gJ2RvaScpCiAgICBBTkQgYi50aXBvX2RlX2VudHJhZGEgSU4gKCdhcnRpY2xlJywgJ2lucHJvY2VlZGluZ3MnLCAnaW5jb2xsZWN0aW9uJywgJ2luYm9vaycpCiAgICBBTkQgQ09BTEVTQ0UoU1VCU1RSSU5HKGZkLnZhbG9yLCAxLCA0KSwgZnkudmFsb3IpID49ICcyMDEwJwpPUkRFUiBCWSBDQVNUKENPQUxFU0NFKFNVQlNUUklORyhmZC52YWxvciwgMSwgNCksIGZ5LnZhbG9yKSBBUyBVTlNJR05FRCkgREVTQzs=
BIB-CAL-002|U0VMRUNUIAogICAgYi5pZCBBUyAnSUQgUmVmZXJlbmNpYScsCiAgICBwLm5vbWJyZSBBUyAnUHJveWVjdG8nLAogICAgYi50aXBvX2RlX2VudHJhZGEgQVMgJ1RpcG8nLAogICAgZmEudmFsb3IgQVMgJ0F1dG9yJywKICAgIGZ0LnZhbG9yIEFTICdUw610dWxvJywKICAgIGZwLnZhbG9yIEFTICdFZGl0b3JpYWwvUmV2aXN0YScKRlJPTSBiaWJ0ZXggYgpKT0lOIHByb3llY3RvcyBwIE9OIHAuaWQgPSBiLmlkX3Byb3llY3RvCkxFRlQgSk9JTiBiaWJ0ZXhfY2FtcG8gZmEgT04gZmEuaWRfYmlidGV4ID0gYi5pZCBBTkQgZmEuY2FtcG8gPSAnYXV0aG9yJwpMRUZUIEpPSU4gYmlidGV4X2NhbXBvIGZ0IE9OIGZ0LmlkX2JpYnRleCA9IGIuaWQgQU5EIGZ0LmNhbXBvID0gJ3RpdGxlJwpMRUZUIEpPSU4gYmlidGV4X2NhbXBvIGZwIE9OIGZwLmlkX2JpYnRleCA9IGIuaWQgQU5EIGZwLmNhbXBvID0gJ3B1Ymxpc2hlcicKV0hFUkUgTk9UIEVYSVNUUyAoU0VMRUNUIDEgRlJPTSBiaWJ0ZXhfY2FtcG8geCBXSEVSRSB4LmlkX2JpYnRleCA9IGIuaWQgQU5EIHguY2FtcG8gSU4gKCdkYXRlJywgJ3llYXInKSkKT1JERVIgQlkgcC5ub21icmUsIGIuaWQ7
BIB-CAL-003|U0VMRUNUIAogICAgYi5pZCBBUyAnSUQgUmVmZXJlbmNpYScsCiAgICBwLm5vbWJyZSBBUyAnUHJveWVjdG8nLAogICAgYi50aXBvX2RlX2VudHJhZGEgQVMgJ1RpcG8nLAogICAgZnQudmFsb3IgQVMgJ1TDrXR1bG8nLAogICAgQ09BTEVTQ0UoU1VCU1RSSU5HKGZkLnZhbG9yLCAxLCA0KSwgZnkudmFsb3IpIEFTICdBw7FvJwpGUk9NIGJpYnRleCBiCkpPSU4gcHJveWVjdG9zIHAgT04gcC5pZCA9IGIuaWRfcHJveWVjdG8KTEVGVCBKT0lOIGJpYnRleF9jYW1wbyBmdCBPTiBmdC5pZF9iaWJ0ZXggPSBiLmlkIEFORCBmdC5jYW1wbyA9ICd0aXRsZScKTEVGVCBKT0lOIGJpYnRleF9jYW1wbyBmZCBPTiBmZC5pZF9iaWJ0ZXggPSBiLmlkIEFORCBmZC5jYW1wbyA9ICdkYXRlJwpMRUZUIEpPSU4gYmlidGV4X2NhbXBvIGZ5IE9OIGZ5LmlkX2JpYnRleCA9IGIuaWQgQU5EIGZ5LmNhbXBvID0gJ3llYXInCldIRVJFIE5PVCBFWElTVFMgKFNFTEVDVCAxIEZST00gYmlidGV4X2NhbXBvIHggV0hFUkUgeC5pZF9iaWJ0ZXggPSBiLmlkIEFORCB4LmNhbXBvIElOICgnYXV0aG9yJywgJ2VkaXRvcicpKQpPUkRFUiBCWSBwLm5vbWJyZSwgYi5pZDs=
BIB-GEO-001|U0VMRUNUIAogICAgZmwudmFsb3IgQVMgJ1ViaWNhY2nDs24nLAogICAgQ09VTlQoKikgQVMgJ1JlZmVyZW5jaWFzJywKICAgIEdST1VQX0NPTkNBVChESVNUSU5DVCBmcC52YWxvciBTRVBBUkFUT1IgJzsgJykgQVMgJ0VkaXRvcmlhbGVzJwpGUk9NIGJpYnRleCBiCkpPSU4gYmlidGV4X2NhbXBvIGZsIE9OIGZsLmlkX2JpYnRleCA9IGIuaWQgQU5EIGZsLmNhbXBvID0gJ2xvY2F0aW9uJwpMRUZUIEpPSU4gYmlidGV4X2NhbXBvIGZwIE9OIGZwLmlkX2JpYnRleCA9IGIuaWQgQU5EIGZwLmNhbXBvID0gJ3B1Ymxpc2hlcicKR1JPVVAgQlkgZmwudmFsb3IKT1JERVIgQlkgQ09VTlQoKikgREVTQwpMSU1JVCAyMDs=
"

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

# group_concat_max_len: EL VALOR POR OMISIÓN (1024) CORTA SIN ERROR LAS
# LISTAS DE COLUMNAS DE bibtex, QUE PASAN DE 1.500 CARACTERES
mysql_adm() {
  $SUDO mysql --default-character-set=utf8mb4 \
    --init-command="SET SESSION group_concat_max_len = 1073741824" "$@"
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

# LAS LÍNEAS DEL CATÁLOGO, SIN LAS VACÍAS
lineas_catalogo() {
  printf '%s\n' "$CATALOGO" | grep -v '^$'
}

# LO QUE IGUALA LA BASE CON EL BASELINE 2.0.0 FUERA DE LA BIBLIOGRAFÍA:
# formatos_pdf Y LAS CONSULTAS CANÓNICAS. ES IDEMPOTENTE Y CORRE TAMBIÉN
# CUANDO LA BIBLIOGRAFÍA YA ESTABA MIGRADA: UNA CORRIDA CORTADA DESPUÉS DE
# BORRAR LAS COLUMNAS LO TERMINA EN LA SIGUIENTE
igualar_resto() {
  # --- 11 BIS. formatos_pdf CON LA COLACIÓN DEL PROYECTO ---
  # UNA COLUMNA utf8mb4_0900_ai_ci COMPARADA CON UNA utf8mb4_unicode_ci DA
  # «Illegal mix of collations» (MISMA FAMILIA QUE GV-175). SOLO SI HACE FALTA
  if [ "$(valor "SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA='${DB}' AND TABLE_NAME='formatos_pdf' AND COLLATION_NAME IS NOT NULL AND COLLATION_NAME <> 'utf8mb4_unicode_ci';")" != "0" ]; then
    mysql_adm "$DB" -e "ALTER TABLE formatos_pdf CONVERT TO CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"
    ok "formatos_pdf pasó a utf8mb4_unicode_ci."
  fi

  # --- 11 TER. LAS CONSULTAS CANÓNICAS DE BIBLIOGRAFÍA ---
  # SIN ESTO, AL ABRIRLAS DARÍAN «Unknown column». SE ESCRIBEN SIEMPRE: EL
  # UPDATE CON EL MISMO TEXTO NO CAMBIA NADA (IDEMPOTENTE)
  if [ "$(existe_tabla consultas)" = "1" ]; then
    N_CONSULTAS=0
    while IFS='|' read -r nombre b64; do
      [ -z "$nombre" ] && continue
      mysql_adm "$DB" -e "UPDATE consultas SET editor_consultas = CONVERT(FROM_BASE64('${b64}') USING utf8mb4) WHERE nombre LIKE '${nombre}:%';"
      N_CONSULTAS=$((N_CONSULTAS + $(valor "SELECT COUNT(*) FROM \`${DB}\`.consultas WHERE nombre LIKE '${nombre}:%';")))
    done < <(printf '%s\n' "$CONSULTAS_BIB" | grep -v '^$')
    ok "Consultas canónicas de bibliografía reescritas: ${N_CONSULTAS}."
  fi
}

# --- 1. BIENVENIDA ---
echo
echo "${NEGRITA}Actualización del esquema de gbpublisher a 2.0.0${RESET}"
echo "--------------------------------------------------"
echo "Pasa la bibliografía a entradas y pares campo/valor: cada referencia"
echo "guarda solo los campos que tienen dato. El .bib de cada proyecto sale"
echo "igual que antes; el script lo comprueba antes de borrar nada."
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

# UNA BASE INSTALADA DESDE EL BASELINE 2.0.0 YA TIENE ESTE CAMBIO: NO HAY
# NADA QUE HACER (Y NO TIENE REGISTRADA LA 1.34.0, QUE EL BASELINE INCLUYE)
if [ "$(valor "SELECT COUNT(*) FROM \`${DB}\`.esquema_version WHERE parche='baseline-2.0.0';")" = "1" ]; then
  ok "La base se instaló desde el baseline 2.0.0, que ya incluye esta actualización. No se modificó nada."
  exit 0
fi

# LA CADENA ES ORDENADA: 2.0.0 VA SOBRE 1.34.0
if [ "$(valor "SELECT COUNT(*) FROM \`${DB}\`.esquema_version WHERE parche='${PREVIO}';")" != "1" ]; then
  error "Falta la actualización 1.34.0. Aplicala primero (actualizar-esquema-1.34.0.sh)."
  exit 1
fi

if [ "$(existe_tabla bibtex)" != "1" ]; then
  error "No existe la tabla bibtex. No se modificó nada."
  exit 1
fi

if [ "$(lineas_catalogo | wc -l)" -ne "$CATALOGO_N" ]; then
  error "El catálogo del script no tiene ${CATALOGO_N} campos. No se modificó nada."
  exit 1
fi

# --- 3. ESTADO REAL ---
# LA MARCA ES LA COLUMNA title: MIENTRAS ESTÉ, LAS COLUMNAS VIEJAS NO SE
# BORRARON. UNA CORRIDA CORTADA DESPUÉS DE COPIAR Y ANTES DE BORRAR SE
# RETOMA DESDE LA COPIA (APARTADO 9 VACÍA bibtex_campo ANTES DE COPIAR)
if [ "$(existe_columna bibtex title)" = "1" ]; then
  SOLO_INFORME=0
else
  if [ "$(existe_tabla bibtex_campo)" != "1" ] || [ "$(existe_tabla bibtex_campo_catalogo)" != "1" ]; then
    error "bibtex ya no tiene las columnas viejas, pero faltan las tablas nuevas."
    error "La base quedó en un estado que este script no sabe completar. No se modificó nada."
    exit 1
  fi
  ok "La bibliografía ya está en pares campo/valor."
  SOLO_INFORME=1
fi

if [ "$SOLO_INFORME" -eq 0 ]; then

  # --- 4. NINGUNA COLUMNA DESCONOCIDA ---
  # UNA COLUMNA QUE NO ESTÁ EN EL CATÁLOGO SE PERDERÍA AL BORRAR. SE CONSULTA
  # LA BASE Y NO SE SUPONE: OTRA INSTALACIÓN PUDO AGREGAR UNA A MANO
  CONOCIDAS="${QUEDAN_SQL},'id_articulo','lang_id'"
  while IFS='|' read -r campo literal columna; do
    CONOCIDAS="${CONOCIDAS},'${columna}'"
  done < <(lineas_catalogo)
  AJENAS="$(valor "SELECT GROUP_CONCAT(COLUMN_NAME ORDER BY ORDINAL_POSITION SEPARATOR ', ')
    FROM information_schema.COLUMNS
    WHERE TABLE_SCHEMA='${DB}' AND TABLE_NAME='bibtex' AND COLUMN_NAME NOT IN (${CONOCIDAS});")"
  if [ -n "$AJENAS" ] && [ "$AJENAS" != "NULL" ]; then
    error "bibtex tiene columnas que el catálogo no conoce: ${AJENAS}"
    error "No se modificó nada. Hay que revisarlo antes de seguir."
    exit 1
  fi

  # Y AL REVÉS: TODAS LAS DEL CATÁLOGO TIENEN QUE ESTAR, EN EL MISMO ORDEN.
  # EL ORDEN DE LAS COLUMNAS ES EL DEL .bib; SI NO COINCIDE, EL .bib
  # CAMBIARÍA DE ORDEN Y LA PRUEBA DEL APARTADO 10 LO DETECTARÍA TARDE
  ORDEN_BASE="$(valor "SELECT GROUP_CONCAT(COLUMN_NAME ORDER BY ORDINAL_POSITION SEPARATOR ' ')
    FROM information_schema.COLUMNS
    WHERE TABLE_SCHEMA='${DB}' AND TABLE_NAME='bibtex'
      AND COLUMN_NAME NOT IN (${QUEDAN_SQL},'id_articulo','lang_id');")"
  ORDEN_CATALOGO="$(lineas_catalogo | cut -d'|' -f3 | paste -sd' ')"
  if [ "$ORDEN_BASE" != "$ORDEN_CATALOGO" ]; then
    error "Las columnas de bibtex no coinciden con el catálogo, o están en otro orden."
    error "No se modificó nada. Hay que revisarlo antes de seguir."
    exit 1
  fi
  ok "Las columnas de bibtex coinciden con el catálogo (${CATALOGO_N} campos)."

  # NADA FUERA DE bibtex PUEDE APUNTAR A UNA COLUMNA QUE SE BORRA
  AJENAS="$(valor "SELECT GROUP_CONCAT(CONCAT(TABLE_NAME, '.', CONSTRAINT_NAME) SEPARATOR ', ')
    FROM information_schema.KEY_COLUMN_USAGE
    WHERE REFERENCED_TABLE_SCHEMA='${DB}' AND REFERENCED_TABLE_NAME='bibtex'
      AND REFERENCED_COLUMN_NAME <> 'id';")"
  if [ -n "$AJENAS" ] && [ "$AJENAS" != "NULL" ]; then
    error "Hay claves foráneas hacia columnas de bibtex que se borran: ${AJENAS}"
    error "No se modificó nada."
    exit 1
  fi

  # --- 5. LO QUE SE VA A HACER ---
  # LAS EXPRESIONES SE ARMAN UNA VEZ Y SE USAN EN EL CONTEO, EN LA COPIA Y EN
  # LA PRUEBA. «CON DATO» ES NO NULO Y CON ALGO MÁS QUE ESPACIOS: LO MISMO
  # QUE ExportarBibTeX MANDA AL .bib
  EXPR_CONTEO=""
  while IFS='|' read -r campo literal columna; do
    [ -n "$EXPR_CONTEO" ] && EXPR_CONTEO="${EXPR_CONTEO} + "
    EXPR_CONTEO="${EXPR_CONTEO}COALESCE(SUM(\`${columna}\` IS NOT NULL AND TRIM(\`${columna}\`) <> ''), 0)"
  done < <(lineas_catalogo)
  # langid CUENTA UNA VEZ: lang_id SOLO SUMA DONDE hyphenation ESTÁ VACÍA
  EXPR_CONTEO="${EXPR_CONTEO} + COALESCE(SUM((hyphenation IS NULL OR TRIM(hyphenation) = '') AND lang_id IS NOT NULL AND TRIM(lang_id) <> ''), 0)"

  N_ENTRADAS="$(valor "SELECT COUNT(*) FROM \`${DB}\`.bibtex;")"
  N_PARES="$(valor "SELECT ${EXPR_CONTEO} FROM \`${DB}\`.bibtex;")"
  N_PROYECTOS="$(valor "SELECT COUNT(DISTINCT id_proyecto) FROM \`${DB}\`.bibtex;")"
  N_CORREGIR="$(valor "SELECT COUNT(*) FROM \`${DB}\`.bibtex
    WHERE hyphenation IN ('eng','span') OR lang_id IN ('eng','span');")"
  N_ARTICULO="$(valor "SELECT COUNT(*) FROM \`${DB}\`.bibtex WHERE id_articulo <> 0;")"

  info "Referencias: ${N_ENTRADAS}, en ${N_PROYECTOS} proyectos."
  info "Pares campo/valor a crear: ${N_PARES}."
  info "Columnas que salen de bibtex: $(( $(columnas_tabla bibtex) - QUEDAN_N ))."
  if [ "$N_CORREGIR" != "0" ]; then
    info "langid abreviados a corregir (eng → english, span → spanish): ${N_CORREGIR}."
    mysql_adm "$DB" -e "SELECT b.id, b.clave_bibtex, b.hyphenation, b.lang_id, p.nombre AS proyecto
      FROM bibtex b JOIN proyectos p ON p.id = b.id_proyecto
      WHERE b.hyphenation IN ('eng','span') OR b.lang_id IN ('eng','span') ORDER BY b.id;"
  fi
  if [ "$N_ARTICULO" != "0" ]; then
    info "Referencias con id_articulo distinto de 0: ${N_ARTICULO}. Apuntan a la tabla articulos, retirada en la 1.32.0; el dato se pierde."
  fi
  echo
  warn "Esta actualización borra columnas. Se vuelve atrás solo restaurando el respaldo completo."
  warn "Se aplica DESPUÉS de instalar la aplicación nueva: la anterior no arranca sin las columnas viejas."
  read -r -p "Para continuar, escribí SI en mayúsculas: " RESPUESTA
  if [ "$RESPUESTA" != "SI" ]; then
    warn "Cancelado. No se modificó nada."
    exit 0
  fi

  # --- 6. RESPALDO PREVIO VERIFICADO ---
  mkdir -p "$DIR_RESPALDO"
  RESPALDO="${DIR_RESPALDO}/gbpublisher-antes-2.0.0-$(date '+%Y%m%d-%H%M%S').sql"
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
  if ! grep -q "CREATE TABLE \`bibtex\`" "$RESPALDO"; then
    error "El respaldo no contiene la tabla bibtex. No se modificó nada."
    exit 1
  fi
  ok "Respaldo verificado ($(du -h "$RESPALDO" | cut -f1))."

  VOLVER_1="sudo mysql ${DB} -e \"DROP TABLE IF EXISTS bibtex_campo, bibtex_campo_catalogo;\""
  VOLVER_2="sudo mysql ${DB} < ${RESPALDO}"

  # --- 7. EL CATÁLOGO ---
  # LA CLAVE ES EL NOMBRE DEL CAMPO: bibtex_campo LO REFERENCIA, ASÍ QUE UN
  # CAMPO QUE NO ESTÁ EN EL CATÁLOGO NO SE PUEDE GUARDAR
  if [ "$(existe_tabla bibtex_campo_catalogo)" != "1" ]; then
    mysql_adm "$DB" -e "CREATE TABLE bibtex_campo_catalogo (
        campo VARCHAR(32) NOT NULL COMMENT 'Nombre del campo en biblatex',
        orden SMALLINT UNSIGNED NOT NULL COMMENT 'Orden de salida en el .bib',
        literal TINYINT(1) NOT NULL DEFAULT 0 COMMENT '1: se escribe tal cual, sin la regla de las órdenes de LaTeX (SC-57)',
        nombre_anterior VARCHAR(64) DEFAULT NULL COMMENT 'Columna de bibtex hasta la 2.0.0: para leer los JSON viejos',
        PRIMARY KEY (campo),
        UNIQUE KEY uk_orden (orden)
      ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
        COMMENT='Campos de biblatex que admite gbpublisher (2.0.0)';"
    ok "Tabla bibtex_campo_catalogo creada."
  fi

  INSERTS=""
  i=0
  while IFS='|' read -r campo literal columna; do
    i=$((i + 1))
    INSERTS="${INSERTS}INSERT IGNORE INTO bibtex_campo_catalogo (campo, orden, literal, nombre_anterior) VALUES ('${campo}', $((i * 10)), ${literal}, '${columna}');"$'\n'
  done < <(lineas_catalogo)
  mysql_adm "$DB" -e "$INSERTS"
  if [ "$(valor "SELECT COUNT(*) FROM \`${DB}\`.bibtex_campo_catalogo;")" != "$CATALOGO_N" ]; then
    error "El catálogo no quedó con ${CATALOGO_N} campos. Las columnas viejas siguen en su lugar."
    exit 1
  fi
  ok "Catálogo con ${CATALOGO_N} campos."

  # --- 8. LA TABLA DE PARES ---
  # UN PAR POR CAMPO Y ENTRADA. EL CHECK ASEGURA «SIN DATO, SIN FILA»: NO
  # CHOCA CON LAS ACCIONES DE LAS CLAVES (GV-111) PORQUE valor NO ES CLAVE.
  # EL FULLTEXT SE AGREGA DESPUÉS DE LA COPIA (APARTADO 9)
  if [ "$(existe_tabla bibtex_campo)" != "1" ]; then
    mysql_adm "$DB" -e "CREATE TABLE bibtex_campo (
        id_bibtex INT NOT NULL COMMENT 'Entrada (bibtex.id)',
        campo VARCHAR(32) NOT NULL COMMENT 'Campo de biblatex (bibtex_campo_catalogo)',
        valor TEXT NOT NULL,
        PRIMARY KEY (id_bibtex, campo),
        KEY idx_campo_valor (campo, valor(100)),
        CONSTRAINT fk_bibtex_campo_entrada FOREIGN KEY (id_bibtex) REFERENCES bibtex (id)
          ON DELETE CASCADE ON UPDATE CASCADE,
        CONSTRAINT fk_bibtex_campo_catalogo FOREIGN KEY (campo) REFERENCES bibtex_campo_catalogo (campo)
          ON DELETE RESTRICT ON UPDATE CASCADE,
        CONSTRAINT chk_bibtex_campo_valor CHECK (CHAR_LENGTH(TRIM(valor)) > 0)
      ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
        COMMENT='Datos de las referencias: un par por campo con dato (2.0.0)';"
    ok "Tabla bibtex_campo creada."
  fi

  # --- 9. CORRECCIÓN Y COPIA, EN UNA TRANSACCIÓN ---
  # SE VACÍA ANTES DE COPIAR: UNA CORRIDA ANTERIOR CORTADA PUDO DEJAR PARES.
  # LOS VALORES SE COPIAN TAL CUAL; ExportarBibTeX LOS RECORTA AL ESCRIBIR.
  # langid: hyphenation PRIMERO; lang_id SOLO DONDE NO HAY hyphenation. ES
  # LA GUARDA cEmitidos DE ExportarBibTeX: LA PRIMERA COLUMNA GANA
  COPIA="START TRANSACTION;
UPDATE bibtex SET hyphenation = CASE hyphenation WHEN 'eng' THEN 'english' WHEN 'span' THEN 'spanish' END
  WHERE hyphenation IN ('eng','span');
UPDATE bibtex SET lang_id = CASE lang_id WHEN 'eng' THEN 'english' WHEN 'span' THEN 'spanish' END
  WHERE lang_id IN ('eng','span');
DELETE FROM bibtex_campo;
"
  while IFS='|' read -r campo literal columna; do
    COPIA="${COPIA}INSERT INTO bibtex_campo (id_bibtex, campo, valor) SELECT id, '${campo}', \`${columna}\` FROM bibtex WHERE \`${columna}\` IS NOT NULL AND TRIM(\`${columna}\`) <> '';"$'\n'
  done < <(lineas_catalogo)
  COPIA="${COPIA}INSERT INTO bibtex_campo (id_bibtex, campo, valor) SELECT id, 'langid', lang_id FROM bibtex
  WHERE lang_id IS NOT NULL AND TRIM(lang_id) <> '' AND (hyphenation IS NULL OR TRIM(hyphenation) = '');
COMMIT;"
  mysql_adm "$DB" -e "$COPIA"

  COPIADOS="$(valor "SELECT COUNT(*) FROM \`${DB}\`.bibtex_campo;")"
  if [ "$COPIADOS" != "$N_PARES" ]; then
    error "Se copiaron ${COPIADOS} pares y se esperaban ${N_PARES}. Las columnas viejas siguen en su lugar."
    mysql_adm "$DB" -e "DELETE FROM bibtex_campo;"
    exit 1
  fi
  ok "Pares copiados: ${COPIADOS}."

  # EL FULLTEXT REEMPLAZA A ft_bibtex_busqueda (m_BuscarBib FILTRA POR campo).
  # SE CREA SOBRE LOS PARES YA COPIADOS: CREADO ANTES, LA CARGA MASIVA EN UNA
  # TRANSACCIÓN DEJÓ TODAS LAS RELEVANCIAS EN 0 HASTA UN OPTIMIZE (MEDIDO EN
  # MySQL 8.0.46 CON LOS DATOS DE ALBERTO, 20/11/2026)
  if [ "$(valor "SELECT COUNT(*) FROM information_schema.STATISTICS WHERE TABLE_SCHEMA='${DB}' AND TABLE_NAME='bibtex_campo' AND INDEX_NAME='ft_bibtex_campo_valor';")" = "0" ]; then
    mysql_adm "$DB" -e "ALTER TABLE bibtex_campo ADD FULLTEXT KEY ft_bibtex_campo_valor (valor);"
    ok "Índice FULLTEXT de bibtex_campo creado."
  fi

  # --- 10. PRUEBA: EL .bib DE CADA PROYECTO, ANTES Y DESPUÉS ---
  # VIEJO: CADA ENTRADA ARMADA DESDE LAS COLUMNAS, EN EL ORDEN DE LAS
  # COLUMNAS. NUEVO: DESDE LOS PARES, EN EL ORDEN DEL CATÁLOGO. LAS
  # ENTRADAS VAN ORDENADAS POR CLAVE, COMO EN ExportarBibTeX. LO QUE NO
  # DEPENDE DE LOS DATOS (SANGRÍA, ALINEACIÓN, FIRMA) NO ENTRA: LO PONE EL
  # CÓDIGO AL ESCRIBIR
  VIEJO=""
  while IFS='|' read -r campo literal columna; do
    if [ "$campo" = "langid" ]; then
      EXPR="COALESCE(IF(hyphenation IS NOT NULL AND TRIM(hyphenation) <> '', hyphenation, NULL), IF(lang_id IS NOT NULL AND TRIM(lang_id) <> '', lang_id, NULL))"
    else
      EXPR="IF(\`${columna}\` IS NOT NULL AND TRIM(\`${columna}\`) <> '', \`${columna}\`, NULL)"
    fi
    [ -n "$VIEJO" ] && VIEJO="${VIEJO}, "
    VIEJO="${VIEJO}CONCAT(CHAR(10), '${campo}=', ${EXPR})"
  done < <(lineas_catalogo)

  # SI LA CONSULTA MISMA FALLA, ES UNA FALLA DE LA PRUEBA: SE DESHACE LA COPIA
  # COMO SI HUBIERA DIFERENCIAS (set -e CORTARÍA SIN VACIAR LOS PARES)
  if ! DIFIEREN="$(mysql_adm "$DB" -N -B -r <<SQL
SET SESSION group_concat_max_len = 1073741824;
CREATE TEMPORARY TABLE _huella_vieja AS
  SELECT id_proyecto, COUNT(*) AS n,
    SHA2(GROUP_CONCAT(texto ORDER BY clave_bibtex, id SEPARATOR '\n'), 256) AS huella
  FROM (SELECT id, id_proyecto, clave_bibtex,
          CONCAT('@', COALESCE(tipo_de_entrada, ''), '{', COALESCE(clave_bibtex, ''), ',', CONCAT_WS('', ${VIEJO})) AS texto
        FROM bibtex) v
  GROUP BY id_proyecto;
CREATE TEMPORARY TABLE _huella_nueva AS
  SELECT b.id_proyecto, COUNT(*) AS n,
    SHA2(GROUP_CONCAT(CONCAT('@', COALESCE(b.tipo_de_entrada, ''), '{', COALESCE(b.clave_bibtex, ''), ',', COALESCE(p.campos, ''))
      ORDER BY b.clave_bibtex, b.id SEPARATOR '\n'), 256) AS huella
  FROM bibtex b
  LEFT JOIN (SELECT c.id_bibtex,
               GROUP_CONCAT(CONCAT(CHAR(10), c.campo, '=', c.valor) ORDER BY k.orden SEPARATOR '') AS campos
             FROM bibtex_campo c JOIN bibtex_campo_catalogo k ON k.campo = c.campo
             GROUP BY c.id_bibtex) p ON p.id_bibtex = b.id
  GROUP BY b.id_proyecto;
SELECT CONCAT(pr.nombre, ' (id ', v.id_proyecto, ')')
  FROM _huella_vieja v
  LEFT JOIN _huella_nueva n ON n.id_proyecto = v.id_proyecto
  LEFT JOIN proyectos pr ON pr.id = v.id_proyecto
  WHERE n.huella IS NULL OR n.huella <> v.huella OR n.n <> v.n;
SQL
)"; then
    DIFIEREN="(la consulta de la prueba falló)"
  fi
  if [ -n "$DIFIEREN" ]; then
    error "El contenido del .bib cambia en estos proyectos:"
    echo "$DIFIEREN" | sed 's/^/    /' >&2
    mysql_adm "$DB" -e "DELETE FROM bibtex_campo;"
    error "Se vaciaron los pares; las columnas viejas siguen en su lugar y la base funciona como antes."
    error "No se registra la actualización. Hay que revisarlo antes de seguir."
    exit 1
  fi
  ok "Prueba del .bib: los ${N_PROYECTOS} proyectos dan el mismo contenido antes y después."

  # --- 11. LAS COLUMNAS VIEJAS ---
  # UN SOLO ALTER: EN MySQL 8 EL DDL ES ATÓMICO, ASÍ QUE SALEN TODAS O
  # NINGUNA. EL FULLTEXT SE BORRA EXPLÍCITO; LOS DEMÁS ÍNDICES DE ESAS
  # COLUMNAS SE VAN CON ELLAS
  BORRAR="$(valor "SELECT GROUP_CONCAT(CONCAT('DROP COLUMN \`', COLUMN_NAME, '\`') ORDER BY ORDINAL_POSITION SEPARATOR ', ')
    FROM information_schema.COLUMNS
    WHERE TABLE_SCHEMA='${DB}' AND TABLE_NAME='bibtex' AND COLUMN_NAME NOT IN (${QUEDAN_SQL});")"
  FT=""
  if [ "$(valor "SELECT COUNT(*) FROM information_schema.STATISTICS WHERE TABLE_SCHEMA='${DB}' AND TABLE_NAME='bibtex' AND INDEX_NAME='ft_bibtex_busqueda';")" != "0" ]; then
    FT="DROP INDEX ft_bibtex_busqueda, "
  fi
  mysql_adm "$DB" -e "ALTER TABLE bibtex ${FT}${BORRAR};"
  ok "Columnas viejas borradas de bibtex."

  # --- 11 BIS Y 11 TER: formatos_pdf Y LAS CONSULTAS (FUNCIÓN igualar_resto) ---
  igualar_resto

  # --- 12. VERIFICACIÓN POSTERIOR ---
  FALLA=0
  QUEDARON="$(valor "SELECT GROUP_CONCAT(COLUMN_NAME ORDER BY ORDINAL_POSITION SEPARATOR ',')
    FROM information_schema.COLUMNS WHERE TABLE_SCHEMA='${DB}' AND TABLE_NAME='bibtex';")"
  if [ "$QUEDARON" != "id,id_proyecto,tipo_de_entrada,clave_bibtex,fecha_modificacion,id_origen" ]; then
    error "bibtex quedó con estas columnas: ${QUEDARON}"
    FALLA=1
  fi
  if [ "$(valor "SELECT COUNT(*) FROM \`${DB}\`.bibtex;")" != "$N_ENTRADAS" ]; then
    error "Cambió la cantidad de referencias."
    FALLA=1
  fi
  if [ "$(valor "SELECT COUNT(*) FROM \`${DB}\`.bibtex_campo;")" != "$N_PARES" ]; then
    error "Cambió la cantidad de pares."
    FALLA=1
  fi
  if [ "$(valor "SELECT COUNT(*) FROM \`${DB}\`.bibtex_campo_catalogo;")" != "$CATALOGO_N" ]; then
    error "El catálogo no tiene ${CATALOGO_N} campos."
    FALLA=1
  fi
  if [ "$(valor "SELECT COUNT(*) FROM information_schema.STATISTICS WHERE TABLE_SCHEMA='${DB}' AND TABLE_NAME='bibtex_campo' AND INDEX_NAME='ft_bibtex_campo_valor';")" = "0" ]; then
    error "Falta el índice FULLTEXT de bibtex_campo."
    FALLA=1
  fi
  if [ "$(valor "SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA='${DB}' AND TABLE_NAME='formatos_pdf' AND COLLATION_NAME IS NOT NULL AND COLLATION_NAME <> 'utf8mb4_unicode_ci';")" != "0" ]; then
    error "formatos_pdf sigue con otra colación."
    FALLA=1
  fi
  if [ "$FALLA" = "1" ]; then
    error "NO se registra la actualización. Para volver atrás:"
    error "  ${VOLVER_1}"
    error "  ${VOLVER_2}"
    exit 1
  fi
  ok "Verificación correcta."

  # --- 13. REGISTRO ---
  mysql_adm "$DB" -e "INSERT IGNORE INTO esquema_version (parche, descripcion) VALUES ('${PARCHE}', '${DESCRIPCION}');"
  ok "Registrado en esquema_version como ${PARCHE}."
  info "Para volver atrás (pisa lo trabajado después), en este orden:"
  echo "  ${VOLVER_1}"
  echo "  ${VOLVER_2}"

else
  # YA ESTABA: SE COMPLETA LO QUE PUDO QUEDAR PENDIENTE Y SE REGISTRA PARA
  # QUE EL NIVEL DECLARADO REFLEJE EL ESTADO REAL
  igualar_resto
  if [ "$(valor "SELECT COUNT(*) FROM \`${DB}\`.esquema_version WHERE parche='${PARCHE}';")" = "0" ]; then
    mysql_adm "$DB" -e "INSERT INTO esquema_version (parche, descripcion) VALUES ('${PARCHE}', '${DESCRIPCION}');"
    ok "Ya estaba aplicada; registrado en esquema_version como ${PARCHE}."
  fi
fi

# --- 14. INFORME DE CONTROL (SOLO LECTURA) ---
# LISTA LO QUE CONVIENE MIRAR A MANO. NO CORRIGE NADA
echo
info "Informe de control (solo lectura):"

# langid QUE NO ES UN NOMBRE DE babel. EL CATÁLOGO idiomas SE GENERÓ DESDE
# LOS .ini DE babel DE ESTA INSTALACIÓN (m_GenerarPDFLibro.CodigoABabel)
if [ "$(existe_tabla idiomas)" = "1" ]; then
  N="$(valor "SELECT COUNT(*) FROM \`${DB}\`.bibtex_campo
    WHERE campo IN ('langid','language','origlanguage') AND valor NOT IN (SELECT babel FROM \`${DB}\`.idiomas);")"
  if [ "$N" = "0" ]; then
    ok "langid, language y origlanguage: todos los valores son nombres de babel."
  else
    warn "Valores de idioma que no son nombres de babel (${N}):"
    mysql_adm "$DB" -e "SELECT b.id, b.clave_bibtex, c.campo, c.valor, p.nombre AS proyecto
      FROM bibtex_campo c JOIN bibtex b ON b.id = c.id_bibtex JOIN proyectos p ON p.id = b.id_proyecto
      WHERE c.campo IN ('langid','language','origlanguage') AND c.valor NOT IN (SELECT babel FROM idiomas)
      ORDER BY b.id, c.campo;"
  fi
fi

# CLAVES DE 32 CARACTERES: EL LÍMITE DEL CONTROL. PUDIERON PERDER EL FINAL
N="$(valor "SELECT COUNT(*) FROM \`${DB}\`.bibtex WHERE CHAR_LENGTH(clave_bibtex) = 32;")"
if [ "$N" != "0" ]; then
  warn "Claves de 32 caracteres, el máximo: pudieron perder el final (${N}):"
  mysql_adm "$DB" -e "SELECT b.id, b.clave_bibtex, p.nombre AS proyecto
    FROM bibtex b JOIN proyectos p ON p.id = b.id_proyecto
    WHERE CHAR_LENGTH(b.clave_bibtex) = 32 ORDER BY b.id;"
fi

# SALTOS DE LÍNEA DENTRO DE UN VALOR: SUELEN VENIR DE UN PEGADO
N="$(valor "SELECT COUNT(*) FROM \`${DB}\`.bibtex_campo WHERE valor REGEXP '[[:cntrl:]]';")"
if [ "$N" != "0" ]; then
  warn "Valores con saltos de línea u otros caracteres de control (${N}):"
  mysql_adm "$DB" -e "SELECT b.id, b.clave_bibtex, c.campo, p.nombre AS proyecto
    FROM bibtex_campo c JOIN bibtex b ON b.id = c.id_bibtex JOIN proyectos p ON p.id = b.id_proyecto
    WHERE c.valor REGEXP '[[:cntrl:]]' ORDER BY b.id, c.campo;"
fi

# CONSULTAS GUARDADAS QUE NOMBRAN TABLAS RETIRADAS (articulos Y revistas_md,
# 1.32.0): FALLAN AL ABRIRLAS. NO SON DE LA BIBLIOGRAFÍA: SE LISTAN
if [ "$(existe_tabla consultas)" = "1" ]; then
  N="$(valor "SELECT COUNT(*) FROM \`${DB}\`.consultas WHERE editor_consultas REGEXP '\\\\b(articulos|revistas_md|articulo_autor|articulo_revisor)\\\\b';")"
  if [ "$N" != "0" ]; then
    warn "Consultas guardadas que usan tablas retiradas en la 1.32.0 (${N}): fallan al abrirlas."
    mysql_adm "$DB" -e "SELECT id, nombre FROM consultas WHERE editor_consultas REGEXP '\\\\b(articulos|revistas_md|articulo_autor|articulo_revisor)\\\\b' ORDER BY id;"
  fi
fi

echo
ok "${NEGRITA}Actualización 2.0.0 lista.${RESET}"
