class gemm_agent extends uvm_agent;
    `uvm_component_utils(gemm_agent)

    uvm_sequencer #(gemm_item) sequencer;
    gemm_driver driver;
    gemm_monitor monitor;

    function new(string name = "gemm_agent", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        sequencer = uvm_sequencer#(gemm_item)::type_id::create("sequencer", this);
        driver = gemm_driver::type_id::create("driver", this);
        monitor = gemm_monitor::type_id::create("monitor", this);
    endfunction

    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);

        driver.seq_item_port.connect(sequencer.seq_item_export);
    endfunction

endclass