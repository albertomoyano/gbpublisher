#!/usr/bin/perl
# ============================================
# Script    : analizar_lexico.pl
# Propósito : Análisis léxico del proyecto para la solapa «Escanear» de
#             gbpublisher: ORACIONES (cantidad, largo, la más larga, párrafos
#             de una sola oración) y VARIANTES de una misma palabra en todo el
#             proyecto (guion, mayúscula dentro de la oración, tilde de la
#             lista cerrada). CALCULA E INFORMA; NO ESCRIBE NUNCA en el
#             proyecto.
#
#             NO LEE EL MARKDOWN. Recibe el texto que engine/analizar_proyecto.lua
#             ya separó del AST de Pandoc (sin citas, notas, fórmulas ni
#             código): una línea por bloque, campos por TAB:
#               ctx  clase  parrafo  texto
#             La estructura es de Lua; lo léxico es de perl, porque los
#             patrones de Lua no reconocen letras fuera de ASCII (GV-88).
#
# Ubicación : engine/ — NO se copia a ~/.gbpublisher (SC-11).
# Requiere  : el paquete «perl» completo, NO solo perl-base: el layer
#             :encoding(UTF-8) necesita PerlIO y Encode, que perl-base no
#             trae. Lo mismo vale para buscar_regex.pl. No usa módulos fuera
#             de la distribución de perl.
# Invocación: perl -CSDA analizar_lexico.pl <abreviaturas> <tildes> <clases_cuerpo>
#                  <nombre1> <texto1> [<nombre2> <texto2> ...]
#             -C S  STDIN/STDOUT/STDERR en UTF-8
#             -C D  capas UTF-8 por defecto al abrir archivos
#             -C A  @ARGV decodificado como UTF-8
#             <clases_cuerpo>: clases de div que cuentan como cuerpo (las del
#             grupo estructura del catálogo), separadas por coma; vacío si
#             no hay ninguna. La decisión es de Gambas, que tiene el catálogo.
#
# SALIDA (stdout, un registro por línea, campos separados por NUL)
#   O   nombre oraciones palabras mediana_x2 max inicio parrafos una_oracion
#   OT  ""     ...mismos campos, sobre todo el proyecto
#   V   id tipo forma cantidad archivos       una forma de un grupo
#   X   id forma archivo oracion              una oración de ejemplo
#   mediana_x2 es la mediana por dos: siempre entera, sin separador decimal
#   que dependa de la configuración regional.
#   tipo: guion, mayuscula, tilde, tilde-rae.
#
# Sale con código 0 si terminó; distinto de 0 si no pudo leer una entrada
# (el mensaje va a stderr).
# ============================================

use strict;
use warnings;
use utf8;

# --- CONSTANTES ---
# ORACIONES DE EJEMPLO QUE SE GUARDAN POR FORMA, Y LARGO MÁXIMO DE CADA UNA
my $MAX_EJEMPLOS = 8;
my $MAX_LARGO_EJEMPLO = 300;
# PALABRAS DEL COMIENZO DE LA ORACIÓN MÁS LARGA (EL MISMO CRITERIO DEL FILTRO)
my $PALABRAS_INICIO = 8;

# --- 1. ARGUMENTOS ---
my ($ruta_abrev, $ruta_tildes, $clases_cuerpo, @pares) = @ARGV;
die "uso: analizar_lexico.pl <abreviaturas> <tildes> <clases_cuerpo> <nombre> <texto> ...\n"
  unless defined $clases_cuerpo && @pares && @pares % 2 == 0;

my %cuerpo = map { $_ => 1 } grep { $_ ne '' } split /,/, $clases_cuerpo;

# --- 2. DATOS: ABREVIATURAS Y TILDES ---
my %abreviatura;
for my $linea (leer_lineas($ruta_abrev)) {
  $abreviatura{lc $linea} = 1;
}

my @tildes;   # [tipo, sin, con]
for my $linea (leer_lineas($ruta_tildes)) {
  my @c = split /\t/, $linea;
  die "tildes: línea mal formada: $linea\n" unless @c == 3;
  push @tildes, [@c];
}

