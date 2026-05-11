# Reemplazo de comillas en LaTeX (\enquote)
import sys
import re
from pathlib import Path
import shutil

# Obtener archivo .tex desde argumentos
if len(sys.argv) > 1:
    archivo_tex = Path(sys.argv[1])
else:
    print("Error: Debe proporcionar la ruta del archivo .tex")
    sys.exit(1)

if not archivo_tex.exists():
    print(f"Error: El archivo {archivo_tex} no existe")
    sys.exit(1)

print(f"Procesando: {archivo_tex.absolute()}")
print()

# Leer contenido del archivo
try:
    with open(archivo_tex, 'r', encoding='utf-8') as f:
        contenido = f.read()
except Exception as e:
    print(f"Error al leer el archivo: {e}")
    sys.exit(1)

# PASO 0: Normalizar caracteres problemáticos heredados de docx/pandoc
normalizaciones = {
    '´': "'",  # Acento agudo → apóstrofo
    ''': "'",  # Comilla simple izquierda tipográfica
    ''': "'",  # Comilla simple derecha tipográfica
    '"': '"',  # Comilla doble izquierda tipográfica
    '"': '"',  # Comilla doble derecha tipográfica
}

contenido_original = contenido
for char_problema, char_correcto in normalizaciones.items():
    if char_problema in contenido:
        count = contenido.count(char_problema)
        contenido = contenido.replace(char_problema, char_correcto)
        print(f"✓ Normalizados {count} caracteres '{char_problema}' → '{char_correcto}'")

if contenido != contenido_original:
    print()

# Separar en líneas pero procesar por párrafos
lineas_totales = contenido.split('\n')

errores_encontrados = []
lineas_procesadas = []

def procesar_comillas_dobles(texto, linea_inicio):
    """Procesa comillas dobles `` y '' primero en un texto (puede ser multi-línea)"""

    texto_original = texto  # Guardar texto original para calcular posiciones

    # Contar comillas dobles en el texto
    aperturas_dobles = texto.count('``')
    cierres_dobles = texto.count("''")

    # Verificar balance
    if aperturas_dobles != cierres_dobles:
        errores_encontrados.append(
            f"Línea {linea_inicio}: "
            f"Desbalance de comillas dobles en párrafo ({aperturas_dobles} aperturas ``, {cierres_dobles} cierres '')"
        )

    # Identificar todas las posiciones de comillas dobles
    posiciones = []

    # Buscar ``
    for match in re.finditer(r'``', texto):
        posiciones.append((match.start(), 'apertura_doble', match.group()))

    # Buscar ''
    for match in re.finditer(r"''", texto):
        posiciones.append((match.start(), 'cierre_doble', match.group()))

    # Ordenar por posición
    posiciones.sort(key=lambda x: x[0])

    # Procesar con stack para manejar anidamiento
    stack = []
    segmentos = []
    ultima_pos = 0

    for pos, tipo, texto_match in posiciones:
        if tipo == 'apertura_doble':
            # Guardar texto antes de la apertura
            if pos > ultima_pos:
                segmentos.append(('texto', texto[ultima_pos:pos]))

            stack.append(pos)
            ultima_pos = pos + 2

        elif tipo == 'cierre_doble':
            if stack:
                # Hay apertura correspondiente
                pos_apertura = stack.pop()
                contenido_comillas = texto[ultima_pos:pos]

                # Agregar el enquote
                segmentos.append(('enquote', contenido_comillas))
                ultima_pos = pos + 2
            else:
                # Cierre sin apertura - error (usar texto original para posición)
                linea_error = linea_inicio + texto_original[:pos].count('\n')
                col_error = pos - texto_original[:pos].rfind('\n') - 1
                errores_encontrados.append(
                    f"Línea {linea_error}, columna {col_error}: "
                    f"Comilla doble de cierre '' sin apertura"
                )
                segmentos.append(('texto', texto[ultima_pos:pos+2]))
                ultima_pos = pos + 2

    # Verificar stack vacío (aperturas sin cierre) - usar texto original
    if stack:
        for pos_apertura in stack:
            linea_error = linea_inicio + texto_original[:pos_apertura].count('\n')
            col_error = pos_apertura - texto_original[:pos_apertura].rfind('\n') - 1
            errores_encontrados.append(
                f"Línea {linea_error}, columna {col_error}: "
                f"Comilla doble de apertura `` sin cierre"
            )

    # Agregar texto restante
    if ultima_pos < len(texto):
        segmentos.append(('texto', texto[ultima_pos:]))

    # Reconstruir texto
    texto_nuevo = ''
    for tipo_seg, contenido_seg in segmentos:
        if tipo_seg == 'enquote':
            texto_nuevo += f'\\enquote{{{contenido_seg}}}'
        else:
            texto_nuevo += contenido_seg

    return texto_nuevo if segmentos else texto


