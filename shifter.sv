module shifter (
    input  logic [31:0] datain,
    input  logic [4:0]  shamt5,
    input  logic [1:0]  sh,
    output logic [31:0] dataout
);
    always_comb begin
        case (sh)
            2'b00: dataout = datain << shamt5;
            2'b01: dataout = datain >> shamt5;
            2'b10: dataout = $signed(datain) >>> shamt5;
            2'b11: dataout = (datain >> shamt5) | (datain << (32 - shamt5));
        endcase
    end
endmodule