import sys
sys.path.insert(0, "tests")
import bench_fluid as b
from harness import run
names = sys.argv[1:]
sys.exit(run({k: v for k, v in vars(b).items() if k in names}))