def procesar_comillas_simples(texto, linea_inicio):
    """Procesa comillas simples ` y ' después de las dobles en un texto (puede ser multi-línea)"""

    texto_original = texto  # Guardar texto original para calcular posiciones

    # Contar comillas simples en el texto
    aperturas_simples = texto.count('`')
    cierres_simples = texto.count("'")

    # Verificar balance
    if aperturas_simples != cierres_simples:
        errores_encontrados.append(
            f"Línea {linea_inicio}: "
            f"Desbalance de comillas simples en párrafo ({aperturas_simples} aperturas `, {cierres_simples} cierres ')"
        )

    # Identificar todas las posiciones de comillas simples
    posiciones = []

    # Buscar `
    for match in re.finditer(r'`', texto):
        posiciones.append((match.start(), 'apertura_simple', match.group()))

    # Buscar '
    for match in re.finditer(r"'", texto):
        posiciones.append((match.start(), 'cierre_simple', match.group()))

    # Ordenar por posición
    posiciones.sort(key=lambda x: x[0])

    # Procesar con stack
    stack = []
    segmentos = []
    ultima_pos = 0

    for pos, tipo, texto_match in posiciones:
        if tipo == 'apertura_simple':
            # Guardar texto antes de la apertura
            if pos > ultima_pos:
                segmentos.append(('texto', texto[ultima_pos:pos]))

            stack.append(pos)
            ultima_pos = pos + 1

        elif tipo == 'cierre_simple':
            if stack:
                # Hay apertura correspondiente
                pos_apertura = stack.pop()
                contenido_comillas = texto[ultima_pos:pos]

                # Agregar el enquote
                segmentos.append(('enquote', contenido_comillas))
                ultima_pos = pos + 1
            else:
                # Cierre sin apertura - error (usar texto original para posición)
                linea_error = linea_inicio + texto_original[:pos].count('\n')
                col_error = pos - texto_original[:pos].rfind('\n') - 1
                errores_encontrados.append(
                    f"Línea {linea_error}, columna {col_error}: "
                    f"Comilla simple de cierre ' sin apertura"
                )
                segmentos.append(('texto', texto[ultima_pos:pos+1]))
                ultima_pos = pos + 1

    # Verificar stack vacío (aperturas sin cierre) - usar texto original
    if stack:
        for pos_apertura in stack:
            linea_error = linea_inicio + texto_original[:pos_apertura].count('\n')
            col_error = pos_apertura - texto_original[:pos_apertura].rfind('\n') - 1
            errores_encontrados.append(
                f"Línea {linea_error}, columna {col_error}: "
                f"Comilla simple de apertura ` sin cierre"
            )

    # Agregar texto restante
    if ultima_pos < len(texto):
        segmentos.append(('texto', texto[ultima_pos:]))

    # Reconstruir texto
    texto_nuevo = ''
    for tipo_seg, contenido_seg in segmentos:
        if tipo_seg == 'enquote':
            texto_nuevo += f'\\enquote{{{contenido_seg}}}'
        else:
            texto_nuevo += contenido_seg

    return texto_nuevo if segmentos else texto


# Procesar por párrafos pero trackear línea global
linea_actual = 1
i = 0

while i < len(lineas_totales):
    # Recolectar líneas del párrafo actual
    parrafo_lineas = []
    linea_inicio_parrafo = linea_actual

    # Recolectar hasta encontrar línea en blanco o fin de archivo
    while i < len(lineas_totales) and lineas_totales[i].strip() != '':
        parrafo_lineas.append(lineas_totales[i])
        i += 1
        linea_actual += 1

    # Si hay contenido en el párrafo, procesarlo
    if parrafo_lineas:
        texto_parrafo = '\n'.join(parrafo_lineas)

        # PASO 1: Procesar comillas dobles primero
        texto_parrafo = procesar_comillas_dobles(texto_parrafo, linea_inicio_parrafo)

        # PASO 2: Procesar comillas simples después
        texto_parrafo = procesar_comillas_simples(texto_parrafo, linea_inicio_parrafo)

        # Separar nuevamente en líneas y agregar
        lineas_procesadas.extend(texto_parrafo.split('\n'))

    # Si encontramos línea en blanco, agregarla
    if i < len(lineas_totales) and lineas_totales[i].strip() == '':
        lineas_procesadas.append(lineas_totales[i])
        i += 1
        linea_actual += 1

# Mostrar errores encontrados
if errores_encontrados:
    print("⚠️  ERRORES ENCONTRADOS:")
    print("-" * 60)
    for error in errores_encontrados:
        print(f"  • {error}")
    print()

# Unir líneas
contenido_final = '\n'.join(lineas_procesadas)

# Crear respaldo del archivo original
archivo_respaldo = archivo_tex.parent / f"{archivo_tex.stem}.respaldo"
try:
    shutil.copy2(archivo_tex, archivo_respaldo)
    print(f"✓ Respaldo creado: {archivo_respaldo}")
except Exception as e:
    print(f"Error al crear respaldo: {e}")
    sys.exit(1)

# Guardar cambios en el archivo original
try:
    with open(archivo_tex, 'w', encoding='utf-8') as f:
        f.write(contenido_final)
    print(f"✓ Archivo modificado: {archivo_tex}")
    print(f"✓ Total de errores reportados: {len(errores_encontrados)}")
except Exception as e:
    print(f"Error al guardar el archivo: {e}")
    sys.exit(1)
