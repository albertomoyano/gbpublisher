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
  var d      = citaData;
  var doiUrl = d.doi ? 'https://doi.org/' + d.doi : '';
  var pages  = d.paginaI ? d.paginaI + (d.paginaF ? '\u2013' + d.paginaF : '') : '';

  // APA 7
  if (formato === 'apa') {
    var lista = d.autores.map(function(a) {
      return a.apellido + ', ' + iniciales(a.nombre);
    });
    var autStr = lista.length === 1
      ? lista[0]
      : lista.slice(0, -1).join(', ') + ', &amp; ' + lista[lista.length - 1];
    var cita = autStr + ' (' + d.anio + '). ' + d.titulo + '. ';
    cita += d.revista;
    if (d.volumen) cita += ', ' + d.volumen;
    if (d.numero)  cita += '(' + d.numero + ')';
    if (pages)     cita += ', ' + pages;
    cita += '.';
    if (doiUrl) cita += ' ' + doiUrl;
    return cita;
  }

  // IEEE
  if (formato === 'ieee') {
    var lista = d.autores.map(function(a) {
      return iniciales(a.nombre) + ' ' + a.apellido;
    });
    var autStr = lista.length &lt;= 3
      ? lista.join(', ')
      : lista[0] + ' et al.';
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

  // VANCOUVER
  if (formato === 'vancouver') {
    var lista = d.autores.map(function(a) {
      return a.apellido + ' ' + iniciales(a.nombre).replace(/\./g, '').replace(/ /g, '');
    });
    var autStr = lista.length > 6
      ? lista.slice(0, 6).join(', ') + ', et al'
      : lista.join(', ');
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

  // BIBTEX
  if (formato === 'bibtex') {
    var citekey = (d.autores[0] ? d.autores[0].apellido.toLowerCase() : 'autor')
                  + d.anio;
    var autStr = d.autores.map(function(a) {
      return a.apellido + ', ' + a.nombre;
    }).join(' and ');
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

  // RIS
  if (formato === 'ris') {
    var cita = 'TY  - JOUR\n';
    d.autores.forEach(function(a) {
      cita += 'AU  - ' + a.apellido + ', ' + a.nombre + '\n';
    });
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
function irAlTexto(refId) {

  // BUSCAR PRIMERA OCURRENCIA EN EL CUERPO DEL ARTÍCULO
  var el = document.querySelector(
    '.xref-bibr[data-ref-id="' + refId + '"], ' +
    '.xref-vancouver[data-ref-id="' + refId + '"]'
  );
  if (!el) return;

  // LIMPIAR SELECCIONES ANTERIORES EN EL TEXTO
  document.querySelectorAll(
    '.xref-bibr.selected, .xref-vancouver.selected'
  ).forEach(function(e) { e.classList.remove('selected'); });

  // LIMPIAR HIGHLIGHT ANTERIOR EN EL PANEL
  document.querySelectorAll('.panel-item.highlighted').forEach(
    function(e) { e.classList.remove('highlighted'); }
  );

  // HIGHLIGHT EN EL PANEL
  var panelItem = document.querySelector(
    '#panel-refs [data-ref-id="' + refId + '"]'
  );
  if (panelItem) panelItem.classList.add('highlighted');

  // SCROLL AL TEXTO Y FLASH DE HIGHLIGHT
  el.scrollIntoView({ behavior: 'smooth', block: 'center' });
  el.classList.add('selected');

  // LIMPIAR TRAS 5 SEGUNDOS
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

