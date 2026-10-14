"""Visualisierung von Support und Apriori-Iterationen."""
from pathlib import Path
import matplotlib.pyplot as plt
from matplotlib.patches import FancyBboxPatch, FancyArrowPatch, Patch


def plot_support(protokoll, min_support, file_name=None):
    """Zeigt den Support geprüfter Kandidaten; speichert optional als PNG/SVG/PDF.

    file_name=None: nur anzeigen, keine Datei schreiben.
    """
    geprueft = [(groesse, kandidat, status, wert)
                for groesse, kandidat, status, wert in protokoll
                if wert is not None]
    if not geprueft:
        raise ValueError("Das Protokoll enthält keine geprüften Kandidaten.")

    geprueft.sort(key=lambda e: (e[0], -e[3], sorted(e[1])))
    namen = [" + ".join(sorted(kandidat)) for _, kandidat, _, _ in geprueft]
    werte = [wert * 100 for _, _, _, wert in geprueft]
    farben = ["#3a9d69" if status == "behalten" else "#d66b62"
              for _, _, status, _ in geprueft]

    fig, ax = plt.subplots(figsize=(11, max(5, len(namen) * 0.37)))
    balken = ax.barh(range(len(namen)), werte, color=farben)
    ax.set_yticks(range(len(namen)), namen)
    ax.invert_yaxis()
    ax.axvline(min_support * 100, color="#333333", linestyle="--",
               label=f"Mindest-Support: {min_support:.0%}")
    ax.set_xlabel("Support (%)")
    ax.set_title("Apriori: Support der geprüften Produktkombinationen")
    ax.set_xlim(0, 105)
    ax.legend(loc="lower right")
    for balken_eintrag, wert in zip(balken, werte):
        ax.text(wert + 1, balken_eintrag.get_y() + balken_eintrag.get_height() / 2,
                f"{wert:.0f} %", va="center", fontsize=9)
    fig.tight_layout()
    _anzeigen_und_optional_speichern(fig, file_name)


def _anzeigen_und_optional_speichern(fig, file_name):
    """Speichert eine Abbildung nur, wenn ein Dateiname übergeben wurde."""
    if file_name is not None:
        pfad = Path(file_name)
        if pfad.suffix.lower() not in {".png", ".svg", ".pdf"}:
            raise ValueError("Unterstützte Dateiformate: .png, .svg, .pdf")
        fig.savefig(pfad, dpi=200, bbox_inches="tight")
    plt.show()
    plt.close(fig)

