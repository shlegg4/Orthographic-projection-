//
//  add_arrays.metal
//  Project I.C.A.R.U.S
//
//  Created by Samuel Legg on 04/12/2021.
//

#include <metal_stdlib>
using namespace metal;

kernel void add_arrays(device const float* inA,
                       device const float* inB,
                       device const float* inC,
                       device float* result,
                       uint index [[thread_position_in_grid]])
{
    // the for-loop is replaced with a collection of threads, each of which
    // calls this function.
    result[index] = inA[index] + inB[index] + inC[index];
}

kernel void multiply_array_by_scalar(device const float* inA,
                                     device const float* inB,
                                     device float* result,
                                     uint index [[thread_position_in_grid]])
{
    
    result[index] = inA[index] * inB[0];
    
}
