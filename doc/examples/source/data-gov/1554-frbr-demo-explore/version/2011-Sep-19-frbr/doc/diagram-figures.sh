#!/bin/bash

for compare in compare-events-*.rdf; do vsr2grf.sh rdf graffle -w $compare; done
