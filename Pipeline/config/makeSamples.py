#!/usr/bin/env python3

import os, sys

input_dir = '/path/to/WGS/files' # adjust this to be where the bam file directories are

sampleDir = {}

for dir in os.listdir(input_dir):
    for i in range(0,10):
        bamPath = os.path.join(input_dir, dir, f"v{i}", f'{dir}.bam')
        if os.path.exists(bamPath):
            sampleDir[dir] = bamPath

with open("~/pathSeqSnakemake/config/samples.yaml", "w") as o:
    o.write("samples:\n")
    for sample, path in sampleDir.items():
        o.write(f"  {sample}: {path}\n")
    o.write("\n")