#!/bin/bash
basepath=$(dirname $0)

#preprocess
./$basepath/rat_exvivo_prepro_7texpmri.sh

# ======================
#if [ 1 -eq 0 ]; then
# ======================

#tensor metrics
./$basepath/rat_exvivo_tensorMetrics_7texpmri.sh

#connectome
./$basepath/rat_exvivo_connectome_7texpmri.sh

#QA
./$basepath/rat_exvivo_qa.sh

# ======================
#fi
# ======================