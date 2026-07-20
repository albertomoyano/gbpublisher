#!/usr/bin/perl
# ============================================
# Script    : buscar_regex.pl
# Propósito : Motor de búsqueda y reemplazo por expresiones regulares de
#             gbpublisher. ENCUENTRA Y CALCULA; NO ESCRIBE NUNCA.
#             La escritura de archivos, la whitelist de rutas, el respaldo y
#             el log son responsabilidad de Gambas. Este script no abre ningún
#             archivo en modo escritura, no borra, no renombra y no enumera el
#             filesystem: recibe la lista exacta de archivos por argv.
# Ubicación : RutaRecursos() — NO se copia a ~/.gbpublisher (CopiarDirectorio
#             no sobrescribe: un archivo copiado una vez nunca se actualiza).
# Requiere  : perl core-base, sin módulos externos y sin JSON::PP (JSON::PP vive
#             en perl-modules, que es Priority: standard; perl-base es Essential
#             y está garantizado). Cero dependencias nuevas en el .deb.
# Invocación: perl -CSA buscar_regex.pl <modo> <patron> <reemplazo> <flags> <aplicar> [archivos...]
#             -C S = STDIN/STDOUT/STDERR en UTF-8
#             -C A = @ARGV decodificado como UTF-8 (imprescindible: el patrón
#                    puede tener acentos, comillas tipográficas o NBSP)
#             Los archivos se abren con :encoding(UTF-8) explícito, que valida
#             la entrada en vez de asumirla (SC-02).
#
# REGLA INVIOLABLE DE ESTE SCRIPT
# ------------------------------
#   NO HAY /e NI /ee EN NINGUNA PARTE, Y NO PUEDE HABERLOS.
#   Con /ee el string de reemplazo del usuario se evalúa como código perl:
#     s/x/$rep/ee  con  $rep = 'system("id")'  →  EJECUTA system("id")
#   Por eso los $1 del reemplazo se expanden a mano (sub expandir_reemplazo),
#   carácter por carácter, sin motor de sustitución en el medio.
#   Es verificable con grep: este archivo no debe contener /e ni /ee jamás.
#   El patrón de búsqueda, en cambio, ya está protegido por perl: viene de una
#   variable, y perl rechaza (?{...}) en patrones de runtime con
#   "Eval-group not allowed at runtime".
#
# MODOS
# -----
#   validar  → compila el patrón y audita el reemplazo. No lee archivos.
#              Salida: OK\0<n_grupos>\0<advertencias>   (advertencias con \x1F)
#                      ERROR\0<mensaje de perl, incluye el marcador <-- HERE>
#              Sale siempre con código 0: el veredicto está en stdout. Un
#              código distinto de 0 significa que falló perl, no el patrón.
#
#   probar   → BANCO DE PRUEBAS EN SECO. Lee un texto desde el archivo que se
#              pasa como PRIMER archivo de la lista (no de STDIN: la forma
#              Exec ... To de Gambas no expone stdin), aplica el patrón sobre el
#              texto completo como un solo documento (multilínea real) y escribe
#              a STDOUT el texto ya transformado. Alimenta
#              areaEditorMostrarResultado. No toca el proyecto: el archivo es un
#              temporal que Gambas crea y borra.
#              Salida: primera línea de control, terminada en \0:
#                      OK\0<n_coincidencias>\0   seguida del texto transformado
#                      ERROR\0<mensaje>\0        si el patrón no compila
#              El texto va DESPUÉS del \0 de control para que Gambas separe el
#              veredicto del cuerpo con un solo Split del primer \0.
#              Sale siempre con código 0 (igual que validar).
#
#   buscar   → aplica el patrón a cada archivo de la lista.
#              Salida: registros de 8 campos, cada campo terminado en \0:
#                1 archivo        ruta tal como se recibió
#                2 offset         desplazamiento en CARACTERES desde el inicio
#                                 del archivo, base 0. Es el dato que consume
#                                 String.Mid() de Gambas para el splice.
#                3 linea          base 0 (igual que TextEditor)
#                4 columna        base 0, en CARACTERES (igual que TextEditor)
#                5 largo          en CARACTERES
#                6 antes          texto de la coincidencia
#                7 despues        texto de reemplazo ya expandido, o vacío si
#                                 aplicar = 0
#                8 linea_texto    línea completa donde EMPIEZA la coincidencia
#              Códigos de salida: 0 ok, 1 patrón inválido, 2 argumentos.
#
# POR QUÉ CARACTERES Y NO BYTES
# -----------------------------
#   Con el string decodificado, los offsets de perl son de caracteres, y
#   String.Mid()/String.Len() de Gambas también (SC-02, RC-GM-12). Encajan sin
#   conversión. gb.pcre habría devuelto offsets en bytes y habría hecho falta
#   traducir byte→carácter en cada coincidencia: ese es el bug que no se
#   encuentra nunca.
# ============================================

