############################################################
## This file is generated automatically by Vitis HLS.
## Please DO NOT edit it.
## Copyright 1986-2022 Xilinx, Inc. All Rights Reserved.
############################################################
set_directive_top -name matrix_mult "matrix_mult"
set_directive_pipeline -II 2 "matrix_mult/Row"
set_directive_pipeline -II 2 "matrix_mult/Col"
set_directive_unroll -factor 4 "matrix_mult/Col"
set_directive_pipeline -II 2 "matrix_mult/Product"
set_directive_unroll -factor 4 "matrix_mult/Product"
set_directive_array_partition -type complete -factor 8 -dim 2 "matrix_mult" a
set_directive_array_partition -type complete -factor 8 -dim 1 "matrix_mult" b
set_directive_array_partition -type complete -factor 8 -dim 2 "matrix_mult" prod
set_directive_dataflow "matrix_mult/Row"
set_directive_expression_balance "matrix_mult/Row"
