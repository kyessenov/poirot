#!/bin/bash

for i in $*; do
    fdp -Tpng -o $i.png $i.dot
done
