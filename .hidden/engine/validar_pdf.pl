#!/usr/bin/perl
# ============================================
# Script    : validar_pdf.pl
# Propósito : Validación de PDF para la solapa «Validaciones» de gbpublisher
#             (rbPDF). Por cada PDF recibido informa tres grupos:
#               metadatos    XMP e Info contra los valores de la base
#               tecnico      versión, páginas, tamaño, fuentes, cifrado
#               conformidad  la norma que el archivo DECLARA, con veraPDF
#             CALCULA E INFORMA; NO ESCRIBE NUNCA en el proyecto.
#
#             NO TOCA LA BASE. Los valores esperados los escribe Gambas en un
#             archivo (SC-05: Gambas orquesta, el proceso externo procesa).
#
# Ubicación : engine/ — NO se copia a ~/.gbpublisher (SC-11).
# Requiere  : el paquete «perl» completo (GV-90) y libimage-exiftool-perl
#             (Image::ExifTool). JSON::PP es del núcleo de perl. Programas:
#             pdfinfo y pdffonts (poppler-utils); veraPDF solo si algún PDF
#             declara PDF/A.
# Invocación: perl -CSDA validar_pdf.pl <esperado> <pdf1> [<pdf2> ...]
#             -C S  STDIN/STDOUT/STDERR en UTF-8
#             -C D  capas UTF-8 por defecto al abrir archivos
#             -C A  @ARGV decodificado como UTF-8
#
# ENTRADA <esperado> (un registro por línea, campos separados por NUL)
#   objeto  clave  valor
#   objeto  nombre del PDF, o «*» para todos
#   clave   titulo subtitulo autor idioma editorial anio licencia
#           url_licencia palabras_clave isbn doi ancho_mm alto_mm
#           ancho_montaje_mm alto_montaje_mm
#   «autor» se repite, en el orden de la autoría. Un archivo vacío es válido:
#   el grupo metadatos sale como INFO y los otros dos corren igual.
#
# SALIDA (stdout, un registro por línea, campos separados por NUL)
#   objeto  grupo  comprobacion  estado  encontrado  esperado  detalle
#   estado: OK, AVISO, ERROR, INFO.
#
# Sale con código 0 si terminó, aunque haya hallazgos: los hallazgos son
# contenido y los cuenta Gambas. Distinto de 0 solo si no pudo empezar
# (argumentos, archivo de esperados ilegible, falta Image::ExifTool); el
# mensaje va a stderr.
# ============================================

use strict;
use warnings;
use utf8;
use JSON::PP;

