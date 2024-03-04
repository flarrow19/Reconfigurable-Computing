#ifndef __MATRIXMUL_H__
#define __MATRIXMUL_H__

#include <ap_int.h>
#include <cmath>
using namespace std;

#define IN_A_ROWS 16
#define IN_A_COLS 16
#define IN_B_ROWS 16
#define IN_B_COLS 16

typedef ap_uint<8> mat_a;
typedef ap_uint<8> mat_b;
typedef ap_uint<32> mat_prod;

// Prototype of top level function for C-synthesis
void matrix_mult(
      mat_a a[IN_A_ROWS][IN_A_COLS],
      mat_b b[IN_B_ROWS][IN_B_COLS],
      mat_prod prod[IN_A_ROWS][IN_B_COLS]);

#endif // __MATRIXMUL_H__ not defined

