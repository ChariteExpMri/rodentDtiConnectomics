#!/bin/bash
basepath=$(dirname $0)

#preprocess
./$basepath/rat_exvivo_prepro_7texpmri.sh

#tensor metrics
./$basepath/rat_exvivo_tensorMetrics_7texpmri.sh

#connectome
./$basepath/rat_exvivo_connectome_7texpmri.sh

#QA
./$basepath/rat_exvivo_qa.sh