# --- 3. ESTADO GLOBAL ---
my @oraciones_texto;   # TODAS LAS ORACIONES; LOS EJEMPLOS GUARDAN EL ÍNDICE
my %lc_cuenta;         # forma en minúscula -> archivo -> cantidad
my %lc_ejemplos;       # forma en minúscula -> [ [archivo, índice] ... ]
my %medio_cuenta;      # forma exacta dentro de la oración -> archivo -> cantidad
my %medio_ejemplos;    # forma exacta dentro de la oración -> [ ... ]
my @total_largos;
my %total = (parrafos => 0, una => 0, max => 0, inicio => '');

# --- 4. RECORRER LOS ARCHIVOS ---
while (@pares) {
  my $nombre = shift @pares;
  my $ruta = shift @pares;
  analizar_archivo($nombre, $ruta);
}

# --- 5. TOTAL DEL PROYECTO ---
emitir('OT', '', scalar(@total_largos), suma(@total_largos), mediana_x2(@total_largos),
  $total{max}, $total{inicio}, $total{parrafos}, $total{una});

# --- 6. VARIANTES ---
emitir_variantes();

exit 0;

# ============================================
# Función   : leer_lineas
# Propósito : lee un archivo de datos: sin comentarios (#) ni líneas vacías
# Parámetros: $ruta
# Retorna   : lista de líneas sin salto ni espacios en los extremos
# ============================================
sub leer_lineas {
  my ($ruta) = @_;
  open(my $fh, '<:encoding(UTF-8)', $ruta) or die "no se pudo leer $ruta: $!\n";
  my @salida;
  while (my $l = <$fh>) {
    $l =~ s/\s+\z//;
    $l =~ s/\A\s+//;
    next if $l eq '' || $l =~ /\A#/;
    push @salida, $l;
  }
  close $fh;
  return @salida;
}

# ============================================
# Función   : emitir
# Propósito : escribe un registro: campos separados por NUL, uno por línea.
#             Ningún campo lleva NUL ni salto: se reemplazan por espacio
# ============================================
sub emitir {
  my @campos = map { my $c = defined $_ ? $_ : ''; $c =~ s/[\x00\n\r]/ /g; $c } @_;
  print join("\0", @campos), "\n";
}

# ============================================
# Función   : es_palabra
# Propósito : el criterio del filtro Lua: un token con al menos una letra o
#             un dígito
# ============================================
sub es_palabra {
  my ($t) = @_;
  return $t =~ /[\p{L}\p{N}]/;
}

