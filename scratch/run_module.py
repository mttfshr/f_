"""Run one module through the live module bench and print its issues (scratch helper)."""
import sys
sys.path.insert(0, "tests")
import bench_modules as b
name = sys.argv[1]
issues, r, info = b.module_issues(name)
print("status:", r["status"], "| errors:", r["errors"][:6])
print("pix:", r.get("pix"))
print("outputs:", r.get("outputs"), "| params_readback:", r.get("params_readback"))
print("bypass_jsui_readback:", r.get("bypass_jsui_readback"))
print("issues:", issues if issues else "none")
for tag, arrs in (r.get("arrays") or {}).items():
    for k, a in arrs.items():
        print(f"array {tag} out{k}: shape {a.shape[:2]}  min {a.min():.3f} max {a.max():.3f}")
