# Soporte oficial

## Alcance del soporte (Linux Mint - Cinnamon)

Esta aplicación está diseñada y probada **exclusivamente** en entornos **Linux Mint** con el escritorio **Cinnamon**.
El soporte oficial se limita a esta plataforma, garantizando funcionamiento correcto y consistencia visual en ellas.

No se ofrece soporte oficial para otros escritorios o distribuciones, aunque la aplicación podría ejecutarse en entornos similares.

## Justificación técnica

### 1. Integración con entornos GTK
Cinnamon está basado en **GTK**.
Esto asegura que:
- La apariencia de la aplicación respete los temas, iconos y estilos del sistema.
- No se requieran dependencias adicionales para integrar visualmente la interfaz.
- Se eviten inconsistencias entre el tema del sistema y la aplicación.

### 2. Exclusión de componentes Qt en Gambas
Aunque Gambas permite trabajar con componentes Qt (`gb.qt5`, `gb.qt6`, etc.), esta aplicación **no los utiliza** por motivos de:
- **Coherencia visual**: evitar diferencias de estilo entre widgets Qt y GTK en entornos GTK.
- **Minimización de dependencias**: no añadir bibliotecas Qt que el sistema objetivo no requiere por defecto.
- **Mantenimiento simplificado**: eliminar la necesidad de compatibilidad cruzada entre Qt 5 y Qt 6.

### 3. Estabilidad y ciclo de actualizaciones de Linux Mint
Linux Mint es reconocido por su:
- **Estabilidad a largo plazo** y actualizaciones no disruptivas.
- Políticas para evitar cambios drásticos de librerías sin un período de transición.
- Uso prolongado de GTK 3 en Cinnamon, evitando rupturas de compatibilidad frecuentes.

Esto permite que el desarrollo se centre en **estabilidad** y **funcionalidad**, sin tener que rehacer partes de la aplicación ante cambios bruscos en las librerías gráficas.

## Nota sobre otros entornos
La aplicación puede ejecutarse en otros escritorios basados en GTK (ej. MATE, GNOME, Xfce) o en otras distribuciones, pero fuera del entorno oficial de Linux Mint:
- No se garantiza compatibilidad visual total.
- El funcionamiento no está probado.
- Los reportes de errores en entornos no soportados se considerarán de **baja prioridad**.

## Conclusión
El uso exclusivo de componentes GTK en Gambas, junto con el soporte oficial limitado a Linux Mint con Cinnamon, es una decisión técnica orientada a:
- Garantizar integración visual completa.
- Reducir dependencias innecesarias.
- Privilegiar mantener estabilidad y coherencia en entornos de producción.
