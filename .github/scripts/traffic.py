#!/usr/bin/env python3
"""Fetch GitHub traffic for this repo and merge it into CSV files under traffic/."""
import csv, json, os, sys, urllib.request, datetime

repo, token = os.environ["REPO"], os.environ.get("TRAFFIC_TOKEN", "")
if not token:
    sys.exit("TRAFFIC_TOKEN secret is missing: add a fine-grained token with 'Administration: read-only' for this repository.")
os.makedirs("traffic", exist_ok=True)

def get(path):
    req = urllib.request.Request(f"https://api.github.com/repos/{repo}{path}",
        headers={"Authorization": f"Bearer {token}", "Accept": "application/vnd.github+json", "X-GitHub-Api-Version": "2022-11-28"})
    with urllib.request.urlopen(req, timeout=30) as r:
        return json.load(r)

def merge(name, rows, key, fields):
    path = f"traffic/{name}.csv"
    data = {}
    if os.path.exists(path):
        with open(path) as f:
            for r in csv.DictReader(f):
                data[r[key]] = r
    for r in rows:
        data[r[key]] = {k: r.get(k, "") for k in fields}   # newer numbers replace older ones for the same day
    with open(path, "w", newline="") as f:
        w = csv.DictWriter(f, fieldnames=fields)
        w.writeheader()
        for k in sorted(data):
            w.writerow(data[k])

today = datetime.date.today().isoformat()
clones = get("/traffic/clones")
merge("clones", [{"date": c["timestamp"][:10], "clones": c["count"], "unique_cloners": c["uniques"]} for c in clones.get("clones", [])],
      "date", ["date", "clones", "unique_cloners"])
views = get("/traffic/views")
merge("views", [{"date": v["timestamp"][:10], "views": v["count"], "unique_visitors": v["uniques"]} for v in views.get("views", [])],
      "date", ["date", "views", "unique_visitors"])
refs = get("/traffic/popular/referrers")
merge("referrers", [{"key": f"{today}|{r['referrer']}", "date": today, "referrer": r["referrer"], "views": r["count"], "unique": r["uniques"]} for r in refs],
      "key", ["key", "date", "referrer", "views", "unique"])
info = get("")
forks = get("/forks?per_page=100")
merge("forks", [{"user": f["owner"]["login"], "forked_at": f["created_at"][:10], "fork": f["full_name"]} for f in forks],
      "user", ["user", "forked_at", "fork"])
merge("summary", [{"date": today, "stars": info["stargazers_count"], "forks": info["forks_count"], "watchers": info["subscribers_count"],
                   "clones_14d": clones.get("count", 0), "unique_cloners_14d": clones.get("uniques", 0),
                   "views_14d": views.get("count", 0), "unique_visitors_14d": views.get("uniques", 0)}],
      "date", ["date", "stars", "forks", "watchers", "clones_14d", "unique_cloners_14d", "views_14d", "unique_visitors_14d"])
print(f"clones 14d: {clones.get('count')} ({clones.get('uniques')} unique) · views 14d: {views.get('count')} ({views.get('uniques')} unique) · forks: {info['forks_count']}")
