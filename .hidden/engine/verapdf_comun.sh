# Validación PDF/A con veraPDF — gbpublisher
# ============================================================================
# SE CARGA CON source DESPUÉS DE comun.sh; NO SE EJECUTA SOLO.
#
# Vive en /usr/share/gbpublisher/engine/ y viaja en el .deb. Es
# infraestructura: no se personaliza y no se copia a ~/.gbpublisher (SC-11).
#
# POR QUÉ UN ARCHIVO APARTE
#   Lo usaban solo los libros (compilar_pdfa_libro.sh). Desde A1.2a lo usa
#   también generar_pdf_revista.sh: todo PDF de revista es PDF/A-2u y se
#   valida. El código se mudó tal cual desde compilar_pdfa_libro.sh, para
#   que la próxima corrección llegue a los dos.
#
# LO QUE EL LLAMADOR DEFINE ANTES DE validar_pdfa
#   VERAPDF        la ruta que devolvió buscar_verapdf
#   NIVEL          el nivel de veraPDF (2u)
#   DIR_AUX, BASE  el informe JSON queda en $DIR_AUX/$BASE.verapdf.json
#   ARCHIVO_PDF    el PDF a validar
# ============================================================================

# DÓNDE SE BUSCA veraPDF, EN ESTE ORDEN: LOS MISMOS LUGARES QUE
# validar_pdf.pl Y m_XML.ValidarPDFA
RUTAS_VERAPDF=("/opt/verapdf/verapdf" "$HOME/verapdf/verapdf")
TIEMPO_VERAPDF=600
# REGLAS FALLIDAS QUE SE NOMBRAN EN LA TERMINAL
MAX_REGLAS=10

# ============================================================================
# Función   : buscar_verapdf
# Propósito : Imprime la ruta de veraPDF, o nada.
# ============================================================================
buscar_verapdf() {
    local r
    if r=$(command -v verapdf 2>/dev/null); then
        echo "$r"
        return
    fi
    for r in "${RUTAS_VERAPDF[@]}"; do
        [[ -x "$r" ]] && { echo "$r"; return; }
    done
}

# ============================================================================
# Función   : validar_pdfa
# Propósito : Valida ARCHIVO_PDF con veraPDF en el nivel pedido.
# Retorna   : 0 conforme, 1 no conforme o informe ilegible
# Nota      : NIVEL EXPLÍCITO (-f 2u) Y NO -f 0: CON -f 0 Y SIN DECLARACIÓN,
#             veraPDF VALIDA CONTRA 1b POR DEFECTO (MEDIDO EN l-CALIFA.pdf).
#             EL JSON LO LEE perl CON JSON::PP, DEL NÚCLEO (GV-90: PAQUETE
#             perl COMPLETO). ESTRUCTURA MEDIDA CON veraPDF 1.30:
#             report.jobs[0].validationResult[0] = { compliant, details,
#             profileName, statement }.
# ============================================================================
validar_pdfa() {
    local informe="$DIR_AUX/$BASE.verapdf.json"

    timeout "$TIEMPO_VERAPDF" "$VERAPDF" -f "$NIVEL" --format json "$ARCHIVO_PDF" \
        > "$informe" 2>/dev/null

    perl -MJSON::PP -e '
        my ($archivo, $max) = @ARGV;
        open(my $fh, "<", $archivo) or exit 1;
        local $/;
        my $texto = <$fh>;
        my $i = index($texto, "{");
        exit 1 if $i < 0;
        my $json = eval { decode_json(substr($texto, $i)) } or exit 1;
        my $v = $json->{report}{jobs}[0]{validationResult};
        $v = $v->[0] if ref $v eq "ARRAY";
        exit 1 unless ref $v eq "HASH";
        print "PERFIL\t", ($v->{profileName} // ""), "\n";
        if ($v->{compliant}) { print "CONFORME\n"; exit 0 }
        my @r = grep { ($_->{status} // "") eq "failed" } @{ $v->{details}{ruleSummaries} // [] };
        print "FALLIDAS\t", ($v->{details}{failedRules} // scalar @r), "\n";
        my $n = 0;
        for (@r) {
            last if ++$n > $max;
            print "REGLA\t", ($_->{clause} // "?"), " [", ($_->{failedChecks} // "?"), "] ",
                  ($_->{description} // ""), "\n";
        }
        exit 2;
    ' "$informe" "$MAX_REGLAS"
}
