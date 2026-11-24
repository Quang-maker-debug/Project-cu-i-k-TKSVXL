module pc_reg (
    input  logic        clk,
    input  logic        reset,
    input  logic [31:0] d,
    output logic [31:0] q
);
    always_ff @(posedge clk or posedge reset)
        if (reset) q <= 32'b0;
        else       q <= d;
endmodule