# --- CONSTANTES ---
# TOLERANCIA DEL TAMAÑO DE PÁGINA: pdfinfo DA PUNTOS CON TRES DECIMALES Y LA
# BASE GUARDA CENTÍMETROS CON DOS. MEDIO MILÍMETRO CUBRE EL REDONDEO Y NO
# CONFUNDE DOS FORMATOS REALES.
my $TOLERANCIA_MM = 0.5;
# REGLAS FALLIDAS DE veraPDF QUE SE NOMBRAN EN EL DETALLE
my $MAX_REGLAS = 5;
# DÓNDE SE BUSCA veraPDF, EN ESTE ORDEN: LOS MISMOS LUGARES QUE
# m_XML.ValidarPDFA (PATH, /opt/verapdf, INSTALACIÓN SIN sudo EN EL HOME)
my @RUTAS_VERAPDF = ('/opt/verapdf/verapdf', ($ENV{HOME} // '') . '/verapdf/verapdf');

# --- 1. ARGUMENTOS ---
my ($ruta_esperado, @pdfs) = @ARGV;
die "uso: validar_pdf.pl <esperado> <pdf1> [<pdf2> ...]\n"
  unless defined $ruta_esperado && @pdfs;

# Image::ExifTool SE CARGA ACÁ Y NO CON use: SI FALTA, EL MENSAJE TIENE QUE
# DECIR QUÉ PAQUETE INSTALAR, NO UN «Can't locate» CON TODO EL @INC
eval { require Image::ExifTool; 1 }
  or die "falta Image::ExifTool: instalar el paquete libimage-exiftool-perl\n";

# --- 2. VALORES ESPERADOS ---
# %esperado{objeto}{clave} = [valores]: UNA LISTA PORQUE «autor» SE REPITE
my %esperado;
open(my $fh_esp, '<', $ruta_esperado)
  or die "no se pudo leer el archivo de esperados $ruta_esperado: $!\n";
while (my $linea = <$fh_esp>) {
  chomp $linea;
  next if $linea eq '';
  my ($objeto, $clave, $valor) = split /\0/, $linea, 3;
  next unless defined $clave;
  push @{ $esperado{$objeto}{$clave} }, $valor // '';
}
close $fh_esp;

# --- 3. HERRAMIENTAS EXTERNAS ---
my $verapdf = BuscarVeraPDF();

# --- 4. RECORRIDO ---
# UN PDF QUE FALLA NO CORTA A LOS DEMÁS: CON «(todos)» EL EDITOR NECESITA VER
# EL ESTADO DE CADA ARCHIVO
for my $ruta (@pdfs) {
  ValidarArchivo($ruta);
}

exit 0;

# ============================================
# 5. FUNCIONES
# ============================================

# ============================================
# Función   : ValidarArchivo
# Propósito : Corre los tres grupos sobre un PDF.
# Parámetros: $ruta — ruta del PDF (texto decodificado)
# Retorna   : nada; escribe registros
# ============================================
sub ValidarArchivo {
  my ($ruta) = @_;

  # --- 1. INICIALIZACIÓN ---
  my $objeto = $ruta;
  $objeto =~ s{.*/}{};

  # --- 2. VALIDACIÓN DE ENTRADA ---
  unless (-f $ruta && -r $ruta) {
    Registro($objeto, 'tecnico', 'Archivo', 'ERROR', '', '',
      'no existe o no se puede leer');
    return;
  }

  # --- 3. LECTURA ---
  my $meta = LeerMetadatos($ruta);
  unless ($meta) {
    Registro($objeto, 'metadatos', 'Lectura', 'ERROR', '', '',
      'exiftool no pudo leer el archivo');
    return;
  }
  my $info = LeerPdfinfo($ruta);
  my $fuentes = LeerPdffonts($ruta);

  # --- 4. LOS TRES GRUPOS ---
  # LOS ESPERADOS DEL ARCHIVO GANAN SOBRE LOS GENERALES («*»)
  my %esp = (%{ $esperado{'*'} // {} }, %{ $esperado{$objeto} // {} });

  GrupoMetadatos($objeto, $meta, \%esp, -s $ruta);
  GrupoTecnico($objeto, $meta, $info, $fuentes, \%esp);
  GrupoConformidad($objeto, $ruta, $meta);
}

# ============================================
# Función   : GrupoMetadatos
# Propósito : Compara XMP e Info con la base, y los dos entre sí.
# Parámetros: $objeto, $meta (de LeerMetadatos), $esp (hash de listas),
#             $bytes — tamaño real del archivo
# ============================================
sub GrupoMetadatos {
  my ($objeto, $meta, $esp, $bytes) = @_;

  # --- 1. LO ENCONTRADO ---
  my $titulo    = Uno($meta, 'XMP-dc:Title');
  my $subtitulo = Uno($meta, 'XMP-dc:Description');
  my @autores   = Lista($meta, 'XMP-dc:Creator');
  my $idioma    = Uno($meta, 'XMP-dc:Language');
  my $editorial = Uno($meta, 'XMP-dc:Publisher');
  my $fecha     = Uno($meta, 'XMP-dc:Date');
  my $licencia  = Uno($meta, 'XMP-dc:Rights');
  my $url_lic   = Uno($meta, 'XMP-xmpRights:WebStatement');
  # pdf:Keywords LO ESCRIBE hyperxmp; CON \DocumentMetadata hyperxmp NO SE
  # CARGA Y LAS CLAVES QUEDAN SOLO EN dc:subject (MEDIDO, TeX Live 2023)
  my $claves    = Uno($meta, 'XMP-pdf:Keywords')
                  // (Lista($meta, 'XMP-dc:Subject') ? join(', ', Lista($meta, 'XMP-dc:Subject')) : undef);
  # prism:isbn LO ESCRIBE hyperxmp. CON \DocumentMetadata (EL PDF/A) hyperxmp
  # NO SE CARGA, pdfisbn SE IGNORA Y EL ISBN LLEGA SOLO POR pdfidentifier, A
  # dc:identifier COMO urn:isbn: (MEDIDO, TeX Live 2023)
  my $isbn      = Uno($meta, 'XMP-prism:ISBN');
  if (!defined $isbn || $isbn eq '') {
    my ($id) = grep { /^urn:isbn:/i } Lista($meta, 'XMP-dc:Identifier');
    ($isbn = $id) =~ s/^urn:isbn://i if defined $id;
  }
  my $doi       = Uno($meta, 'XMP-prism:DOI');

  # --- 2. CONTRA LA BASE ---
  # SIN ESPERADOS NO HAY CONTRA QUÉ COMPARAR: UNA SOLA FILA LO DICE, Y LA
  # COHERENCIA ENTRE Info Y XMP CORRE IGUAL PORQUE NO NECESITA LA BASE
  if (!%$esp) {
    Registro($objeto, 'metadatos', 'Valores esperados', 'INFO', '', '',
      'sin valores de la base para este archivo: no se comparan');
  } else {
    # OBLIGATORIOS: SI FALTAN EN EL PDF, ES ERROR
    Comparar($objeto, 'Título', $titulo, Esp($esp, 'titulo'), 'obligatorio');
    CompararAutoria($objeto, \@autores, $esp->{autor} // []);
    CompararIdioma($objeto, $idioma, Esp($esp, 'idioma'));
    Comparar($objeto, 'Editorial', $editorial, Esp($esp, 'editorial'), 'obligatorio');
    # dc:date PUEDE VENIR COMO AÑO O COMO FECHA: SE COMPARA EL AÑO
    my ($anio) = ($fecha // '') =~ /^(\d{4})/;
    Comparar($objeto, 'Año', $anio, Esp($esp, 'anio'), 'obligatorio');

    # OPCIONALES: SI FALTAN EN EL PDF TENIÉNDOLOS LA BASE, ES AVISO
    Comparar($objeto, 'Subtítulo', $subtitulo, Esp($esp, 'subtitulo'), 'opcional');
    Comparar($objeto, 'Licencia', $licencia, Esp($esp, 'licencia'), 'opcional');
    Comparar($objeto, 'URL de licencia', $url_lic, Esp($esp, 'url_licencia'), 'opcional');
    CompararClaves($objeto, $claves, Esp($esp, 'palabras_clave'));

    # IDENTIFICADORES: SU FALTA ES AVISO AUNQUE LA BASE NO LOS TENGA. UN LIBRO
    # EN DESARROLLO TODAVÍA NO TIENE ISBN, Y PUEDE NO TENER NUNCA DOI
    Comparar($objeto, 'ISBN', $isbn, Esp($esp, 'isbn'), 'identificador');
    Comparar($objeto, 'DOI', $doi, Esp($esp, 'doi'), 'identificador');
  }

  # --- 3. COHERENCIA ENTRE Info Y XMP ---
  # CADA LECTOR MIRA UNO: SI DIFIEREN, EL LIBRO SE CATALOGA DISTINTO SEGÚN
  # QUIÉN LO LEA
  Coherencia($objeto, 'Título: Info y XMP', Uno($meta, 'PDF:Title'), $titulo);
  Coherencia($objeto, 'Autoría: Info y XMP', Uno($meta, 'PDF:Author'),
    @autores ? join(', ', @autores) : undef);

  # --- 4. prism:byteCount ---
  # hyperxmp CON LuaLaTeX ESCRIBE EL TAMAÑO DE LA COMPILACIÓN ANTERIOR
  # (GV-101): UN DATO FALSO QUE VIAJA EN EL XMP
  my $cuenta = Uno($meta, 'XMP-prism:ByteCount');
  if (defined $cuenta && $cuenta ne '') {
    if ($cuenta == $bytes) {
      Registro($objeto, 'metadatos', 'prism:byteCount', 'OK', $cuenta, $bytes, '');
    } else {
      Registro($objeto, 'metadatos', 'prism:byteCount', 'AVISO', $cuenta, $bytes,
        'no es el tamaño del archivo: hyperxmp con LuaLaTeX toma el de la compilación anterior (GV-101)');
    }
  }
}

# ============================================
# Función   : GrupoTecnico
# Propósito : Versión, páginas, tamaño, fuentes, cifrado, JavaScript,
#             etiquetado, herramienta y productor.
# ============================================
sub GrupoTecnico {
  my ($objeto, $meta, $info, $fuentes, $esp) = @_;

  # --- 1. pdfinfo ---
  # SIN pdfinfo NO HAY GRUPO TÉCNICO: UNA FILA LO DICE Y SE SIGUE
  unless ($info) {
    Registro($objeto, 'tecnico', 'pdfinfo', 'ERROR', '', '',
      'no se pudo ejecutar pdfinfo (poppler-utils)');
  } else {
    Registro($objeto, 'tecnico', 'Versión PDF', 'INFO', $info->{'PDF version'} // '', '', '');
    Registro($objeto, 'tecnico', 'Páginas', 'INFO', $info->{'Pages'} // '', '', '');
    TamanioPagina($objeto, $info->{'Page size'}, $esp);
    SiNo($objeto, 'Cifrado', $info->{'Encrypted'}, 'el archivo está cifrado');
    SiNo($objeto, 'JavaScript', $info->{'JavaScript'}, 'el archivo tiene JavaScript');
    my $etiquetado = $info->{'Tagged'} // '';
    Registro($objeto, 'tecnico', 'Etiquetado', 'INFO', $etiquetado, '',
      $etiquetado eq 'yes' ? 'PDF etiquetado' : 'sin estructura lógica');
  }

  # --- 2. FUENTES ---
  if (!$fuentes) {
    Registro($objeto, 'tecnico', 'pdffonts', 'ERROR', '', '',
      'no se pudo ejecutar pdffonts (poppler-utils)');
  } else {
    # SOLO LAS FUENTES USADAS: pdffonts LISTA LAS DEL CONTENIDO; EL XMP
    # (xmpTPg) LISTA TAMBIÉN LAS CARGADAS Y NO USADAS
    my @sin_emb = map { $_->{nombre} } grep { $_->{emb} ne 'yes' } @$fuentes;
    my @sin_uni = map { $_->{nombre} } grep { $_->{uni} ne 'yes' } @$fuentes;
    my $total = scalar @$fuentes;
    Registro($objeto, 'tecnico', 'Fuentes embebidas',
      @sin_emb ? 'ERROR' : 'OK', ($total - @sin_emb) . " de $total", "$total de $total",
      @sin_emb ? 'sin embeber: ' . join(', ', @sin_emb) : '');
    # SIN TABLA ToUnicode ES AVISO, NUNCA ERROR. LA COLUMNA uni DE pdffonts
    # SOLO DICE SI LA FUENTE TRAE LA TABLA, Y UNA Type 1 CON NOMBRES DE GLIFO
    # ESTÁNDAR SE MAPEA A UNICODE SIN ELLA: MEDIDO, UN PDF/A-2u CON LCIRCLE10
    # (uni no) PASA veraPDF 1.30. LA CONFORMIDAD LA DECIDE veraPDF, EN SU
    # GRUPO. LCIRCLE10 SON LOS CÍRCULOS DE LAS CRUCES DE crop (OPCIÓN cam),
    # DIBUJADOS CON \circle (l-CALIFA DE IMPRENTA)
    my $detalle = '';
    if (@sin_uni) {
      $detalle = 'sin tabla ToUnicode: ' . join(', ', @sin_uni);
      $detalle .= '. LCIRCLE son los círculos de las cruces de corte (crop, cam): no es texto'
        if grep { /LCIRCLE/i } @sin_uni;
      $detalle .= '. Si es una fuente de texto, revisar que el texto se copie bien';
    }
    Registro($objeto, 'tecnico', 'Fuentes con Unicode',
      @sin_uni ? 'AVISO' : 'OK',
      ($total - @sin_uni) . " de $total", "$total de $total", $detalle);
  }

  # --- 3. HERRAMIENTA Y PRODUCTOR ---
  # Creator / xmp:CreatorTool ES LA APLICACIÓN; Producer ES EL MOTOR. LOS DOS
  # JUNTOS DICEN QUÉ VERSIÓN COMPUSO CON QUÉ VERSIÓN (GV-101)
  my $herramienta = Uno($meta, 'XMP-xmp:CreatorTool') // Uno($meta, 'PDF:Creator') // '';
  if ($herramienta =~ /^gbpublisher\b/) {
    Registro($objeto, 'tecnico', 'Herramienta', 'INFO', $herramienta, '', '');
  } else {
    Registro($objeto, 'tecnico', 'Herramienta', 'AVISO', $herramienta, 'gbpublisher',
      'el PDF no dice que lo produjo gbpublisher: generado por fuera o antes del cambio');
  }
  my $productor = Uno($meta, 'PDF:Producer') // Uno($meta, 'XMP-pdf:Producer') // '';
  Registro($objeto, 'tecnico', 'Productor', 'INFO', $productor, '', '');
}

# ============================================
# Función   : GrupoConformidad
# Propósito : Valida la norma que el archivo DECLARA. Sin declaración no se
#             llama a veraPDF: con -f 0 y sin pdfaid, veraPDF valida contra
#             PDF/A-1b por defecto y da miles de errores falsos (medido en
#             l-CALIFA.pdf: «PDF/A-1b validation profile», 9 reglas).
# ============================================
sub GrupoConformidad {
  my ($objeto, $ruta, $meta) = @_;

  # --- 1. LO QUE DECLARA ---
  my $parte = Uno($meta, 'XMP-pdfaid:Part');
  my $nivel = Uno($meta, 'XMP-pdfaid:Conformance');
  # EL NOMBRE DE LA ETIQUETA PDF/X VARÍA SEGÚN DÓNDE LA ESCRIBA EL PRODUCTOR
  # (Info O XMP): SE BUSCA POR NOMBRE EN CUALQUIER GRUPO
  my ($pdfx) = map { $meta->{$_}[0] } grep { /GTS_PDFXVersion$/ } sort keys %$meta;

  # --- 2. PDF/X: SIN VALIDADOR LIBRE ---
  if (defined $pdfx && $pdfx ne '') {
    Registro($objeto, 'conformidad', 'PDF/X', 'INFO', $pdfx, '',
      'declara PDF/X; veraPDF no valida PDF/X y no hay validador libre');
  }

  # --- 3. SIN PDF/A DECLARADO ---
  unless (defined $parte && $parte ne '') {
    Registro($objeto, 'conformidad', 'PDF/A', 'INFO', '', '', 'no declara PDF/A')
      unless defined $pdfx && $pdfx ne '';
    return;
  }

  # --- 4. PDF/A DECLARADO: veraPDF CON EL NIVEL DECLARADO ---
  # SE PASA EL NIVEL EXPLÍCITO (-f 2u) Y NO -f 0: ASÍ NUNCA CAE EN EL 1b POR
  # DEFECTO SI LA AUTODETECCIÓN FALLA
  my $sabor = lc($parte . ($nivel // ''));
  my $declarada = 'PDF/A-' . $parte . uc($nivel // '');

  unless ($verapdf) {
    Registro($objeto, 'conformidad', 'PDF/A', 'ERROR', $declarada, '',
      'declara PDF/A pero no se encontró veraPDF (PATH, /opt/verapdf, ~/verapdf)');
    return;
  }

  my $salida = Ejecutar($verapdf, '-f', $sabor, '--format', 'json', $ruta);
  my $resultado = LeerJsonVeraPDF($salida);
  unless ($resultado) {
    Registro($objeto, 'conformidad', 'PDF/A', 'ERROR', $declarada, '',
      'veraPDF no devolvió un informe legible');
    return;
  }

  # --- 5. INFORME ---
  # compliant ES UN BOOLEANO DE JSON::PP: SE EVALÚA, NO SE COMPARA CON TEXTO
  my $perfil = $resultado->{profileName} // '';
  if ($resultado->{compliant}) {
    Registro($objeto, 'conformidad', 'PDF/A', 'OK', $declarada, $declarada, $perfil);
  } else {
    my $detalles = $resultado->{details} // {};
    my @reglas = map { ($_->{clause} // '?') . ' ' . ($_->{description} // '') }
                 grep { ($_->{status} // '') eq 'failed' }
                 @{ $detalles->{ruleSummaries} // [] };
    my $fallidas = $detalles->{failedRules} // scalar @reglas;
    my $texto = "$perfil: $fallidas regla(s) fallida(s)";
    $texto .= '; ' . join('; ', @reglas[0 .. ($#reglas < $MAX_REGLAS - 1 ? $#reglas : $MAX_REGLAS - 1)])
      if @reglas;
    Registro($objeto, 'conformidad', 'PDF/A', 'ERROR', $declarada, $declarada, $texto);
  }
}

# ============================================
# 6. COMPARACIONES
# ============================================

# ============================================
# Función   : Comparar
# Propósito : Compara un valor del PDF con el de la base y escribe la fila.
# Parámetros: $objeto, $nombre, $hallado, $esperado,
#             $clase — obligatorio | opcional | identificador
# ============================================
sub Comparar {
  my ($objeto, $nombre, $hallado, $esperado, $clase) = @_;

  my $h = Normalizar($hallado);
  my $e = Normalizar($esperado);

  # LAS DOS VACÍAS: SOLO LOS IDENTIFICADORES LO INFORMAN (DECISIÓN: SU FALTA
  # ES AVISO AUNQUE LA BASE TAMPOCO LOS TENGA)
  if ($h eq '' && $e eq '') {
    if ($clase eq 'identificador') {
      Registro($objeto, 'metadatos', $nombre, 'AVISO', '', '', 'no está en la base ni en el PDF');
    } elsif ($clase eq 'obligatorio') {
      Registro($objeto, 'metadatos', $nombre, 'ERROR', '', '', 'no está en la base ni en el PDF');
    }
    return;
  }

  if ($h eq $e) {
    Registro($objeto, 'metadatos', $nombre, 'OK', $h, $e, '');
  } elsif ($h eq '') {
    Registro($objeto, 'metadatos', $nombre, $clase eq 'obligatorio' ? 'ERROR' : 'AVISO',
      '', $e, 'la base lo tiene y el PDF no: recompilar');
  } elsif ($e eq '') {
    Registro($objeto, 'metadatos', $nombre, 'AVISO', $h, '',
      'el PDF lo tiene y la base no');
  } else {
    Registro($objeto, 'metadatos', $nombre, 'ERROR', $h, $e, 'difiere de la base');
  }
}

# ============================================
# Función   : CompararAutoria
# Propósito : La lista de dc:creator contra la de la base: cantidad, orden y
#             forma. Una lista partida (GV-101) da otra cantidad.
# ============================================
sub CompararAutoria {
  my ($objeto, $hallados, $esperados) = @_;

  my @h = map { Normalizar($_) } @$hallados;
  my @e = map { Normalizar($_) } @$esperados;
  my $th = join(' · ', @h);
  my $te = join(' · ', @e);

  if (!@e) {
    Registro($objeto, 'metadatos', 'Autoría', 'ERROR', $th, '', 'la base no tiene autoría');
  } elsif (!@h) {
    Registro($objeto, 'metadatos', 'Autoría', 'ERROR', '', $te, 'el PDF no tiene dc:creator');
  } elsif ($th eq $te) {
    Registro($objeto, 'metadatos', 'Autoría', 'OK', $th, $te, '');
  } elsif (@h != @e) {
    Registro($objeto, 'metadatos', 'Autoría', 'ERROR', $th, $te,
      scalar(@h) . ' elemento(s) en el PDF y ' . scalar(@e) . ' en la base');
  } else {
    Registro($objeto, 'metadatos', 'Autoría', 'ERROR', $th, $te, 'difiere en la forma o en el orden');
  }
}

# ============================================
# Función   : CompararIdioma
# Propósito : Compara la subetiqueta principal del idioma, sin mayúsculas:
#             «es» y «es-AR» son el mismo idioma para un catálogo.
# ============================================
sub CompararIdioma {
  my ($objeto, $hallado, $esperado) = @_;

  my ($h) = lc(Normalizar($hallado)) =~ /^([a-z]+)/;
  my ($e) = lc(Normalizar($esperado)) =~ /^([a-z]+)/;
  Comparar($objeto, 'Idioma', $h, $e, 'obligatorio');
}

# ============================================
# Función   : CompararClaves
# Propósito : Palabras clave como conjunto ordenado: hyperxmp las separa en
#             las comas, así que se comparan elemento por elemento.
# ============================================
sub CompararClaves {
  my ($objeto, $hallado, $esperado) = @_;

  my $h = join(', ', grep { $_ ne '' } map { Normalizar($_) } split /,/, $hallado // '');
  my $e = join(', ', grep { $_ ne '' } map { Normalizar($_) } split /,/, $esperado // '');
  Comparar($objeto, 'Palabras clave', $h, $e, 'opcional');
}

# ============================================
# Función   : Coherencia
# Propósito : Info contra XMP. Si falta Info es AVISO: hyperxmp lo quita sin
#             keeppdfinfo (GV-101).
# ============================================
sub Coherencia {
  my ($objeto, $nombre, $info, $xmp) = @_;

  my $i = Normalizar($info);
  my $x = Normalizar($xmp);
  return if $i eq '' && $x eq '';

  if ($i eq $x) {
    Registro($objeto, 'metadatos', $nombre, 'OK', $i, $x, '');
  } elsif ($i eq '') {
    Registro($objeto, 'metadatos', $nombre, 'AVISO', '', $x,
      'falta en Info: hay lectores que solo miran Info (keeppdfinfo, GV-101)');
  } else {
    Registro($objeto, 'metadatos', $nombre, 'ERROR', $i, $x,
      'Info y XMP dicen cosas distintas');
  }
}

# ============================================
# Función   : TamanioPagina
# Propósito : El tamaño de la primera página contra el formato del libro.
#             Formato final: OK. Hoja de montaje: AVISO, porque el nombre del
#             archivo no dice con qué estado se compuso y puede ser el de
#             imprenta. Otro tamaño: ERROR.
# ============================================
sub TamanioPagina {
  my ($objeto, $texto, $esp) = @_;

  # «439.37 x 651.968 pts» Y A VECES UN NOMBRE DE FORMATO DETRÁS
  my ($ancho_pt, $alto_pt) = ($texto // '') =~ /([\d.]+)\s*x\s*([\d.]+)\s*pts/;
  unless (defined $alto_pt) {
    Registro($objeto, 'tecnico', 'Tamaño de página', 'ERROR', $texto // '', '',
      'pdfinfo no informó el tamaño');
    return;
  }

  my $ancho = $ancho_pt * 25.4 / 72;
  my $alto = $alto_pt * 25.4 / 72;
  my $hallado = Medida($ancho, $alto);

  my $e_ancho = Esp($esp, 'ancho_mm');
  my $e_alto = Esp($esp, 'alto_mm');
  unless ($e_ancho ne '' && $e_alto ne '') {
    Registro($objeto, 'tecnico', 'Tamaño de página', 'INFO', $hallado, '',
      'sin formato en la base para comparar');
    return;
  }

  if (Cerca($ancho, $e_ancho) && Cerca($alto, $e_alto)) {
    Registro($objeto, 'tecnico', 'Tamaño de página', 'OK', $hallado, Medida($e_ancho, $e_alto), 'formato final');
    return;
  }

  my $m_ancho = Esp($esp, 'ancho_montaje_mm');
  my $m_alto = Esp($esp, 'alto_montaje_mm');
  if ($m_ancho ne '' && Cerca($ancho, $m_ancho) && Cerca($alto, $m_alto)) {
    Registro($objeto, 'tecnico', 'Tamaño de página', 'AVISO', $hallado, Medida($e_ancho, $e_alto),
      'hoja de montaje con cruces: es el PDF de imprenta, no sirve para pantalla ni preservación');
    return;
  }

  Registro($objeto, 'tecnico', 'Tamaño de página', 'ERROR', $hallado, Medida($e_ancho, $e_alto),
    'no coincide con el formato del libro ni con su hoja de montaje');
}

# ============================================
# Función   : SiNo
# Propósito : Una propiedad de pdfinfo que tiene que ser «no».
# ============================================
sub SiNo {
  my ($objeto, $nombre, $valor, $problema) = @_;

  $valor //= '';
  if ($valor eq 'no') {
    Registro($objeto, 'tecnico', $nombre, 'OK', 'no', 'no', '');
  } else {
    Registro($objeto, 'tecnico', $nombre, 'ERROR', $valor, 'no', $problema);
  }
}

# ============================================
# 7. LECTURA DE LAS HERRAMIENTAS
# ============================================

# ============================================
# Función   : LeerMetadatos
# Propósito : Lee XMP e Info con Image::ExifTool.
# Parámetros: $ruta — ruta del PDF
# Retorna   : hash ref { "Grupo:Nombre" => [valores] }, o undef si no pudo.
#             Los valores con idioma (dc:title, dc:description, dc:rights:
#             «Title-es») se guardan sin el sufijo: lo que importa es el
#             texto.
# Nota      : CON Charset UTF8, exiftool DEVUELVE BYTES EN UTF-8. SE
#             DECODIFICAN CON utf8::decode, QUE ES DEL NÚCLEO, PARA QUE LA
#             CAPA -C S DE stdout NO LOS CODIFIQUE DOS VECES.
#             UNA LISTA (dc:creator) LLEGA COMO ARRAY CON List => 1.
# ============================================
sub LeerMetadatos {
  my ($ruta) = @_;

  my $et = Image::ExifTool->new;
  $et->Options(List => 1, Charset => 'UTF8', Duplicates => 1);
  my $bytes = $ruta;
  utf8::encode($bytes);
  return undef unless $et->ExtractInfo($bytes);

  my %meta;
  for my $clave ($et->GetFoundTags('File')) {
    my $grupo = $et->GetGroup($clave, 1);
    next unless $grupo =~ /^(XMP-|PDF$)/;
    my $nombre = Image::ExifTool::GetTagName($clave);
    $nombre =~ s/-[a-zA-Z]{2,3}(?:-[a-zA-Z0-9]+)?$//;
    my $valor = $et->GetValue($clave);
    my @valores = ref $valor eq 'ARRAY' ? @$valor : ($valor);
    for my $v (@valores) {
      next if ref $v;
      utf8::decode($v);
      push @{ $meta{"$grupo:$nombre"} }, $v;
    }
  }
  return \%meta;
}

# ============================================
# Función   : LeerPdfinfo
# Propósito : Las líneas «Clave: valor» de pdfinfo.
# Retorna   : hash ref, o undef si pdfinfo no corrió
# ============================================
sub LeerPdfinfo {
  my ($ruta) = @_;

  my $salida = Ejecutar('pdfinfo', $ruta);
  return undef unless defined $salida && $salida =~ /^Pages:/m;

  my %info;
  for my $linea (split /\n/, $salida) {
    $info{$1} = $2 if $linea =~ /^([^:]+):\s*(.*?)\s*$/;
  }
  return \%info;
}

# ============================================
# Función   : LeerPdffonts
# Propósito : Las fuentes del contenido, con emb y uni.
# Retorna   : array ref de { nombre, emb, uni }, o undef si no corrió
# Nota      : LAS COLUMNAS SE CORTAN POR LA POSICIÓN DE LOS GUIONES DE LA
#             SEGUNDA LÍNEA: EL NOMBRE Y EL TIPO PUEDEN TENER ESPACIOS
#             («CID Type 0C»), ASÍ QUE PARTIR POR ESPACIOS FALLARÍA.
# ============================================
sub LeerPdffonts {
  my ($ruta) = @_;

  my $salida = Ejecutar('pdffonts', $ruta);
  return undef unless defined $salida && $salida =~ /^name\s+type/m;

  my @lineas = split /\n/, $salida;
  my $guiones = $lineas[1] // '';
  my @columnas;
  while ($guiones =~ /(-+)/g) {
    push @columnas, [ $-[1], $+[1] - $-[1] ];
  }
  return [] unless @columnas >= 6;

  my @fuentes;
  for my $linea (@lineas[2 .. $#lineas]) {
    next if $linea =~ /^\s*$/;
    my @c = map { Normalizar(length($linea) > $_->[0] ? substr($linea, $_->[0], $_->[1]) : '') } @columnas;
    push @fuentes, { nombre => $c[0], emb => $c[3], uni => $c[5] };
  }
  return \@fuentes;
}

# ============================================
# Función   : LeerJsonVeraPDF
# Propósito : El primer validationResult del informe JSON de veraPDF.
# Retorna   : hash ref con compliant, profileName, details; undef si no hay
# Nota      : ESTRUCTURA MEDIDA CON veraPDF 1.30.1:
#             report.jobs[0].validationResult[0] = { compliant, details,
#             jobEndStatus, profileName, statement }.
#             LA SALIDA YA ES TEXTO DECODIFICADO (CAPA -C D): EL DECODIFICADOR
#             VA SIN utf8.
# ============================================
sub LeerJsonVeraPDF {
  my ($salida) = @_;

  return undef unless defined $salida;
  my $inicio = index($salida, '{');
  return undef if $inicio < 0;

  my $json = eval { JSON::PP->new->decode(substr($salida, $inicio)) };
  return undef unless $json;

  my $resultado = $json->{report}{jobs}[0]{validationResult};
  $resultado = $resultado->[0] if ref $resultado eq 'ARRAY';
  return ref $resultado eq 'HASH' ? $resultado : undef;
}

# ============================================
# 8. AUXILIARES
# ============================================

# ============================================
# Función   : Ejecutar
# Propósito : Corre un programa SIN shell y devuelve su stdout.
# Retorna   : el texto, o undef si no se pudo lanzar
# Nota      : open CON LISTA: LAS RUTAS NO PASAN POR sh (SC-05). stderr SE
#             DESCARTA: pdfinfo AVISA POR AHÍ DE COSAS QUE NO SON FALLAS.
# ============================================
sub Ejecutar {
  my (@comando) = @_;

  my @bytes = map { my $b = $_; utf8::encode($b); $b } @comando;
  my $pid = open(my $fh, '-|') // return undef;
  if ($pid == 0) {
    open(STDERR, '>', '/dev/null');
    exec { $bytes[0] } @bytes or exit 127;
  }
  local $/;
  my $salida = <$fh>;
  close $fh;
  return undef if ($? >> 8) == 127;
  return $salida;
}

# ============================================
# Función   : BuscarVeraPDF
# Propósito : Ruta del ejecutable de veraPDF, o undef.
# ============================================
sub BuscarVeraPDF {
  for my $dir (split /:/, $ENV{PATH} // '') {
    return "$dir/verapdf" if $dir ne '' && -x "$dir/verapdf";
  }
  for my $ruta (@RUTAS_VERAPDF) {
    return $ruta if -x $ruta;
  }
  return undef;
}

# ============================================
# Función   : Uno / Lista / Esp
# Propósito : Acceso a los valores: el primero, todos, o el esperado.
# ============================================
sub Uno {
  my ($meta, $clave) = @_;
  return $meta->{$clave} ? $meta->{$clave}[0] : undef;
}

sub Lista {
  my ($meta, $clave) = @_;
  return $meta->{$clave} ? @{ $meta->{$clave} } : ();
}

sub Esp {
  my ($esp, $clave) = @_;
  return $esp->{$clave} ? $esp->{$clave}[0] : '';
}

# ============================================
# Función   : Normalizar
# Propósito : Sin espacios en los extremos y con los internos colapsados.
#             No cambia mayúsculas: «Imago Mundi» e «imago mundi» difieren.
# ============================================
sub Normalizar {
  my ($texto) = @_;
  return '' unless defined $texto;
  $texto =~ s/\s+/ /g;
  $texto =~ s/^ | $//g;
  return $texto;
}

# ============================================
# Función   : Cerca / Medida
# Propósito : Comparación de medidas con tolerancia, y su forma legible.
# ============================================
sub Cerca {
  my ($a, $b) = @_;
  return abs($a - $b) <= $TOLERANCIA_MM;
}

sub Medida {
  my ($ancho, $alto) = @_;
  return sprintf('%.1f × %.1f mm', $ancho, $alto);
}

# ============================================
# Función   : Registro
# Propósito : Escribe un registro de salida. Un NUL o un salto de línea en un
#             valor romperían el registro: se reemplazan por un espacio.
# ============================================
sub Registro {
  my @campos = map { my $c = $_ // ''; $c =~ s/[\0\r\n]+/ /g; $c } @_;
  print join("\0", @campos), "\n";
}
