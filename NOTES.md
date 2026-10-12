# NOTES
- 2026-10-11: benchmark built and run. Checkov 10/11, tfsec 9/11, union with custom Rego 11/11.
- Gotcha 1: conftest's HCL2 parser makes every block a list (`resource.aws_db_instance.db[0]`), so Rego must iterate with `some x in ...`.
- Gotcha 2: conftest counts every `deny_*` rule, so an extra aggregate `deny` set doubled the findings. Removed it.
- Interview angles: recall vs noise, writing custom policy for org-specific gaps, skip/baseline workflows (`#checkov:skip=` with a justification), and why tfsec → Trivy.
- Next: generate 50 TF samples with an LLM from fixed prompts, scan them, and report the % insecure per category. Add trivy config as a 4th tool.
