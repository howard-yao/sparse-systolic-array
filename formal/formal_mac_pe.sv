`default_nettype none

// Formal contract for an 8x8->32-bit output-stationary MAC PE.
// Inputs are arbitrary each cycle except for the initial reset.
module formal_mac_pe(input wire clk);
    (* anyseq *) reg rst;
    (* anyseq *) reg step;
    (* anyseq *) reg clear_acc;
    (* anyseq *) reg sparse_en;
    (* anyseq *) reg signed [7:0] a_in;
    (* anyseq *) reg signed [7:0] b_in;
    (* anyseq *) reg a_valid_in;
    (* anyseq *) reg b_valid_in;

    wire signed [7:0] a_out;
    wire signed [7:0] b_out;
    wire a_valid_out;
    wire b_valid_out;
    wire signed [31:0] acc_out;

    mac_pe #(.DATA_W(8), .ACC_W(32)) dut (
        .clk(clk), .rst(rst), .step(step),
        .clear_acc(clear_acc), .sparse_en(sparse_en),
        .a_in(a_in), .b_in(b_in),
        .a_valid_in(a_valid_in), .b_valid_in(b_valid_in),
        .a_out(a_out), .b_out(b_out),
        .a_valid_out(a_valid_out), .b_valid_out(b_valid_out),
        .acc_out(acc_out)
    );

    function automatic signed [31:0] expected_product;
        input signed [7:0] a;
        input signed [7:0] b;
        reg signed [15:0] p;
        begin
            p = a * b;
            expected_product = {{16{p[15]}}, p};
        end
    endfunction

    // Initialize the proof in reset; arbitrary behavior after that.
    initial assume(rst);

    // $past is only meaningful after one sampled edge.
    reg past_valid = 1'b0;
    always @(posedge clk) begin
        past_valid <= 1'b1;

        if (past_valid) begin
            if ($past(rst)) begin
                assert(a_out == 8'sd0);
                assert(b_out == 8'sd0);
                assert(a_valid_out == 1'b0);
                assert(b_valid_out == 1'b0);
                assert(acc_out == 32'sd0);
            end else begin
                // Forward current cycle inputs when enabled, otherwise hold.
                if ($past(step)) begin
                    assert(a_out == $past(a_in));
                    assert(b_out == $past(b_in));
                    assert(a_valid_out == $past(a_valid_in));
                    assert(b_valid_out == $past(b_valid_in));
                end else begin
                    assert(a_out == $past(a_out));
                    assert(b_out == $past(b_out));
                    assert(a_valid_out == $past(a_valid_out));
                    assert(b_valid_out == $past(b_valid_out));
                end

                // Accumulator priority: reset > clear > enabled MAC > hold.
                // Spec checks mathematical product independent of sparse_en;
                // zero-suppression must not change functional results.
                if ($past(clear_acc)) begin
                    assert(acc_out == 32'sd0);
                end else if ($past(step && a_valid_in && b_valid_in)) begin
                    assert(acc_out == $past(acc_out) +
                           expected_product($past(a_in), $past(b_in)));
                end else begin
                    assert(acc_out == $past(acc_out));
                end
            end
        end

        // Nonvacuity: seek traces exercising all three behaviors.
        cover(past_valid && !rst && step && a_valid_in && b_valid_in
              && a_in != 0 && b_in != 0);
        cover(past_valid && !rst && step && sparse_en
              && a_valid_in && b_valid_in && a_in == 0);
        cover(past_valid && !rst && !step && a_valid_in && b_valid_in);
    end
endmodule
`default_nettype wire
