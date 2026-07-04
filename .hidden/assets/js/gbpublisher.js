/* ============================================================
 * gbpublisher.js — Interactividad compartida (libros y revistas)
 * ============================================================
 *
 * Este archivo NO es autosuficiente. Cada HTML debe declarar
 * ANTES de este script el objeto global window.citaData con la
 * estructura esperada por generarCita() (revisar la función más
 * abajo para el shape esperado).
 *
 * Estructura de citaData para LIBROS (index.html):
 *   var citaData = {
 *     tipo: "libro",
 *     titulo: "Título del libro",
 *     editorial: "Nombre editorial",
 *     ciudad: "Buenos Aires",
 *     isbn: "978-...",
 *     doi: "10.xxxx/yyy",
 *     anio: "2026",
 *     autores: [{apellido:"...", nombre:"..."}, ...],
 *     editores: [{apellido:"...", nombre:"..."}, ...]
 *   };
 *
 * Estructura de citaData para CAPÍTULOS (h-*.html):
 *   var citaData = {
 *     tipo: "capitulo",
 *     titulo: "Título del capítulo",
 *     tituloLibro: "Título del libro",
 *     editorial: "...", ciudad: "...", isbn: "...",
 *     doi: "...", anio: "...", paginaI: "1", paginaF: "12",
 *     autores: [...], editores: [...]
 *   };
 *
 * Estructura para ARTÍCULOS (compatibilidad con revistas):
 *   var citaData = {
 *     tipo: "articulo",
 *     titulo: "...", revista: "...", doi: "...",
 *     anio: "...", volumen: "...", numero: "...",
 *     paginaI: "...", paginaF: "...",
 *     autores: [...]
 *   };
 *
 * Funciones expuestas (usadas por el HTML generado):
 *   togglePanel(), openDrawerMeta(), openDrawerPanel(),
 *   closeDrawers(), mostrarFormato(), copiarCita()
 * ============================================================ */

// ============================================
// INICIALIZACIÓN: CONSTRUIR PANEL DESDE EL DOM
// ============================================
document.addEventListener('DOMContentLoaded', function() {
  buildNotesPanel();
  buildFigsPanel();
  updateCounts();
  // MOSTRAR APA POR DEFECTO SIN EVENTO
  document.getElementById('citar-output').textContent = generarCita('apa');
});

// ============================================
// CONSTRUIR INICIAL DE NOMBRE (ej: "J. A.")
// ============================================
function iniciales(nombre) {
  if (!nombre) return '';
  return nombre.split(' ').map(function(p) {
    return p.charAt(0).toUpperCase() + '.';
  }).join(' ');
}

// ============================================
// GENERAR CITA SEGÚN FORMATO
// ============================================
function generarCita(formato) {
  var d = citaData;
  if (d.tipo === 'libro')    return generarCitaLibro(formato, d);
  if (d.tipo === 'capitulo') return generarCitaCapitulo(formato, d);
  return generarCitaArticulo(formato, d);
}

// ============================================
// LOCALIZADOR HTML: DOI Y/O URL (NO PÁGINAS)
// ============================================
function localizadorHtml(d) {
  var loc = '';
  if (d.doi) loc = 'https://doi.org/' + d.doi;
  else if (d.url) loc = d.url;
  return loc;
}

// ============================================
// AUTORES O EDITORES SEGÚN DISPONIBILIDAD
// ============================================
function personasCita(d) {
  if (d.autores && d.autores.length > 0) return { lista: d.autores, esEditor: false };
  if (d.editores && d.editores.length > 0) return { lista: d.editores, esEditor: true };
  return { lista: [], esEditor: false };
}

