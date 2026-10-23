"""
wc_retinotopy.py -- inverse retinotopic (log-polar) map for f_wc (task T006).

Maps a cortical-coordinate pattern (what the WC solver produces, periodic on
the cortical sheet) into visual-field coordinates, so that cortical rolls and
hexagons appear as the Ermentrout-Cowan form constants (funnel, spiral,
lattice/honeycomb, cobweb).

Model (Bressloff/Ermentrout-Cowan lineage): the retinotopic map from visual
field (r, theta) to cortical complex coordinate is approximately

    z_cortex = log(1 + r / r0) * exp(i * theta)        (conformal, wedge model)

The INVERSE map (what we need: for each visual-field output pixel, find the
cortical sample point) is

    r = r0 * (exp(|z|) - 1) ;  theta = arg(z)

But for rendering we go the other way: for each output pixel (visual field
polar coords (r, theta)), the cortical coordinate is

    u = k_e * log(1 + r / r0)        (eccentricity axis, log-compressed)
    v = k_t * theta                  (angular axis, periodic)

and we sample the cortical field at (u, v) (periodic in both cortical axes).

So the render is: build (u, v) per output pixel from that pixel's (r, theta),
sample the cortical pattern. Cortical rolls (stripes along one axis) then
appear as:
  rolls along v  (u = const stripes)  -> concentric rings ("tunnel"/funnel)
  rolls along u  (v = const stripes)  -> radial spokes ("cobweb"-like)
  rolls diagonal -> spirals
  hexagons       -> lattice/honeycomb

Constants:
  r0      the map's eccentricity scale (the "foveal" radius below which the
          log map is regularized -- avoids the singularity at r=0)
  k_e     eccentricity gain: how many cortical wavelengths per log-unit radius
  k_t     angular gain: cortical periods around the full 2*pi (should be ~an
          integer for seam-free wrapping around the origin)
  r_max   outer visual-field radius mapped (pixels beyond show the wrap)
"""
import numpy as np


def render(cortex, out_size=512, r0=0.5, k_e=8.0, k_t=5.0, r_max=4.0):
    """Render a cortical field (2D array, periodic) into visual-field
    coordinates. Returns an out_size x out_size array.

    cortex: 2D array on the cortical sheet (periodic both axes).
    out_size: output resolution (square).
    r0: foveal regularization radius.
    k_e: eccentricity gain (cortical units per log-eccentricity).
    k_t: angular gain (cortical units per radian of visual angle).
    r_max: visual radius at the image corner.
    """
    n_c = cortex.shape[0]
    o = out_size
    yy, xx = np.mgrid[0:o, 0:o]
    cx = cy = o / 2.0
    # pixel -> visual polar
    px = (xx - cx) / (o / 2.0) * r_max
    py = (yy - cy) / (o / 2.0) * r_max
    r = np.hypot(px, py)
    theta = np.arctan2(py, px)

    # visual -> cortical
    u = k_e * np.log1p(r / r0)     # log(1 + r/r0)
    v = k_t * theta

    # cortical coords -> array indices (periodic)
    iu = np.mod(u / (2 * np.pi) * n_c, n_c).astype(int)
    iv = np.mod(v / (2 * np.pi) * n_c, n_c).astype(int)

    return cortex[iu, iv]
