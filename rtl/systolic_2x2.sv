`timescale 1ns/1ps
`default_nettype none

module systolic_2x2(
    input logic clk,
    input logic rst,
    input logic step,
    input logic clear_acc,
    input logic sparse_en,

    // inputs
    input logic signed [7:0] a_left [2],
    input logic a_valid_left[2],
    input logic signed [7:0] b_top [2],
    input logic b_valid_top[2],

    output logic signed [31:0] acc_out [2][2]
);

logic signed [7:0] a_00_to_01;
logic signed [7:0] a_10_to_11;
logic a_valid_00_to_01;
logic a_valid_10_to_11;

logic signed [7:0] b_00_to_10;
logic signed [7:0] b_01_to_11;
logic b_valid_00_to_10;
logic b_valid_01_to_11;

mac_pe pe00(
    .clk(clk),
    .rst(rst),
    .step(step),
    .clear_acc(clear_acc),
    .sparse_en(sparse_en),

    .a_in(a_left[0]),
    .b_in(b_top[0]),

    .a_valid_in(a_valid_left[0]),
    .b_valid_in(b_valid_top[0]),

    .a_out(a_00_to_01),
    .b_out(b_00_to_10),

    .a_valid_out(a_valid_00_to_01),
    .b_valid_out(b_valid_00_to_10),

    .acc_out(acc_out[0][0])
);

endmodule