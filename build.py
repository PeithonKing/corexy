# /// script
# requires-python = ">=3.10"
# dependencies = ["tqdm"]
# ///
"""Export every printable part of corexy.scad as STL, for your size and printer.

  uv run build.py                                   # default size and fits -> stl/
  uv run build.py my_stl --work-x 100 --work-y 120
  uv run build.py --slide-clearance 0.25 --pin-hole 2.4
  uv run build.py --single                          # one file per part, not one per copy
  uv run build.py --help

Needs only OpenSCAD on the PATH (2021.01 or newer). Plain `python3 build.py`
works too, just without the progress bar.
"""
import argparse, json, os, re, shutil, subprocess, sys, tempfile
from concurrent.futures import ThreadPoolExecutor, as_completed
from pathlib import Path

try:
    from tqdm import tqdm
except ImportError:              # plain python3 without tqdm: no progress bar
    tqdm = None

ROOT = Path(__file__).resolve().parent
SCAD = ROOT / "corexy.scad"

# size + fit options
options = argparse.ArgumentParser(add_help=False)
g = options.add_argument_group("size")
g.add_argument("--work-x", type=float, default=72, help="carriage travel left-right, mm (50-150, default 72)")
g.add_argument("--work-y", type=float, default=80, help="carriage travel front-back, mm (50-170, default 80)")
g = options.add_argument_group("fit (tune for your printer)")
g.add_argument("--slide-clearance", type=float, default=0.2, help="gap per side for sliding parts (default 0.2)")
g.add_argument("--socket-clearance", type=float, default=0.15, help="gap per side for parts in sockets (default 0.15)")
g.add_argument("--spin-clearance", type=float, default=0.25, help="gap per side for spinning parts (default 0.25)")
g.add_argument("--pin-hole", type=float, default=2.3, help="hole for 1.75 mm filament pins (default 2.3)")
g.add_argument("--yarn-d", type=float, default=1.1, help="yarn thickness (default 1.1)")
g.add_argument("--yarn-hole", type=float, default=2.5, help="yarn holes in fins and drums (default 2.5)")

parser = argparse.ArgumentParser(parents=[options], description="Export the String CoreXY parts as STL files.")
parser.add_argument("out", nargs="?", type=Path, default=ROOT / "stl", help="output folder (default: stl/)")
parser.add_argument("--single", action="store_true",
                    help="one file per part (e.g. pulley.stl) instead of one per copy (pulley_1.stl ... pulley_8.stl)")
parser.add_argument("--legacy", action="store_true",
                    help="render with the old CGAL engine (slower). The default is whatever your OpenSCAD uses: "
                         "Manifold on recent versions, CGAL on 2021.01")

PARAMS = {"work_x": "work_x", "work_y": "work_y", "slide_clearance": "slide_clearance",
          "socket_clearance": "socket_clearance", "spin_clearance": "spin_clearance",
          "pin_hole": "pin_hole", "yarn_d": "yarn_d", "yarn_hole": "yarn_hole"}


def defines(args):
    """-D overrides for every size and fit value."""
    out = []
    for scad_name, arg_name in PARAMS.items():
        out += ["-D", f"{scad_name}={getattr(args, arg_name)}"]
    return out


def need_openscad():
    """Stop right away if OpenSCAD isn't installed."""
    if not shutil.which("openscad"):
        sys.exit("OpenSCAD not found. Install it from https://openscad.org and make sure `openscad` is on your PATH.")


def legacy_flags():
    """Flags that force the CGAL engine. Versions without --backend (2021.01 and older
    nightlies) already use CGAL unless told otherwise, so they need nothing."""
    r = subprocess.run(["openscad", "--help"], capture_output=True, text=True)
    return ["--backend", "CGAL"] if "--backend" in r.stdout + r.stderr else []


def run(cmd, out, part):
    """Run openscad and stop with a readable message if it fails."""
    if str(out).endswith(".stl"):
        cmd[1:1] = ["--export-format", "binstl"]
    r = subprocess.run(cmd, capture_output=True, text=True)
    # with an .echo output, openscad writes its errors into that file and exits 0
    log = r.stderr + (Path(out).read_text() if str(out).endswith(".echo") and Path(out).exists() else "")
    if r.returncode != 0 or "ERROR" in log:
        said = re.findall(r'failed: "(.*)" in file', log)      # a failed check in corexy.scad
        lines = [l for l in log.splitlines() if "ERROR" in l] or log.splitlines()[-3:]
        sys.exit(f"openscad failed for {part}:\n" + "\n".join(said or lines))


def openscad(out, scad, defs, part, flags=()):
    run(["openscad", *flags, "-o", str(out), "-D", f'part="{part}"', *defs, str(scad)], out, part)


def export(out, defs, flags, name, qty, single):
    """Export one part; unless single, save one file per copy so they drop straight into a slicer."""
    for old in [out / f"{name}.stl", *out.glob(f"{name}_[0-9]*.stl")]:   # leftovers from a run in the other mode
        old.unlink(missing_ok=True)
    openscad(out / f"{name}.stl", SCAD, defs, name, flags)
    if single or qty == 1:
        return [f"{name}.stl"]
    files = [f"{name}_{i}.stl" for i in range(1, qty + 1)]
    for f in files[1:]:
        shutil.copyfile(out / f"{name}.stl", out / f)
    (out / f"{name}.stl").rename(out / files[0])
    return files


if __name__ == "__main__":
    args = parser.parse_args()
    need_openscad()
    defs = defines(args)
    flags = legacy_flags() if args.legacy else []
    args.out.mkdir(parents=True, exist_ok=True)

    # one quick run (no geometry) for the summary lines and the part list
    with tempfile.TemporaryDirectory() as tmp:
        openscad(Path(tmp) / "info.echo", SCAD, defs, "none")
        echo = (Path(tmp) / "info.echo").read_text().splitlines()
    parts = json.loads(next(l for l in echo if l.startswith('ECHO: "PARTS"')).split(", ", 1)[1])

    print(f"Exporting {len(parts)} parts to {args.out}" + (" with CGAL (slow)" if args.legacy else "") + " ...", flush=True)
    files = {}
    with ThreadPoolExecutor(os.cpu_count() or 4) as ex:
        jobs = {ex.submit(export, args.out, defs, flags, name, qty, args.single): name for name, qty in parts}
        done = as_completed(jobs)
        if tqdm:
            done = tqdm(done, total=len(jobs), unit="part", leave=False)
        for job in done:
            files[jobs[job]] = job.result()
    for name, qty in parts:
        f = files[name]
        print(f"  {f[0]} ... {f[-1]}" if len(f) > 1 else f"  {f[0]}" + (f"  (print {qty})" if qty > 1 else ""))
    print()
    for l in echo:
        if l.startswith("ECHO:") and '"PARTS"' not in l:
            print(l[6:].strip('"'))
