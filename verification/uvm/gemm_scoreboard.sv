class gemm_scoreboard extends uvm_scoreboard;

    `uvm_component_utils(gemm_scoreboard)

    uvm_analysis_imp #(systolic_sample, gemm_scoreboard) analysis_export;

    bit initialized = 0;

    // Reference model
    logic signed [7:0] ref_a [2][2];
    logic signed [7:0] ref_b [2][2];

    logic ref_a_valid [2][2];
    logic ref_b_valid [2][2];

    logic signed [31:0] ref_acc [2][2];

    int unsigned samples_checked = 0;
    int unsigned pe_checks = 0;
    int unsigned mismatches = 0;

    function new(string name = "gemm_scoreboard", uvm_component parent = null);
        super.new(name, parent);
        analysis_export = new("analysis_export", this);
    endfunction

    function void write(systolic_sample sample);

        logic signed [7:0] next_a [2][2];
        logic signed [7:0] next_b [2][2];
        logic next_a_valid [2][2];
        logic next_b_valid [2][2];

        logic signed [31:0] next_acc [2][2];

        if(sample.rst) begin
            initialized = 1;
        end

        if (!initialized) begin
            return;
        end

        samples_checked++;

        if(sample.rst) begin
            for (int r = 0; r < 2; r++) begin
                for(int c = 0; c < 2; c++) begin
                    ref_a[r][c] = '0;
                    ref_b[r][c] = '0;
                    ref_a_valid[r][c] = 0;
                    ref_b_valid[r][c] = 0;

                    ref_acc[r][c] = '0;
                end
            end
        end
        else begin
            for (int r = 0; r < 2; r++) begin
                for(int c = 0; c < 2; c++) begin
                    logic signed [7:0] a_in, b_in;
                    logic a_valid, b_valid;

                    if (c==0) begin
                        a_in = sample.a_left[r];
                        a_valid = sample.a_valid_left[r];
                    end
                    else begin
                        a_in = ref_a[r][c-1];
                        a_valid = ref_a_valid[r][c-1];
                    end

                    if(r==0) begin
                        b_in = sample.b_top[c];
                        b_valid = sample.b_valid_top[c];
                    end
                    else begin
                        b_in = ref_b[r-1][c];
                        b_valid = ref_b_valid[r-1][c];
                    end


                    next_a[r][c] = ref_a[r][c];
                    next_b[r][c] = ref_b[r][c];

                    next_a_valid[r][c] = ref_a_valid[r][c];
                    next_b_valid[r][c] = ref_b_valid[r][c];

                    next_acc[r][c] = ref_acc[r][c];

                    if(sample.step) begin
                        next_a[r][c] = a_in;
                        next_b[r][c] = b_in;

                        next_a_valid[r][c] = a_valid;
                        next_b_valid[r][c] = b_valid;
                    end

                    if(sample.clear_acc) begin
                        next_acc[r][c] = '0;
                    end
                    else if (sample.step && a_valid && b_valid) begin
                        next_acc[r][c] = ref_acc[r][c] + int'(a_in) * int'(b_in);
                    end
                end
            end

            ref_a = next_a;
            ref_b = next_b;
            ref_a_valid = next_a_valid;
            ref_b_valid = next_b_valid;
            ref_acc = next_acc;
        end

        for(int r = 0; r < 2; r++) begin
            for(int c = 0; c < 2; c++) begin

                pe_checks++;
                if(ref_acc[r][c] !== sample.acc_out[r][c]) begin
                    mismatches++;
                    `uvm_error("MISMATCH", $sformatf("PE[%d][%d]: expected = %d, actual = %d", r, c, ref_acc[r][c], sample.acc_out[r][c]))
                end
            end
        end
    endfunction

    function void report_phase(uvm_phase phase);
        super.report_phase(phase);

        `uvm_info("GEMM_SUMMARY",
            $sformatf(
                "Samples=%0d, PE checks=%0d, mismatches=%0d",
                samples_checked, pe_checks, mismatches
            ), UVM_NONE)

        if (pe_checks == 0)
            `uvm_error("NO_CHECKS", "Scoreboard performed no checks")
    endfunction
endclass