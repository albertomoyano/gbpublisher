<?xml version="1.0" encoding="UTF-8"?>
<!-- ============================================================ -->
<!-- HOJA      : vista-cuadro-revista.xsl                         -->
<!-- PROPÓSITO : LA VISTA PREVIA DE UN CUADRO DE REVISTA (SC-67). -->
<!--             COMPONE SOLO EL CUADRO, CON LA MISMA PLANTILLA   -->
<!--             QUE EL ARTÍCULO: IMPORTA jats-to-latex.xsl Y     -->
<!--             REEMPLAZA LA RAÍZ. NO HAY OTRA COMPOSICIÓN DEL   -->
<!--             CUADRO: LO QUE SE VE EN LA VISTA ES LO QUE SALE  -->
<!--             EN EL ARTÍCULO.                                  -->
<!-- ENTRADA   : EL FRAGMENTO QUE ESCRIBE vista_cuadro.sh: LA     -->
<!--             SALIDA DE PANDOC CON LOS FILTROS DE LA REVISTA,  -->
<!--             DENTRO DE UN <body>, COMO EN m_XML.GenerarBodyXML-->
<!-- SALIDA    : cuadro-vista.tex, QUE INCLUYE EL MAESTRO         -->
<!--             vista.tex QUE ESCRIBE GAMBAS                     -->
<!-- ============================================================ -->
<xsl:stylesheet version="3.0"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

  <!-- xsl:import TIENE QUE SER EL PRIMER HIJO: LAS PLANTILLAS DE ESTA
       HOJA TIENEN PRECEDENCIA SOBRE LAS IMPORTADAS -->
  <xsl:import href="jats-to-latex.xsl"/>

  <xsl:output method="text" encoding="UTF-8"/>

  <!-- ============================================ -->
  <!-- Plantilla : /                                -->
  <!-- Propósito : Solo el cuadro: sin el documento, sin el resto del   -->
  <!--             artículo. LA RAÍZ DE jats-to-latex.xsl ARMA EL       -->
  <!--             ARTÍCULO ENTERO: ACÁ NO CORRE                        -->
  <!-- ============================================ -->
  <xsl:template match="/">
    <!-- 1. EL CUADRO QUE ARMÓ cuadro-armar.lua: ES EL ÚNICO DEL FRAGMENTO -->
    <xsl:variable name="cuadro" select="//table-wrap[processing-instruction('gb-cuadro')]"/>
    <xsl:if test="count($cuadro) != 1">
      <xsl:message terminate="yes">
        <xsl:text>[vista] SE ESPERABA UN CUADRO Y EL FRAGMENTO TRAE </xsl:text>
        <xsl:value-of select="count($cuadro)"/>
      </xsl:message>
    </xsl:if>
    <!-- 2. LA COMPOSICIÓN: LA PLANTILLA DEL ARTÍCULO -->
    <xsl:apply-templates select="$cuadro"/>
  </xsl:template>

</xsl:stylesheet>
