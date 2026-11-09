`timescale 1ns/1ps

interface systolic_if(input logic clk);

    logic rst;
    logic step;
    logic clear_acc;
    logic sparse_en;

    logic signed [31:0] a_left[2];
    logic [7:0] a_valid_left[2];

    logic signed [31:0] b_top[2];
    logic [7:0] b_valid_top[2];

    logic signed [31:0] acc_out [2][2];
endinterface