// ============================================
// CITA DE ARTÍCULO (REVISTAS)
// ============================================
function generarCitaArticulo(formato, d) {
  var doiUrl = d.doi ? 'https://doi.org/' + d.doi : '';
  var pages  = d.paginaI ? d.paginaI + (d.paginaF ? '\u2013' + d.paginaF : '') : '';

  if (formato === 'apa') {
    var lista = d.autores.map(function(a) { return a.apellido + ', ' + iniciales(a.nombre); });
    var autStr = lista.length === 1 ? lista[0] : lista.slice(0, -1).join(', ') + ', & ' + lista[lista.length - 1];
    var cita = autStr + ' (' + d.anio + '). ' + d.titulo + '. ';
    cita += d.revista;
    if (d.volumen) cita += ', ' + d.volumen;
    if (d.numero)  cita += '(' + d.numero + ')';
    if (pages)     cita += ', ' + pages;
    cita += '.';
    if (doiUrl) cita += ' ' + doiUrl;
    return cita;
  }
  if (formato === 'ieee') {
    var lista = d.autores.map(function(a) { return iniciales(a.nombre) + ' ' + a.apellido; });
    var autStr = lista.length <= 3 ? lista.join(', ') : lista[0] + ' et al.';
    var cita = autStr + ', "' + d.titulo + '," ';
    cita += d.revista;
    if (d.volumen) cita += ', vol. ' + d.volumen;
    if (d.numero)  cita += ', no. ' + d.numero;
    if (pages)     cita += ', pp. ' + pages;
    if (d.anio)    cita += ', ' + d.anio;
    if (d.doi)     cita += ', doi: ' + d.doi;
    cita += '.';
    return cita;
  }
  if (formato === 'vancouver') {
    var lista = d.autores.map(function(a) { return a.apellido + ' ' + iniciales(a.nombre).replace(/\./g, '').replace(/ /g, ''); });
    var autStr = lista.length > 6 ? lista.slice(0, 6).join(', ') + ', et al' : lista.join(', ');
    var cita = autStr + '. ' + d.titulo + '. ';
    cita += d.revista + '. ';
    cita += d.anio;
    if (d.volumen) cita += ';' + d.volumen;
    if (d.numero)  cita += '(' + d.numero + ')';
    if (pages)     cita += ':' + pages.replace('\u2013', '-');
    cita += '.';
    if (d.doi) cita += ' doi:' + d.doi;
    return cita;
  }
  if (formato === 'bibtex') {
    var citekey = (d.autores[0] ? d.autores[0].apellido.toLowerCase() : 'autor') + d.anio;
    var autStr = d.autores.map(function(a) { return a.apellido + ', ' + a.nombre; }).join(' and ');
    var cita = '@article{' + citekey + ',\n';
    cita += '  author  = {' + autStr + '},\n';
    cita += '  title   = {' + d.titulo + '},\n';
    cita += '  journal = {' + d.revista + '},\n';
    cita += '  year    = {' + d.anio + '}';
    if (d.volumen) cita += ',\n  volume  = {' + d.volumen + '}';
    if (d.numero)  cita += ',\n  number  = {' + d.numero + '}';
    if (d.paginaI) cita += ',\n  pages   = {' + d.paginaI + (d.paginaF ? '--' + d.paginaF : '') + '}';
    if (d.doi)     cita += ',\n  doi     = {' + d.doi + '}';
    cita += '\n}';
    return cita;
  }
  if (formato === 'ris') {
    var cita = 'TY  - JOUR\n';
    d.autores.forEach(function(a) { cita += 'AU  - ' + a.apellido + ', ' + a.nombre + '\n'; });
    cita += 'TI  - ' + d.titulo + '\n';
    cita += 'JO  - ' + d.revista + '\n';
    cita += 'PY  - ' + d.anio + '\n';
    if (d.volumen) cita += 'VL  - ' + d.volumen + '\n';
    if (d.numero)  cita += 'IS  - ' + d.numero + '\n';
    if (d.paginaI) cita += 'SP  - ' + d.paginaI + '\n';
    if (d.paginaF) cita += 'EP  - ' + d.paginaF + '\n';
    if (d.doi)     cita += 'DO  - ' + d.doi + '\n';
    cita += 'ER  - ';
    return cita;
  }
  return '';
}

