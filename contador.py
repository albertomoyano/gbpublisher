# Contador de caracteres par/impar
import sys
from pathlib import Path

# Caracteres a contar
caracteres_a_contar = ['¿', '?', '¡', '!', '(', ')', '[', ']', '{', '}']

# Obtener directorio del proyecto desde argumentos
if len(sys.argv) > 1:
    directorio_raiz = Path(sys.argv[1])
else:
    directorio_raiz = Path(".")

print(f"Analizando archivos .md en: {directorio_raiz.absolute()}")
print()

# Buscar específicamente en la carpeta articulos
carpeta_articulos = directorio_raiz / "articulos"

if not carpeta_articulos.exists():
    print("ERROR: No se encontró la carpeta 'articulos' en el directorio del proyecto")
    sys.exit(1)

archivos_encontrados = 0

# Recorremos todos los archivos .md en la carpeta articulos
for archivo in carpeta_articulos.rglob("*.md"):
    archivos_encontrados += 1
    print(f"Archivo: {archivo.relative_to(directorio_raiz)}")

    try:
        contenido = archivo.read_text(encoding="utf-8")

        for c in caracteres_a_contar:
            cantidad = contenido.count(c)
            print(f"  {c} = {cantidad}")

        print()  # Separador entre archivos

    except Exception as e:
        print(f"  Error al leer archivo: {e}")
        print()

if archivos_encontrados == 0:
    print("No se encontraron archivos .md en la carpeta articulos")
else:
    print(f"Procesados {archivos_encontrados} archivos")
