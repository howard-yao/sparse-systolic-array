class gemm_driver extends uvm_driver #(gemm_item);

    `uvm_component_utils(gemm_driver)

    virtual systolic_if vif;

    function new(string name = "gemm_driver", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        if(!uvm_config_db#(virtual systolic_if)::get(this, "", "vif", vif)) begin
            `uvm_fatal("VIF", "Cannot find systolic vif")
        end
    endfunction

    task run_phase(uvm_phase phase);
        // init a transaction item
        gemm_item req;

        forever begin
            seq_item_port.get_next_item(req);

            drive_gemm(req);

            // Ackownledge the sequencer the transaction is sent
            seq_item_port.item_done();
        end
    endtask

    task automatic drive_gemm(gemm_item req);
        @(negedge vif.clk);

        vif.rst = 1;
        vif.step = 0;
        vif.clear_acc = 0;
        vif.sparse_en = req.sparse_mode;

        for(int i = 0; i<2; i++) begin
            vif.a_left[i] = '0;
            vif.b_top[i] = '0;
            vif.a_valid_left[i] = 0;
            vif.b_valid_top[i] = 0;
        end

        @(posedge vif.clk);
        @(negedge vif.clk);

        vif.rst = 0;
        vif.step = 1;


        // Assign value from the sequence to the interface, just like what we did in the simple tb

        for (int t = 0; t < 4; t++) begin
            for (int r = 0; r < 2; r++) begin
                if (t>=r && t-r < 2) begin
                    vif.a_left[r] = req.mat_a[r][t-r];
                    vif.a_valid_left[r] = 1;
                end
                else begin
                    vif.a_left[r] = '0;
                    vif.a_valid_left[r] = 0;
                end

                if (t>=r && t-r < 2) begin
                    vif.b_top[r] = req.mat_b[t-r][r];
                    vif.b_valid_top[r] = 1;
                end
                else begin
                    vif.b_top[r] = '0;
                    vif.b_valid_top[r] = 0;
                end
            end

            @(posedge vif.clk);
            @(negedge vif.clk);
        end

        vif.step = 0;

        for(int i = 0; i < 2; i++) begin
            vif.a_left[i] = '0;
            vif.b_top[i] = '0;
            vif.a_valid_left[i] = 0;
            vif.b_valid_top[i] = 0;
        end
    endtask
endclass