// ============================================
// CITA DE LIBRO (index.html)
// ============================================
function generarCitaLibro(formato, d) {
  var p       = personasCita(d);
  var loc     = localizadorHtml(d);
  var edMarca = p.esEditor ? (p.lista.length > 1 ? ' (Eds.)' : ' (Ed.)') : '';

  if (formato === 'apa') {
    var lista = p.lista.map(function(a) { return a.apellido + ', ' + iniciales(a.nombre); });
    var autStr = lista.length === 1 ? lista[0] : lista.slice(0, -1).join(', ') + ', & ' + lista[lista.length - 1];
    if (p.esEditor) autStr += edMarca;
    var cita = autStr + ' (' + d.anio + '). ' + d.titulo + '.';
    if (d.editorial) cita += ' ' + d.editorial + '.';
    if (loc) cita += ' ' + loc;
    return cita;
  }
  if (formato === 'ieee') {
    var lista = p.lista.map(function(a) { return iniciales(a.nombre) + ' ' + a.apellido; });
    var autStr = lista.length <= 3 ? lista.join(', ') : lista[0] + ' et al.';
    var cita = autStr + ', ' + d.titulo + '. ';
    if (d.ciudad)    cita += d.ciudad + ': ';
    if (d.editorial) cita += d.editorial;
    if (d.anio)      cita += ', ' + d.anio;
    cita += '.';
    if (d.doi) cita += ' doi: ' + d.doi;
    return cita;
  }
  if (formato === 'vancouver') {
    var lista = p.lista.map(function(a) { return a.apellido + ' ' + iniciales(a.nombre).replace(/\./g, '').replace(/ /g, ''); });
    var autStr = lista.length > 6 ? lista.slice(0, 6).join(', ') + ', et al' : lista.join(', ');
    var cita = autStr + '. ' + d.titulo + '. ';
    if (d.ciudad)    cita += d.ciudad + ': ';
    if (d.editorial) cita += d.editorial + '; ';
    cita += d.anio + '.';
    if (d.doi) cita += ' doi:' + d.doi;
    return cita;
  }
  if (formato === 'bibtex') {
    var citekey = (p.lista[0] ? p.lista[0].apellido.toLowerCase().replace(/\s/g, '') : 'libro') + d.anio;
    var campo   = p.esEditor ? 'editor' : 'author';
    var persStr = p.lista.map(function(a) { return a.apellido + ', ' + a.nombre; }).join(' and ');
    var cita = '@book{' + citekey + ',\n';
    cita += '  ' + campo + '    = {' + persStr + '},\n';
    cita += '  title     = {' + d.titulo + '},\n';
    if (d.editorial) cita += '  publisher = {' + d.editorial + '},\n';
    if (d.ciudad)    cita += '  address   = {' + d.ciudad + '},\n';
    cita += '  year      = {' + d.anio + '}';
    if (d.isbn) cita += ',\n  isbn      = {' + d.isbn + '}';
    if (d.doi)  cita += ',\n  doi       = {' + d.doi + '}';
    if (d.url)  cita += ',\n  url       = {' + d.url + '}';
    cita += '\n}';
    return cita;
  }
  if (formato === 'ris') {
    var campo = p.esEditor ? 'A2' : 'AU';
    var cita = 'TY  - BOOK\n';
    p.lista.forEach(function(a) { cita += campo + '  - ' + a.apellido + ', ' + a.nombre + '\n'; });
    cita += 'TI  - ' + d.titulo + '\n';
    if (d.editorial) cita += 'PB  - ' + d.editorial + '\n';
    if (d.ciudad)    cita += 'CY  - ' + d.ciudad + '\n';
    cita += 'PY  - ' + d.anio + '\n';
    if (d.isbn) cita += 'SN  - ' + d.isbn + '\n';
    if (d.doi)  cita += 'DO  - ' + d.doi + '\n';
    if (d.url)  cita += 'UR  - ' + d.url + '\n';
    cita += 'ER  - ';
    return cita;
  }
  return '';
}

