module imem (
    input  logic [31:0] addr,
    output logic [31:0] instr
);
    logic [31:0] RAM [63:0];

    assign instr = RAM[addr[31:2]];
endmodule