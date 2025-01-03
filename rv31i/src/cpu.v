`include "ProgramCounter.v"
`include "InstructionMemory.v"
`include "RV32I_Decoder.v"
`include "ALU.v"
`include "ManagePC.v"

`include "opcode.v"



module CPU (
    input clk,
    input reset
);

// COUNTER & INSTRUCTION MEMORY
wire [31:0] pc;
reg [31:0] next_pc;

wire [31:0] instruction;

// DATA RAM
// reg [31:0] RAM[0:255]; // RAM with 32-bits x 256
reg [31:0] RAM[0:1023]; // RAM with 32-bits x 1024


/*
// testing
parameter KEYBOARD_ADDRESS = 32'h00000000;
parameter DISPLAY_ADDRESS = 32'h00100000;
task write_keyboard_presses(input [7:0] key, input [7:0] pressed);
    begin
        RAM[KEYBOARD_ADDRESS + key] = pressed;
    end
endtask

task read_display_output(input [7:0] offset, output [7:0] ascii);
    begin
        ascii = RAM[DISPLAY_ADDRESS + offset];
    end
endtask
*/


// REGISTERS
reg [31:0] regs[0:31]; // 31-bit x 32 registers



/* *********************************** */
// PROGRAM COUNTER
ProgramCounter program_counter (
    .clk(clk),
    .reset(reset),

    .next_pc(next_pc),
    .pc(pc)
);



/* *********************************** */
// FETCH
InstructionMemory instr_mem (
    .address(pc),
    .instruction(instruction)
);


/* *********************************** */
// DECODE
wire [6:0] opcode;
wire [2:0] funct3;
wire [6:0] funct7;
wire [31:0] imm;

wire [4:0] rs2;
wire [4:0] rs1;
wire [4:0] rd;

wire [3:0] op;




RV32I_Decoder decoder (
    .instr(instruction),

    .funct3(funct3),
    .funct7(funct7),
    .opcode(opcode),
    .imm(imm),

    .rs2(rs2),
    .rs1(rs1),
    .rd(rd),

    .op(op)
);




/* *********************************** */
// EXECUTE


ManagePC manage_pc (
    .clk(clk),

    .pc(pc),
    .rs1(regs[rs1]),
    .rs2(regs[rs2]),
    .imm(imm),
    .opcode(opcode),

    .next_pc(next_pc),
    .rd(regs[rd])
);



reg [31:0] s_type_adr;
reg [31:0] s_type_data;

// always @* begin
always @(posedge clk or posedge reset) begin
    $display("program_counter = %b, %d", pc, pc);
    $display("instruction: %b", instruction);

    if (reset) begin
        $display("reset");

        s_type_adr <= 32'b0;
        s_type_data <= 32'b0;

    end else begin
        // ALU
        if (op == OP_R_TYPE) begin
            $display("R-type");
            regs[rd] = ALU(1'b1, regs[rs1], regs[rs2], funct3, funct7);
            $display("rd = %b", regs[rd]);

        end else if (op == OP_I_TYPE) begin
            $display("I-type");

            case (opcode) 
                7'b0000011: begin
                    $display("LOAD");

                    case (funct3) 
                        3'b000: begin
                            $display("BYTE");
                            regs[rd] = RAM[regs[rs1] + imm][7:0];
                            $display("rd = %b", regs[rd]);
                        end
                        3'b001: begin
                            $display("HALF");
                            regs[rd] = RAM[regs[rs1] + imm][15:0];
                            $display("rd = %b", regs[rd]);
                        end
                        3'b010: begin
                            $display("WORD");
                            regs[rd] = RAM[regs[rs1] + imm];
                            $display("rd = %b", regs[rd]);
                        end
                    endcase

                end
                7'b0010011: begin
                    $display("ALU");
                    regs[rd] = ALU(1'b1, regs[rs1], imm, funct3, 7'b0);
                    $display("rd = %b", regs[rd]);
                end
            endcase


        end else if (op == OP_S_TYPE) begin
            // TODO: TEST
            $display("S-type");

            s_type_adr = regs[rs1] + imm;
            s_type_data = regs[rs2];

            case (funct3) 
                3'b000: begin
                    $display("BYTE");
                    RAM[regs[rs1] + imm] = regs[rs2];

                    case (s_type_adr[1:0])
                        2'b00: RAM[s_type_adr[31:2]][7:0]       <= s_type_data[7:0];
                        2'b01: RAM[s_type_adr[31:2]][15:8]      <= s_type_data[7:0];
                        2'b10: RAM[s_type_adr[31:2]][23:16]     <= s_type_data[7:0];
                        2'b11: RAM[s_type_adr[31:2]][31:24]     <= s_type_data[7:0];
                    endcase

                end
                3'b001: begin
                    $display("HALF");

                    case (s_type_adr[1])
                        1'b0: RAM[s_type_adr[31:2]][15:0]       <= s_type_data[15:0];
                        1'b1: RAM[s_type_adr[31:2]][31:16]      <= s_type_data[15:0];
                    endcase

                end
                3'b010: begin
                    $display("WORD");

                    RAM[s_type_adr[31:2]]       <= s_type_data;

                end

            endcase
        end else if (op == OP_B_TYPE) begin
            $display("B-type");
        end else if (op == OP_U_TYPE) begin
            $display("U-type");

            case (opcode) 
                7'b0110111: begin // LUI
                    $display("LUI");

                    // TODO: TEST it
                    // regs[rd] = imm >> 12;
                    regs[rd] = imm;
                    $display("rd = %b", regs[rd]);
                end
                7'b0010111: begin // AUIPC
                    $display("AUIPC");

                    // TODO: TEST it
                    // regs[rd] = pc + imm;         
                    $display("rd = %b", regs[rd]);
                end
            endcase

        end else if (op == OP_J_TYPE) begin
            $display("J-type");

            // regs[rd] = pc + 4;
            // $display("pc_reg = %b", pc_reg);

        end else if (op == OP_ECALL_TYPE) begin
            $display("ECALL");

            case (funct3)
                3'b000: begin
                    $display("ECALL PRINT: %b %d", regs[rd], regs[rd]);
                end
            endcase
        end
    end



    $display("\n");
end



endmodule;







