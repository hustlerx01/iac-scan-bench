import os, re, shutil, subprocess, yaml, pytest
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
GT = yaml.safe_load(open(os.path.join(ROOT, "bench/ground_truth.yaml")))

def test_every_plant_is_tagged_in_sample():
    src = open(os.path.join(ROOT, "samples/insecure/main.tf")).read()
    for p in GT: assert p in src, p

def test_ground_truth_shape():
    for p, v in GT.items():
        assert set(v) == {"desc", "checkov", "tfsec", "conftest"}

@pytest.mark.skipif(not shutil.which("conftest"), reason="conftest not installed")
def test_rego_unit_tests():
    p = subprocess.run(["conftest", "verify", "-p", "policy"], cwd=ROOT, capture_output=True, text=True)
    assert p.returncode == 0, p.stdout + p.stderr

@pytest.mark.skipif(not (shutil.which("checkov") and shutil.which("tfsec") and shutil.which("conftest")), reason="scanners missing")
def test_benchmark_regression(tmp_path):
    import sys; sys.path.insert(0, os.path.join(ROOT, "bench"))
    from run_bench import main
    r = main(str(tmp_path))
    assert r["checkov"]["recall"] >= 0.9
    assert r["tfsec"]["recall"] >= 0.8
    assert set(r["conftest"]["planted_detected"]) == {"PLANT-03", "PLANT-05", "PLANT-11"}
    assert r["conftest"]["fixed_findings"] == 0
    # union of scanners must cover everything
    assert set().union(*(set(x["planted_detected"]) for x in r.values())) == set(GT)
