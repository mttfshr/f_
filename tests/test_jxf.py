"""
test_jxf.py -- offline checks of the .jxf reader/writer.

The independent ground truth is a file Max itself wrote:
C74/help/jitter/matrix1.jxf (hand-decoded with xxd, 2026-09-22).

Run:  tests/run.sh tests/test_jxf.py
"""
import os
import struct
import sys
import tempfile

import numpy as np

from harness import check, run
from jxf import (JxfError, read_jxf, read_rgba, write_jxf, write_rgba,
                 matrix_to_rgba, rgba_to_matrix)

MAX_JXF = "/Applications/Max.app/Contents/Resources/C74/help/jitter/matrix1.jxf"


def _tmp():
    fd, path = tempfile.mkstemp(suffix=".jxf")
    os.close(fd)
    return path


def test_parse_max_written_file():
    """Header fields and first cells as read from the raw bytes by hand."""
    if not os.path.exists(MAX_JXF):
        print("    SKIP (Max not installed at default path)")
        return
    m = read_jxf(MAX_JXF)
    check("shape == (240, 320, 2) [H, W, planes]", 0 if m.shape == (240, 320, 2) else 1, 0)
    check("dtype int32 (LONG)", 0 if m.dtype == np.int32 else 1, 0)
    # bytes 0x28..0x38 of the file: 000000ff 00000004 000000ff 00000008
    check("cell (0,0) == [255, 4]", np.abs(m[0, 0] - [255, 4]).max(), 0)
    check("cell (0,1) == [255, 8]", np.abs(m[0, 1] - [255, 8]).max(), 0)


def test_float32_roundtrip_bitwise():
    rng = np.random.default_rng(0)
    for shape in [(8, 8, 4), (64, 128, 4), (3, 5, 1)]:
        m = (rng.standard_normal(shape) * 1e3).astype(np.float32)
        m.flat[0], m.flat[1] = np.float32(1e-38), np.float32(-0.0)
        path = _tmp()
        try:
            write_jxf(path, m)
            back = read_jxf(path)
        finally:
            os.remove(path)
        same = back.shape == m.shape and back.tobytes() == m.tobytes()
        check(f"FL32 {shape} bitwise round trip", 0 if same else 1, 0)


def test_other_types_roundtrip():
    rng = np.random.default_rng(1)
    for dtype in (np.uint8, np.int32, np.float64):
        m = (rng.random((4, 6, 4)) * 200).astype(dtype)
        path = _tmp()
        try:
            write_jxf(path, m)
            back = read_jxf(path)
        finally:
            os.remove(path)
        check(f"{np.dtype(dtype).name} round trip",
              0 if back.dtype == m.dtype and np.array_equal(back, m) else 1, 0)


def test_written_header_layout():
    """Our writer's bytes follow the layout decoded from Max's file."""
    path = _tmp()
    try:
        write_jxf(path, np.zeros((2, 3, 4), np.float32))
        raw = open(path, "rb").read()
    finally:
        os.remove(path)
    ok = (raw[0:4] == b"FORM" and struct.unpack(">I", raw[4:8])[0] == len(raw)
          and raw[8:12] == b"JIT!" and raw[12:16] == b"FVER"
          and struct.unpack(">II", raw[16:24]) == (12, 0x3C93DC80)
          and raw[24:28] == b"MTRX"
          and struct.unpack(">I4sIIII", raw[32:56]) == (32, b"FL32", 4, 2, 3, 2)
          and struct.unpack(">I", raw[28:32])[0] == 32 + 2 * 3 * 4 * 4)
    check("header layout matches Max's", 0 if ok else 1, 0)


def test_rgba_conversion_inverse():
    rng = np.random.default_rng(2)
    rgba = rng.random((5, 7, 4)).astype(np.float32)
    check("rgba -> matrix -> rgba", np.abs(matrix_to_rgba(rgba_to_matrix(rgba)) - rgba).max(), 0)
    path = _tmp()
    try:
        write_rgba(path, rgba)
        back = read_rgba(path)
    finally:
        os.remove(path)
    check("write_rgba/read_rgba", np.abs(back - rgba).max(), 0)


def test_rejects_corrupt_file():
    path = _tmp()
    try:
        write_jxf(path, np.zeros((2, 2, 4), np.float32))
        raw = bytearray(open(path, "rb").read())
        open(path, "wb").write(bytes(raw[:-4]))          # truncated
        try:
            read_jxf(path)
            rejected = False
        except JxfError:
            rejected = True
    finally:
        os.remove(path)
    check("truncated file rejected", 0 if rejected else 1, 0)


if __name__ == "__main__":
    sys.exit(run(globals()))
