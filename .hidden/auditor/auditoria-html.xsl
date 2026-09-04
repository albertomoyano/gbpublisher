<?xml version="1.0" encoding="UTF-8"?>
<!--
  auditoria-html.xsl

  Convierte el informe canónico de auditoría en un HTML AUTOCONTENIDO:
  CSS embebido, sin recursos externos, sin tipografías web, sin
  JavaScript. Se abre con doble clic desde un pendrive, sin red, y se
  imprime a PDF desde el navegador con la hoja @media print que trae.
  Por eso no hay una rama LaTeX para este entregable.

  Los TEXTOS no vienen del informe: vienen del catálogo, que se
  resuelve con document(). El informe archivado guarda códigos, así
  que una auditoría de marzo se puede regenerar en septiembre con los
  mensajes mejorados sobre los mismos hechos medidos.

  ORDEN DEL DOCUMENTO, y las razones:
    1. Identificación de la revista
    2. Bloque de defensibilidad
    3. Lo verificado correcto — BREVE. Va arriba porque al final es
       una disculpa y al principio es una credencial, pero corto:
       una sección larga en verde antes de las malas noticias se lee
       como relleno y logra lo contrario de lo que busca.
    4. Resumen por impacto
    5. Hallazgos agrupados por CORRECCIÓN, de menor a mayor esfuerzo.
       Así el informe se lee como plan de trabajo. La grilla de la
       aplicación los ordena por impacto, que es como se decide qué
       mirar; el informe los ordena por esfuerzo, que es como se
       planifica qué hacer.
    6. Detalle por archivo

  LOTE CON MÁS DE UNA REVISTA: la frecuencia n/N pierde sentido,
  porque el denominador pasa a ser la cantidad de archivos y no la de
  artículos de UNA publicación. En ese caso el informe se emite igual
  —los hallazgos por archivo son ciertos— pero omite las frecuencias y
  declara por qué. Es la misma disciplina del bloque de
  defensibilidad: declarar el límite de lo que se afirma.
