############################################################
## This file is generated automatically by Vitis HLS.
## Please DO NOT edit it.
## Copyright 1986-2022 Xilinx, Inc. All Rights Reserved.
############################################################
set_directive_top -name matrix_mult "matrix_mult"
set_directive_pipeline -II 1 "matrix_mult/Row"
set_directive_pipeline -II 1 "matrix_mult/Col"
set_directive_unroll -factor 6 "matrix_mult/Col"
set_directive_pipeline -II 1 "matrix_mult/Product"
set_directive_unroll -factor 6 "matrix_mult/Product"
set_directive_array_reshape -dim 1 -type complete "matrix_mult" a
set_directive_array_reshape -dim 2 -type complete "matrix_mult" b
set_directive_array_reshape -dim 0 -type complete "matrix_mult" prod
