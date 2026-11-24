module extend (
    input  logic [23:0] instr,
    input  logic [1:0]  immsrc,
    output logic [31:0] extimm
);
    always_comb begin
        case (immsrc)
            2'b00:   extimm = {24'b0, instr[7:0]};                   // Data-processing
            2'b01:   extimm = {20'b0, instr[11:0]};                  // LDR / STR
            2'b10:   extimm = {{6{instr[23]}}, instr[23:0], 2'b00};  // Branch
            default: extimm = 32'b0;
        endcase
    end
endmodule