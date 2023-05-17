#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
check_sql_consistency.py - Ra soat tinh nhat quan cua bo SQL MediCore
(khong can SQL Server):
  1. Liet ke bang tao trong 01_schema.sql; moi bang duoc INSERT trong
     02_seed.sql phai ton tai trong schema.
  2. Moi tham chieu dbo.<bang> trong views/procedures/triggers/queries/tests
     phai la bang/view/procedure da dinh nghia.
  3. Dem doi tuong: tables / views / procedures / triggers / indexes.
  4. Kiem tra can bang BEGIN...END va BEGIN TRY...END TRY trong cac file
     co procedure/trigger/test (dem don gian theo tu khoa).
  5. Kiem tra moi file SQL co dung USE MediCoreDB va ket thuc bang GO.

Chay:  python3 tools/check_sql_consistency.py
"""
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
DB = ROOT / "database"


def read(name):
    return (DB / name).read_text(encoding="utf-8")


def strip_comments(sql):
    sql = re.sub(r"/\*.*?\*/", " ", sql, flags=re.S)
    sql = re.sub(r"--[^\n]*", " ", sql)
    return sql


def main():
    problems = []

    schema = strip_comments(read("01_schema.sql"))
    tables = re.findall(r"CREATE TABLE dbo\.(\w+)", schema)
    table_set = set(tables)

    seed = strip_comments(read("02_seed.sql"))
    seed_tables = set(re.findall(r"INSERT INTO dbo\.(\w+)", seed))
    seed_tables |= set(re.findall(r"DELETE FROM dbo\.(\w+)", seed))
    for t in sorted(seed_tables - table_set):
        problems.append(f"Seed dung bang khong co trong schema: {t}")

    views_sql = strip_comments(read("04_views.sql"))
    views = re.findall(r"CREATE OR ALTER VIEW dbo\.(\w+)", views_sql)
    procs_sql = strip_comments(read("05_procedures.sql"))
    procs = re.findall(r"CREATE OR ALTER PROCEDURE dbo\.(\w+)", procs_sql)
    trg_sql = strip_comments(read("06_triggers.sql"))
    triggers = re.findall(r"CREATE OR ALTER TRIGGER dbo\.(\w+)", trg_sql)
    idx_sql = strip_comments(read("03_indexes.sql"))
    indexes = re.findall(r"CREATE (?:UNIQUE )?NONCLUSTERED INDEX (\w+)", idx_sql)

    known_objects = table_set | set(views) | set(procs) | set(triggers)
    for fname in ["04_views.sql", "05_procedures.sql", "06_triggers.sql",
                  "07_queries_reports.sql", "08_tests.sql"]:
        sql = strip_comments(read(fname))
        refs = set(re.findall(r"\bdbo\.(\w+)", sql))
        for r in sorted(refs - known_objects):
            problems.append(f"{fname}: tham chieu dbo.{r} chua duoc dinh nghia")

    # Can bang BEGIN/END cho file co logic (bo qua BEGIN TRANSACTION mot minh:
    # dem cap BEGIN ... END sau khi loai 'BEGIN TRANSACTION' va 'BEGIN TRY')
    for fname in ["05_procedures.sql", "06_triggers.sql", "08_tests.sql"]:
        sql = strip_comments(read(fname))
        begins = len(re.findall(r"\bBEGIN\b(?!\s+TRANSACTION)", sql))
        ends = len(re.findall(r"\bEND\b", sql))
        cases = len(re.findall(r"\bCASE\b", sql))
        # Moi bieu thuc CASE ... END co 1 END nhung khong co BEGIN -> tru di.
        # END TRY / END CATCH cung la END; BEGIN TRY/CATCH dem trong BEGIN.
        if begins != ends - cases:
            problems.append(
                f"{fname}: lech BEGIN ({begins}) / END ({ends}) sau khi tru {cases} CASE...END")
        bt = len(re.findall(r"BEGIN TRY", sql))
        et = len(re.findall(r"END TRY", sql))
        bc = len(re.findall(r"BEGIN CATCH", sql))
        ec = len(re.findall(r"END CATCH", sql))
        if bt != et or bc != ec:
            problems.append(f"{fname}: lech TRY/CATCH ({bt}/{et}, {bc}/{ec})")

    for fname in ["01_schema.sql", "02_seed.sql", "03_indexes.sql", "04_views.sql",
                  "05_procedures.sql", "06_triggers.sql", "07_queries_reports.sql",
                  "08_tests.sql"]:
        raw = read(fname)
        if "USE MediCoreDB" not in raw:
            problems.append(f"{fname}: thieu USE MediCoreDB")
        if not raw.rstrip().endswith("GO"):
            problems.append(f"{fname}: khong ket thuc bang GO")

    print(f"Tables    : {len(tables)} -> {', '.join(tables)}")
    print(f"Views     : {len(views)} -> {', '.join(views)}")
    print(f"Procedures: {len(procs)} -> {', '.join(procs)}")
    print(f"Triggers  : {len(triggers)} -> {', '.join(triggers)}")
    print(f"Indexes   : {len(indexes)} -> {', '.join(indexes)}")
    print(f"Seed tables touched: {len(seed_tables)}")
    if problems:
        print("\nPROBLEMS:")
        for p in problems:
            print(" -", p)
        return 1
    print("\nOK: Khong phat hien lech ten doi tuong / can bang khoi lenh.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
