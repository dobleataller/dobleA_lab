#!/usr/bin/env python3
"""
Sincroniza los 3 sheets del Taller Doble A y regenera seguimiento.data.js
(solo nombres + flags, sin PII) para alimentar el management dashboard.

Setup (una sola vez):
    pip3 install gspread google-auth
    # Descargar .sa-key.json desde Google Cloud Console (service account)
    # Compartir los 3 sheets con el email del bot como Viewer

Uso:
    python3 sync_inscritos.py

Escribe:
    seguimiento.data.js  — consumido por dashboard.html / seguimiento.render.js
    seguimiento.md       — reporte humano
"""
from __future__ import annotations

import json
import sys
import unicodedata
import warnings
from datetime import datetime
from pathlib import Path

warnings.filterwarnings("ignore")

HERE = Path(__file__).resolve().parent
KEY_PATH = HERE / ".sa-key.json"
OUT_JS = HERE / "seguimiento.data.js"
OUT_MD = HERE / "seguimiento.md"

SHEETS = {
    "inscripciones": "1CckvGXAfemvd8AWGtUEewZkWnjofQYL0uNUhft9ZTe0",
    "bbdd_taller":   "1LpZ3oB7IjOErr5qWiwuGRR1o2_K2fgClQvtx5hxvmw4",
    "pagados":       "1lqfmz3NcleC_k9orEds7l4v6tIrgLXYe9OqpXbjY7_M",
}

NEG_PHRASES = [
    "no participa",  # valor canonico del sheet
    "no esta interesad", "no está interesad",
    "no podra participar", "no podrá participar",
    "no puede participar", "no participara", "no participará",
    "no estaba interesado", "no esta intereesado",
    "desistio", "desistió",
]
ALIVE_PHRASES = [
    "seguimiento", "espera de respuesta", "llamar",
    "avisara", "avisará", "nos avisara",
]


def norm(s):
    s = (s or "").strip()
    return unicodedata.normalize("NFKD", s).encode("ascii", "ignore").decode().lower()


def classify(estatus: str) -> str:
    """pagado / perdido / esperanza. 'Estatus' vacío o 'Incierto' → esperanza."""
    n = norm(estatus)
    if "pagada" in n or "pagado" in n:
        return "pagado"
    if any(p in n for p in NEG_PHRASES) and not any(p in n for p in ALIVE_PHRASES):
        return "perdido"
    return "esperanza"


def get_client():
    try:
        import gspread
        from google.oauth2.service_account import Credentials
    except ImportError:
        sys.exit("Falta: pip3 install gspread google-auth")

    if not KEY_PATH.exists():
        sys.exit(f"No se encuentra {KEY_PATH.name}. Bajala desde Google Cloud Console.")

    scopes = ["https://www.googleapis.com/auth/spreadsheets.readonly"]
    creds = Credentials.from_service_account_file(str(KEY_PATH), scopes=scopes)
    import gspread as _gs
    return _gs.authorize(creds)


