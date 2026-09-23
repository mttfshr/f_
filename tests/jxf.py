"""
jxf.py -- read/write Jitter binary matrix files (.jxf), and convert between
Jitter matrices and the RGBA (H, W, 4) float32 arrays gpu_sim.py uses.

Format, decoded 2026-09-22 from Max's own C74/help/jitter/matrix1.jxf
(big-endian throughout; chunk sizes INCLUDE their 8-byte header, and the
FORM size is the total file size):

    'FORM' u32 file_size 'JIT!'
    'FVER' u32 12        u32 version (0x3C93DC80)
    'MTRX' u32 chunk_size
           u32 data_offset          (from start of MTRX chunk; 24 + 4*dimcount)
           4cc type                 ('CHAR' | 'LONG' | 'FL32' | 'FL64')
           u32 planecount
           u32 dimcount
           u32 dim[0..dimcount-1]   (dim[0] = width / x)
           data: cells interleaved (all planes of a cell together),
                 dim[0] fastest, no row padding

'FL32' confirmed as the float32 tag: Max-written out.jxf from the bench
(2026-09-22) has a header byte-identical to write_jxf's output.
"""
import struct

import numpy as np

FVER_VERSION = 0x3C93DC80
TYPES = {b"CHAR": ">u1", b"LONG": ">i4", b"FL32": ">f4", b"FL64": ">f8"}
TYPES_BY_DTYPE = {np.dtype(np.uint8): b"CHAR", np.dtype(np.int32): b"LONG",
                  np.dtype(np.float32): b"FL32", np.dtype(np.float64): b"FL64"}


class JxfError(ValueError):
    pass


def read_jxf(path):
    """Return the matrix as a native-endian array of shape
    (dim[n-1], ..., dim[1], dim[0], planecount) -- for 2D: (H, W, planes)."""
    with open(path, "rb") as f:
        data = f.read()
    if data[0:4] != b"FORM" or data[8:12] != b"JIT!":
        raise JxfError(f"{path}: not a Jitter .jxf file")
    form_size = struct.unpack(">I", data[4:8])[0]
    if form_size != len(data):
        raise JxfError(f"{path}: FORM size {form_size} != file size {len(data)}")
    pos = 12
    mtrx = None
    while pos < len(data):
        tag = data[pos:pos + 4]
        size = struct.unpack(">I", data[pos + 4:pos + 8])[0]
        if size < 8:
            raise JxfError(f"{path}: bad chunk size {size} for {tag!r}")
        if tag == b"MTRX":
            mtrx = (pos, size)
        pos += size
    if mtrx is None:
        raise JxfError(f"{path}: no MTRX chunk")
    start, size = mtrx
    offset, type4 = struct.unpack(">I4s", data[start + 8:start + 16])
    planecount, dimcount = struct.unpack(">II", data[start + 16:start + 24])
    dims = struct.unpack(">" + "I" * dimcount, data[start + 24:start + 24 + 4 * dimcount])
    if type4 not in TYPES:
        raise JxfError(f"{path}: unknown matrix type {type4!r}")
    dtype = np.dtype(TYPES[type4])
    n = planecount * int(np.prod(dims))
    expected = offset + n * dtype.itemsize
    if expected != size:
        raise JxfError(f"{path}: MTRX size {size} != header+data {expected}")
    arr = np.frombuffer(data, dtype=dtype, count=n, offset=start + offset)
    shape = tuple(reversed(dims)) + (planecount,)
    return arr.reshape(shape).astype(dtype.newbyteorder("="))


def write_jxf(path, matrix):
    """Write an array shaped like read_jxf's output. dtype selects the type."""
    matrix = np.asarray(matrix)
    type4 = TYPES_BY_DTYPE.get(matrix.dtype)
    if type4 is None:
        raise JxfError(f"unsupported dtype {matrix.dtype}")
    planecount = matrix.shape[-1]
    dims = tuple(reversed(matrix.shape[:-1]))
    offset = 24 + 4 * len(dims)
    body = np.ascontiguousarray(matrix, dtype=matrix.dtype.newbyteorder(">")).tobytes()
    mtrx = (b"MTRX" + struct.pack(">II4sII", offset + len(body), offset, type4,
                                  planecount, len(dims))
            + struct.pack(">" + "I" * len(dims), *dims))
    fver = b"FVER" + struct.pack(">II", 12, FVER_VERSION)
    total = 12 + len(fver) + len(mtrx) + len(body)
    with open(path, "wb") as f:
        f.write(b"FORM" + struct.pack(">I", total) + b"JIT!" + fver + mtrx + body)


# ---------------------------------------------------------------- conventions
# Bench-verified 2026-09-22 (.specify/test_bench/tasks.md T018; Max 9,
# jit.gl.pix float32 readback via jit.matrix jit_gl_texture):
#   - plane order is ARGB: const codebox vec(1,2,3,4) read back as raw
#     planes [4, 1, 2, 3].
#   - no row flip: the probe codebox's norm.y is smallest at matrix row 0,
#     and norm = (i + 0.5)/dim exactly (texel centers), matching gpu_sim.
#   - identity pass on float32 values in [-10, 10]: bitwise exact round trip
#     (no clamping, no 8-bit path).
#   - Max writes 'FL32' with a header byte-identical to write_jxf's.
PLANES_ARGB_TO_RGBA = [1, 2, 3, 0]
PLANES_RGBA_TO_ARGB = [3, 0, 1, 2]
FLIP_ROWS = False


def matrix_to_rgba(m):
    rgba = np.asarray(m, np.float32)[..., PLANES_ARGB_TO_RGBA]
    return rgba[::-1] if FLIP_ROWS else rgba


def rgba_to_matrix(rgba):
    m = np.asarray(rgba, np.float32)[..., PLANES_RGBA_TO_ARGB]
    return np.ascontiguousarray(m[::-1] if FLIP_ROWS else m)


def read_rgba(path):
    return matrix_to_rgba(read_jxf(path))


def write_rgba(path, rgba):
    write_jxf(path, rgba_to_matrix(rgba))