use strict;
use warnings;

# use utf8 NO ES DECORATIVO: sin él, los literales en castellano de este mismo
# archivo ("patrón", "vacía") son bytes crudos, y -CS los vuelve a codificar a
# UTF-8 al imprimirlos. Resultado: doble codificación, y Gambas recibe
# "patrÃ³n". El flag -C gobierna los handles; use utf8 gobierna el fuente. Hacen
# falta los dos.
use utf8;

# --- 1. SEPARADORES DEL PROTOCOLO ---
# NUL entre campos: el contenido es texto UTF-8 y no puede contenerlo.
# No se usa \n como separador porque una coincidencia con /s o /m puede
# contener saltos de línea.
my $SEP_CAMPO = "\0";
my $SEP_LISTA = "\x1F";

# --- 2. LECTURA Y VALIDACIÓN DE ARGUMENTOS ---
my $modo      = shift @ARGV;
my $patron    = shift @ARGV;
my $reemplazo = shift @ARGV;
my $flags     = shift @ARGV;
my $aplicar   = shift @ARGV;
my @archivos  = @ARGV;

if (!defined $modo || !defined $patron || !defined $reemplazo
    || !defined $flags || !defined $aplicar) {
    print STDERR "Argumentos insuficientes.\n";
    exit 2;
}
if ($modo ne 'validar' && $modo ne 'buscar' && $modo ne 'probar') {
    print STDERR "Modo desconocido: $modo\n";
    exit 2;
}
$flags = '' if $flags eq '-';
$aplicar = ($aplicar eq '1') ? 1 : 0;

# --- 3. DESPACHO ---
if ($modo eq 'validar') {
    modo_validar();
} elsif ($modo eq 'probar') {
    modo_probar();
} else {
    modo_buscar();
}
exit 0;

# ============================================
# Función   : compilar_patron
# Propósito : Compila el patrón con los flags del usuario. Los flags se aplican
#             envolviendo el patrón en un grupo no capturante (?imsx:...), que
#             NO desplaza la numeración de los grupos del usuario: $1 sigue
#             siendo su primer grupo.
#             Se usa eval de bloque, nunca eval de string: con eval de string
#             el patrón se interpolaría en el código fuente y (?{...}) volvería
#             a ser ejecutable.
#             No existe flag de ungreedy: perl rechaza /U y (?U) — son cosas de
#             PCRE. En perl la pereza se escribe donde corresponde, .*? , que
#             además es visible para quien lea el patrón.
# Parámetros: (usa $patron y $flags globales)
# Retorna   : (qr compilado, mensaje de error). Uno de los dos es undef.
# ============================================
sub compilar_patron {

    my $f = '';
    $f .= 'i' if $flags =~ /i/;
    $f .= 'm' if $flags =~ /m/;
    $f .= 's' if $flags =~ /s/;
    $f .= 'x' if $flags =~ /x/;

    # SALTO DE LÍNEA DE CIERRE, SOLO BAJO /x.
    # Bajo /x un comentario # corre hasta el fin de la línea real. Si el patrón
    # termina en comentario — o sea, si está bien escrito — ese comentario se
    # come el paréntesis que cierra este mismo envoltorio y el patrón deja de
    # compilar. Un \n final termina el comentario y bajo /x es espacio ignorado.
    # SIN /x no se agrega: ahí el \n sería un carácter literal a matchear.
    my $cierre = ($f =~ /x/) ? "\n" : '';

    my $re = eval { qr/(?$f:$patron$cierre)/ };
    if (!$re) {
        my $msg = $@ // 'Error desconocido al compilar el patrón';
        chomp $msg;
        # El mensaje de perl termina en " at buscar_regex.pl line N." — al
        # usuario no le importa dónde vive el motor. Lo que sí le importa, y se
        # conserva, es el marcador "<-- HERE" que le dice DÓNDE está el error
        # dentro de su patrón. Eso gb.pcre no lo da: recibe el err_offset de
        # PCRE2 y lo descarta.
        $msg =~ s/ at \S+ line \d+\.?\s*\z//;
        return (undef, $msg);
    }
    return ($re, undef);
}

