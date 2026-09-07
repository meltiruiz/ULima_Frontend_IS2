#!/usr/bin/env python3
"""Comprueba que los conteos del README coincidan con el código.

El README cita cifras exactas (pantallas, servicios, suites, casos de prueba) y
rutas de archivo. Eso envejece a cada merge: el 2026-09-07 se descubrió que dos
merges lo habían dejado con una docena de números falsos, incluida una tabla que
declaraba `test/HU_asistencia/` como «sin commitear» cuando ya estaba en `main`.

    python3 scripts/verificar_readme.py

Falla con estado 1 si algo no cuadra. Sin dependencias: solo librería estándar,
para que se pueda correr sin `flutter pub get` ni nada instalado.
"""

from __future__ import annotations

import re
import sys
from pathlib import Path

RAIZ = Path(__file__).resolve().parent.parent
README = RAIZ / "README.md"


def dart(carpeta: str) -> list[Path]:
    return sorted((RAIZ / carpeta).rglob("*.dart")) if (RAIZ / carpeta).exists() else []


def medir() -> dict[str, int]:
    pruebas = dart("test")
    texto_pruebas = "\n".join(p.read_text(encoding="utf-8", errors="replace") for p in pruebas)
    return {
        "pantallas": len(dart("lib/pages")),
        "controllers": len([p for p in dart("lib/pages") if p.name.endswith("_controller.dart")]),
        "servicios": len(dart("lib/services")),
        "modelos": len(dart("lib/models")),
        "componentes": len(dart("lib/components")),
        "suites": len(pruebas),
        "casos": len(re.findall(r"\btest\(", texto_pruebas))
        + len(re.findall(r"\btestWidgets\(", texto_pruebas)),
        "widget_tests": len(re.findall(r"\btestWidgets\(", texto_pruebas)),
        "carpetas_test": len({p.parent for p in pruebas}),
        "lineas_prueba": sum(
            len(p.read_text(encoding="utf-8", errors="replace").splitlines()) for p in pruebas
        ),
    }


# Grupo 1 = la cifra. Una afirmación que ya no se encuentra también se reporta:
# significa que la frase se reescribió y el patrón hay que actualizarlo.
# «28 pantallas» NO se comprueba: no hay forma objetiva de contarlas —
# lib/pages/ tiene 74 archivos .dart, 25 de ellos *_page.dart, en 18 carpetas —
# y afirmar un número que el script calcula distinto sería peor que no mirarlo.
AFIRMACIONES: list[tuple[str, str, str]] = [
    ("servicios", r"\*\*(\d+) services\*\*", "resumen de superficie"),
    ("suites", r"\*\*(\d+) suites\*\*", "insignia de verificación"),
    ("suites", r"\*\*(\d+) archivos de prueba", "cabecera de la matriz de pruebas"),
]

NEGACION = re.compile(r"no existe|nunca existió|que no existen|se perdió|sin trackear|sin commitear")
EXTENSIONES = (".dart", ".yaml", ".yml", ".md", ".json", ".py")


def rutas_citadas(texto: str) -> list[str]:
    patron = re.compile(r"`((?:lib|test|specs|docs|scripts)/[\w./-]+)`?")
    encontradas: set[str] = set()
    for parrafo in re.split(r"\n\s*\n", texto):
        if NEGACION.search(parrafo):
            continue
        for m in patron.finditer(parrafo):
            if m.group(1).endswith(EXTENSIONES):
                encontradas.add(m.group(1))
    return sorted(encontradas)


def main() -> int:
    if not README.exists():
        print("No encuentro README.md", file=sys.stderr)
        return 1

    texto = README.read_text(encoding="utf-8")
    real = medir()
    fallos = 0

    print("Números medidos en el código:")
    for clave, valor in real.items():
        print(f"  {clave:16} {valor}")

    print("\nAfirmaciones del README:")
    for clave, patron, donde in AFIRMACIONES:
        hallado = re.search(patron, texto)
        if not hallado:
            print(f"  ? {clave:16} no encontré la frase de «{donde}» — ¿se reescribió?")
            fallos += 1
            continue
        dice = int(hallado.group(1))
        if dice == real[clave]:
            print(f"  ✓ {clave:16} {dice} ({donde})")
        else:
            print(f"  ✗ {clave:16} dice {dice}, son {real[clave]} ({donde})")
            fallos += 1

    print("\nRutas de archivo citadas:")
    faltan = [r for r in rutas_citadas(texto) if not (RAIZ / r).exists()]
    for r in faltan:
        print(f"  ✗ {r} — citada en el README pero no existe")
    if not faltan:
        print("  ✓ todas existen")
    fallos += len(faltan)

    print()
    if fallos:
        print(f"{fallos} discrepancia(s). El README no está al día.")
        return 1
    print("El README concuerda con el código.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
