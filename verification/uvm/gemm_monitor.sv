class gemm_monitor extends uvm_monitor;
    `uvm_component_utils(gemm_monitor)

    virtual systolic_if vif;

    // Capture DUT inputs and outputs into a systolic_sample.
    // Publish each sample to the scoreboard for independent verification.
    uvm_analysis_port #(systolic_sample) ap;

    function new (string name = "gemm_monitor", uvm_component parent = null);
        super.new(name, parent);
        // Create a new analysis port, with name "ap" and parent = this, just like this "new" definition!
        ap = new("ap", this);
    endfunction

    function void build_phase (uvm_phase phase);
        super.build_phase(phase);

        if(!uvm_config_db#(virtual systolic_if)::get(this, "", "vif", vif)) begin
            `uvm_fatal("VIF", "Cannot find systolic interface")
        end
    endfunction

    task run_phase (uvm_phase phase);
        // Capture vif inputs with systolic sample
        systolic_sample sample;

        forever begin
            @(posedge vif.clk);
            sample = systolic_sample::type_id::create("sample");

            sample.rst = vif.rst;
            sample.step = vif.step;
            sample.clear_acc = vif.clear_acc;
            sample.sparse_en = vif.sparse_en;

            sample.a_left = vif.a_left;
            sample.a_valid_left = vif.a_valid_left;
            sample.b_top = vif.b_top;
            sample.b_valid_top = vif.b_valid_top;

            @(negedge vif.clk);
            sample.acc_out = vif.acc_out;

            ap.write(sample);
        end
    endtask



endclass