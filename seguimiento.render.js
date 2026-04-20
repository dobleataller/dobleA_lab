// Auto-renderer para "Pendientes de seguimiento" dentro del dashboard.
// Consume window.SEGUIMIENTO (formato reducido: solo nombres + flags).
// Busca el div #seguimiento-pendientes y lo llena.
(function () {
  'use strict';

  function esc(s) {
    return String(s == null ? '' : s).replace(/[&<>"']/g, function (c) {
      return { '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[c];
    });
  }

  function nameRow(p) {
    var star = p.p ? '<span style="color:#E040A0;font-weight:700;">★</span> ' : '';
    var call = p.c ? ' <span style="color:#facc15;font-size:.7rem;font-weight:600;">📞 llamar</span>' : '';
    var nivel = p.nivel ? ' <span style="display:inline-block;padding:1px 8px;border-radius:999px;background:rgba(139,92,246,.2);font-size:.7rem;margin-left:4px;">' + esc(p.nivel) + '</span>' : '';
    return '<li style="padding:6px 0;border-bottom:1px solid rgba(255,255,255,.06);font-size:.9rem;">' +
             star + esc(p.nombre) + nivel + call +
           '</li>';
  }

  function render() {
    var mount = document.getElementById('seguimiento-pendientes');
    if (!mount) return;
    if (mount.dataset.rendered === '1') return;
    var d = window.SEGUIMIENTO;
    if (!d) {
      mount.innerHTML = '<div style="color:rgba(255,255,255,.5);padding:12px;font-size:.85rem;">seguimiento.data.js no cargado</div>';
      return;
    }

    var estrella = [], resto = [];
    d.esperanza.forEach(function (p) { (p.p ? estrella : resto).push(p); });

    var gen = new Date(d.generado).toLocaleString('es-CL', { dateStyle: 'short', timeStyle: 'short' });

    mount.innerHTML =
      '<div style="margin-top:18px;padding-top:18px;border-top:1px solid rgba(139,92,246,.2);">' +
        '<div style="display:flex;justify-content:space-between;align-items:baseline;flex-wrap:wrap;gap:8px;margin-bottom:10px;">' +
          '<h4 style="margin:0;font-size:1rem;">Inciertos — a contactar</h4>' +
          '<span style="font-size:.7rem;color:rgba(255,255,255,.4);">Actualizado ' + esc(gen) + ' · solo nombres (datos sensibles en el Sheet)</span>' +
        '</div>' +
        '<p style="margin-bottom:12px;color:rgba(255,255,255,.65);font-size:.82rem;">' +
          '<strong>' + d.totales.esperanza + '</strong> inciertos · ' +
          '<strong style="color:#E040A0;">' + estrella.length + '</strong> ★ (Seguimiento Pablo) · ' +
          '<strong>' + d.totales.pagados + '</strong> pagados · ' +
          '<strong style="color:rgba(255,255,255,.5);">' + d.totales.perdidos + '</strong> perdidos' +
        '</p>' +
        '<div style="display:grid;grid-template-columns:repeat(auto-fit,minmax(260px,1fr));gap:16px;">' +
          '<div>' +
            '<div style="font-size:.7rem;letter-spacing:.1em;text-transform:uppercase;color:#E040A0;margin-bottom:4px;">' +
              'Prioridad ★ (' + estrella.length + ')</div>' +
            '<ul style="list-style:none;padding:0;margin:0;">' + estrella.map(nameRow).join('') + '</ul>' +
          '</div>' +
          '<div>' +
            '<div style="font-size:.7rem;letter-spacing:.1em;text-transform:uppercase;color:rgba(255,255,255,.45);margin-bottom:4px;">' +
              'Otros inciertos (' + resto.length + ')</div>' +
            '<ul style="list-style:none;padding:0;margin:0;">' + resto.map(nameRow).join('') + '</ul>' +
          '</div>' +
        '</div>' +
      '</div>';
    mount.dataset.rendered = '1';
  }

  function renderB2B() {
    var mount = document.getElementById('b2b-stats');
    if (!mount || mount.dataset.rendered === '1') return;
    var d = window.SEGUIMIENTO;
    if (!d || !d.b2b) return;
    var b = d.b2b;
    var pct = b.total_contactos > 0
      ? Math.round(100 * b.mensajes_enviados / b.total_contactos)
      : 0;
    var splitHTML = '';
    var entries = Object.keys(b.por_contactadora || {});
    if (entries.length) {
      splitHTML = '<div class="b2b-split">' +
        entries.map(function (k) {
          return esc(k) + ': <strong>' + b.por_contactadora[k] + '</strong>';
        }).join(' · ') +
        '</div>';
    }
    mount.innerHTML =
      '<div class="b2b-row">' +
        '<div><div class="b2b-num">' + b.total_contactos + '</div><div class="b2b-label">Contactos B2B</div></div>' +
        '<div><div class="b2b-num">' + b.mensajes_enviados + '</div><div class="b2b-label">Mensajes enviados</div></div>' +
        '<div style="flex:1;min-width:180px;">' +
          '<div style="display:flex;justify-content:space-between;font-size:.72rem;color:rgba(255,255,255,.5);margin-bottom:4px;">' +
            '<span>Progreso outreach</span><span>' + pct + '%</span>' +
          '</div>' +
          '<div class="b2b-progress"><div class="b2b-progress-fill" style="width:' + pct + '%;"></div></div>' +
        '</div>' +
      '</div>' +
      splitHTML;
    mount.dataset.rendered = '1';
  }

  function runAll() { render(); renderB2B(); }

  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', runAll);
  } else {
    runAll();
  }
  // Observer para cuando main-content se re-renderice (dashboard dinamico)
  var observer = new MutationObserver(function () {
    var el1 = document.getElementById('seguimiento-pendientes');
    var el2 = document.getElementById('b2b-stats');
    if (el1 && el1.dataset.rendered !== '1') render();
    if (el2 && el2.dataset.rendered !== '1') renderB2B();
  });
  if (document.body) {
    observer.observe(document.body, { childList: true, subtree: true });
  } else {
    document.addEventListener('DOMContentLoaded', function () {
      observer.observe(document.body, { childList: true, subtree: true });
    });
  }
})();