# ============================================
# Función   : contar_grupos
# Propósito : Devuelve la cantidad de grupos de captura del patrón compilado.
#             El truco: se matchea contra una alternativa vacía, que siempre
#             tiene éxito, y $#+ queda con la cantidad de subgrupos del patrón.
# Parámetros: $re — patrón compilado
# Retorna   : Integer
# ============================================
sub contar_grupos {
    my ($re) = @_;
    "" =~ /$re|/;
    return $#+;
}

# ============================================
# Función   : detectar_invisibles
# Propósito : Busca caracteres invisibles literales dentro del patrón y avisa.
#             Esto no lo hace ninguna herramienta genérica de regex, porque
#             ninguna sabe que su usuario edita textos con espacios duros. Acá
#             el dominio está lleno de "300 kHz", "12 %" y "Fig. 3": el
#             maquetador copia un fragmento del .md para armar el patrón y se
#             trae un NBSP sin enterarse.
#             El caso es especialmente traicionero bajo /x: /x IGNORA el espacio
#             común pero NO ignora el NBSP, que pasa a ser un carácter a
#             matchear. Los dos se ven idénticos en cualquier fuente.
# Parámetros: $texto — el patrón crudo
# Retorna   : lista de advertencias
# ============================================
sub detectar_invisibles {
    my ($texto) = @_;
    my @avisos;

    my %nombres = (
        "\x{00A0}" => 'NBSP (espacio duro)',
        "\x{202F}" => 'NNBSP (espacio duro angosto)',
        "\x{2009}" => 'espacio fino',
        "\x{200B}" => 'espacio de ancho cero',
        "\x{FEFF}" => 'BOM / espacio sin ancho',
        "\x{0009}" => 'tabulador',
    );

    my $len = length($texto);
    for (my $i = 0; $i < $len; $i++) {
        my $c = substr($texto, $i, 1);
        next unless exists $nombres{$c};
        push @avisos, sprintf(
            'El patrón contiene un %s literal en la posición %d. Si era intencional, escribilo como \x{%04X} para que se vea.',
            $nombres{$c}, $i, ord($c));
    }
    return @avisos;
}

