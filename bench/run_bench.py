"""Run Checkov, tfsec and conftest on samples/{insecure,fixed}; score against bench/ground_truth.yaml."""
import json, os, re, shutil, subprocess, sys, time
import yaml
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

def run(cmd):
    t = time.time(); p = subprocess.run(cmd, capture_output=True, text=True, cwd=ROOT); return p.stdout, time.time() - t

def checkov_ids(d):
    out, sec = run(["checkov", "-d", d, "-o", "json", "--quiet", "--compact", "--skip-download"])
    data = json.loads(out) if out.strip() else []
    data = data if isinstance(data, list) else [data]
    return [f["check_id"] for r in data for f in r.get("results", {}).get("failed_checks", [])], sec

def tfsec_ids(d):
    out, sec = run(["tfsec", d, "--format", "json", "--no-color"])
    return [f["long_id"] for f in (json.loads(out).get("results") or [])], sec

def conftest_ids(d):
    out, sec = run(["conftest", "test", "-p", "policy", "-o", "json", f"{d}/main.tf"])
    msgs = [m["msg"] for r in json.loads(out) for m in (r.get("failures") or [])]
    return [m.split(":")[0] for m in msgs], sec

TOOLS = {"checkov": checkov_ids, "tfsec": tfsec_ids, "conftest": conftest_ids}

def main(outdir="results"):
    gt = yaml.safe_load(open(os.path.join(ROOT, "bench/ground_truth.yaml")))
    res = {}
    for tool, fn in TOOLS.items():
        if tool != "conftest" and not shutil.which(tool):
            print(f"skip {tool}: not installed"); continue
        ins, t1 = fn("samples/insecure"); fix, t2 = fn("samples/fixed")
        detected = sorted(p for p, v in gt.items() if set(v[tool]) & set(ins))
        res[tool] = {"insecure_findings": len(ins), "unique_rules": len(set(ins)),
                     "planted_detected": detected, "planted_missed": sorted(set(gt) - set(detected)),
                     "recall": round(len(detected) / len(gt), 3),
                     "fixed_findings": len(fix), "fixed_rules": sorted(set(fix)), "runtime_s": round(t1 + t2, 2)}
    os.makedirs(os.path.join(ROOT, outdir), exist_ok=True)
    json.dump(res, open(os.path.join(ROOT, outdir, "bench.json"), "w"), indent=2)
    lines = ["| Tool | Findings (insecure) | Planted detected | Recall | Missed | Findings on fixed | Runtime |", "|---|---|---|---|---|---|---|"]
    for t, r in res.items():
        lines.append(f"| {t} | {r['insecure_findings']} | {len(r['planted_detected'])}/{len(gt)} | {r['recall']} | {', '.join(r['planted_missed']) or '-'} | {r['fixed_findings']} | {r['runtime_s']} s |")
    union = set().union(*(set(r["planted_detected"]) for r in res.values())) if res else set()
    lines.append(f"\nUnion of all tools: {len(union)}/{len(gt)} planted issues.")
    open(os.path.join(ROOT, outdir, "bench.md"), "w").write("\n".join(lines) + "\n")
    print("\n".join(lines)); return res

if __name__ == "__main__":
    main(*sys.argv[1:])