// ============================================
// CITA DE CAPÍTULO (h-*.html)
// ============================================
function generarCitaCapitulo(formato, d) {
  var loc = localizadorHtml(d);
  var eds = (d.editores && d.editores.length > 0) ? d.editores : [];

  if (formato === 'apa') {
    var lista = d.autores.map(function(a) { return a.apellido + ', ' + iniciales(a.nombre); });
    var autStr = lista.length === 1 ? lista[0] : lista.slice(0, -1).join(', ') + ', & ' + lista[lista.length - 1];
    var cita = autStr + ' (' + d.anio + '). ' + d.titulo + '. En ';
    if (eds.length > 0) {
      var edStr = eds.map(function(e) { return iniciales(e.nombre) + ' ' + e.apellido; }).join(', ');
      cita += edStr + (eds.length > 1 ? ' (Eds.), ' : ' (Ed.), ');
    }
    cita += d.tituloLibro + '.';
    if (d.editorial) cita += ' ' + d.editorial + '.';
    if (loc) cita += ' ' + loc;
    return cita;
  }
  if (formato === 'ieee') {
    var lista = d.autores.map(function(a) { return iniciales(a.nombre) + ' ' + a.apellido; });
    var autStr = lista.length <= 3 ? lista.join(', ') : lista[0] + ' et al.';
    var cita = autStr + ', "' + d.titulo + '," in ' + d.tituloLibro + ', ';
    if (d.ciudad)    cita += d.ciudad + ': ';
    if (d.editorial) cita += d.editorial;
    if (d.anio)      cita += ', ' + d.anio;
    cita += '.';
    if (d.doi) cita += ' doi: ' + d.doi;
    return cita;
  }
  if (formato === 'vancouver') {
    var lista = d.autores.map(function(a) { return a.apellido + ' ' + iniciales(a.nombre).replace(/\./g, '').replace(/ /g, ''); });
    var autStr = lista.length > 6 ? lista.slice(0, 6).join(', ') + ', et al' : lista.join(', ');
    var cita = autStr + '. ' + d.titulo + '. En: ' + d.tituloLibro + '. ';
    if (d.ciudad)    cita += d.ciudad + ': ';
    if (d.editorial) cita += d.editorial + '; ';
    cita += d.anio + '.';
    if (d.doi) cita += ' doi:' + d.doi;
    return cita;
  }
  if (formato === 'bibtex') {
    var citekey = (d.autores[0] ? d.autores[0].apellido.toLowerCase().replace(/\s/g, '') : 'cap') + d.anio;
    var autStr = d.autores.map(function(a) { return a.apellido + ', ' + a.nombre; }).join(' and ');
    var cita = '@incollection{' + citekey + ',\n';
    cita += '  author    = {' + autStr + '},\n';
    cita += '  title     = {' + d.titulo + '},\n';
    cita += '  booktitle = {' + d.tituloLibro + '},\n';
    if (eds.length > 0) {
      var edStr = eds.map(function(e) { return e.apellido + ', ' + e.nombre; }).join(' and ');
      cita += '  editor    = {' + edStr + '},\n';
    }
    if (d.editorial) cita += '  publisher = {' + d.editorial + '},\n';
    if (d.ciudad)    cita += '  address   = {' + d.ciudad + '},\n';
    cita += '  year      = {' + d.anio + '}';
    if (d.doi) cita += ',\n  doi       = {' + d.doi + '}';
    if (d.url) cita += ',\n  url       = {' + d.url + '}';
    cita += '\n}';
    return cita;
  }
  if (formato === 'ris') {
    var cita = 'TY  - CHAP\n';
    d.autores.forEach(function(a) { cita += 'AU  - ' + a.apellido + ', ' + a.nombre + '\n'; });
    cita += 'TI  - ' + d.titulo + '\n';
    cita += 'T2  - ' + d.tituloLibro + '\n';
    eds.forEach(function(e) { cita += 'A2  - ' + e.apellido + ', ' + e.nombre + '\n'; });
    if (d.editorial) cita += 'PB  - ' + d.editorial + '\n';
    if (d.ciudad)    cita += 'CY  - ' + d.ciudad + '\n';
    cita += 'PY  - ' + d.anio + '\n';
    if (d.doi) cita += 'DO  - ' + d.doi + '\n';
    if (d.url) cita += 'UR  - ' + d.url + '\n';
    cita += 'ER  - ';
    return cita;
  }
  return '';
}

