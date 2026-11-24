module arm_single_cycle (
    input  logic        clk,
    input  logic        reset,
    output logic [31:0] pc,
    output logic [31:0] instr,
    output logic [31:0] aluresult,
    output logic [31:0] writedata,
    output logic        memwrite
);
    logic [31:0] pcnext, pcplus4, pcplus8, extimm, srca, srcb, shifted, readdata, result;
    logic [3:0]  ra1, ra2, aluflags;
    logic [2:0]  alucontrol;
    logic [1:0]  regsrc, immsrc;
    logic        regwrite, alusrc, memtoreg, pcsrc;

    // 1. Khối điều khiển
    controller ctrl (
        .clk(clk), .reset(reset), .instr(instr[31:12]), .aluflags(aluflags),
        .regsrc(regsrc), .immsrc(immsrc), .regwrite(regwrite), .alusrc(alusrc),
        .alucontrol(alucontrol), .memwrite(memwrite), .memtoreg(memtoreg), .pcsrc(pcsrc)
    );

    // 2. Mạch cập nhật PC
    assign pcnext = pcsrc ? result : pcplus4;
    pc_reg pcreg  (.clk(clk), .reset(reset), .d(pcnext), .q(pc));
    adder  add_pc4(.a(pc), .b(32'd4), .y(pcplus4));
    adder  add_pc8(.a(pcplus4), .b(32'd4), .y(pcplus8));

    // 3. Bộ nhớ lệnh
    imem imem_unit (.addr(pc), .instr(instr));

    // 4. Tập thanh ghi
    assign ra1 = regsrc[0] ? 4'd15 : instr[19:16];
    assign ra2 = regsrc[1] ? instr[15:12] : instr[3:0];
    regfile rf (
        .clk(clk), .reset(reset), .we3(regwrite),
        .ra1(ra1), .ra2(ra2), .wa3(instr[15:12]),
        .wd3(result), .r15(pcplus8), .rd1(srca), .rd2(writedata)
    );

    // 5. Khối dịch bit (LSL, LSR, ASR) & Mở rộng hằng số
    shifter sh_unit (.datain(writedata), .shamt5(instr[11:7]), .sh(instr[6:5]), .dataout(shifted));
    extend ext (.instr(instr[23:0]), .immsrc(immsrc), .extimm(extimm));

    // 6. Khối tính toán ALU
    assign srcb = alusrc ? extimm : shifted;
    alu alu_unit (.a(srca), .b(srcb), .alucontrol(alucontrol), .result(aluresult), .aluflags(aluflags));

    // 7. Bộ nhớ dữ liệu & Chọn kết quả ghi ngược
    dmem dmem_unit (.clk(clk), .we(memwrite), .a(aluresult), .wd(writedata), .rd(readdata));
    assign result = memtoreg ? readdata : aluresult;
endmodule