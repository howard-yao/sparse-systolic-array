`timescale 1ns/1ps
`default_nettype none

module tb_mac_pe;
    logic clk = 1'b0;
    always #5 clk = ~clk;

    logic rst = 1'b1;
    logic step = 1'b0;
    logic clear_acc = 1'b0;
    logic signed [7:0] a_in = '0;
    logic signed [7:0] b_in = '0;
    logic a_valid_in = 1'b0;
    logic b_valid_in = 1'b0;

    logic signed [7:0] a_out_dense, b_out_dense;
    logic signed [7:0] a_out_sparse, b_out_sparse;
    logic a_valid_dense, b_valid_dense;
    logic a_valid_sparse, b_valid_sparse;
    logic signed [31:0] acc_dense, acc_sparse;

    // Independent expected state: do not call the DUT's multiplier!
    int signed expected_acc = 0;
    logic signed [7:0] expected_a = '0;
    logic signed [7:0] expected_b = '0;
    logic expected_av = 1'b0;
    logic expected_bv = 1'b0;
    int unsigned checked = 0;

    mac_pe dense_dut (
        .clk(clk), .rst(rst), .step(step), .clear_acc(clear_acc), .sparse_en(1'b0),
        .a_in(a_in), .b_in(b_in),
        .a_valid_in(a_valid_in), .b_valid_in(b_valid_in),
        .a_out(a_out_dense), .b_out(b_out_dense),
        .a_valid_out(a_valid_dense), .b_valid_out(b_valid_dense),
        .acc_out(acc_dense)
    );

    mac_pe sparse_dut (
        .clk(clk), .rst(rst), .step(step), .clear_acc(clear_acc), .sparse_en(1'b1),
        .a_in(a_in), .b_in(b_in),
        .a_valid_in(a_valid_in), .b_valid_in(b_valid_in),
        .a_out(a_out_sparse), .b_out(b_out_sparse),
        .a_valid_out(a_valid_sparse), .b_valid_out(b_valid_sparse),
        .acc_out(acc_sparse)
    );

    initial begin
        if ($test$plusargs("trace")) begin
            $dumpfile("build/pe_wave.vcd");
            $dumpvars(0, tb_mac_pe);
        end
    end

    task automatic tick(
        input logic rst_i,
        input logic clear_i,
        input logic step_i,
        input logic av_i,
        input logic bv_i,
        input logic signed [7:0] a_i,
        input logic signed [7:0] b_i
    );
        @(negedge clk);
        rst        = rst_i;
        clear_acc  = clear_i;
        step       = step_i;
        a_valid_in = av_i;
        b_valid_in = bv_i;
        a_in       = a_i;
        b_in       = b_i;

        // Reference update models the rising edge about to happen.
        if (rst_i) begin
            expected_acc = 0;
            expected_a = '0;
            expected_b = '0;
            expected_av = 1'b0;
            expected_bv = 1'b0;
        end else begin
            if (step_i) begin
                expected_a = a_i;
                expected_b = b_i;
                expected_av = av_i;
                expected_bv = bv_i;
            end
            if (clear_i) begin
                expected_acc = 0;
            end else if (step_i && av_i && bv_i) begin
                expected_acc = expected_acc + int'(a_i) * int'(b_i);
            end
        end

        @(posedge clk);
        #1; // Sample after nonblocking assignments settle.
        if (acc_dense !== expected_acc || acc_sparse !== expected_acc)
            $fatal(1, "ACC mismatch at case %0d: dense=%0d sparse=%0d expected=%0d",
                   checked, acc_dense, acc_sparse, expected_acc);

        if (a_out_dense !== expected_a || b_out_dense !== expected_b ||
            a_valid_dense !== expected_av || b_valid_dense !== expected_bv)
            $fatal(1, "Dense forwarding mismatch at case %0d", checked);

        if (a_out_sparse !== expected_a || b_out_sparse !== expected_b ||
            a_valid_sparse !== expected_av || b_valid_sparse !== expected_bv)
            $fatal(1, "Sparse forwarding mismatch at case %0d", checked);

        checked++;
    endtask

    initial begin : stimulus
        logic rst_i, clear_i, step_i, av_i, bv_i;
        logic signed [7:0] a_i, b_i;

        // Directed corner cases: reset, clear, signed arithmetic, zero,
        // invalid operands, stall, min/max INT8, and reset while active.
        tick(1, 0, 0, 0, 0,    0,    0);
        tick(0, 1, 0, 0, 0,    0,    0);
        tick(0, 0, 1, 1, 1,    3,    4);
        tick(0, 0, 1, 1, 1,   -5,    3);
        tick(0, 0, 1, 1, 1,    0,  100);
        tick(0, 0, 1, 1, 1,   65,    0);
        tick(0, 0, 1, 1, 0,   22,    8);
        tick(0, 0, 0, 1, 1,  100,  100);
        tick(0, 0, 1, 1, 1, -128,  127);
        tick(0, 0, 1, 1, 1, -128, -128);
        tick(0, 1, 1, 1, 1,   42,   42);
        tick(1, 0, 1, 1, 1,  100,  100);

        // Reproducible randomized regression, with extra zero-heavy cases.
        for (int n = 0; n < 1000; n++) begin
            rst_i   = ($urandom_range(0, 199) == 0);
            clear_i = ($urandom_range(0, 29) == 0);
            step_i  = ($urandom_range(0, 7) != 0);
            av_i    = ($urandom_range(0, 7) != 0);
            bv_i    = ($urandom_range(0, 7) != 0);
            a_i     = 8'($urandom);
            b_i     = 8'($urandom);
            if ($urandom_range(0, 3) == 0) a_i = '0;
            if ($urandom_range(0, 3) == 0) b_i = '0;
            tick(rst_i, clear_i, step_i, av_i, bv_i, a_i, b_i);
        end

        $display("ALL PE TESTS PASSED: %0d cycles checked", checked);
        $finish;
    end
endmodule
`default_nettype wire
