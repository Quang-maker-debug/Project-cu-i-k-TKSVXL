module alu (
    input  logic [31:0] a, b,
    input  logic [2:0]  alucontrol,
    output logic [31:0] result,
    output logic [3:0]  aluflags
);
    logic        neg, zero, carry, overflow;
    logic [31:0] condinvb;
    logic [32:0] sum;

    assign condinvb = alucontrol[0] ? ~b : b;
    assign sum      = a + condinvb + alucontrol[0];

    always_comb begin
        casex (alucontrol)
            3'b00?:  result = sum[31:0]; // ADD, SUB, CMP
            3'b010:  result = a & b;     // AND
            3'b011:  result = a | b;     // ORR
            3'b100:  result = b;         // MOV / Shift
            default: result = 32'b0;
        endcase
    end

    assign neg      = result[31];
    assign zero     = (result == 32'b0);
    assign carry    = ~alucontrol[1] & sum[32];
    assign overflow = ~alucontrol[1] & ~(a[31] ^ b[31] ^ alucontrol[0]) & (a[31] ^ sum[31]);
    assign aluflags = {neg, zero, carry, overflow};
endmodule