/**********************************************************************************************************************

 *                                           TESTBENCH FOR MATRIX MULTIPLICATION                                     *

***********************************************************************************************************************/


/**********************************************************************************************************************
 
*                                                            CONTENTS                                                  
 
 I.     INTRODUCTION                                                                                  .......  39
 
 II.    HEADER INCLUSIONS AND NAMESPACE DECLARATION                                                   .......  67

 III.   UTILITY FUNCTIONS                                                                             ....... 103

 IV.    MAIN FUNCTION                                                                                 ....... 185

            IV. A. DECLARATION OF MATRICES                                                            ....... 208

            IV. B. INITIALIZATION OF INPUT MATRICES                                                   ....... 221

            IV. C. COPYING DATA  (DESIGN ==> uBLAS MATRICES)                                          ....... 228

            IV. D. MATRIX MULTIPLICATION USING DESIGN                                                 ....... 251

            IV. E. MATRIX MULTIPLICATION USING uBLAS                                                  ....... 267

            IV. F. PRINTING BOTH MATRICES                                                             ....... 273

            IV. G. RESULT COMPARISION                                                                 ....... 295 

 V.     CONCLUSION                                                                                    ....... 318   
 
*                                                                                    
***********************************************************************************************************************/

/**********************************************************************************************************************

 *                                                    INTRODUCTION                                                  *

***********************************************************************************************************************/

/************************************************************************
*   
    This code is a testbench for our design which is doing matrix multi-
    plication of two matrices. For our testbench design we are first 
    randomizing our design matrices with some random numbers. After which
    we are multiplying these two matrices using our design. For our golden
    output, we are going to use uBLAS library in our system. We will first
    define our uBLAS matrices, to ensure both our design matrices and uBLAS
    matrices have smae value we will copy the values of design matrices
    to our uBLAS matrices. We will compute the product of both the matrix
    pairs seperately (using multiplication function defined in our design
    & the function from uBLAS library) seperately.

    We will take a tolerence value of 10^-6 for correctness of our result.
    Comparision of two matrices are done and print statements print if the
    output is correct or not.
*   
************************************************************************/

/**********************************************************************************************************************/


/**********************************************************************************************************************

 *                                       HEADER INCLUSIONS AND NAMESPACE DECLARATION                                 *

***********************************************************************************************************************/

/************************************************************************
*   
    The header inclusions section contain different inclusions needed to 
    set-up the environment for matrix multiplication. Starting with first
    inclusion to provide necessary declarations for multiplication 
    functionality. The other two inclusions related ot ublas library. 
    They provide matrix manipulation along with a streamlined I/O for 
    ublas types. Moving on we have cstdlib and cmath for using float 
    abs value and random number generation.
*

*   
    The namespace is done to simplify the code , which is instead of 
    writing "boost::numeric::ublas" we will simply write "ublas".
*   
************************************************************************/

#include "matrix_mult.h"
#include <boost/numeric/ublas/matrix.hpp> // including uBLAS library
#include <boost/numeric/ublas/io.hpp>
#include <iostream>
#include <cstdlib>  // For rand() and srand()
#include <ctime>    // For time()
#include <cmath>    // For fabs()

namespace ublas = boost::numeric::ublas;

/**********************************************************************************************************************/


/**********************************************************************************************************************

 *                                                      UTILITY FUNCTIONS                                           *

***********************************************************************************************************************/

/************************************************************************
*   
    This section of the code deals with two parts

    A) Generating random values for our matrices:
    We are generating random values between 0 to 100. The func-
    tion name is initialize design which should not give anything in
    return (i.e. void). The function should take matrix of type mat_a or
    mat_b, any of the two, later it will be called on both A and B. 
*  

* 
    Since rand() will generate an int value between 0 to RAND_MAX, where
    RAND_MAX is defined in '<cstdlib>'. We are then casting this integer
    number into floating point as out matrices are defined as float in 
    "matrix_mult.h"
*

*
    We are normalizing the random value by dividing it with RAND_MAX, 
    this way our random which can return values between 0 to 1. After
    that denominator can be multiplied by any number depending on what
    range of numbers we wnat to generate, in our case we are generating
    numbers between 0 to 100.
*

*
    B) Defining a function to compare two matrices:
    We defined the function return type to bool just to see if the func-
    tion runs correctly or not otherwise we wouldn't know. Okay, so the 
    function takes two parameters golden matrix from uBLAS and 
    mat_prod from our design.
*

*
    We are goiing with a tolerence value of 10^-6 for now, if it comes 
    to be more relaxed it can be more strict in future.
    Then using for loops and a if condition we are checking if the 
    absolute value of golden and prod matrix is greater than or less
    than tolerence. If greater than tolerence, we are going to print 
    mismatch elements along with Expected Golden matrix and the matrix
    we got after computation in our design. If the absolute value is 
    less than tolerence value we will not print anything and return with
    true. Also these return values can be used inside if condition 
    when we use if condition during comparision stage and print results
    directly.
*
************************************************************************/

//Initializing Design
void init_design(mat_a matrix[IN_A_ROWS][IN_A_COLS]) {
    for (int i = 0; i < IN_A_ROWS; ++i) {
        for (int j = 0; j < IN_A_COLS; ++j) {
            matrix[i][j] = static_cast<float>(rand()) / RAND_MAX * 100.0f;  // Random floats between 0 and 100
        }
    }
}

