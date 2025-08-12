# Reemplazador de @rm{} por rayas
import sys
import re
from pathlib import Path
import shutil

# Obtener directorio del proyecto desde argumentos
if len(sys.argv) > 1:
    directorio_raiz = Path(sys.argv[1])
else:
    directorio_raiz = Path(".")

# Configuración: elegir tipo de raya
# Opción 1: Usar dos guiones -- (se convierte automáticamente en guión em)
# Opción 2: Usar directamente el carácter Unicode —
USAR_UNICODE = True  # Cambiar a False para usar --

if USAR_UNICODE:
    RAYA = "—"  # Carácter Unicode para guión em
    tipo_raya = "carácter Unicode (—)"
else:
    RAYA = "--"  # Dos guiones que se convierten automáticamente
    tipo_raya = "doble guión (--)"

print(f"Reemplazando @rm{{}} por rayas en: {directorio_raiz.absolute()}")
print(f"Tipo de raya: {tipo_raya}")
print()

# Buscar específicamente en la carpeta articulos
carpeta_articulos = directorio_raiz / "articulos"

if not carpeta_articulos.exists():
    print("ERROR: No se encontró la carpeta 'articulos' en el directorio del proyecto")
    sys.exit(1)

archivos_encontrados = 0
archivos_modificados = 0
total_reemplazos = 0
archivos_backup = []

def reemplazar_rayas(contenido):
    """
    Reemplaza todas las ocurrencias de @rm{texto} por —texto—
    """
    patron = r'@rm\{([^}]*)\}'
    reemplazos = 0

    def sustituir(match):
        nonlocal reemplazos
        texto_interno = match.group(1)
        reemplazos += 1
        return f"{RAYA}{texto_interno}{RAYA}"

    contenido_nuevo = re.sub(patron, sustituir, contenido)
    return contenido_nuevo, reemplazos

# Recorremos todos los archivos .md en la carpeta articulos
for archivo in carpeta_articulos.rglob("*.md"):
    # Saltar archivos que ya son backup
    if archivo.name.startswith("orig-"):
        continue

    archivos_encontrados += 1
    print(f"Archivo: {archivo.relative_to(directorio_raiz)}")

    try:
        contenido_original = archivo.read_text(encoding="utf-8")
        contenido_nuevo, reemplazos = reemplazar_rayas(contenido_original)

        if reemplazos > 0:
            # Crear archivo de backup
            archivo_backup = archivo.parent / f"orig-{archivo.name}"
            shutil.copy2(archivo, archivo_backup)
            archivos_backup.append(archivo_backup)
            print(f"  BACKUP: Creado {archivo_backup.name}")

            # Escribir archivo modificado
            archivo.write_text(contenido_nuevo, encoding="utf-8")
            archivos_modificados += 1
            total_reemplazos += reemplazos
            print(f"  MODIFICADO: {reemplazos} reemplazo(s) @rm{{}} → {RAYA}texto{RAYA}")
        else:
            print(f"  OK: No se encontraron patrones @rm{{}}")

        print()

    except Exception as e:
        print(f"  Error al procesar archivo: {e}")
        print()

# Resumen general
if archivos_encontrados == 0:
    print("No se encontraron archivos .md en la carpeta articulos")
else:
    print(f"Procesados {archivos_encontrados} archivos")
    print(f"Archivos modificados: {archivos_modificados}")
    print(f"Total de reemplazos realizados: {total_reemplazos}")

# Informar sobre archivos de backup creados
if archivos_backup:
    print()
    print(f"Se crearon {len(archivos_backup)} archivo(s) de backup:")
    for archivo_backup in archivos_backup:
        print(f"  {archivo_backup.relative_to(directorio_raiz)}")
    print()
    print("IMPORTANTE: Revisa los cambios y elimina manualmente los archivos orig-*.md cuando estés conforme")
