from __future__ import annotations
from .profile import timeprofile
from matplotlib.pyplot import show
from .plots import timeprofile as plot_time

from argparse import ArgumentParser
from datetime import timedelta


def main(time: list[str], alt_km: list[float], glat: float, glon: float):
    """IRI time profile"""
    return timeprofile((time[0], time[1]), timedelta(hours=float(time[2])), alt_km, glat, glon)


def cli():
    p = ArgumentParser()
    p.add_argument("time", help="start yy-mm-dd, stop yy-mm-dd, step_hour", nargs=3)
    p.add_argument("latlon", help="geodetic latitude, longitude (degrees)", nargs=2, type=float)
    p.add_argument(
        "-alt_km",
        help="altitude START STOP STEP (km)",
        type=float,
        nargs=3,
        default=(100, 200, 20),
    )
    P = p.parse_args()

    iono = main(P.time, P.alt_km, *P.latlon)

    plot_time(iono)
    show()


if __name__ == "__main__":
    cli()
