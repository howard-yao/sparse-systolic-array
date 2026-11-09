class gemm_sequence extends uvm_sequence #(gemm_item);

    `uvm_object_utils(gemm_sequence)

    function new(string name = "gemm_sequence");
        super.new(name);
    endfunction

    task body();
        gemm_item req;

        repeat (100) begin
            req = gemm_item::type_id::create("req");

            start_item(req);

            if(!req.randomize()) begin
                `uvm_fatal("RAND", "GEMM randomization failed")
            end

            finish_item(req);

        end
    endtask

endclass