// Function to compare matrices
bool compare_matrices(const ublas::matrix<float>& golden, const mat_prod prod[IN_A_ROWS][IN_B_COLS]) {
    const float tolerance = 1e-6f;

    for (unsigned i = 0; i < golden.size1(); ++i) {
        for (unsigned j = 0; j < golden.size2(); ++j) {
            if (std::fabs(golden(i, j) - prod[i][j]) > tolerance) {
                std::cout << "Mismatch at [" << i << "][" << j << "] - Expected: " << golden(i, j) << ", Got: " << prod[i][j] << "\n";
                return false;  // Indicates failure
            }
        }
    }
    return true;  // Indicates success
}

/**********************************************************************************************************************/


/**********************************************************************************************************************

 *                                                         MAIN FUNCTION                                            *

***********************************************************************************************************************/

/************************************************************************
*   
    We are entering the main function now which will have different sub-
    sections. In short we will first create instance of our matrices from
    the design and from our uBLAS library. Following that we will 
    initialize our design matrices and then copy values from our design 
    matrices to uBLAS matrices . Then we compute product for both using 
    design and using boost uBLAS seperately. After which we compare both
    and print them.
* 
************************************************************************/

int main() {

    // Seed the random number generator derived from current time 
    srand(static_cast<unsigned int>(time(nullptr)));  

    /****************************************************
     *            DECLARATION OF MATRICES               *
    ****************************************************/

    // Design Matrix Declaration 
    mat_a a[IN_A_ROWS][IN_A_COLS];
    mat_b b[IN_B_ROWS][IN_B_COLS];
    
    // uBLAS MAtrix Declaration
    ublas::matrix<float> ublas_a(IN_A_ROWS, IN_A_COLS);
    ublas::matrix<float> ublas_b(IN_B_ROWS, IN_B_COLS);


    /****************************************************
     *        INITIALIZATION OF INPUT MATRICES          *
    ****************************************************/

    init_design(a);
    init_design(b);

    /****************************************************
     *   COPYING DATA  (DESIGN ==> uBLAS MATRICES)      *
    ****************************************************/
        /********************************
         * We are copying the design 
           matrices which are already 
           randomized to our uBLAS 
           matrices to ensure both have 
           same matrices before perfor-
           ming multiplication.
        *********************************/  

    for (int i = 0; i < IN_A_ROWS; ++i) {
        for (int j = 0; j < IN_A_COLS; ++j) {
            ublas_a(i, j) = a[i][j];
        }
    }
    for (int i = 0; i < IN_B_ROWS; ++i) {
        for (int j = 0; j < IN_B_COLS; ++j) {
            ublas_b(i, j) = b[i][j];
        }
    }

    /****************************************************
     *        MATRIX MULTIPLICATION USING DESIGN        *
    ****************************************************/

        /********************************
         * Initializing product matrix
         to 0.

        *  Calling "matrix_mult" from
            our design to perform
            multiplication.
        *********************************/    

    mat_prod prod[IN_A_ROWS][IN_B_COLS] = {0};
    matrix_mult(a, b, prod);

    /****************************************************
     *        MATRIX MULTIPLICATION USING uBLAS         *
    ****************************************************/

    ublas::matrix<float> golden_out = ublas::prod(ublas_a, ublas_b);

    /****************************************************
     *              PRINTING BOTH MATRICES              *
    ****************************************************/

    // Printing Computed Matrix from our Design
    std::cout << "Computed Matrix:\n";
    for (int i = 0; i < IN_A_ROWS; ++i) {
        for (int j = 0; j < IN_B_COLS; ++j) {
            std::cout << prod[i][j] << " ";
        }
        std::cout << "\n";
    }

    // Print the golden matrix (from Boost uBLAS)
    std::cout << "Golden Output:\n";
    for (unsigned i = 0; i < golden_out.size1(); ++i) {
        for (unsigned j = 0; j < golden_out.size2(); ++j) {
            std::cout << golden_out(i, j) << " ";
        }
        std::cout << "\n";
    }

    /****************************************************
     *                RESULT COMPARISION                *
    ****************************************************/

         /*********************************
        *  Calling compare_matrices 
           function from the utility
           section to perform comparision.
        **********************************/  

    if (compare_matrices(golden_out, prod)) {
        std::cout << "Test Passed: The design's output matches the golden output.\n";
    } else {
        std::cout << "Test Failed: The design's output does not match the golden output.\n";
        return 1;  // Return a non-zero value to indicate failure
    }

        return 0;
}

/**********************************************************************************************************************/


/**********************************************************************************************************************

 *                                                          CONCLUSION                                              *

***********************************************************************************************************************/

/************************************************************************
*   
    In this testbench, we've put our matrix multiplication design through 
    its paces by comparing its results with those from the trusted Boost 
    uBLAS library. We filled our matrices with random numbers and let both 
    our design and uBLAS do their magic. By using a tiny margin for error 
    in our comparisons, we made sure we're being fair and thorough. Whenever
    our design's results matched up with uBLAS, it was a win, showing that 
    our matrix multiplication is on the right track. 
* 
************************************************************************/

/**********************************************************************************************************************/
