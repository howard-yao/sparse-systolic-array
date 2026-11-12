`timescale 1ns/1ps

module tb_uvm_top;

    import uvm_pkg::*;
    import systolic_pkg::*;

    logic clk = 0;
    always #5 clk = ~clk;

    systolic_if sif(clk);

    systolic_2x2 dut (
        .clk          (clk),
        .rst          (sif.rst),
        .step         (sif.step),
        .clear_acc    (sif.clear_acc),
        .sparse_en    (sif.sparse_en),

        .a_left       (sif.a_left),
        .a_valid_left (sif.a_valid_left),

        .b_top        (sif.b_top),
        .b_valid_top  (sif.b_valid_top),

        .acc_out      (sif.acc_out)
    );
    
    initial begin
        sif.rst = 1;
        sif.step = 0;
        sif.clear_acc = 0;
        sif.sparse_en = 0;

        for (int i = 0; i < 2; i++) begin
            sif.a_left[i] = '0;
            sif.b_top[i] = '0;
            sif.a_valid_left[i] = 0;
            sif.b_valid_top[i] = 0;
        end

        uvm_config_db#(virtual systolic_if)::set(null, "uvm_test_top.*", "vif", sif);

        run_test("gemm_test");

    end
endmodule