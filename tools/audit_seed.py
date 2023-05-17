# -*- coding: utf-8 -*-
"""
audit_seed.py - Doi chieu doc lap file 02_seed.sql da sinh:
parse truc tiep SQL va kiem tra lai cong thuc hoa don, tong dong hoa don,
thanh toan cua hoa don PAID, booked_count theo ca, tong luong thuoc va
co abnormal. Khong dung chung code voi generate_seed.py.
Chay: python3 tools/audit_seed.py
"""
import re
from decimal import Decimal
from pathlib import Path
from collections import defaultdict
sql = (Path(__file__).resolve().parent.parent / "database" / "02_seed.sql").read_text(encoding="utf-8")

def parse_table(table):
    m = re.search(rf"INSERT INTO dbo\.{table} \(([^)]*)\) VALUES\n(.*?);\nSET IDENTITY_INSERT", sql, re.S)
    cols = [c.strip() for c in m.group(1).split(",")]
    body = m.group(2)
    rows = []
    # split tuples at line level: each row is one line starting with spaces + (
    for line in body.splitlines():
        line = line.strip().rstrip(",")
        if not line.startswith("("): continue
        inner = line[1:-1]
        parts, cur, inq = [], "", False
        for ch in inner:
            if ch == "'": inq = not inq
            if ch == "," and not inq:
                parts.append(cur.strip()); cur = ""
            else: cur += ch
        parts.append(cur.strip())
        rows.append(dict(zip(cols, parts)))
    return rows

def D(x): return Decimal(x) if x not in ("NULL",) else None

inv = parse_table("invoices"); items = parse_table("invoice_items"); pays = parse_table("payments")
print(f"invoices={len(inv)} items={len(items)} payments={len(pays)}")
bad = []
for r in inv:
    svc, lab, med = D(r["services_total"]), D(r["labs_total"]), D(r["meds_total"])
    gross, ins, disc, copay = D(r["gross_total"]), D(r["insurance_payable"]), D(r["discount_amount"]), D(r["patient_copay"])
    if gross != svc+lab+med or copay != gross-ins-disc: bad.append(r["invoice_no"])
print("invoice formula violations:", bad)
tot = defaultdict(Decimal)
for r in items:
    if D(r["line_total"]) != D(r["quantity"])*D(r["unit_price"]): print("BAD line:", r)
    tot[int(r["invoice_id"])] += D(r["line_total"])
mm = [r["invoice_no"] for r in inv if tot[int(r["invoice_id"])] != D(r["gross_total"])]
print("item-sum vs gross mismatches:", mm)
# paid invoices fully covered?
paid = defaultdict(lambda: defaultdict(Decimal))
for r in pays:
    assert D(r["amount"]) > 0, "zero/negative payment!"
    paid[int(r["invoice_id"])][r["payer_type"].strip("'")] += D(r["amount"])
prob = []
for r in inv:
    if r["status"].strip("'") == "PAID":
        p = paid[int(r["invoice_id"])]
        if p["PATIENT"] != D(r["patient_copay"]): prob.append((r["invoice_no"], "patient"))
        if r["insurance_claim_status"].strip("'") == "APPROVED" and p["INSURANCE"] != D(r["insurance_payable"]): prob.append((r["invoice_no"], "insurance"))
print("PAID-invoice coverage problems:", prob)
# schedules booked_count audit
appts = parse_table("appointments"); scheds = parse_table("doctor_schedules")
active = {"BOOKED","CHECKED_IN","COMPLETED","NO_SHOW"}
cnt = defaultdict(int)
for a in appts:
    if a["status"].strip("'") in active: cnt[int(a["schedule_id"])] += 1
sb = [s["schedule_id"] for s in scheds if int(s["booked_count"]) != cnt[int(s["schedule_id"])]]
print("booked_count mismatches:", sb)
# prescription totals
pi = parse_table("prescription_items")
pb = [r["item_id"] for r in pi if D(r["total_quantity"]) != D(r["dose_per_intake"])*int(r["intakes_per_day"])*int(r["duration_days"])]
print("prescription total violations:", pb)
# lab abnormal audit
lr = parse_table("lab_results")
def ab(val, lo, hi):
    if val is None: return 0
    return 1 if (lo is not None and val < lo) or (hi is not None and val > hi) else 0
lb = [r["result_id"] for r in lr if int(r["is_abnormal"]) != ab(D(r["result_value"]), D(r["ref_low"]), D(r["ref_high"]))]
print("lab abnormal flag mismatches:", lb, "| abnormal count:", sum(int(r['is_abnormal']) for r in lr))
