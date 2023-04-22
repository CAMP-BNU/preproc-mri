#!/usr/bin/env python
import sys
subject = sys.argv[-1]
parts = subject.split("_")
print(parts[0] + parts[3][3:])
