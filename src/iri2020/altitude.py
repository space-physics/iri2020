from __future__ import annotations
from .base import IRI

from argparse import ArgumentParser


def main(time: str, alt_km: list[float], glat: float, glon: float):
    """Height Profile Example"""

    return IRI(time, alt_km, glat, glon)


def cli():
    p = ArgumentParser(description="IRI altitude profile")
    p.add_argument("time", help="time of simulation")
    p.add_argument("latlon", help="geodetic latitude, longitude (degrees)", type=float, nargs=2)
    p.add_argument(
        "-alt_km",
        help="altitude START STOP STEP (km)",
        type=float,
        nargs=3,
        default=(80, 1000, 10),
    )
    P = p.parse_args()

    iono = main(P.time, P.alt_km, *P.latlon)

    try:
        from matplotlib.pyplot import show
        import iri2020.plots as piri

        piri.altprofile(iono)
        show()
    except ImportError:
        pass


if __name__ == "__main__":
    cli()
