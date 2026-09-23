"""
benchclient.py -- Python side of the Max test bench
(.specify/test_bench/plan.md). Talks to tests/bench/bench.maxpat over
OSC/UDP; data and reports move through files in a per-job directory.

    Python -> bench  UDP 7471   /ping            /run <abs job dir>
    bench -> Python  UDP 7472   /pong            /done <job dir>   /busy <job dir>

OSC encoding is hand-rolled (string/int/float args only) to avoid a
dependency. The bench writes result.json BEFORE replying /done.
"""
import json
import socket
import struct
import time
import uuid
from pathlib import Path

HOST = "127.0.0.1"
TO_BENCH_PORT = 7471
FROM_BENCH_PORT = 7472
CODEBOX_PORTS = (TO_BENCH_PORT, FROM_BENCH_PORT)     # tests/bench/bench.maxpat
MODULE_PORTS = (7473, 7474)                          # tests/bench/bench_module.maxpat

TESTS_DIR = Path(__file__).resolve().parent
BENCH_DIR = TESTS_DIR / "bench"
JOBS_DIR = TESTS_DIR / "jobs"


class BenchUnreachable(RuntimeError):
    pass


class BenchBusy(RuntimeError):
    pass


class BenchTimeout(RuntimeError):
    pass


# ---------------------------------------------------------------- OSC

def _osc_string(s):
    b = s.encode("utf-8") + b"\x00"
    return b + b"\x00" * (-len(b) % 4)


def osc_encode(address, *args):
    tags, payload = ",", b""
    for a in args:
        if isinstance(a, bool):
            raise TypeError("bool OSC args not supported")
        if isinstance(a, int):
            tags += "i"
            payload += struct.pack(">i", a)
        elif isinstance(a, float):
            tags += "f"
            payload += struct.pack(">f", a)
        else:
            tags += "s"
            payload += _osc_string(str(a))
    return _osc_string(address) + _osc_string(tags) + payload


def _read_osc_string(data, pos):
    end = data.index(b"\x00", pos)
    s = data[pos:end].decode("utf-8")
    return s, end + 1 + (-(end + 1) % 4)


def osc_decode(data):
    address, pos = _read_osc_string(data, 0)
    if pos >= len(data):
        return address, []
    tags, pos = _read_osc_string(data, pos)
    args = []
    for t in tags[1:]:
        if t == "i":
            args.append(struct.unpack(">i", data[pos:pos + 4])[0])
            pos += 4
        elif t == "f":
            args.append(struct.unpack(">f", data[pos:pos + 4])[0])
            pos += 4
        elif t == "s":
            s, pos = _read_osc_string(data, pos)
            args.append(s)
        else:
            raise ValueError(f"unsupported OSC type tag {t!r}")
    return address, args


# ---------------------------------------------------------------- transport

class Channel:
    """Context manager: bind the reply port, send, and receive replies.
    ports = (to_bench, from_bench); defaults to the codebox bench."""

    def __init__(self, ports=CODEBOX_PORTS):
        self.to_port, self.from_port = ports

    def __enter__(self):
        self.sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        self.sock.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
        self.sock.bind((HOST, self.from_port))
        return self

    def __exit__(self, *exc):
        self.sock.close()

    def send(self, address, *args):
        self.sock.sendto(osc_encode(address, *args), (HOST, self.to_port))

    def wait_for(self, match, timeout):
        """Receive until match(address, args) is true; ignore other traffic.
        Returns (address, args), or raises socket.timeout."""
        deadline = time.monotonic() + timeout
        while True:
            remaining = deadline - time.monotonic()
            if remaining <= 0:
                raise socket.timeout()
            self.sock.settimeout(remaining)
            data, _ = self.sock.recvfrom(65536)
            try:
                address, args = osc_decode(data)
            except (ValueError, UnicodeDecodeError):
                continue
            if match(address, args):
                return address, args


def ping(timeout=1.0, ports=CODEBOX_PORTS):
    with Channel(ports) as ch:
        ch.send("/ping")
        try:
            ch.wait_for(lambda a, _: a == "/pong", timeout)
            return True
        except socket.timeout:
            return False


def require_bench(ports=CODEBOX_PORTS, patch="bench.maxpat"):
    if not ping(ports=ports):
        raise BenchUnreachable(
            f"bench not reachable -- open Max and tests/bench/{patch} "
            f"(expects /pong on UDP {ports[1]})")


