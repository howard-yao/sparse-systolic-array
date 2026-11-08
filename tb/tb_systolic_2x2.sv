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
typedef logic signed [7:0] matrix_t [2][2];
matrix_t A, B;

task automatic run_gemm(
    input matrix_t mat_a,
    input matrix_t mat_b,
    input logic sparse_mode
);
    int signed expected;

    @(negedge clk);
    rst = 1;
    step = 0;
    clear_acc = 0;
    sparse_en = sparse_mode;

    @(posedge clk);

    @(negedge clk);
        step = 1;
        rst = 0;

    for(int t = 0; t < 4; t++) begin

        for(int r = 0; r < 2; r++) begin
            if(t>=r && t-r<2) begin
                a_left[r] = mat_a[r][t-r];
                a_valid_left[r] = 1;
            end
            else begin
                a_left[r] = '0;
                a_valid_left[r] = 0;
            end

            if(t>=r && t-r<2) begin
                b_top[r] = mat_b[t-r][r];
                b_valid_top[r] = 1;
            end
            else begin
                b_top[r] = '0;
                b_valid_top[r] = 0;
            end
        end

        @(posedge clk);
        @(negedge clk);

        // Reference model
        for(int r = 0; r < 2; r++) begin
            for(int c = 0; c < 2; c++) begin
                expected = 0;
                for(int k = 0; k < 2; k++) begin
                    if(r+c+k<=t) begin
                        expected += mat_a[r][k] * mat_b[k][c];
                    end
                end

                if(expected !== acc_out[r][c]) begin
                    $fatal(1, "Step %d PE [%d] [%d]: expected %d got %d", t, r, c, expected, acc_out[r][c]);
                end
            end
        end
    end

    $display("GEMM passed! With sparse mode:%d", sparse_mode);
endtask

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

    // Stall the entire systolic array
    step = 0;

    a_left[0] = 9;
    a_left[1] = 11;
    b_top[0] = 13;
    b_top[1] = 17;

    a_valid_left[0] = 1;
    a_valid_left[1] = 1;
    b_valid_top[0] = 1;
    b_valid_top[1] = 1;

    @(posedge clk);
    @(negedge clk);

    if (acc_out[0][0] !== 19 ||
    acc_out[0][1] !== 6  ||
    acc_out[1][0] !== 15 ||
    acc_out[1][1] !== 0) begin

    $fatal(1, "Global stall failed: accumulator changed!");
    end

    $display("Global stall passed!");

    // Step 3: Continue matrix multiplication
    step = 1;
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

    A = '{'{1, 2}, '{3, 4}};
    B = '{'{5, 6}, '{7, 8}};

    run_gemm(A, B, 0);

    A = '{'{1, 0}, '{3, 4}};
    B = '{'{5, 6}, '{7, 0}};

    run_gemm(A, B, 1);

    A = '{'{-1, 2}, '{3, -4}};
    B = '{'{5, -6}, '{-7, 8}};

    run_gemm(A, B, 0);
    run_gemm(A, B, 1);

    // Randomized Test

    for(int test_id = 0; test_id<100; test_id++) begin

        for(int r = 0; r < 2; r++) begin
            for(int c = 0; c < 2; c++) begin
                if($urandom_range(0, 3) == 0) begin
                    A[r][c] = 0;
                end
                else begin
                    A[r][c] = 8'($urandom);
                end

                if($urandom_range(0, 3) == 0) begin
                    B[r][c] = 0;
                end
                else begin
                    B[r][c] = 8'($urandom);
                end
            end
        end

        run_gemm(A, B, 0);
        run_gemm(A, B, 1);
    end

    $display("ALL TESTS PASSED!");

    $finish;

end

endmodule

`default_nettype wire