# ============================================
# Función   : auditar_reemplazo
# Propósito : Verifica que las referencias $N del reemplazo existan en el
#             patrón. Perl no puede avisar de esto porque la expansión la
#             hacemos nosotros: si nadie mira, $3 sobre un patrón de 2 grupos
#             se expande a vacío en silencio y el reemplazo borra texto.
# Parámetros: $plantilla, $n_grupos
# Retorna   : lista de advertencias
# ============================================
sub auditar_reemplazo {
    my ($plantilla, $n_grupos) = @_;
    my @avisos;
    my %vistos;

    while ($plantilla =~ /\$(?:\{)?([0-9]+)/g) {
        my $n = $1;
        next if $n == 0;
        next if $n <= $n_grupos;
        next if $vistos{$n}++;
        push @avisos, "El reemplazo usa \$$n pero el patrón tiene $n_grupos grupo(s) de captura: se expandirá a vacío.";
    }
    return @avisos;
}

# ============================================
# Función   : modo_validar
# Propósito : Compila, audita y reporta. No toca ningún archivo.
# ============================================
sub modo_validar {

    # --- 1. COMPILAR ---
    my ($re, $err) = compilar_patron();
    if (!$re) {
        print 'ERROR', $SEP_CAMPO, $err, $SEP_CAMPO;
        return;
    }

    # --- 2. AUDITAR ---
    my $n_grupos = contar_grupos($re);
    my @avisos = detectar_invisibles($patron);

    # UN PATRÓN QUE PUEDE MATCHEAR LA CADENA VACÍA PRODUCE COINCIDENCIAS DE
    # LARGO CERO EN CADA POSICIÓN DEL TEXTO. modo_buscar LAS DESCARTA, PERO EL
    # USUARIO MERECE SABER POR QUÉ SU PATRÓN NO ENCUENTRA LO QUE ESPERA.
    if ("" =~ /$re/) {
        push @avisos, 'El patrón puede coincidir con la cadena vacía: las coincidencias de largo cero se descartan.';
    }

    push @avisos, auditar_reemplazo($reemplazo, $n_grupos) if $aplicar;

    print 'OK', $SEP_CAMPO, $n_grupos, $SEP_CAMPO, join($SEP_LISTA, @avisos), $SEP_CAMPO;
}

# ============================================
# Función   : expandir_reemplazo
# Propósito : Expande las referencias del reemplazo contra las capturas de la
#             coincidencia actual. TODO LO QUE NO SEA UNA REFERENCIA O UN ESCAPE
#             DE CARÁCTER SE COPIA LITERAL. Se hace a mano, carácter por
#             carácter, porque el atajo (s///ee) es ejecución de código
#             arbitrario del usuario.
# Sintaxis  : $0        la coincidencia completa
#             $1..$99   grupo numerado
#             ${12}     grupo numerado, forma con llaves (necesaria si al
#                       número le sigue un dígito literal)
#             ${nombre} grupo nombrado, de (?<nombre>...)
#             $$        un $ literal
#             \n \t \r  salto de línea, tabulador, retorno de carro
#             \xHH      carácter por código hexadecimal de 2 dígitos
#             \x{HHHH}  carácter Unicode por codepoint (p.ej. \x{00A0} = NBSP)
#             \\        una barra invertida literal
#             Un $ o un \ que no encabece ninguna de esas formas se copia
#             literal: es lo que el usuario quiso decir.
#             LOS ESCAPES SON SOLO DE CARÁCTER: PRODUCEN UN CARÁCTER, NUNCA
#             CÓDIGO. La regla anti-/e sigue intacta: acá no se evalúa nada, se
#             traduce una notación a un carácter y se copia.
# Parámetros: $plantilla — texto de reemplazo crudo
#             $completa  — texto de la coincidencia completa
#             $caps      — arrayref con las capturas numeradas (índice 0 = $1)
#             $nombradas — hashref con las capturas nombradas
# Retorna   : String
# ============================================
sub expandir_reemplazo {
    my ($plantilla, $completa, $caps, $nombradas) = @_;

    my $salida = '';
    my $i = 0;
    my $len = length($plantilla);

    while ($i < $len) {

        my $c = substr($plantilla, $i, 1);

        # --- ESCAPES DE CARÁCTER (barra invertida) ---
        if ($c eq "\\") {

            # \ AL FINAL DE LA PLANTILLA: LITERAL
            if ($i + 1 >= $len) {
                $salida .= "\\";
                $i++;
                next;
            }

            my $sigue = substr($plantilla, $i + 1, 1);

            if ($sigue eq 'n') { $salida .= "\n"; $i += 2; next; }
            if ($sigue eq 't') { $salida .= "\t"; $i += 2; next; }
            if ($sigue eq 'r') { $salida .= "\r"; $i += 2; next; }
            if ($sigue eq "\\") { $salida .= "\\"; $i += 2; next; }

            # \x{HHHH} — CODEPOINT UNICODE ENTRE LLAVES
            if ($sigue eq 'x' && substr($plantilla, $i + 2, 1) eq '{') {
                my $cierre = index($plantilla, '}', $i + 3);
                if ($cierre >= 0) {
                    my $hex = substr($plantilla, $i + 3, $cierre - $i - 3);
                    if ($hex =~ /^[0-9A-Fa-f]+$/) {
                        $salida .= chr(hex($hex));
                        $i = $cierre + 1;
                        next;
                    }
                }
                # MAL FORMADO: \ LITERAL, SEGUIMOS DESDE x
                $salida .= "\\";
                $i++;
                next;
            }

            # \xHH — DOS DÍGITOS HEXADECIMALES
            if ($sigue eq 'x') {
                my $hex = substr($plantilla, $i + 2, 2);
                if ($hex =~ /^[0-9A-Fa-f]{2}$/) {
                    $salida .= chr(hex($hex));
                    $i += 4;
                    next;
                }
                # MAL FORMADO: \ LITERAL
                $salida .= "\\";
                $i++;
                next;
            }

            # CUALQUIER OTRO \X: SE COPIAN AMBOS CARACTERES LITERALES. NO SE
            # INVENTA UN ESCAPE NUEVO NI SE COME LA BARRA: EL USUARIO VE LO QUE
            # ESCRIBIÓ.
            $salida .= "\\" . $sigue;
            $i += 2;
            next;
        }

        # TEXTO LITERAL
        if ($c ne '$') {
            $salida .= $c;
            $i++;
            next;
        }

        # $ AL FINAL DE LA PLANTILLA: LITERAL
        if ($i + 1 >= $len) {
            $salida .= '$';
            $i++;
            next;
        }

        my $sig = substr($plantilla, $i + 1, 1);

        # $$ → $ LITERAL
        if ($sig eq '$') {
            $salida .= '$';
            $i += 2;
            next;
        }

        # ${...} → NUMERADO CON LLAVES O NOMBRADO
        if ($sig eq '{') {
            my $cierre = index($plantilla, '}', $i + 2);
            if ($cierre < 0) {
                # LLAVE SIN CERRAR: LITERAL, NO ADIVINAMOS
                $salida .= '$';
                $i++;
                next;
            }
            my $clave = substr($plantilla, $i + 2, $cierre - $i - 2);
            if ($clave =~ /^[0-9]+$/) {
                $salida .= valor_grupo($clave, $completa, $caps);
            } elsif ($clave =~ /^\w+$/) {
                $salida .= defined($nombradas->{$clave}) ? $nombradas->{$clave} : '';
            } else {
                # CONTENIDO NO RECONOCIBLE: LITERAL
                $salida .= substr($plantilla, $i, $cierre - $i + 1);
            }
            $i = $cierre + 1;
            next;
        }

        # $N → NUMERADO SIN LLAVES, TOMANDO TODOS LOS DÍGITOS SEGUIDOS
        if ($sig =~ /^[0-9]$/) {
            my $j = $i + 1;
            $j++ while ($j < $len && substr($plantilla, $j, 1) =~ /^[0-9]$/);
            my $n = substr($plantilla, $i + 1, $j - $i - 1);
            $salida .= valor_grupo($n, $completa, $caps);
            $i = $j;
            next;
        }

        # CUALQUIER OTRA COSA DESPUÉS DEL $: LITERAL
        $salida .= '$';
        $i++;
    }

    return $salida;
}

# ============================================
# Función   : valor_grupo
# Propósito : Devuelve el texto de un grupo numerado. Un grupo inexistente o
#             que no participó en la coincidencia devuelve cadena vacía, que es
#             lo mismo que hace perl.
# Parámetros: $n, $completa, $caps
# Retorna   : String
# ============================================
sub valor_grupo {
    my ($n, $completa, $caps) = @_;
    return $completa if $n == 0;
    my $v = $caps->[$n - 1];
    return defined($v) ? $v : '';
}

# ============================================
# Función   : indices_de_lineas
# Propósito : Devuelve un array con el offset de inicio de cada línea, para
#             convertir offset absoluto en (línea, columna) sin recorrer el
#             texto una vez por coincidencia.
# Parámetros: $texto
# Retorna   : arrayref de offsets
# ============================================
sub indices_de_lineas {
    my ($texto) = @_;
    my @inicios = (0);
    my $p = -1;
    while (($p = index($texto, "\n", $p + 1)) >= 0) {
        push @inicios, $p + 1;
    }
    return \@inicios;
}

# ============================================
# Función   : modo_buscar
# Propósito : Recorre la lista de archivos y emite un registro por coincidencia.
#             El texto se procesa entero (slurp), no línea por línea: perl
#             mantiene pos() y no hay que truncar el sujeto, así que ^, $, \b y
#             los lookbehind se evalúan siempre contra el contexto real.
# ============================================
sub modo_buscar {

    # --- 1. COMPILAR EL PATRÓN UNA SOLA VEZ PARA TODA LA BÚSQUEDA ---
    my ($re, $err) = compilar_patron();
    if (!$re) {
        print STDERR "$err\n";
        exit 1;
    }

    my $vacias = 0;

    # --- 2. RECORRER LOS ARCHIVOS EN EL ORDEN RECIBIDO ---
    # El orden lo decide Gambas (orden editorial: fm → a → bm). Este script no
    # ordena ni enumera nada: recibe la lista y la respeta.
    for my $ruta (@archivos) {

        my $fh;
        if (!open($fh, '<:encoding(UTF-8)', $ruta)) {
            print STDERR "No se pudo leer: $ruta ($!)\n";
            next;
        }
        my $texto = do { local $/; <$fh> };
        close $fh;
        next unless defined $texto;

        my $inicios = indices_de_lineas($texto);
        my $idx_linea = 0;
        my $ultimo_inicio = -1;

        # --- 3. RECORRER LAS COINCIDENCIAS ---
        while ($texto =~ /$re/g) {

            my $ini   = $-[0];
            my $largo = $+[0] - $ini;

            # GUARDA CONTRA COINCIDENCIAS DE LARGO CERO. Perl no entra en bucle
            # infinito con ellas (tiene la regla anti-loop de //g), pero un
            # patrón como \s* produce una coincidencia vacía en cada posición
            # del archivo y llenaría la grilla con miles de filas que no
            # significan nada. modo_validar ya avisó de esto.
            if ($largo == 0) {
                $vacias++;
                next;
            }

            # SALVAGUARDA: si por cualquier razón el motor no avanzara, cortamos
            # en vez de colgar la aplicación.
            if ($ini <= $ultimo_inicio) {
                print STDERR "Progreso detenido en $ruta, se aborta el archivo.\n";
                last;
            }
            $ultimo_inicio = $ini;

            # --- 4. UBICAR LÍNEA Y COLUMNA ---
            # El cursor solo avanza: las coincidencias llegan en orden creciente
            $idx_linea++ while ($idx_linea + 1 <= $#$inicios
                                && $inicios->[$idx_linea + 1] <= $ini);
            my $linea   = $idx_linea;
            my $columna = $ini - $inicios->[$idx_linea];

            # TEXTO DE LA LÍNEA DONDE EMPIEZA LA COINCIDENCIA (SIN EL \n FINAL)
            my $fin_linea = ($idx_linea + 1 <= $#$inicios)
                          ? $inicios->[$idx_linea + 1] - 1
                          : length($texto);
            my $texto_linea = substr($texto, $inicios->[$idx_linea],
                                     $fin_linea - $inicios->[$idx_linea]);
            $texto_linea =~ s/\r\z//;

            # --- 5. CALCULAR EL REEMPLAZO ---
            # Se copian las capturas ANTES de tocar nada: cualquier match
            # posterior las pisa.
            my $completa = substr($texto, $ini, $largo);
            my $despues  = '';
            if ($aplicar) {
                # Las capturas se extraen con @- y @+, la misma maquinaria de
                # offsets que usa todo el script, en vez de @{^CAPTURE} (que
                # exige perl 5.26). Un grupo que no participó tiene $-[$g]
                # indefinido y queda como undef, igual que en perl.
                my @caps;
                for my $g (1 .. $#+) {
                    push @caps, defined($-[$g])
                              ? substr($texto, $-[$g], $+[$g] - $-[$g])
                              : undef;
                }
                my %nombradas = %+;
                $despues = expandir_reemplazo($reemplazo, $completa,
                                              \@caps, \%nombradas);
            }

            # --- 6. EMITIR EL REGISTRO ---
            print join($SEP_CAMPO,
                $ruta, $ini, $linea, $columna, $largo,
                $completa, $despues, $texto_linea), $SEP_CAMPO;
        }
    }

    # --- 7. INFORMAR LAS DESCARTADAS ---
    if ($vacias > 0) {
        print STDERR "Se descartaron $vacias coincidencia(s) de largo cero.\n";
    }
}

# ============================================
# Función   : modo_probar
# Propósito : Banco de pruebas en seco. Lee el texto de STDIN, aplica el patrón
#             sobre el documento completo y escribe el texto transformado a
#             STDOUT, precedido de una línea de control con el veredicto y el
#             número de coincidencias. No abre ningún archivo ni toca el
#             proyecto: opera solo sobre lo que el usuario pegó en areaEditor.
#             Igual que modo_buscar: expande el reemplazo a mano, nunca /e, y
#             descarta las coincidencias de largo cero para no colgarse con
#             patrones que matcheen la cadena vacía.
# ============================================
sub modo_probar {

    # --- 1. COMPILAR ---
    my ($re, $err) = compilar_patron();
    if (!$re) {
        print 'ERROR', $SEP_CAMPO, $err, $SEP_CAMPO;
        return;
    }

    # --- 2. LEER EL TEXTO DE PRUEBA DESDE EL ARCHIVO TEMPORAL ---
    # Gambas pasa el texto en un archivo temporal (su forma Exec ... To no
    # expone stdin). El archivo es el primer elemento de @archivos.
    # slurp: se procesa como un solo documento, así el patrón multilínea (/s,
    # /m) funciona igual que sobre un archivo real del proyecto.
    my $ruta_tmp = $archivos[0];
    if (!defined $ruta_tmp) {
        print 'ERROR', $SEP_CAMPO, 'Falta el archivo de texto de prueba.', $SEP_CAMPO;
        return;
    }
    my $texto;
    if (open(my $fh, '<:encoding(UTF-8)', $ruta_tmp)) {
        $texto = do { local $/; <$fh> };
        close $fh;
    }
    $texto = '' unless defined $texto;

    # --- 3. RECORRER Y RECONSTRUIR ---
    # Se reconstruye el texto tramo por tramo en vez de usar s///g, porque s///g
    # con reemplazo dinámico obligaría a /e. Acá copiamos lo que hay entre
    # coincidencias y expandimos el reemplazo a mano en cada una.
    my $salida = '';
    my $cursor = 0;
    my $cuenta = 0;
    my $ultimo_ini = -1;

    while ($texto =~ /$re/g) {

        my $ini   = $-[0];
        my $largo = $+[0] - $ini;

        # LARGO CERO: SE IGNORA, IGUAL QUE EN modo_buscar
        next if $largo == 0;

        # SALVAGUARDA DE PROGRESO
        last if $ini <= $ultimo_ini;
        $ultimo_ini = $ini;

        # COPIAR EL TEXTO ANTERIOR A LA COINCIDENCIA
        $salida .= substr($texto, $cursor, $ini - $cursor);

        # EXPANDIR EL REEMPLAZO CON LAS CAPTURAS DE ESTA COINCIDENCIA
        my $completa = substr($texto, $ini, $largo);
        if ($aplicar) {
            my @caps;
            for my $g (1 .. $#+) {
                push @caps, defined($-[$g])
                          ? substr($texto, $-[$g], $+[$g] - $-[$g])
                          : undef;
            }
            my %nombradas = %+;
            $salida .= expandir_reemplazo($reemplazo, $completa,
                                          \@caps, \%nombradas);
        } else {
            # SIN REEMPLAZO: EL BANCO MUESTRA EL TEXTO INTACTO. LA COINCIDENCIA
            # SE COPIA TAL CUAL. (LO QUE CAMBIA ES EL CONTADOR, QUE DICE CUÁNTAS
            # HUBO.)
            $salida .= $completa;
        }

        $cursor = $ini + $largo;
        $cuenta++;
    }

    # COPIAR EL RESTO DEL TEXTO DESPUÉS DE LA ÚLTIMA COINCIDENCIA
    $salida .= substr($texto, $cursor);

    # --- 4. EMITIR VEREDICTO + CUERPO ---
    # El \0 tras el contador separa la línea de control del texto transformado:
    # Gambas hace Split del primer \0 y todo lo que sigue es el cuerpo.
    print 'OK', $SEP_CAMPO, $cuenta, $SEP_CAMPO, $salida;
}

