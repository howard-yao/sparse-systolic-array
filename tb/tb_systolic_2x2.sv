`timescale 1ns/1ps
`default_nettype none


module tb_systolic_2x2;

logic clk = 0;
always #5 clk <= ~clk;

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

//Reset:

initial begin
    // iterate over the index
    foreach (a_left[i]) begin
        a_left[i] = '0;
        a_valid_left[i] = 0;
    end

    foreach (b_top[i]) begin
        b_top[i] = '0;
        b_valid_top[i] = 0;
    end

    @(posedge clk);
    #1;

    @(negedge clk);
    rst = 0;

    // First simple test
    step = 1;
    
    a_left[0] = 1;
    a_valid_left[0] = 1;
    a_left[1] = 0;
    a_valid_left[1] = 0;


    b_top[0] = 5;
    b_valid_top[0] = 1;
    b_top[1] = 0;
    b_valid_top[1] = 0;

    // Expected 1x5 = 5 at the top left PE
    // 0 for rest of the PEs

    @(posedge clk);

    @(negedge clk);
    if(acc_out[0][0] !== 5) begin
        $fatal(1, "PE00 failed: expected 5, got %0d", acc_out[0][0]);
    end
    if(acc_out[0][1] !== 0) begin
        $fatal(1, "PE01 failed: expected 0, got %0d", acc_out[0][1]);
    end
    if(acc_out[1][0] !== 0) begin
        $fatal(1, "PE10 failed: expected 0, got %0d", acc_out[1][0]);
    end
    if(acc_out[1][1] !== 0) begin
        $fatal(1, "PE11 failed: expected 0, got %0d", acc_out[1][1]);
    end

    $display("Step 1 passed!");

    // Step 2 test with inter matrix forwarding
    a_left[0] = 2;
    a_left[1] = 3;
    b_top[0] = 7;
    b_top[1] = 6;

    b_valid_top[1] = 1;
    a_valid_left[1] = 1;

    @(posedge clk);
    @(negedge clk);
    if(acc_out[0][0] !== 19) begin
        $fatal(1, "PE00 failed: expected 19, got %0d", acc_out[0][0]);
    end
    if(acc_out[0][1] !== 6) begin
        $fatal(1, "PE01 failed: expected 6, got %0d", acc_out[0][1]);
    end
    if(acc_out[1][0] !== 15) begin
        $fatal(1, "PE10 failed: expected 15, got %0d", acc_out[1][0]);
    end
    if(acc_out[1][1] !== 0) begin
        $fatal(1, "PE11 failed: expected 0, got %0d", acc_out[1][1]);
    end

    $display("Step 2 passed!");

    // Step 3: Continue matrix multiplication
    a_left[0] = 0;
    a_valid_left[0] = 0;

    a_left[1] = 4;
    a_valid_left[1] = 1;

    b_top[0] = 0;
    b_valid_top[0] = 0;

    b_top[1] = 8;
    b_valid_top[1] = 1;

    @(posedge clk);
    @(negedge clk);

    if (acc_out[0][0] !== 19 ||
    acc_out[0][1] !== 22 ||
    acc_out[1][0] !== 43 ||
    acc_out[1][1] !== 18) begin

    $fatal(1, "Step 3 failed: ACC=[[%0d,%0d],[%0d,%0d]]",
        acc_out[0][0],
        acc_out[0][1],
        acc_out[1][0],
        acc_out[1][1]
    );
    end

    $display("Step 3 passed!");

    // Step 4: Drain the pipeline
    a_left[0] = '0;
    a_left[1] = '0;
    b_top[0]  = '0;
    b_top[1]  = '0;

    a_valid_left[0] = 0;
    a_valid_left[1] = 0;
    b_valid_top[0] = 0;
    b_valid_top[1] = 0;

    @(posedge clk);
    @(negedge clk);

    if (acc_out[0][0] !== 19 ||
        acc_out[0][1] !== 22 ||
        acc_out[1][0] !== 43 ||
        acc_out[1][1] !== 50) begin

        $fatal(1,
            "Step 4 failed: ACC=[[%0d,%0d],[%0d,%0d]]",
            acc_out[0][0],
            acc_out[0][1],
            acc_out[1][0],
            acc_out[1][1]
        );
    end

    $display("Step 4 passed! Full 2x2 GEMM completed.");

    $finish;

end

endmodule

`default_nettype wire