// ============================================
// MOSTRAR FORMATO SELECCIONADO
// ============================================
function mostrarFormato(btn, formato) {
  document.getElementById('citar-output').textContent = generarCita(formato);

  // ACTUALIZAR BOTONES ACTIVOS
  document.querySelectorAll('.citar-btn').forEach(function(b) {
    b.classList.remove('active');
  });
  btn.classList.add('active');

  // RESET BOTÓN COPIAR
  var btnCopiar = document.getElementById('citar-copiar-btn');
  btnCopiar.textContent = 'Copiar';
  btnCopiar.classList.remove('copiado');
}

// ============================================
// COPIAR CITA AL PORTAPAPELES
// ============================================
function copiarCita() {
  var texto = document.getElementById('citar-output').textContent;
  var btn   = document.getElementById('citar-copiar-btn');
  navigator.clipboard.writeText(texto).then(function() {
    btn.textContent = '\u2713 Copiado';
    btn.classList.add('copiado');
    setTimeout(function() {
      btn.textContent = 'Copiar';
      btn.classList.remove('copiado');
    }, 10000);
  });
}

// ============================================
// CONSTRUIR PANEL DE NOTAS DESDE LOS fn-ref DEL TEXTO
// ============================================
function buildNotesPanel() {
  var panelNotas = document.getElementById('panel-notas');
  var fnRefs     = document.querySelectorAll('.fn-ref');
  panelNotas.innerHTML = '';

  if (fnRefs.length === 0) {
    panelNotas.innerHTML =
      '<p style="padding:1rem;color:var(--color-text-muted);' +
      'font-size:0.875rem;">Sin notas al pie.</p>';
    return;
  }

  fnRefs.forEach(function(ref) {
    var id    = ref.getAttribute('data-fn-id');
    var texto = ref.getAttribute('data-fn-text');
    var num   = ref.textContent;
    var item  = document.createElement('div');
    item.className = 'panel-item';
    item.id = 'panel-fn-' + id;
    item.setAttribute('data-fn-id', id);
    // NAVEGACIÓN INVERSA (LIBROS): CLICK EN LA NOTA → MARCA EN EL TEXTO
    item.setAttribute('onclick', "irAlTexto('notas','" + id + "')");
    item.style.cursor = 'pointer';
    item.innerHTML =
      '<div class="panel-item-label">Nota ' + num + '</div>' +
      '<div class="panel-item-text">' + texto + '</div>';
    panelNotas.appendChild(item);
  });
}

// ============================================
// CONSTRUIR PANEL DE FIGURAS DESDE LAS fig-wrapper DEL TEXTO
// ============================================
function buildFigsPanel() {
  var panelFigs = document.getElementById('panel-figs');
  var figs      = document.querySelectorAll('.fig-wrapper');
  panelFigs.innerHTML = '';

  if (figs.length === 0) {
    panelFigs.innerHTML =
      '<p style="padding:1rem;color:var(--color-text-muted);' +
      'font-size:0.875rem;">Sin figuras.</p>';
    return;
  }

  figs.forEach(function(fig) {
    var id      = fig.getAttribute('data-fig-id');
    var img     = fig.querySelector('img');
    var caption = fig.querySelector('.fig-caption');
    var label   = fig.querySelector('.fig-label');
    var item    = document.createElement('div');
    item.className = 'panel-item panel-fig';
    item.id = 'panel-fig-' + id;
    item.setAttribute('data-fig-id', id);
    // NAVEGACIÓN INVERSA (LIBROS): CLICK EN LA FIGURA → MARCA EN EL TEXTO
    item.setAttribute('onclick', "irAlTexto('figs','" + id + "')");
    item.style.cursor = 'pointer';

    var html = '';
    if (img)     html += '<img src="' + img.src + '" alt="' + (img.alt || '') + '"/>';
    if (label)   html += '<div class="panel-item-label">' + label.textContent + '</div>';
    if (caption) html += '<div class="panel-item-text">' + caption.textContent + '</div>';

    item.innerHTML = html;
    panelFigs.appendChild(item);
  });
}

