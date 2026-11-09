class systolic_sample extends uvm_object;
// We use this for monitor to track the transaction independently from the driver
    `uvm_object_utils(systolic_sample);

    logic rst;
    logic step;
    logic clear_acc;
    logic sparse_en;

    logic signed [7:0] a_left[2];
    logic a_valid_left[2];
    logic signed [7:0] b_top[2];
    logic b_valid_top[2];

    logic signed [31:0] acc_out[2][2];

    function new(string name = "systolic_sample");
        super.new(name);
    endfunction

endclass