# Detector de repeticiones cercanas
import sys
import re
from pathlib import Path

# Obtener directorio del proyecto desde argumentos
if len(sys.argv) > 1:
    directorio_raiz = Path(sys.argv[1])
else:
    directorio_raiz = Path(".")

print(f"Detectando repeticiones cercanas en: {directorio_raiz.absolute()}")
print()

# Buscar específicamente en la carpeta articulos
carpeta_articulos = directorio_raiz / "articulos"

if not carpeta_articulos.exists():
    print("ERROR: No se encontró la carpeta 'articulos' en el directorio del proyecto")
    sys.exit(1)

archivos_encontrados = 0
total_repeticiones = 0

def encontrar_repeticiones_cercanas(texto, rango_maximo=82):
    """
    Encuentra palabras de 4+ caracteres que se repiten dentro del rango especificado
    """
    repeticiones = []

    # Extraer palabras con sus posiciones
    palabras_con_posicion = []
    for match in re.finditer(r'\b[a-zA-ZáéíóúÁÉÍÓÚñÑüÜ]{4,}\b', texto, re.IGNORECASE):
        palabra = match.group().lower()
        posicion_inicio = match.start()
        posicion_fin = match.end()
        palabras_con_posicion.append((palabra, posicion_inicio, posicion_fin))

    # Buscar repeticiones cercanas
    for i, (palabra1, pos1_inicio, pos1_fin) in enumerate(palabras_con_posicion):
        for j, (palabra2, pos2_inicio, pos2_fin) in enumerate(palabras_con_posicion[i+1:], i+1):
            if palabra1 == palabra2:
                # Calcular distancia desde el final de la primera palabra al inicio de la segunda
                distancia = pos2_inicio - pos1_fin

                if distancia <= rango_maximo:
                    # Encontrar números de línea aproximados
                    linea1 = texto[:pos1_inicio].count('\n') + 1
                    linea2 = texto[:pos2_inicio].count('\n') + 1

                    # Extraer contexto alrededor de cada ocurrencia
                    contexto1_inicio = max(0, pos1_inicio - 20)
                    contexto1_fin = min(len(texto), pos1_fin + 20)
                    contexto1 = texto[contexto1_inicio:contexto1_fin].replace('\n', ' ').strip()

                    contexto2_inicio = max(0, pos2_inicio - 20)
                    contexto2_fin = min(len(texto), pos2_fin + 20)
                    contexto2 = texto[contexto2_inicio:contexto2_fin].replace('\n', ' ').strip()

                    repeticiones.append({
                        'palabra': palabra1,
                        'linea1': linea1,
                        'linea2': linea2,
                        'distancia': distancia,
                        'contexto1': contexto1,
                        'contexto2': contexto2
                    })

                    # Solo reportar la primera repetición cercana de cada palabra
                    break

    return repeticiones

# Recorremos todos los archivos .md en la carpeta articulos
for archivo in carpeta_articulos.rglob("*.md"):
    archivos_encontrados += 1
    print(f"Archivo: {archivo.relative_to(directorio_raiz)}")

    try:
        contenido = archivo.read_text(encoding="utf-8")

        repeticiones = encontrar_repeticiones_cercanas(contenido)

        if repeticiones:
            for rep in repeticiones:
                print(f"  REPETICION: '{rep['palabra']}' (distancia: {rep['distancia']} caracteres)")
                print(f"    Línea {rep['linea1']}: ...{rep['contexto1']}...")
                print(f"    Línea {rep['linea2']}: ...{rep['contexto2']}...")
                print()
                total_repeticiones += 1
        else:
            print(f"  No se encontraron repeticiones cercanas")
            print()

    except Exception as e:
        print(f"  Error al leer archivo: {e}")
        print()

# Resumen general
if archivos_encontrados == 0:
    print("No se encontraron archivos .md en la carpeta articulos")
else:
    print(f"Procesados {archivos_encontrados} archivos")
    print(f"Total de repeticiones cercanas encontradas: {total_repeticiones}")
