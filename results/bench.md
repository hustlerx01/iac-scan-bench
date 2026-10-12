| Tool | Findings (insecure) | Planted detected | Recall | Missed | Findings on fixed | Runtime |
|---|---|---|---|---|---|---|
| checkov | 47 | 10/11 | 0.909 | PLANT-05 | 17 | 4.69 s |
| tfsec | 30 | 9/11 | 0.818 | PLANT-05, PLANT-11 | 7 | 2.2 s |
| conftest | 3 | 3/11 | 0.273 | PLANT-01, PLANT-02, PLANT-04, PLANT-06, PLANT-07, PLANT-08, PLANT-09, PLANT-10 | 0 | 0.11 s |

Union of all tools: 11/11 planted issues.
