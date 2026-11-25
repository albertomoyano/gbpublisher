#!/usr/bin/perl
# Paginación de las piezas del libro — gbpublisher
# ============================================================================
# Vive en /usr/share/gbpublisher/engine/ y viaja en el .deb (SC-11). Lo llama
# compilar_pdf_libro.sh al terminar una composición completa; se puede correr
# a mano sobre un latex/ ya compilado.
#
# Decisión de Alberto del 25/11/2026 (claude/crossref-libros.md, F3): las
# páginas de cada pieza nacen en la composición y vuelven a la base. Probado
# sobre el libro Duek (6/11) y una composición mínima, LuaHBTeX 1.17.0, TeX
# Live 2023, LaTeX2e 2023-11-01:
#
#   INICIO  el \label{cap-ID} que docbook-to-latex.xsl escribe al abrir cada
#           pieza: \newlabel{cap-26}{{1}{1}{título}{chapter.1}{}}. El folio
#           es el segundo campo, como se imprime (arábigo o romano).
#   FIN     el checkpoint que \include escribe en el .aux de la pieza
#           después de su \clearpage, \@setckpt{c-…}{…\setcounter{page}{N}…},
#           menos 1. La página en blanco de openright la agrega el \chapter
#           de la pieza SIGUIENTE, no este \include: N−1 es la última página
#           con texto. El fin se escribe en el estilo del inicio.
#   DESCARTADO un \label en el gancho include/end: cuando la pieza llena su
#           última página, la marca cae en la siguiente.
#
# USO
#   paginacion_libro.pl <main.tex> <dir_aux>
#
# SALIDA (stdout), una línea por pieza con folio, en el orden del main.tex,
# separada por tabuladores:
#
#   archivo  id_capitulo  inicio  fin  paginas
#   a-01-CAP01  26  1  20  20
#
# archivo es el de \include{c-archivo}: el nombre_archivo de capitulos.
#
# LAS PÁGINAS ESPECIALES (fm/bm 00 a 09: dedicatoria, foto, recordatorio) NO
# LLEVAN \label NI FOLIO: no salen, y se informan por stderr con «especial».
#
# CÓDIGOS: 0 bien; 1 algo no se pudo leer (por stderr, una línea por
# problema): un .aux que falta, una pieza con folio sin checkpoint, un folio
# que no es arábigo ni romano. Con 1, la salida no sirve y no se usa.
# ============================================================================

use strict;
use warnings;

# --- 1. ARGUMENTOS ---
die "Uso: paginacion_libro.pl <main.tex> <dir_aux>\n" unless @ARGV == 2;
my ($main, $dir_aux) = @ARGV;

# --- 2. ROMANOS ---
# LA PRIMERA PÁGINA DE LAS PRELIMINARES PUEDE IR EN ROMANOS (Duek: IX)
my %ROMANO = (I => 1, V => 5, X => 10, L => 50, C => 100, D => 500, M => 1000);

sub de_romano {
    my ($s) = @_;
    my ($total, $mayor) = (0, 0);
    # DE DERECHA A IZQUIERDA: UNA CIFRA MENOR QUE LA MAYOR VISTA RESTA
    for my $c (reverse split //, uc $s) {
        my $v = $ROMANO{$c};
        $total += $v < $mayor ? -$v : $v;
        $mayor = $v if $v > $mayor;
    }
    return $total;
}

sub a_romano {
    my ($n) = @_;
    my @tabla = ([1000, 'M'], [900, 'CM'], [500, 'D'], [400, 'CD'], [100, 'C'], [90, 'XC'],
                 [50, 'L'], [40, 'XL'], [10, 'X'], [9, 'IX'], [5, 'V'], [4, 'IV'], [1, 'I']);
    my $r = '';
    for my $par (@tabla) {
        while ($n >= $par->[0]) { $r .= $par->[1]; $n -= $par->[0]; }
    }
    return $r;
}

# --- 3. LAS PIEZAS DEL main.tex, EN ORDEN ---
# SOLO LAS LÍNEAS SIN COMENTAR: UN \include COMENTADO NO SE COMPUSO
open my $fm, '<:encoding(UTF-8)', $main or die "No se pudo leer $main: $!\n";
my @piezas;
while (my $l = <$fm>) {
    next if $l =~ /^\s*%/;
    push @piezas, $1 while $l =~ /\\include\{c-([^}]+)\}/g;
}
close $fm;

# --- 4. CADA PIEZA ---
my $problemas = 0;
for my $p (@piezas) {
    my $aux = "$dir_aux/c-$p.aux";
    my $fa;
    unless (open $fa, '<:encoding(UTF-8)', $aux) {
        print STDERR "falta\t$p\tno existe c-$p.aux\n";
        $problemas++;
        next;
    }
    local $/;
    my $t = <$fa>;
    close $fa;

    # INICIO: LA PRIMERA MARCA cap-ID DEL .aux DE LA PIEZA
    my ($id, $ini) = $t =~ /\\newlabel\{cap-(\d+)\}\{\{[^{}]*\}\{([^{}]*)\}/;
    unless (defined $id) {
        print STDERR "especial\t$p\tsin folio (página especial)\n";
        next;
    }

    # FIN: EL CHECKPOINT DE \include, MENOS 1
    my ($ck) = $t =~ /\\\@setckpt\{[^}]*\}\{.*?\\setcounter\{page\}\{(-?\d+)\}/s;
    unless (defined $ck) {
        print STDERR "checkpoint\t$p\tel .aux no tiene el checkpoint de \\include\n";
        $problemas++;
        next;
    }
    my $num_fin = $ck - 1;

    # EL FIN EN EL ESTILO DEL INICIO
    my ($fin, $paginas);
    if ($ini =~ /^\d+$/) {
        ($fin, $paginas) = ($num_fin, $num_fin - $ini + 1);
    } elsif ($ini =~ /^[ivxlcdm]+$/) {
        ($fin, $paginas) = (lc a_romano($num_fin), $num_fin - de_romano($ini) + 1);
    } elsif ($ini =~ /^[IVXLCDM]+$/) {
        ($fin, $paginas) = (a_romano($num_fin), $num_fin - de_romano($ini) + 1);
    } else {
        print STDERR "folio\t$p\tel folio «$ini» no es arábigo ni romano\n";
        $problemas++;
        next;
    }
    if ($paginas < 1) {
        print STDERR "rango\t$p\tel fin ($fin) queda antes del inicio ($ini)\n";
        $problemas++;
        next;
    }

    print join("\t", $p, $id, $ini, $fin, $paginas), "\n";
}

exit($problemas ? 1 : 0);
