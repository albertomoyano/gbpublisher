# Verificador de estructura MD
import sys
from pathlib import Path

# Obtener directorio del proyecto desde argumentos
if len(sys.argv) > 1:
    directorio_raiz = Path(sys.argv[1])
else:
    directorio_raiz = Path(".")

print(f"Verificando estructura Markdown en: {directorio_raiz.absolute()}")
print()

# Buscar específicamente en la carpeta articulos
carpeta_articulos = directorio_raiz / "articulos"

if not carpeta_articulos.exists():
    print("ERROR: No se encontró la carpeta 'articulos' en el directorio del proyecto")
    sys.exit(1)

archivos_encontrados = 0
total_errores = 0

# Recorremos todos los archivos .md en la carpeta articulos
for archivo in carpeta_articulos.rglob("*.md"):
    archivos_encontrados += 1
    print(f"Archivo: {archivo.relative_to(directorio_raiz)}")

    try:
        contenido = archivo.read_text(encoding="utf-8")
        lineas = contenido.split('\n')

        errores_archivo = 0
        nivel_anterior = 0

        # Analizar cada línea
        for num_linea, linea in enumerate(lineas, 1):
            linea_limpia = linea.strip()

            # Verificar encabezados con #
            if linea_limpia.startswith('#'):
                # Contar cuántos # hay al inicio
                nivel_actual = 0
                for char in linea_limpia:
                    if char == '#':
                        nivel_actual += 1
                    else:
                        break

                # Solo considerar niveles válidos (1-6)
                if 1 <= nivel_actual <= 6:
                    texto_encabezado = linea_limpia[nivel_actual:].strip()

                    # Verificar correlatividad
                    if nivel_anterior > 0:  # No es el primer encabezado
                        diferencia = nivel_actual - nivel_anterior

                        if diferencia > 1:  # Salto hacia adelante mayor a 1
                            print(f"  ERROR (línea {num_linea}): Salto de H{nivel_anterior} a H{nivel_actual}")
                            print(f"    Debería ser H{nivel_anterior + 1} como máximo")
                            print(f"    Texto: {texto_encabezado}")
                            errores_archivo += 1
                            total_errores += 1
                        else:
                            print(f"  OK (línea {num_linea}): H{nivel_actual} - {texto_encabezado}")
                    else:
                        # Primer encabezado del archivo
                        if nivel_actual != 1:
                            print(f"  ADVERTENCIA (línea {num_linea}): El primer encabezado es H{nivel_actual}, se recomienda H1")
                            print(f"    Texto: {texto_encabezado}")
                        else:
                            print(f"  OK (línea {num_linea}): H{nivel_actual} - {texto_encabezado}")

                    nivel_anterior = nivel_actual

        # Resumen del archivo
        if errores_archivo == 0:
            print(f"  Resultado: Estructura correcta")
        else:
            print(f"  Resultado: {errores_archivo} error(es) de estructura")
        print()

    except Exception as e:
        print(f"  Error al leer archivo: {e}")
        print()

# Resumen general
if archivos_encontrados == 0:
    print("No se encontraron archivos .md en la carpeta articulos")
else:
    print(f"Procesados {archivos_encontrados} archivos")
    if total_errores == 0:
        print("Todos los archivos tienen estructura correcta")
    else:
        print(f"Total de errores encontrados: {total_errores}")
