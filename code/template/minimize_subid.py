#!/usr/bin/env python
import os
import sys
import csv
subject = sys.argv[-1]

# new subject label is site + sid + scanner(can be empty)
parts = subject.split("_")
site = parts[0]
sid = parts[3][3:]
# scanner info for TJNU
suffix = None
if site == "TJNU":
    scanner_file = os.path.join(os.getenv("PROJECT_ROOT"), "sourcedata", "tjnu-scanner.csv")
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