def reopen(wait=15.0, ports=CODEBOX_PORTS, patch="bench.maxpat"):
    """Close the open bench (if any) and open tests/bench/<patch> fresh,
    e.g. after regenerating it. Max must be running."""
    import subprocess
    with Channel(ports) as ch:
        ch.send("/close")
        try:
            ch.wait_for(lambda a, _: a in ("/closing", "/busy"), 1.0)
        except socket.timeout:
            pass                                    # not open: fine
    time.sleep(1.0)
    subprocess.run(["open", "-a", "Max", str(BENCH_DIR / patch)], check=True)
    deadline = time.monotonic() + wait
    while time.monotonic() < deadline:
        if ping(0.5, ports=ports):
            return True
    raise BenchUnreachable("bench did not answer after reopening")


# ---------------------------------------------------------------- jobs

def new_job(mode, **fields):
    """Create a job dir and return (job_dict, job_dir). Ids are unique and
    symbol-safe (they also name the job's .genjit, plan.md ADR-3)."""
    job_id = time.strftime("%Y%m%d_%H%M%S_") + uuid.uuid4().hex[:6]
    job_dir = JOBS_DIR / job_id
    job_dir.mkdir(parents=True, exist_ok=False)
    job = {"id": job_id, "mode": mode, "timeout_ms": 10000}
    job.update(fields)
    return job, job_dir


def _write_job(job, job_dir):
    with open(job_dir / "job.json", "w") as f:
        json.dump(job, f, indent=2)


def _is_reply(kinds, job_dir):
    target = str(job_dir)
    return lambda a, args: a in kinds and args and str(args[0]) == target


def run_job(job, job_dir, channel=None, ports=CODEBOX_PORTS):
    """Trigger a prepared job and wait for its result.json. Raises
    BenchBusy, BenchTimeout, or BenchUnreachable (no reply at all)."""
    _write_job(job, job_dir)
    timeout = job.get("timeout_ms", 10000) / 1000.0 + 2.0

    def go(ch):
        ch.send("/run", str(job_dir))
        try:
            address, _ = ch.wait_for(_is_reply({"/done", "/busy"}, job_dir), timeout)
        except socket.timeout:
            raise BenchTimeout(f"job {job['id']}: no reply within {timeout:.1f}s")
        if address == "/busy":
            raise BenchBusy(f"job {job['id']}: bench busy")
        with open(job_dir / "result.json") as f:
            return json.load(f)

    if channel is not None:
        return go(channel)
    with Channel(ports) as ch:
        return go(ch)


# ---------------------------------------------------------------- passes

def _prepare(code, inputs, dim, mode, **fields):
    """Create a job dir with inputs, code.gen and this job's .genjit."""
    import jxf
    from genjit import write_genjit

    if not inputs:
        raise ValueError("needs at least one input (in1 drives rendering)")
    h, w = inputs[0].shape[:2]
    dim = dim or (w, h)
    job, job_dir = new_job(mode, dim=[int(dim[0]), int(dim[1])], type="float32", **fields)
    job["gen"] = "job_" + job["id"]
    job["inputs"] = []
    for i, arr in enumerate(inputs[:3]):
        name = f"in{i + 1}.jxf"
        jxf.write_rgba(job_dir / name, arr)
        job["inputs"].append(name)
    (job_dir / "code.gen").write_text(code)
    genjit_path = BENCH_DIR / (job["gen"] + ".genjit")
    write_genjit(genjit_path, code, min_inputs=3, min_outputs=4)   # constant inlets/outlets
    return job, job_dir, genjit_path


def _cleanup_genjits(keep):
    """Keep the just-loaded .genjit; delete older ones only now that the
    slots have moved on to this job's gen. (2026-09-22: deleting the
    *loaded* file made Max try to reload it -- "could not find gen patcher"
    -- an error that can land in the next job's report.)"""
    for old in BENCH_DIR.glob("job_*.genjit"):
        if old != keep:
            old.unlink()