def main():
    gc = get_client()

    # ── 1) INSCRIPCIONES (fuente principal) ─────────────────────────────────
    inscripciones = gc.open_by_key(SHEETS["inscripciones"]).sheet1.get_all_records()
    # Filtra filas placeholder/legenda (no son personas reales)
    IGNORAR = {"rojo", "verde", "amarillo", "test", "prueba", "legenda"}
    pagados, esperanza, perdidos = [], [], []
    for r in inscripciones:
        nombre = (r.get("Nombre y Apellido") or "").strip()
        if not nombre or nombre.lower() in IGNORAR:
            continue
        est = (r.get("Estatus") or r.get("Estatus ") or "").strip()
        sp = (r.get("Seguimiento Pablo") or "").strip().lower() == "si"
        llamar = "llamar" in norm(est)
        nivel = (r.get("Nivel análisis de datos") or r.get("Nivel analisis de datos") or "").strip()
        entry = {"nombre": nombre}
        if nivel:  entry["nivel"] = nivel
        if sp:     entry["p"] = True
        if llamar: entry["c"] = True
        grupo = classify(est)
        (pagados if grupo == "pagado" else perdidos if grupo == "perdido" else esperanza).append(entry)

    esperanza.sort(key=lambda e: (not e.get("c"), not e.get("p"), e["nombre"].lower()))

    # ── 2) BBDD TALLER (B2B outreach) ───────────────────────────────────────
    bbdd_rows = gc.open_by_key(SHEETS["bbdd_taller"]).sheet1.get_all_records()
    bbdd_total = len(bbdd_rows)
    bbdd_enviados = sum(1 for r in bbdd_rows if (r.get("Mensaje enviado") or r.get("Mensaje enviado ") or "").strip())
    contactadoras = {}
    for r in bbdd_rows:
        c = (r.get("Contactadora") or "").strip()
        if c:
            contactadoras[c] = contactadoras.get(c, 0) + 1

    # ── 3) PAGOS (cross-check) ──────────────────────────────────────────────
    pagos_rows = gc.open_by_key(SHEETS["pagados"]).sheet1.get_all_records()
    pagos_count = sum(1 for r in pagos_rows if (r.get("Nombre") or "").strip())

    data = {
        "generado": datetime.now().isoformat(timespec="seconds"),
        "totales": {
            "inscritos": len(pagados) + len(esperanza) + len(perdidos),
            "pagados":   len(pagados),
            "esperanza": len(esperanza),
            "perdidos":  len(perdidos),
        },
        "b2b": {
            "total_contactos": bbdd_total,
            "mensajes_enviados": bbdd_enviados,
            "por_contactadora": contactadoras,
        },
        "pagos_sheet_count": pagos_count,  # para sanity check
        "pagados":   pagados,
        "esperanza": esperanza,
        "perdidos":  perdidos,
    }

    OUT_JS.write_text(
        "// Solo nombres + flags priority (★ = Seguimiento Pablo, 📞 = llamar).\n"
        "// Datos sensibles (email/telefono/estatus detallado) quedan en el Sheet privado.\n"
        "// Generado por sync_inscritos.py — NO editar a mano.\n"
        "window.SEGUIMIENTO = " + json.dumps(data, ensure_ascii=False, indent=2) + ";\n",
        encoding="utf-8",
    )

    lines = [
        "# Seguimiento Taller Doble A — solo nombres",
        f"_Generado: {data['generado']}_", "",
        f"- Inscritos: **{data['totales']['inscritos']}** · Pagados: **{data['totales']['pagados']}**"
        f" · Con esperanza: **{data['totales']['esperanza']}** · Perdidos: **{data['totales']['perdidos']}**",
        f"- B2B outreach: **{bbdd_total}** contactos, **{bbdd_enviados}** mensajes enviados "
        f"({100*bbdd_enviados//max(bbdd_total,1)}%)",
        f"- Cross-check pagos sheet: {pagos_count} registros (match con pagados: {pagos_count == len(pagados)})",
        "",
        "## Pagados",
    ]
    for p in pagados:
        nivel = f" _{p['nivel']}_" if p.get("nivel") else ""
        lines.append(f"- {p['nombre']}{nivel}")
    lines += ["", "## Con esperanza", "★ = Seguimiento Pablo · 📞 = llamar", ""]
    for e in esperanza:
        marks = ("★ " if e.get("p") else "") + ("📞 " if e.get("c") else "")
        lines.append(f"- {marks}**{e['nombre']}**")
    lines += ["", "## Perdidos"]
    for x in perdidos:
        lines.append(f"- {x['nombre']}")
    OUT_MD.write_text("\n".join(lines) + "\n", encoding="utf-8")

    print(f"✓ {OUT_JS.name}  ({data['totales']['pagados']} pagados, "
          f"{data['totales']['esperanza']} con esperanza, {data['totales']['perdidos']} perdidos)")
    print(f"✓ {OUT_MD.name}")
    print(f"  B2B: {bbdd_total} contactos, {bbdd_enviados} enviados")
    if pagos_count != len(pagados):
        print(f"  ⚠ pagos_sheet={pagos_count} vs pagados en inscripciones={len(pagados)}")


if __name__ == "__main__":
    main()
