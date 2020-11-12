#!/bin/bash
basepath=$(dirname $0)
#preprocess
./$basepath/mouse_prepro_7texpmri.sh

#tensor metrics
./$basepath/mouse_tensorMetrics_7texpmri.sh

#connectome
./$basepath/mouse_connectome_7texpmri.sh

#QA
./$basepath/mouse_dti_qa.sh
