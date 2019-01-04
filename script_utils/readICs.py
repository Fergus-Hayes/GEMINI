#!/usr/bin/env python
import h5py
import numpy as np
from pathlib import Path
from argparse import ArgumentParser
from readdata import readsimsize

LSP = 7

def ICs2hdf5(rawfn: Path, flagswap: bool):
    rawfn = Path(rawfn).expanduser()

    sizefn = rawfn.parent / 'simsize.dat'
    lxs = readsimsize(sizefn)
    lxsp = np.append(lxs,LSP)

    with rawfn.open('rb') as f:
        dmys = np.fromfile(f, 'float64', 4).astype(int)
        lx1in, lx2in, lx3in = np.fromfile(f, 'float64', 3).astype(int)

        if flagswap:
            lx3in = lx2in
            lx2in = 1

            nsall = np.fromfile(f, 'float64', np.prod(lxsp)).reshape(lxsp)
            vs1all = np.fromfile(f, 'float64', np.prod(lxsp)).reshape(lxsp)
            Tsall = np.fromfile(f, 'float64', np.prod(lxsp)).reshape(lxsp)

if __name__ == '__main__':
    p = ArgumentParser()
    p.add_argument('rawfn')
    p.add_argument('flagswap',type=bool)
    p = p.parse_args()

    ICs2hdf5(p.rawfn, p.flagswap)