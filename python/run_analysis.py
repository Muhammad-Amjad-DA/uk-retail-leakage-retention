"""Runs the SQL pipeline in order and writes each result set to outputs/*.csv.
Usage (from repo root):  python python/run_analysis.py
"""
import re, pathlib, duckdb

root = pathlib.Path(__file__).resolve().parents[1]
out = root / "outputs"; out.mkdir(exist_ok=True)
con = duckdb.connect()

for f in sorted((root / "sql").glob("*.sql")):
    # split on ';' at end of statement; keep it simple, our files have no semicolons in strings
    stmts = [s.strip() for s in re.split(r";\s*(?:\n|$)", f.read_text()) if s.strip()]
    n = 0
    for s in stmts:
        if not re.sub(r"--.*", "", s).strip():
            continue
        res = con.execute(s)
        if s.lstrip().upper().startswith(("SELECT", "WITH")) or re.search(r"^\s*(SELECT|WITH)\b", re.sub(r"--.*", "", s), re.M) and not re.match(r"\s*(CREATE|INSERT)", re.sub(r"--.*\n", "", s).strip(), re.I):
            df = res.fetchdf()
            n += 1
            df.to_csv(out / f"{f.stem}_q{n}.csv", index=False)
            print(f"\n=== {f.name} (result {n}) ===")
            print(df.to_string(index=False))
