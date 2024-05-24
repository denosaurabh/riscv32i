`include "opcode.v"


module ManagePC (
    input wire clk,

    input wire [31:0] pc,
    input wire [31:0] rs1, rs2, imm,
    input wire [3:0] op,

    output wire [31:0] next_pc,
    output wire [31:0] rd
);

always @(posedge clk) begin
    $display("[PC]");

    case (op)
        OP_J_TYPE: begin
            rd = pc + 4;
            next_pc = pc + imm; // Jump to the target address
        end


        OP_I_TYPE: begin
        case (opcode)
            7'b1100111: begin
                $display("JALR");

                rd = pc + 4;
                next_pc = (rs1 + imm) & ~1; // Compute target address, ensure LSB is 0
            end
            default: begin
                next_pc = pc + 4;
            end
        endcase
        end

        OP_B_TYPE: begin
        case (funct3) 
            3'b000: begin
                $display("BEQ");
                 if (rs1 == rs2) begin
                    next_pc = pc + {{19{imm[12]}}, imm};
                 end else begin
                    next_pc = pc + 4;
                 end
            end
            3'b001: begin
                $display("BNE");
                 if (rs1 != rs2) begin
                    next_pc = pc + {{19{imm[12]}}, imm};
                end else begin
                    next_pc = pc + 4;
                end 
            end
            3'b100: begin
                $display("BLT");
                if ($signed(rs1) < $signed(rs2)) begin
                    next_pc = pc + {{19{imm[12]}}, imm};
                end else begin
                    next_pc = pc + 4;
                end 
            end
            3'b101: begin
                $display("BGE");
                if ($signed(rs1) >= $signed(rs2)) begin
                    next_pc = pc + {{19{imm[12]}}, imm};
                end else begin
                    next_pc = pc + 4; 
                end 
            end
            3'b110: begin
                $display("BLTU");
                if (rs1 < rs2) begin
                    next_pc = pc + {{19{imm[12]}}, imm};
                end else begin
                    next_pc = pc + 4;
                end 
            end
            3'b111: begin
                $display("BGEU");
                if (rs1 >= rs2) begin
                    next_pc = pc + {{19{imm[12]}}, imm};
                end else begin
                    next_pc = pc + 4;
                end
            end
            default: begin
                next_pc = pc + 4;
            end

        endcase
        end

        default: begin
            next_pc = pc + 4; // Default to next sequential instruction
        end

    endcase

    $display("\n");
end

endmodule