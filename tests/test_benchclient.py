"""
test_benchclient.py -- offline checks of the OSC encoding used to talk to the
bench, against hand-written OSC 1.0 byte strings (independent ground truth),
plus an in-process UDP loopback of the reply-matching logic.

Run:  tests/run.sh tests/test_benchclient.py
"""
import socket
import sys
import threading

import benchclient
from benchclient import Channel, osc_decode, osc_encode
from harness import check, run


def test_encode_matches_spec_bytes():
    # OSC 1.0: address and type-tag strings null-terminated, padded to 4
    check("/ping", 0 if osc_encode("/ping") == b"/ping\x00\x00\x00,\x00\x00\x00" else 1, 0)
    check("4-char address gets 4 nulls",
          0 if osc_encode("/abc") == b"/abc\x00\x00\x00\x00,\x00\x00\x00" else 1, 0)
    expect = b"/run\x00\x00\x00\x00,s\x00\x00/a b\x00\x00\x00\x00"
    check("/run '/a b'", 0 if osc_encode("/run", "/a b") == expect else 1, 0)
    check("int arg", 0 if osc_encode("/x", 7) == b"/x\x00\x00,i\x00\x00\x00\x00\x00\x07" else 1, 0)


def test_roundtrip():
    cases = [("/ping", []), ("/pong", []),
             ("/run", ["/Users/matt/Github/f_/tests/jobs/20260922_120000_abcdef"]),
             ("/done", ["/path with spaces/x"]), ("/mix", ["s", 3, 0.5])]
    bad = 0
    for address, args in cases:
        a, got = osc_decode(osc_encode(address, *args))
        bad += (a != address) or (got != args)
    check("round trips", bad, 0)
    check("address-only packet (no type tags) decodes",
          0 if osc_decode(b"/pong\x00\x00\x00") == ("/pong", []) else 1, 0)


def test_loopback_reply_matching():
    """A fake bench on the bench port: replies to /run with an unrelated
    /done first, then the matching one. wait_for must skip the unrelated."""
    fake = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    try:
        fake.bind((benchclient.HOST, benchclient.TO_BENCH_PORT))
    except OSError:
        fake.close()
        print("    SKIP (bench port in use -- the real bench is probably open)")
        return
    fake.settimeout(2.0)

    def serve():
        data, _ = fake.recvfrom(65536)
        _, args = osc_decode(data)
        reply_to = (benchclient.HOST, benchclient.FROM_BENCH_PORT)
        fake.sendto(osc_encode("/done", "/some/other/job"), reply_to)
        fake.sendto(osc_encode("/done", args[0]), reply_to)

    t = threading.Thread(target=serve)
    try:
        with Channel() as ch:
            t.start()
            ch.send("/run", "/tmp/job_x")
            match = benchclient._is_reply({"/done", "/busy"}, "/tmp/job_x")
            address, args = ch.wait_for(match, 2.0)
        check("matched reply is ours", 0 if args == ["/tmp/job_x"] else 1, 0)
    finally:
        t.join(timeout=2.0)
        fake.close()


if __name__ == "__main__":
    sys.exit(run(globals()))
