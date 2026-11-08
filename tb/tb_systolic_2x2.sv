`timescale 1ns/1ps
`default_nettype none


module tb_systolic_2x2;

logic clk = 0;
always #5 clk = ~clk;

logic rst = 1;
logic step = 0;
logic clear_acc = 0;
logic sparse_en = 0;

logic signed [7:0] a_left [2];
logic a_valid_left [2];
logic signed [7:0] b_top [2];
logic b_valid_top [2];

logic signed [31:0] acc_out [2][2];

// Kept the same naming
systolic_2x2 dut(
    .*
);

endmodule

`default_nettype wire
