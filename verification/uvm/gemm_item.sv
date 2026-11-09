class gemm_item extends uvm_sequence_item;

    rand bit signed [7:0] mat_a [2][2];
    rand bit signed [7:0] mat_b [2][2];
    rand bit sparse_mode;

    `uvm_object_utils(gemm_item)

    function new(string name = "gemm_item");
        super.new(name);
    endfunction

endclass