// ============================================
// ACTUALIZAR CONTADORES DE SOLAPAS
// ============================================
function updateCounts() {
  document.getElementById('count-notas').textContent =
    document.querySelectorAll('.fn-ref').length;
  document.getElementById('count-refs').textContent =
    document.querySelectorAll('#panel-refs .panel-item').length;
  document.getElementById('count-figs').textContent =
    document.querySelectorAll('.fig-wrapper').length;
}

// ============================================
// CAMBIAR SOLAPA ACTIVA
// ============================================
function switchTab(tab) {
  ['notas', 'refs', 'figs'].forEach(function(t) {
    document.getElementById('tab-'   + t).classList.remove('active');
    document.getElementById('panel-' + t).classList.remove('active');
  });
  document.getElementById('tab-'   + tab).classList.add('active');
  document.getElementById('panel-' + tab).classList.add('active');
}

// ============================================
// HIGHLIGHT CON TOGGLE (TEXTO → PANEL)
// ============================================
var selectedRef  = null;
var panelVisible = false;

function highlightPanel(tipo, id) {

  // TOGGLE: DESPINTAR Y OCULTAR PANEL
  if (selectedRef === tipo + '-' + id) {
    selectedRef = null;
    document.querySelectorAll('.panel-item.highlighted').forEach(function(el) {
      el.classList.remove('highlighted');
    });
    document.querySelectorAll('.xref-bibr.selected, .fn-ref.selected, .xref-vancouver.selected').forEach(
      function(el) { el.classList.remove('selected'); }
    );
    if (panelVisible) togglePanel();
    return;
  }

  // LIMPIAR SELECCIÓN ANTERIOR
  selectedRef = tipo + '-' + id;
  document.querySelectorAll('.panel-item.highlighted').forEach(function(el) {
    el.classList.remove('highlighted');
  });
  document.querySelectorAll('.xref-bibr.selected, .fn-ref.selected, .xref-vancouver.selected').forEach(
    function(el) { el.classList.remove('selected'); }
  );

  // ABRIR PANEL SI ESTÁ OCULTO
  if (!panelVisible) togglePanel();

  // RESALTAR EN EL TEXTO
  var textoEl = document.querySelector(
    '.xref-bibr[data-ref-id="' + id + '"], ' +
    '.fn-ref[data-fn-id="' + id + '"], ' +
    '.xref-vancouver[data-ref-id="' + id + '"]'
  );
  if (textoEl) textoEl.classList.add('selected');

  // RESALTAR EN EL PANEL CON DELAY PARA ESPERAR DISPLAY
  switchTab(tipo);
  setTimeout(function() {
    var target = null;
    if (tipo === 'notas') {
      target = document.getElementById('panel-fn-' + id);
    } else if (tipo === 'refs') {
      target = document.querySelector('#panel-refs [data-ref-id="' + id + '"]');
    } else if (tipo === 'figs') {
      target = document.getElementById('panel-fig-' + id);
    }
    if (target) {
      target.classList.add('highlighted');
      target.scrollIntoView({ behavior: 'smooth', block: 'start' });
    }
  }, 100);
}

