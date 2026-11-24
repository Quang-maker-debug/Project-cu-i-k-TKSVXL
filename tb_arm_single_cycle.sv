`timescale 1ns / 1ps

module tb_arm_single_cycle();
    logic        clk, reset, memwrite;
    logic [31:0] pc, instr, aluresult, writedata;

    arm_single_cycle dut (
        .clk(clk), .reset(reset), .pc(pc), .instr(instr),
        .aluresult(aluresult), .writedata(writedata), .memwrite(memwrite)
    );

    // Nạp trực tiếp chương trình vào imem
    initial begin
        dut.imem_unit.RAM[0] = 32'hE3A00004; // MOV R0, #4
        dut.imem_unit.RAM[1] = 32'hE2801008; // ADD R1, R0, #8      -> R1 = 12
        dut.imem_unit.RAM[2] = 32'hE0412000; // SUB R2, R1, R0      -> R2 = 8
        dut.imem_unit.RAM[3] = 32'hE1A03082; // MOV R3, R2, LSL #1  -> R3 = 16
        dut.imem_unit.RAM[4] = 32'hE5803050; // STR R3, [R0, #80]   -> Mem[84] = 16
        dut.imem_unit.RAM[5] = 32'hE5904050; // LDR R4, [R0, #80]   -> R4 = 16
        dut.imem_unit.RAM[6] = 32'hE1540003; // CMP R4, R3          -> Z = 1
        dut.imem_unit.RAM[7] = 32'h0AFFFFFE; // BEQ HERE            -> Nhảy tại chỗ

        reset = 1; #15; reset = 0;
        #100;
        $stop;
    end

    always begin
        clk = 1; #5; clk = 0; #5;
    end
endmodule