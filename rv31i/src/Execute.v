`include "ALU.v"


module Execute (
    input wire clk, reset,

    input wire [31:0] pc, instruction,
    input wire [31:0] rs1, rs2, imm,

    input wire [3:0] op,
    input wire [2:0] funct3;
    input wire [6:0] funct7;


    output wire [31:0] rd,

    output wire write_ram,
    output wire [31:0] ram_adr, ram_data
)




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
            rd = ALU(1'b1, rs1, rs2, funct3, funct7);
            $display("rd = %b", rd);

        end else if (op == OP_I_TYPE) begin
            $display("I-type");

            case (opcode) 
                7'b0000011: begin
                    $display("LOAD");

                    case (funct3) 
                        3'b000: begin
                            $display("BYTE");
                            rd = RAM[rs1 + imm][7:0];
                            $display("rd = %b", rd);
                        end
                        3'b001: begin
                            $display("HALF");
                            rd = RAM[rs1 + imm][15:0];
                            $display("rd = %b", rd);
                        end
                        3'b010: begin
                            $display("WORD");
                            rd = RAM[rs1 + imm];
                            $display("rd = %b", rd);
                        end
                    endcase

                end
                7'b0010011: begin
                    $display("ALU");
                    rd = ALU(1'b1, rs1, imm, funct3, 7'b0);
                    $display("rd = %b", rd);
                end
            endcase


        end else if (op == OP_S_TYPE) begin
            // TODO: TEST
            $display("S-type");

            s_type_adr = rs1 + imm;
            s_type_data = rs2;

            case (funct3) 
                3'b000: begin
                    $display("BYTE");
                    RAM[rs1 + imm] = rs2;

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
                    // rd = imm >> 12;
                    rd = imm;
                    $display("rd = %b", rd);
                end
                7'b0010111: begin // AUIPC
                    $display("AUIPC");

                    // TODO: TEST it
                    // rd = pc + imm;         
                    $display("rd = %b", rd);
                end
            endcase

        end else if (op == OP_J_TYPE) begin
            $display("J-type");

            // rd = pc + 4;
            // $display("pc_reg = %b", pc_reg);

        end else if (op == OP_ECALL_TYPE) begin
            $display("ECALL");

            case (funct3)
                3'b000: begin
                    $display("ECALL PRINT: %b %d", rd, rd);
                end
            endcase
        end
    end



    $display("\n");
end


endmodule