# ============================================
# Función   : segmentar
# Propósito : parte el texto de un bloque en oraciones. Corta después de un
#             token que termina en . ? ! o … (con cierres « » ” ’ ) ] detrás)
#             SOLO si el token siguiente empieza con mayúscula (admite antes
#             ¿ ¡ « “ ( [ —), y no si el token es una abreviatura de la lista
#             o una inicial de una letra. Un número detrás no corta: p. 23.
# Parámetros: $texto
# Retorna   : lista de oraciones (texto)
# ============================================
sub segmentar {
  my ($texto) = @_;
  my @tokens = grep { $_ ne '' } split /\s+/, $texto;
  my @oraciones;
  my @actual;

  for my $i (0 .. $#tokens) {
    my $t = $tokens[$i];
    push @actual, $t;
    next if $i == $#tokens;

    # ¿TERMINA EN SIGNO DE CIERRE DE ORACIÓN?
    next unless $t =~ /[.?!…][»”’"')\]]*\z/;
    # ¿LO SIGUE UNA MAYÚSCULA?
    next unless $tokens[$i + 1] =~ /\A[¿¡«“"'(\[—]*\p{Lu}/;

    # ABREVIATURAS E INICIALES: SOLO CUANDO EL SIGNO ES UN PUNTO
    if ($t =~ /\.[»”’"')\]]*\z/) {
      (my $base = $t) =~ s/[»”’"')\]]+\z//;
      $base =~ s/\A[¿¡«“"'(\[—]+//;
      next if $abreviatura{lc $base};
      next if $base =~ /\A\p{Lu}\.\z/;
    }

    push @oraciones, join(' ', @actual);
    @actual = ();
  }
  push @oraciones, join(' ', @actual) if @actual;
  return @oraciones;
}

# ============================================
# Función   : registrar
# Propósito : cuenta una forma en un registro y guarda hasta $MAX_EJEMPLOS
#             oraciones de ejemplo
# ============================================
sub registrar {
  my ($cuenta, $ejemplos, $forma, $nombre, $indice) = @_;
  $cuenta->{$forma}{$nombre}++;
  my $lista = ($ejemplos->{$forma} ||= []);
  push @$lista, [$nombre, $indice] if @$lista < $MAX_EJEMPLOS;
}

# ============================================
# Función   : analizar_archivo
# Propósito : oraciones del cuerpo y formas de todo el texto de un archivo
# ============================================
sub analizar_archivo {
  my ($nombre, $ruta) = @_;
  my @largos;
  my %arch = (parrafos => 0, una => 0, max => 0, inicio => '');

  open(my $fh, '<:encoding(UTF-8)', $ruta) or die "no se pudo leer $ruta: $!\n";
  while (my $linea = <$fh>) {
    chomp $linea;
    my ($ctx, $clase, $parrafo, $texto) = split /\t/, $linea, 4;
    next unless defined $texto;

    # LAS CITAS EN BLOQUE RESPETAN LA GRAFÍA DEL ORIGINAL: NO SE CORRIGEN
    next if $ctx eq 'cita';

    # PÁRRAFO DEL CUERPO: EL MISMO CRITERIO QUE m_AnalizarProyecto
    my $es_parrafo = $ctx eq 'cuerpo' && $parrafo eq '1'
      && ($clase eq '' || $cuerpo{$clase});

    # LOS TÍTULOS SE USAN PARA GUION Y TILDE, NO PARA MAYÚSCULAS: UN TÍTULO
    # PUEDE LLEVAR MAYÚSCULAS DE ESTILO
    my $mira_mayusculas = $ctx ne 'titulo';

    my @oraciones = segmentar($texto);

    if ($es_parrafo) {
      $arch{parrafos}++;
      $arch{una}++ if @oraciones == 1;
    }

    for my $oracion (@oraciones) {
      push @oraciones_texto, $oracion;
      my $indice = $#oraciones_texto;
      my @tokens = grep { $_ ne '' } split /\s+/, $oracion;

      # LARGO DE LA ORACIÓN: SOLO LAS DEL CUERPO
      if ($es_parrafo) {
        my $palabras = grep { es_palabra($_) } @tokens;
        push @largos, $palabras;
        if ($palabras > $arch{max}) {
          $arch{max} = $palabras;
          my @ini = (grep { es_palabra($_) } @tokens)[0 .. $PALABRAS_INICIO - 1];
          $arch{inicio} = join(' ', grep { defined } @ini);
          # LOS PUNTOS SUSPENSIVOS VAN SI LA ORACIÓN SIGUE, Y NO SE DUPLICAN
          $arch{inicio} .= '…' if $palabras > $PALABRAS_INICIO && $arch{inicio} !~ /…\z/;
        }
      }

      # FORMAS: LA PRIMERA PALABRA DE LA ORACIÓN NO CUENTA PARA MAYÚSCULAS
      my $posicion = 0;
      for my $t (@tokens) {
        for my $w ($t =~ /(\p{L}+(?:[-‐]\p{L}+)*)/g) {
          registrar(\%lc_cuenta, \%lc_ejemplos, lc $w, $nombre, $indice);
          if ($mira_mayusculas && $posicion > 0 && $w !~ /[-‐]/) {
            # SOLO LA FORMA «Estado» Y LA FORMA «estado»; LAS ESCRITAS TODA
            # EN MAYÚSCULAS (SIGLAS, ÉNFASIS) NO SE COMPARAN
            if ($w =~ /\A\p{Lu}\p{Ll}+\z/ || $w =~ /\A\p{Ll}+\z/) {
              registrar(\%medio_cuenta, \%medio_ejemplos, $w, $nombre, $indice);
            }
          }
          $posicion++;
        }
      }
    }
  }
  close $fh;

  emitir('O', $nombre, scalar(@largos), suma(@largos), mediana_x2(@largos),
    $arch{max}, $arch{inicio}, $arch{parrafos}, $arch{una});

  # ACUMULAR EN EL TOTAL; LA ORACIÓN MÁS LARGA LLEVA EL NOMBRE DEL ARCHIVO
  push @total_largos, @largos;
  $total{parrafos} += $arch{parrafos};
  $total{una} += $arch{una};
  if ($arch{max} > $total{max}) {
    $total{max} = $arch{max};
    $total{inicio} = "$nombre: $arch{inicio}";
  }
}

# ============================================
# Función   : suma / mediana_x2
# ============================================
sub suma {
  my $s = 0;
  $s += $_ for @_;
  return $s;
}

sub mediana_x2 {
  my @v = sort { $a <=> $b } @_;
  return 0 unless @v;
  my $m = int(@v / 2);
  return @v % 2 ? 2 * $v[$m] : $v[$m - 1] + $v[$m];
}

# ============================================
# Función   : emitir_grupo
# Propósito : emite las formas de un grupo y sus oraciones de ejemplo
# Parámetros: $id, $tipo, $cuenta, $ejemplos, @formas
# ============================================
sub emitir_grupo {
  my ($id, $tipo, $cuenta, $ejemplos, @formas) = @_;
  for my $forma (@formas) {
    my $por_archivo = $cuenta->{$forma} || {};
    my $cantidad = suma(values %$por_archivo);
    my $archivos = join(', ', map { "$_ ($por_archivo->{$_})" } sort keys %$por_archivo);
    emitir('V', $id, $tipo, $forma, $cantidad, $archivos);
    for my $ej (@{ $ejemplos->{$forma} || [] }) {
      my $oracion = $oraciones_texto[$ej->[1]];
      $oracion = substr($oracion, 0, $MAX_LARGO_EJEMPLO) . '…'
        if length($oracion) > $MAX_LARGO_EJEMPLO;
      emitir('X', $id, $forma, $ej->[0], $oracion);
    }
  }
}

# ============================================
# Función   : emitir_variantes
# Propósito : arma los grupos de las tres clases y los emite
# ============================================
sub emitir_variantes {
  my $id = 0;

  # --- GUION: on-line / online. CLAVE: LA FORMA SIN GUIONES ---
  my %por_clave;
  for my $forma (keys %lc_cuenta) {
    (my $clave = $forma) =~ s/[-‐]//g;
    push @{ $por_clave{$clave} }, $forma;
  }
  for my $clave (sort keys %por_clave) {
    my @formas = sort @{ $por_clave{$clave} };
    next unless @formas > 1;
    next unless grep { /[-‐]/ } @formas;
    emitir_grupo(++$id, 'guion', \%lc_cuenta, \%lc_ejemplos, @formas);
  }

  # --- MAYÚSCULA DENTRO DE LA ORACIÓN: Estado / estado ---
  for my $forma (sort keys %medio_cuenta) {
    next unless $forma =~ /\A\p{Lu}/;
    my $minuscula = lc $forma;
    next unless $medio_cuenta{$minuscula};
    emitir_grupo(++$id, 'mayuscula', \%medio_cuenta, \%medio_ejemplos, $forma, $minuscula);
  }

  # --- TILDE: SOLO LA LISTA CERRADA ---
  for my $t (@tildes) {
    my ($tipo, $sin, $con) = @$t;
    next unless $lc_cuenta{$con};
    if ($tipo eq 'opcional') {
      next unless $lc_cuenta{$sin};
      emitir_grupo(++$id, 'tilde', \%lc_cuenta, \%lc_ejemplos, $sin, $con);
    } else {
      my @formas = ($con);
      push @formas, $sin if $lc_cuenta{$sin};
      emitir_grupo(++$id, 'tilde-rae', \%lc_cuenta, \%lc_ejemplos, @formas);
    }
  }
}