// ============================================
// NAVEGACIÓN INVERSA: PANEL → PRIMERA CITA EN TEXTO
// AL HACER CLICK EN UNA REFERENCIA DEL PANEL
// BUSCA SU PRIMERA APARICIÓN EN EL CUERPO Y
// HACE SCROLL CON FLASH TEMPORAL DE HIGHLIGHT
// ============================================
// ============================================
// NAVEGACIÓN INVERSA (PANEL → TEXTO) BIDIRECCIONAL EN LIBROS
// ============================================
// A diferencia de revistas (solo refs), en libros las 3 pestañas
// son bidireccionales: al hacer click en un item del panel (nota,
// referencia o figura) se navega a la primera aparición de su marca
// en el cuerpo del capítulo. La razón es la lectura en tablet/celular,
// donde el drawer tapa el contexto y hace falta un retorno explícito.
//
// Se llama con (refId) para referencias (compatibilidad con revistas)
// o con (tipo, id) para notas y figuras.
function irAlTexto(arg1, arg2) {
  var tipo, id;
  if (arg2 === undefined) {
    // FORMA COMPATIBLE CON REVISTAS: irAlTexto(refId) → referencia
    tipo = 'refs';
    id = arg1;
  } else {
    tipo = arg1;
    id = arg2;
  }

  // SELECTOR DE LA MARCA EN EL CUERPO SEGÚN TIPO
  var selectorTexto, selectorPanel;
  if (tipo === 'refs') {
    selectorTexto = '.xref-bibr[data-ref-id="' + id + '"], .xref-vancouver[data-ref-id="' + id + '"]';
    selectorPanel = '#panel-refs [data-ref-id="' + id + '"]';
  } else if (tipo === 'notas') {
    selectorTexto = '.fn-ref[data-fn-id="' + id + '"]';
    selectorPanel = '#panel-fn-' + id;
  } else if (tipo === 'figs') {
    // EN LIBROS LA FIGURA ES UN BLOQUE COMPLETO (.fig-wrapper) EN EL
    // CUERPO, NO UNA MARCA INLINE. LA NAVEGACIÓN INVERSA LLEVA AL BLOQUE.
    selectorTexto = '.fig-wrapper[data-fig-id="' + id + '"]';
    selectorPanel = '#panel-fig-' + id;
  } else {
    return;
  }

  // BUSCAR PRIMERA OCURRENCIA DE LA MARCA EN EL CUERPO
  var el = document.querySelector(selectorTexto);
  if (!el) return;

  // LIMPIAR SELECCIONES ANTERIORES EN EL TEXTO
  document.querySelectorAll(
    '.xref-bibr.selected, .xref-vancouver.selected, .fn-ref.selected, .fig-ref.selected'
  ).forEach(function(e) { e.classList.remove('selected'); });

  // LIMPIAR HIGHLIGHT ANTERIOR EN EL PANEL
  document.querySelectorAll('.panel-item.highlighted').forEach(
    function(e) { e.classList.remove('highlighted'); }
  );

  // HIGHLIGHT EN EL PANEL
  var panelItem = document.querySelector(selectorPanel);
  if (panelItem) panelItem.classList.add('highlighted');

  // SCROLL AL TEXTO Y FLASH DE HIGHLIGHT
  el.scrollIntoView({ behavior: 'smooth', block: 'center' });
  el.classList.add('selected');

  // LIMPIAR TRAS 10 SEGUNDOS
  setTimeout(function() {
    el.classList.remove('selected');
    if (panelItem) panelItem.classList.remove('highlighted');
  }, 10000);
}

// ============================================
// TOGGLE PANEL DERECHO (SOLO DESKTOP)
// ============================================
function togglePanel() {
  var layout = document.getElementById('mainLayout');
  var btn    = document.getElementById('panelToggle');
  panelVisible = !panelVisible;
  layout.classList.toggle('panel-hidden', !panelVisible);
  btn.textContent = panelVisible ? '\u2190 Ocultar panel' : '\u2192 Mostrar panel';
}

// ============================================
// DRAWERS — TABLET / MÓVIL
// SIN CLONACIÓN DE CONTENIDO: col-left y
// col-right se convierten en drawers via CSS.
// Los IDs originales permanecen únicos.
// ============================================

function openDrawerMeta() {
  document.querySelector('.col-left').classList.add('drawer-open');
  document.getElementById('drawerBackdrop').classList.add('open');
}

function openDrawerPanel() {
  document.getElementById('rightPanel').classList.add('drawer-open');
  document.getElementById('drawerBackdrop').classList.add('open');
}

function closeDrawers() {
  document.querySelector('.col-left').classList.remove('drawer-open');
  document.getElementById('rightPanel').classList.remove('drawer-open');
  document.getElementById('drawerBackdrop').classList.remove('open');
}

