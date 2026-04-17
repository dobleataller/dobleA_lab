#!/usr/bin/env python3
"""
Sincroniza el Sheet de inscritos del Taller Doble A y genera
`seguimiento.data.js` con la clasificacion (pagados / con esperanza / perdidos).

Uso:
    # 1) Setup (una sola vez):
    #    pip install gspread google-auth
    #    gcloud auth application-default login   # usa tu cuenta personal; el sheet se queda privado
    #
    # 2) Cada vez que quieras refrescar:
    python3 sync_inscritos.py

El script usa Application Default Credentials (tu login de Google), asi que
NO hace falta compartir el sheet con nadie ni crear service accounts. Queda
100% privado.
"""
from __future__ import annotations

import json
import os
import re
import sys
import unicodedata
from pathlib import Path
from datetime import datetime

SHEET_ID = "1CckvGXAfemvd8AWGtUEewZkWnjofQYL0uNUhft9ZTe0"
GID = 0
HERE = Path(__file__).resolve().parent
OUT_JS = HERE / "seguimiento.data.js"
OUT_MD = HERE / "seguimiento.md"

NEG_PHRASES = [
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


def norm(s: str) -> str:
    s = (s or "").strip()
    s = unicodedata.normalize("NFKD", s).encode("ascii", "ignore").decode()
    return s.lower()


def classify(row: dict) -> str:
    est = norm(row.get("Estatus", ""))
    if "pagada" in est or "pagado" in est:
        return "pagado"
    is_neg = any(p in est for p in NEG_PHRASES)
    is_alive = any(p in est for p in ALIVE_PHRASES)
    if is_neg and not is_alive:
        return "perdido"
    return "esperanza"


def fetch_rows():
    """Lee el sheet con gspread usando Application Default Credentials."""
    try:
        import gspread
        from google.auth import default
    except ImportError:
        sys.exit(
            "Falta instalar dependencias:\n"
            "    pip install gspread google-auth\n"
        )

    scopes = ["https://www.googleapis.com/auth/spreadsheets.readonly"]
    creds, _ = default(scopes=scopes)
    gc = gspread.authorize(creds)
    sh = gc.open_by_key(SHEET_ID)
    ws = sh.get_worksheet_by_id(GID) if hasattr(sh, "get_worksheet_by_id") else sh.sheet1
    records = ws.get_all_records()
    # Normaliza keys quitando espacios finales
    clean = []
    for r in records:
        clean.append({k.strip(): (v if isinstance(v, str) else str(v)).strip()
                      for k, v in r.items()})
    return clean


def build_entry(row: dict) -> dict:
    return {
        "nombre": row.get("Nombre y Apellido", ""),
        "correo": row.get("Correo Electronico") or row.get("Correo Electrónico", ""),
        "telefono": row.get("Telefono Contacto") or row.get("Teléfono Contacto", ""),
        "nivel": row.get("Nivel analisis de datos") or row.get("Nivel análisis de datos", ""),
        "estatus": row.get("Estatus", ""),
        "seguimiento_pablo": (row.get("Seguimiento Pablo") or "").strip().lower() == "si",
    }


def main():
    rows = fetch_rows()
    pagados, esperanza, perdidos = [], [], []

    for raw in rows:
        if not raw.get("Nombre y Apellido"):
            continue
        entry = build_entry(raw)
        grupo = classify(raw)
        if grupo == "pagado":
            pagados.append(entry)
        elif grupo == "perdido":
            perdidos.append(entry)
        else:
            esperanza.append(entry)

    # Prioriza "Seguimiento Pablo = Si" y luego "llamar"
    def prio(e):
        est = norm(e["estatus"])
        return (0 if "llamar" in est else 1,
                0 if e["seguimiento_pablo"] else 1,
                e["nombre"].lower())
    esperanza.sort(key=prio)

    data = {
        "generado": datetime.now().isoformat(timespec="seconds"),
        "totales": {
            "inscritos": len(rows),
            "pagados": len(pagados),
            "esperanza": len(esperanza),
            "perdidos": len(perdidos),
        },
        "pagados": pagados,
        "esperanza": esperanza,
        "perdidos": perdidos,
    }

    # seguimiento.data.js — consumible por el dashboard (window.SEGUIMIENTO)
    OUT_JS.write_text(
        "// Generado por sync_inscritos.py — NO editar a mano\n"
        "window.SEGUIMIENTO = " + json.dumps(data, ensure_ascii=False, indent=2) + ";\n",
        encoding="utf-8",
    )

    # seguimiento.md — reporte humano
    lines = [
        f"# Seguimiento Taller Doble A",
        f"_Generado: {data['generado']}_",
        "",
        f"- Inscritos: **{data['totales']['inscritos']}**",
        f"- Pagados: **{data['totales']['pagados']}**",
        f"- Con esperanza: **{data['totales']['esperanza']}**",
        f"- Perdidos: **{data['totales']['perdidos']}**",
        "",
        "## Pagados",
    ]
    for p in pagados:
        lines.append(f"- {p['nombre']} — {p['nivel'] or 'sin nivel'} — {p['correo']}")
    lines += ["", "## Con esperanza (a contactar)"]
    for e in esperanza:
        mark = "★" if e["seguimiento_pablo"] else " "
        tel = e["telefono"] if e["telefono"] and e["telefono"] != "-" else "s/tel"
        lines.append(f"- {mark} **{e['nombre']}** · {e['correo']} · {tel}")
        lines.append(f"    - {e['estatus']}")
    lines += ["", "## Perdidos (no insistir)"]
    for x in perdidos:
        lines.append(f"- {x['nombre']}")

    OUT_MD.write_text("\n".join(lines) + "\n", encoding="utf-8")

    print(f"✓ {OUT_JS.name}  ({data['totales']['pagados']} pagados, "
          f"{data['totales']['esperanza']} con esperanza, "
          f"{data['totales']['perdidos']} perdidos)")
    print(f"✓ {OUT_MD.name}")


if __name__ == "__main__":
    main()
