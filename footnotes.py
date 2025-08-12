# Organizar footnotes en MD
import sys
import re
from pathlib import Path
import shutil

# Obtener directorio del proyecto desde argumentos
if len(sys.argv) > 1:
    directorio_raiz = Path(sys.argv[1])
else:
    directorio_raiz = Path(".")

print(f"Organizando footnotes en: {directorio_raiz.absolute()}")
print()

# Buscar específicamente en la carpeta articulos
carpeta_articulos = directorio_raiz / "articulos"

if not carpeta_articulos.exists():
    print("ERROR: No se encontró la carpeta 'articulos' en el directorio del proyecto")
    sys.exit(1)

archivos_encontrados = 0
archivos_modificados = 0
total_inconsistencias = 0
archivos_backup = []  # Lista para rastrear archivos de backup creados

def procesar_footnotes(contenido):
    """
    Procesa el contenido del archivo para organizar footnotes
    """
    lineas = contenido.split('\n')

    # Extraer referencias a footnotes en el texto [^1], [^nota], etc.
    referencias = set()
    for linea in lineas:
        matches = re.findall(r'\[\^([^\]]+)\](?!\:)', linea)
        referencias.update(matches)

    # Extraer definiciones de footnotes existentes [^1]: texto
    footnotes_existentes = {}
    lineas_sin_footnotes = []

    for linea in lineas:
        match = re.match(r'^\[\^([^\]]+)\]:\s*(.*)$', linea.strip())
        if match:
            nota_id = match.group(1)
            texto_nota = match.group(2)
            footnotes_existentes[nota_id] = texto_nota
        else:
            lineas_sin_footnotes.append(linea)

    # Verificar correlación
    inconsistencias = []

    # Referencias sin definición
    referencias_sin_definicion = referencias - footnotes_existentes.keys()
    for ref in referencias_sin_definicion:
        inconsistencias.append(f"Referencia '[^{ref}]' sin definición")

    # Definiciones sin referencias
    definiciones_sin_referencia = footnotes_existentes.keys() - referencias
    for def_id in definiciones_sin_referencia:
        inconsistencias.append(f"Definición '[^{def_id}]:' sin referencia en el texto")

    # Crear contenido reorganizado
    contenido_nuevo = '\n'.join(lineas_sin_footnotes)

    # Agregar footnotes al final si existen
    if footnotes_existentes:
        # Remover líneas vacías al final
        contenido_nuevo = contenido_nuevo.rstrip('\n')

        # Agregar separador y footnotes
        contenido_nuevo += '\n\n---\n\n'

        # Ordenar footnotes: primero números, luego alfabético
        def ordenar_footnotes(item):
            nota_id = item[0]
            # Intentar convertir a número, si no es posible usar string
            try:
                return (0, int(nota_id))  # Números primero
            except ValueError:
                return (1, nota_id.lower())  # Strings después

        footnotes_ordenados = sorted(footnotes_existentes.items(), key=ordenar_footnotes)

        for nota_id, texto_nota in footnotes_ordenados:
            contenido_nuevo += f'[^{nota_id}]: {texto_nota}\n'

    return contenido_nuevo, inconsistencias, len(footnotes_existentes)

# Recorremos todos los archivos .md en la carpeta articulos
for archivo in carpeta_articulos.rglob("*.md"):
    # Saltar archivos que ya son backup
    if archivo.name.startswith("orig-"):
        continue

    archivos_encontrados += 1
    print(f"Archivo: {archivo.relative_to(directorio_raiz)}")

    try:
        contenido_original = archivo.read_text(encoding="utf-8")
        contenido_nuevo, inconsistencias, num_footnotes = procesar_footnotes(contenido_original)

        # Reportar inconsistencias
        if inconsistencias:
            for inconsistencia in inconsistencias:
                print(f"  INCONSISTENCIA: {inconsistencia}")
            total_inconsistencias += len(inconsistencias)

        # Verificar si el contenido cambió
        if contenido_nuevo != contenido_original:
            # Crear archivo de backup
            archivo_backup = archivo.parent / f"orig-{archivo.name}"
            shutil.copy2(archivo, archivo_backup)
            archivos_backup.append(archivo_backup)
            print(f"  BACKUP: Creado {archivo_backup.name}")

            # Escribir archivo modificado
            archivo.write_text(contenido_nuevo, encoding="utf-8")
            archivos_modificados += 1
            print(f"  MODIFICADO: {num_footnotes} footnote(s) reorganizado(s)")
        else:
            if num_footnotes > 0:
                print(f"  OK: {num_footnotes} footnote(s) ya están organizados")
            else:
                print(f"  OK: No contiene footnotes")

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
    if total_inconsistencias > 0:
        print(f"Total de inconsistencias encontradas: {total_inconsistencias}")
    else:
        print("No se encontraron inconsistencias en los footnotes")

# Informar sobre archivos de backup creados
if archivos_backup:
    print()
    print(f"Se crearon {len(archivos_backup)} archivo(s) de backup:")
    for archivo_backup in archivos_backup:
        print(f"  {archivo_backup.relative_to(directorio_raiz)}")
    print()
    print("IMPORTANTE: Revisa los cambios y elimina manualmente los archivos orig-*.md cuando estés conforme")

# Mover archivos de backup a carpeta respaldo
if archivos_backup:
    carpeta_respaldo = carpeta_articulos / "respaldo"

    # Crear carpeta respaldo si no existe
    if not carpeta_respaldo.exists():
        carpeta_respaldo.mkdir(parents=True, exist_ok=True)
        print(f"Carpeta creada: {carpeta_respaldo.relative_to(directorio_raiz)}")

    # Mover archivos backup
    archivos_movidos = []
    for archivo_backup in archivos_backup:
        destino = carpeta_respaldo / archivo_backup.name

        # Si ya existe un archivo con el mismo nombre, crear uno único
        contador = 1
        destino_original = destino
        while destino.exists():
            nombre_sin_ext = destino_original.stem
            extension = destino_original.suffix
            destino = carpeta_respaldo / f"{nombre_sin_ext}_{contador}{extension}"
            contador += 1

        shutil.move(str(archivo_backup), str(destino))
        archivos_movidos.append(destino)

    print(f"\nArchivos de backup movidos a respaldo/:")
    for archivo_movido in archivos_movidos:
        print(f"  {archivo_movido.relative_to(directorio_raiz)}")

    print(f"\nIMPORTANTE: Los archivos de respaldo están en {carpeta_respaldo.relative_to(directorio_raiz)}/")
    print("Revisa los cambios y elimina manualmente los archivos de respaldo cuando estés conforme")