-->
<xsl:stylesheet version="2.0"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:local="urn:local"
                exclude-result-prefixes="xsl local">

  <xsl:output method="html" version="5.0" encoding="UTF-8" indent="yes"/>

  <!-- RUTA DEL CATÁLOGO DE MENSAJES, PASADA POR LA APLICACIÓN -->
  <xsl:param name="catalogo"/>

  <xsl:variable name="cat" select="document($catalogo)"/>

  <!-- LA FRECUENCIA SOLO TIENE SENTIDO DENTRO DE UNA REVISTA -->
  <xsl:variable name="hayFrecuencia"
                select="/auditoria/revista/@revista-unica = 'sí'"/>

  <!-- BÚSQUEDA DE MENSAJE POR CÓDIGO -->
  <xsl:key name="msg" match="mensaje" use="@codigo"/>

  <!-- PESO DE CADA NIVEL DE IMPACTO, PARA ORDENAR -->
  <xsl:function name="local:peso">
    <xsl:param name="i"/>
    <xsl:choose>
      <xsl:when test="$i = 'bloqueante'">1</xsl:when>
      <xsl:when test="$i = 'vacio'">2</xsl:when>
      <xsl:when test="$i = 'degradante'">3</xsl:when>
      <xsl:otherwise>4</xsl:otherwise>
    </xsl:choose>
  </xsl:function>

  <!-- ETIQUETAS PARA EL EDITOR: NO SE USA EL VOCABULARIO INTERNO.
       Adentro decimos 'bloqueante'; acá decimos qué significa. -->
  <xsl:function name="local:etiquetaImpacto">
    <xsl:param name="i"/>
    <xsl:choose>
      <xsl:when test="$i = 'bloqueante'">Impide procesar el archivo</xsl:when>
      <xsl:when test="$i = 'vacio'">El archivo no contiene el artículo</xsl:when>
      <xsl:when test="$i = 'degradante'">Se ve en la publicación</xsl:when>
      <xsl:otherwise>Afecta la indexación y la reutilización</xsl:otherwise>
    </xsl:choose>
  </xsl:function>


  <xsl:template match="/auditoria">
    <html lang="es">
      <head>
        <meta charset="UTF-8"/>
        <title>Informe de auditoría JATS — <xsl:value-of select="revista/titulo"/></title>
        <style>
          <xsl:call-template name="estilos"/>
        </style>
      </head>
      <body>

        <!-- ==== 1. IDENTIFICACIÓN ==== -->
        <header>
          <p class="rotulo">Informe de auditoría de marcación JATS</p>
          <h1>
            <xsl:choose>
              <xsl:when test="revista/@revista-unica = 'no'">
                Artículos de varias publicaciones
              </xsl:when>
              <xsl:when test="revista/titulo != ''">
                <xsl:value-of select="revista/titulo"/>
              </xsl:when>
              <xsl:otherwise>Revista sin título declarado</xsl:otherwise>
            </xsl:choose>
          </h1>
          <p class="sub">
            <xsl:if test="revista/@revista-unica = 'sí'">
              <xsl:if test="revista/issn[@tipo='epub'] != ''">
                <span>ISSN electrónico <xsl:value-of select="revista/issn[@tipo='epub']"/></span>
              </xsl:if>
              <xsl:if test="revista/issn[@tipo='ppub'] != ''">
                <span>ISSN impreso <xsl:value-of select="revista/issn[@tipo='ppub']"/></span>
              </xsl:if>
            </xsl:if>
            <span><xsl:value-of select="revista/@archivos"/> artículos analizados</span>
            <span><xsl:value-of select="cabecera/fecha"/></span>
          </p>

          <!-- LOS DOS AVISOS DE ALCANCE SON EXCLUYENTES: SI LA CARPETA
               MEZCLA PUBLICACIONES, LA ADVERTENCIA DE MUESTRA CHICA
               SOBRA, PORQUE NO HAY FRECUENCIAS QUE MATIZAR -->
          <xsl:choose>
            <xsl:when test="revista/@revista-unica = 'no'">
              <p class="aviso"><strong>Los archivos analizados pertenecen a más de una
              publicación.</strong> Este informe describe cada artículo por separado y
              todo lo que afirma sobre ellos es correcto, pero no puede establecer qué
              problemas son propios de una revista y cuáles aparecen de forma aislada.
              Esa distinción es la que separa un defecto del procedimiento de producción
              de un descuido en un artículo puntual, y es la más útil para decidir qué
              corregir. Para obtenerla hay que analizar cada revista por separado.</p>
            </xsl:when>
            <xsl:when test="revista/@muestra-suficiente = 'no'">
              <p class="aviso">Se analizaron menos de tres artículos. Con esa cantidad
              no es posible distinguir un defecto sistemático de un descuido puntual,
              de modo que las frecuencias que aparecen más abajo deben leerse con
              reserva.</p>
            </xsl:when>
          </xsl:choose>

          <xsl:if test="revista/generador/@nombre != ''">
            <p class="generador">
              <strong>Herramienta de marcación detectada:</strong>
              <xsl:text> </xsl:text>
              <xsl:value-of select="revista/generador/@nombre"/>
              <xsl:text> </xsl:text>
              <xsl:value-of select="revista/generador/@version"/>
              <xsl:if test="revista/generador/@confianza = 'inferido'">
                <xsl:text> (identificación inferida, no declarada por el archivo)</xsl:text>
              </xsl:if>
              <xsl:if test="revista/generador/@vigente != '' and
                            revista/generador/@vigente != revista/generador/@version">
                <xsl:text>. La versión vigente de esa misma herramienta es la </xsl:text>
                <xsl:value-of select="revista/generador/@vigente"/>
                <xsl:text>, y corrige de origen varios de los puntos señalados en este
                informe: antes de corregir artículo por artículo conviene evaluar volver
                a exportar la colección con la versión actual.</xsl:text>
              </xsl:if>
            </p>
          </xsl:if>
        </header>

        <!-- ==== 2. DEFENSIBILIDAD ==== -->
        <!-- Sin esto el informe es un PDF con logo. Con esto, cualquier
             tercero puede reproducirlo y deja de ser opinable. -->
        <section class="defensa">
          <h2>Alcance y verificabilidad</h2>
          <dl>
            <dt>Perfil aplicado</dt>
            <dd><xsl:value-of select="cabecera/perfil"/></dd>
            <dt>Herramientas</dt>
            <dd>
              <xsl:for-each select="cabecera/herramientas/herramienta">
                <xsl:value-of select="@nombre"/><xsl:text> </xsl:text>
                <xsl:value-of select="@version"/>
                <xsl:if test="position() != last()"><xsl:text> · </xsl:text></xsl:if>
              </xsl:for-each>
            </dd>
            <dt>No se evaluó</dt>
            <dd><xsl:value-of select="cabecera/no-evaluado"/></dd>
            <xsl:if test="cabecera/recursos/recurso[@estado = 'modificado']">
              <dt>Recursos modificados</dt>
              <dd>
                <xsl:for-each select="cabecera/recursos/recurso[@estado = 'modificado']">
                  <xsl:value-of select="@nombre"/>
                  <xsl:if test="position() != last()"><xsl:text>, </xsl:text></xsl:if>
                </xsl:for-each>
                <xsl:text>. Los textos o la presentación de este informe fueron ajustados respecto de los que distribuye la aplicación.</xsl:text>
              </dd>
            </xsl:if>
          </dl>
          <p class="nota">Cada artículo se identifica más abajo por su huella
          SHA-256. Repetir este análisis sobre los mismos archivos, con las mismas
          herramientas, debe producir el mismo resultado.</p>
        </section>

        <!-- ==== 3. LO VERIFICADO CORRECTO ==== -->
        <xsl:variable name="bienFormados" select="count(archivos/archivo[@bien-formado='sí'])"/>
        <xsl:variable name="conCuerpo" select="count(archivos/archivo[number(@cuerpo) &gt; 0])"/>
        <xsl:variable name="total" select="count(archivos/archivo)"/>
        <section class="correcto">
          <h2>Verificado correcto</h2>
          <ul>
            <xsl:if test="$bienFormados = $total">
              <li>Los <xsl:value-of select="$total"/> archivos son XML correctamente
              formado y pueden abrirse con cualquier herramienta estándar.</li>
            </xsl:if>
            <xsl:if test="$conCuerpo = $total">
              <li>Los <xsl:value-of select="$total"/> archivos contienen el texto
              completo del artículo, y no solamente sus metadatos.</li>
            </xsl:if>
            <xsl:if test="count(archivos/archivo[number(@recursos-faltantes) = 0]) = $total">
              <li>Todas las imágenes referenciadas por los artículos están
              presentes.</li>
            </xsl:if>
            <xsl:if test="count(hallazgos/hallazgo) = 0">
              <li>No se detectaron problemas dentro del alcance declarado.</li>
            </xsl:if>
          </ul>
        </section>

        <!-- ==== 4. RESUMEN POR IMPACTO ==== -->
        <xsl:if test="count(hallazgos/hallazgo) &gt; 0">
          <section>
            <h2>Resumen</h2>
            <table class="resumen">
              <tr>
                <th>Impide procesar el archivo</th>
                <th>No contiene el artículo</th>
                <th>Se ve en la publicación</th>
                <th>Afecta la indexación</th>
              </tr>
              <tr>
                <td class="n i1"><xsl:value-of select="revista/resumen/@bloqueantes"/></td>
                <td class="n i2"><xsl:value-of select="revista/resumen/@vacios"/></td>
                <td class="n i3"><xsl:value-of select="revista/resumen/@degradantes"/></td>
                <td class="n i4"><xsl:value-of select="revista/resumen/@reutilizacion"/></td>
              </tr>
            </table>
            <p class="nota">Los números cuentan problemas distintos, no repeticiones.
            Un mismo problema presente en sesenta y siete lugares de un artículo
            cuenta como uno.<xsl:if test="not($hayFrecuencia)"><xsl:text> </xsl:text>
            Como los artículos pertenecen a publicaciones distintas, estos totales
            suman hallazgos de varias revistas y no describen a ninguna en
            particular.</xsl:if></p>
          </section>

          <!-- ==== 5. HALLAZGOS POR ESFUERZO DE CORRECCIÓN ==== -->
          <xsl:call-template name="grupo">
            <xsl:with-param name="clave" select="'automatica'"/>
            <xsl:with-param name="titulo" select="'Corrección automática'"/>
            <xsl:with-param name="bajada" select="'Un procedimiento resuelve estos puntos sin decisión editorial. Se corrigen una vez para toda la colección.'"/>
          </xsl:call-template>

          <xsl:call-template name="grupo">
            <xsl:with-param name="clave" select="'editorial'"/>
            <xsl:with-param name="titulo" select="'Corrección editorial'"/>
            <xsl:with-param name="bajada" select="'El dato existe o es averiguable, pero alguien tiene que decidir cuál es el correcto.'"/>
          </xsl:call-template>

          <xsl:call-template name="grupo">
            <xsl:with-param name="clave" select="'origen'"/>
            <xsl:with-param name="titulo" select="'Corrección en el origen'"/>
            <xsl:with-param name="bajada" select="'El dato no está en el archivo y no puede recuperarse desde él. Requiere volver al material original o modificar el procedimiento de producción.'"/>
          </xsl:call-template>
        </xsl:if>

        <!-- ==== 6. DETALLE POR ARCHIVO ==== -->
        <section>
          <h2>Artículos analizados</h2>
          <table class="archivos">
            <tr>
              <th>Archivo</th>
              <th>JATS</th>
              <th>Cuerpo</th>
              <th>Imágenes</th>
              <th>SHA-256</th>
            </tr>
            <xsl:for-each select="archivos/archivo">
              <tr>
                <td><xsl:value-of select="@nombre"/></td>
                <td><xsl:value-of select="@dtd-version"/></td>
                <td class="n">
                  <xsl:choose>
                    <xsl:when test="number(@cuerpo) = 0">
                      <span class="mal">vacío</span>
                    </xsl:when>
                    <xsl:otherwise><xsl:value-of select="@cuerpo"/> car.</xsl:otherwise>
                  </xsl:choose>
                </td>
                <td class="n">
                  <xsl:choose>
                    <xsl:when test="number(@recursos) = 0">—</xsl:when>
                    <xsl:when test="number(@recursos-faltantes) &gt; 0">
                      <span class="mal">
                        faltan <xsl:value-of select="@recursos-faltantes"/> de
                        <xsl:text> </xsl:text><xsl:value-of select="@recursos"/>
                      </span>
                    </xsl:when>
                    <xsl:otherwise><xsl:value-of select="@recursos"/></xsl:otherwise>
                  </xsl:choose>
                </td>
                <td class="hash"><xsl:value-of select="substring(@sha256, 1, 16)"/></td>
              </tr>
            </xsl:for-each>
          </table>
        </section>

        <footer>
          <p>Informe generado con gbpublisher. El análisis se apoya en herramientas
          libres y es reproducible por terceros con los datos declarados más arriba.</p>
        </footer>

      </body>
    </html>
  </xsl:template>


  <!-- ============================================================
       UN GRUPO DE HALLAZGOS, POR ESFUERZO DE CORRECCIÓN
       ============================================================ -->
  <xsl:template name="grupo">
    <xsl:param name="clave"/>
    <xsl:param name="titulo"/>
    <xsl:param name="bajada"/>

    <xsl:variable name="items" select="hallazgos/hallazgo[@correccion = $clave]"/>

    <xsl:if test="count($items) &gt; 0">
      <section class="grupo">
        <h2><xsl:value-of select="$titulo"/></h2>
        <p class="bajada"><xsl:value-of select="$bajada"/></p>

        <!-- DENTRO DEL GRUPO, LO MÁS GRAVE PRIMERO.
             SIN FRECUENCIA VÁLIDA NO TIENE SENTIDO ORDENAR POR ELLA:
             SE USA EL TOTAL DE APARICIONES, QUE SIGUE SIENDO CIERTO -->
        <xsl:for-each select="$items">
          <xsl:sort select="local:peso(@impacto)" data-type="number"/>
          <xsl:sort select="if ($hayFrecuencia) then number(@frecuencia)
                            else sum(ocurrencia/number(@veces))"
                    data-type="number" order="descending"/>

          <xsl:variable name="m" select="key('msg', @codigo, $cat)"/>

          <article class="hallazgo">
            <h3>
              <xsl:if test="@certeza = 'probable'">
                <span class="prob">Posible</span><xsl:text> </xsl:text>
              </xsl:if>
              <xsl:choose>
                <xsl:when test="$m"><xsl:value-of select="$m/corto"/></xsl:when>
                <xsl:otherwise><xsl:value-of select="@codigo"/></xsl:otherwise>
              </xsl:choose>
            </h3>

            <p class="meta">
              <span class="chip i{local:peso(@impacto)}">
                <xsl:value-of select="local:etiquetaImpacto(@impacto)"/>
              </span>
              <!-- 'En 1 artículo' ES CIERTO EN UN LOTE MEZCLADO;
                   '1 de 3' NO LO ES -->
              <xsl:choose>
                <xsl:when test="$hayFrecuencia">
                  <span class="chip">
                    <xsl:value-of select="@frecuencia"/> de <xsl:value-of select="@de"/> artículos
                  </span>
                </xsl:when>
                <xsl:otherwise>
                  <span class="chip">
                    <xsl:choose>
                      <xsl:when test="number(@frecuencia) = 1">En 1 artículo</xsl:when>
                      <xsl:otherwise>En <xsl:value-of select="@frecuencia"/> artículos</xsl:otherwise>
                    </xsl:choose>
                  </span>
                </xsl:otherwise>
              </xsl:choose>
              <span class="cod"><xsl:value-of select="@codigo"/></span>
            </p>

            <xsl:if test="$m">
              <p><xsl:value-of select="$m/largo"/></p>
              <p><strong>Por qué importa. </strong><xsl:value-of select="$m/consecuencia"/></p>
              <p><strong>Qué hacer. </strong><xsl:value-of select="$m/remedio"/></p>
            </xsl:if>

            <xsl:if test="@certeza = 'probable'">
              <p class="nota">Esta detección es una inferencia y requiere verificación
              humana. El informe la señala para que se revise, no la da por
              cierta.</p>
            </xsl:if>

            <!-- CAMBIA EL SENTIDO DEL HALLAZGO DE REPROCHE A OPORTUNIDAD -->
            <xsl:if test="@universal = 'sí'">
              <p class="nota">Ninguna de las herramientas de marcación analizadas
              resuelve este punto. La revista no está en peor situación que el resto
              del sector, pero tampoco obtiene el beneficio correspondiente.</p>
            </xsl:if>

            <p class="donde">
              <xsl:for-each select="ocurrencia">
                <xsl:variable name="id" select="@archivo"/>
                <xsl:value-of select="/auditoria/archivos/archivo[@id = $id]/@nombre"/>
                <xsl:if test="number(@veces) &gt; 1">
                  <xsl:text> (</xsl:text><xsl:value-of select="@veces"/><xsl:text> veces)</xsl:text>
                </xsl:if>
                <xsl:if test="@xpath != ''">
                  <xsl:text> · </xsl:text><code><xsl:value-of select="@xpath"/></code>
                </xsl:if>
                <xsl:if test="number(@linea) &gt; 0">
                  <xsl:text> · línea </xsl:text><xsl:value-of select="@linea"/>
                </xsl:if>
                <xsl:if test="position() != last()"><br/></xsl:if>
              </xsl:for-each>
            </p>
          </article>
        </xsl:for-each>
      </section>
    </xsl:if>
  </xsl:template>


  <!-- ============================================================
       ESTILOS
       Tipografías del sistema, sin descargas. Colores sobrios: el
       informe tiene que parecer un peritaje y no un folleto.
       ============================================================ -->
  <xsl:template name="estilos">
    <xsl:text>
      :root {
        --tinta: #1b1b1b; --suave: #5b5b5b; --linea: #d8d8d8;
        --fondo: #ffffff; --caja: #f6f6f4;
        --i1: #8c2f2f; --i2: #8c5a2f; --i3: #6b6b2f; --i4: #3f5f6b;
      }
      * { box-sizing: border-box; }
      body {
        font-family: "IBM Plex Sans", "Segoe UI", system-ui, -apple-system, sans-serif;
        color: var(--tinta); background: var(--fondo);
        max-width: 44rem; margin: 0 auto; padding: 2.5rem 1.5rem;
        line-height: 1.55; font-size: 16px;
      }
      header { border-bottom: 2px solid var(--tinta); padding-bottom: 1.2rem; }
      .rotulo { text-transform: uppercase; letter-spacing: .09em;
                font-size: .72rem; color: var(--suave); margin: 0 0 .3rem; }
      h1 { font-size: 1.6rem; margin: 0 0 .5rem; line-height: 1.25; }
      h2 { font-size: 1.12rem; margin: 2.2rem 0 .6rem;
           padding-bottom: .25rem; border-bottom: 1px solid var(--linea); }
      h3 { font-size: 1rem; margin: 0 0 .45rem; }
      .sub span { color: var(--suave); font-size: .85rem; }
      .sub span + span::before { content: " · "; }
      .generador { background: var(--caja); padding: .7rem .9rem;
                   border-left: 3px solid var(--i4); font-size: .9rem;
                   margin-top: 1rem; }
      .aviso { background: #fdf6e3; border-left: 3px solid var(--i2);
               padding: .7rem .9rem; font-size: .9rem; }
      .defensa dl { display: grid; grid-template-columns: 11rem 1fr;
                    gap: .3rem .9rem; font-size: .87rem; margin: 0; }
      .defensa dt { color: var(--suave); }
      .defensa dd { margin: 0; }
      .correcto ul { margin: .4rem 0; padding-left: 1.1rem; }
      .correcto li { margin-bottom: .3rem; }
      table { border-collapse: collapse; width: 100%; font-size: .88rem;
              margin-top: .6rem; }
      th { text-align: left; font-weight: 600; font-size: .78rem;
           text-transform: uppercase; letter-spacing: .04em; color: var(--suave);
           border-bottom: 1px solid var(--linea); padding: .35rem .5rem; }
      td { padding: .38rem .5rem; border-bottom: 1px solid #eee;
           vertical-align: top; }
      td.n { text-align: right; font-variant-numeric: tabular-nums; }
      .resumen td.n { font-size: 1.5rem; font-weight: 600; text-align: center;
                      padding: .6rem; }
      .resumen th { text-align: center; }
      .i1 { color: var(--i1); } .i2 { color: var(--i2); }
      .i3 { color: var(--i3); } .i4 { color: var(--i4); }
      .hash { font-family: "IBM Plex Mono", ui-monospace, monospace;
              font-size: .74rem; color: var(--suave); }
      .mal { color: var(--i1); font-weight: 600; }
      .bajada { color: var(--suave); font-size: .9rem; margin: 0 0 1rem; }
      .hallazgo { border-left: 2px solid var(--linea); padding: 0 0 .2rem 1rem;
                  margin: 1.4rem 0; }
      .hallazgo p { margin: .4rem 0; font-size: .93rem; }
      .meta { display: flex; flex-wrap: wrap; gap: .4rem; align-items: center; }
      .chip { font-size: .74rem; padding: .12rem .5rem; border-radius: 2px;
              background: var(--caja); border: 1px solid var(--linea); }
      .chip.i1 { color: var(--i1); border-color: var(--i1); }
      .chip.i2 { color: var(--i2); border-color: var(--i2); }
      .chip.i3 { color: var(--i3); border-color: var(--i3); }
      .chip.i4 { color: var(--i4); border-color: var(--i4); }
      .cod { font-family: "IBM Plex Mono", ui-monospace, monospace;
             font-size: .72rem; color: var(--suave); margin-left: auto; }
      .prob { font-style: italic; color: var(--suave); font-weight: 400; }
      .donde, .nota { font-size: .8rem !important; color: var(--suave); }
      .donde code { font-family: "IBM Plex Mono", ui-monospace, monospace;
                    font-size: .74rem; }
      footer { margin-top: 3rem; padding-top: .8rem;
               border-top: 1px solid var(--linea);
               font-size: .78rem; color: var(--suave); }

      @media print {
        body { max-width: none; padding: 0; font-size: 10.5pt; }
        h2 { break-after: avoid; }
        .hallazgo, .grupo, section { break-inside: avoid; }
        .generador, .aviso { background: none; }
        footer { position: fixed; bottom: 0; }
      }
    </xsl:text>
  </xsl:template>

</xsl:stylesheet>
