############################################################
## This file is generated automatically by Vitis HLS.
## Please DO NOT edit it.
## Copyright 1986-2022 Xilinx, Inc. All Rights Reserved.
############################################################
set_directive_top -name matrix_mult "matrix_mult"
set_directive_array_partition -dim 1 -factor 8 -type complete "matrix_mult" prod
set_directive_array_partition -dim 2 -factor 8 -type complete "matrix_mult" prod