def run_pass(code, inputs, dim=None, params=None, warmup=5, timeout_ms=10000,
             compile=False, raw=False, keep_genjit=False, pix_type="float32",
             all_outputs=False):
    """Run one codebox pass on the bench (spec Story 2; plan ADR-3/ADR-4).

    code    -- codebox text (GenExpr)
    inputs  -- list of up to 3 RGBA float32 arrays (H, W, 4)
    dim     -- (w, h) output size; defaults to the first input's size
    raw     -- return the output as the raw Jitter matrix (planes as stored)
               instead of converting through jxf's RGBA conventions
    pix_type    -- "float32" (default) or "char" (E2); char outputs come back
                   scaled to 0..1 (k/255)
    all_outputs -- return [out1, out2, out3, out4] (None for silent outlets)
                   instead of out1 alone (E1)

    Returns (output_array_or_None, result_dict). The codebox is also saved
    as code.gen in the job dir for post-mortems.
    """
    import jxf

    job, job_dir, genjit_path = _prepare(
        code, inputs, dim, "correctness", params=params or {}, warmup=warmup,
        timeout_ms=timeout_ms, compile=bool(compile))
    job["type"] = pix_type
    result = run_job(job, job_dir)
    if not keep_genjit:
        _cleanup_genjits(genjit_path)
    read = jxf.read_jxf if raw else jxf.read_rgba
    outs = []
    for k in range(1, 5):
        path = job_dir / ("out.jxf" if k == 1 else f"out{k}.jxf")
        outs.append(read(path) if path.exists() else None)
    result["job_dir"] = str(job_dir)
    return (outs if all_outputs else outs[0]), result


def run_temporal(code, inputs, steps, feedback=(1, 2), dim=None, params=None,
                 pix_type="float32", timeout_ms=15000):
    """E4: run a codebox for several frames with feedback -- slot 1's outlet
    feedback[0] is copied (identity pass pix) into its inlet feedback[1] (2 or
    3), one frame later. inputs[feedback[1]-1] is the initial state. Step s
    reads step s-1's output (step 1 reads the initial state).

    Returns ({step: [out1..out4 or None]}, result)."""
    import jxf
    from_out, to_in = feedback
    if to_in not in (2, 3) or not 1 <= from_out <= 4:
        raise ValueError("feedback = (from_out 1..4, to_in 2 or 3)")
    if len(inputs) < to_in:
        raise ValueError(f"inputs[{to_in - 1}] must hold the initial state")
    job, job_dir, genjit_path = _prepare(
        code, inputs, dim, "temporal", params=params or {}, timeout_ms=timeout_ms,
        steps=sorted(set(int(s) for s in steps)),
        feedback={"from_out": int(from_out), "to_in": int(to_in)})
    job["type"] = pix_type
    result = run_job(job, job_dir)
    _cleanup_genjits(genjit_path)
    frames = {}
    for s in job["steps"]:
        outs = []
        for k in range(1, 5):
            p = job_dir / f"out{k}_s{s}.jxf"
            outs.append(jxf.read_rgba(p) if p.exists() else None)
        frames[s] = outs
    result["job_dir"] = str(job_dir)
    return frames, result


def measure(code, inputs, dim=None, chain=1, params=None, warmup=30,
            measure_ms=1000, target_fps=1000, timeout_ms=None):
    """Performance run (spec Story 3; plan ADR-6/ADR-9): the codebox in
    slots 1..chain, fps over measure_ms, then a K=0 (all bypassed) baseline.

    CPU and GPU work overlap, so frame time ~= max(CPU overhead, K * pass
    cost) -- verified 2026-09-22 (heavy codebox: K=1 8.8 ms, K=2 17.3 ms;
    N=512 DFT K=1/2/4/8 fits 1/max(overhead, K*2.9 ms)). Hence:
      gpu_bound    fps < 0.75 * baseline: GPU work dominates the frame
      ms_per_pass  frame_ms / chain, only when gpu_bound (slight
                   overestimate: includes the bench's own tiny GPU work)
      ms_per_pass_upper_bound  frame_ms_k0 / chain when NOT gpu_bound: the
                   pass fits inside the CPU overhead and can't be resolved
                   -- raise chain or resolution to measure it
    Subtracting the baseline (the original plan) is wrong under overlap.
    """
    if timeout_ms is None:
        timeout_ms = 2 * measure_ms + 15000
    job, job_dir, genjit_path = _prepare(
        code, inputs, dim, "performance", params=params or {}, warmup=warmup,
        chain=int(chain), measure_ms=int(measure_ms), target_fps=target_fps,
        timeout_ms=timeout_ms)
    result = run_job(job, job_dir)
    _cleanup_genjits(genjit_path)
    fk, f0 = result.get("fps"), result.get("fps_baseline_k0")
    if fk and f0 and chain:
        result["frame_ms"] = 1000.0 / fk
        result["frame_ms_k0"] = 1000.0 / f0
        result["gpu_bound"] = fk < 0.75 * f0
        if result["gpu_bound"]:
            result["ms_per_pass"] = result["frame_ms"] / chain
        else:
            result["ms_per_pass_upper_bound"] = result["frame_ms_k0"] / chain
    result["job_dir"] = str(job_dir)
    return result
