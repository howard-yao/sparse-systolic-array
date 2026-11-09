class gemm_test extends uvm_test;

    `uvm_component_utils(gemm_test)

    gemm_env env;
    gemm_sequence seq;

    function new(string name = "gemm_test", uvm_component parent = null);
        super.new(name, parent);

    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        env = gemm_env::type_id::create("env", this);
    endfunction

    task run_phase(uvm_phase phase);
        super.run_phase(phase);

        phase.raise_objection(this);

        seq = gemm_sequence::type_id::create("seq");
        seq.start(env.agent.sequencer);

        phase.drop_objection(this);
    endtask
endclass