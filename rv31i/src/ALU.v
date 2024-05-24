
// CREDIT: https://www.fromthetransistor.com
function [31:0] ALU;

input enable;

input [31:0] A;          // Operand A
input [31:0] B;          // Operand B

input [2:0] funct3;     // ALU operation function code (subset of the funct3 field)
input [6:0] funct7;            // Used for discerning between ADD and SUB

// output [31:0] result; // Result of the operation
// output reg zero,         // Zero flag, 1 if result is 0
// output reg overflow      // Overflow flag for addition and subtraction

// funct3 codes
parameter ADD_SUB = 3'b000;
parameter SLL     = 3'b001;
parameter SLT     = 3'b010;
parameter SLTU    = 3'b011;
parameter XOR     = 3'b100;
parameter SRL_SRA = 3'b101;
parameter OR      = 3'b110;
parameter AND     = 3'b111;

// funct7 codes
parameter STARD = 7'b0000000; // STANDARD
parameter ALTER = 7'b0100000; // ALTERNATE

if (!enable) begin
    ALU = 32'b0;
    // zero = 1'b0;
    // overflow = 1'b0;
end else begin

    case(funct3)
        ADD_SUB: begin
            if (funct7 == STARD)
                ALU = A + B;
            else if (funct7 == ALTER)
                ALU = A - B;
        end
        
        SLL: ALU = A << B[4:0];
        SLT: ALU = (A < B) ? 1 : 0;
        SLTU: ALU = (A < B) ? 1 : 0; // TODO
        XOR: ALU = A ^ B;
        SRL_SRA: begin
            if (funct7 == STARD)
                ALU = A >> B[4:0];
            else if (funct7 == ALTER)
                ALU = $signed(A) >>> B[4:0];
        end
        OR:  ALU = A | B;
        AND: ALU = A & B;
        default: ALU = 32'b0;
    endcase

    // Zero flag
    // zero = (result == 0);

    // // Overflow detection for ADD and SUB
    // if (funct3 == ADD_SUB) begin
    //     if (funct7 == STARD) // ADD overflow
    //         overflow = (A[31] & B[31] & ~result[31]) | (~A[31] & ~B[31] & result[31]);
    //     else if (funct7 == ALTER) // SUB overflow
    //         overflow = (A[31] & ~B[31] & ~result[31]) | (~A[31] & B[31] & result[31]);
    // end else
    //     overflow = 0;

end

endfunction

