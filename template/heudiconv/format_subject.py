#!/usr/bin/env python3
import os
import sys
import csv
subject = sys.argv[-1]

# new subject label is site + sid + suffix(for scanner, can be empty)
parts = subject.split("_")
site = parts[0]
sid = parts[3][3:]

# prepare scanner suffix
suffix = None
if site == "TJNU":
    # scanner info for TJNU
    scanner_file = os.path.join(os.path.dirname(__file__), "tjnu-scanner.csv")
    with open(scanner_file, newline="") as csvfile:
        reader = csv.DictReader(csvfile)
        for row in reader:
            if row["sid"] == sid:
                suffix = row["suffix"]
                break
    assert suffix is not None, "Cannot find scanner suffix for TJNU subject, which is necessary."
else:
    # currently no need for scanner suffix for other sites than TJNU
    suffix = ""

print(site + sid + suffix)
