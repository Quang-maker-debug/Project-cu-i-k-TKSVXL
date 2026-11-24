module controller (
    input  logic         clk, reset,
    input  logic [31:12] instr,
    input  logic [3:0]   aluflags,
    output logic [1:0]   regsrc, immsrc,
    output logic         regwrite, alusrc,
    output logic [2:0]   alucontrol,
    output logic         memwrite, memtoreg, pcsrc
);
    logic [9:0] controls;
    logic [3:0] flags;
    logic [1:0] flagw;
    logic       branch, aluop, nowrite, regw_raw, regw, memw, pcs, condex;

    // 1. Main Decoder
    always_comb begin
        casex ({instr[27:26], instr[25], instr[20]})
            4'b00_0_?: controls = 10'b0_0_0_1_00_00_1_0; // DP Reg
            4'b00_1_?: controls = 10'b0_0_1_1_00_00_1_0; // DP Imm
            4'b01_?_0: controls = 10'b0_1_1_0_01_10_0_0; // STR
            4'b01_?_1: controls = 10'b0_0_1_1_01_00_0_1; // LDR
            4'b10_?_?: controls = 10'b1_0_1_0_10_01_0_0; // Branch
            default:   controls = 10'b0;
        endcase
    end
    assign {branch, memw, alusrc, regw_raw, immsrc, regsrc, aluop, memtoreg} = controls;

    // 2. ALU Decoder
    always_comb begin
        nowrite = 1'b0;
        if (aluop) begin
            case (instr[24:21])
                4'b0100: alucontrol = 3'b000; // ADD
                4'b0010: alucontrol = 3'b001; // SUB
                4'b0000: alucontrol = 3'b010; // AND
                4'b1100: alucontrol = 3'b011; // ORR
                4'b1101: alucontrol = 3'b100; // MOV / Shift
                4'b1010: begin alucontrol = 3'b001; nowrite = 1'b1; end // CMP
                default: alucontrol = 3'b000;
            endcase
            flagw[1] = instr[20];
            flagw[0] = instr[20] & (alucontrol == 3'b000 | alucontrol == 3'b001);
        end else begin
            alucontrol = 3'b000;
            flagw      = 2'b00;
        end
    end

    assign regw = regw_raw & ~nowrite;
    assign pcs  = ((instr[15:12] == 4'b1111) & regw) | branch;

    // 3. Thanh ghi lưu cờ NZCV
    always_ff @(posedge clk or posedge reset) begin
        if (reset) flags <= 4'b0;
        else begin
            if (flagw[1] & condex) flags[3:2] <= aluflags[3:2];
            if (flagw[0] & condex) flags[1:0] <= aluflags[1:0];
        end
    end

    // 4. Kiểm tra điều kiện Cond
    always_comb begin
        case (instr[31:28])
            4'b0000: condex = flags[2];                    // EQ
            4'b0001: condex = ~flags[2];                   // NE
            4'b1010: condex = (flags[3] == flags[0]);      // GE
            4'b1011: condex = (flags[3] != flags[0]);      // LT
            4'b1100: condex = ~flags[2] & (flags[3] == flags[0]); // GT
            4'b1101: condex = flags[2] | (flags[3] != flags[0]);  // LE
            4'b1110: condex = 1'b1;                        // AL (Always)
            default: condex = 1'b0;
        endcase
    end

    assign regwrite = regw & condex;
    assign memwrite = memw & condex;
    assign pcsrc    = pcs  & condex;
endmodule