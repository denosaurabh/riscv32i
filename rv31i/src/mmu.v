module MMU (
    input clk, reset
    input [31:0] v_adr,
    input read_write, // 0 = read, 1 = write
    input [31:0] data_in,

    output reg valid,
    output reg [31:0] p_adr,
    output reg [31:0] data_out
)

reg[31:0] page_table[0:255];
reg[31:0] RAM[0:1023] // ~4kb RAM


// CLEAR PAGE TABLE & RAM
integer i;
always @(posedge reset) begin
    for (i = 0; i < 256; i = i + 1) begin
        page_table[i] <= 32'b0;
    end

    for (i = 0; i < 1024; i = i + 1) begin
        RAM[i] <= 32'b0;
    end

    valid <= 1'b0;

end


// reg [19:0] page_number;
reg [7:0] page_number;
reg [11:0] offset;

always @(posedge clk) begin

    if (reset) begin
        valid <= 0;
    end else begin
        // page_number = v_adr[31:12];
        page_number = v_adr[19:12]; // 8-bit = 256 pages
        offset = v_adr[11:0]; // 12-bit = 4KB page size

        if (page_table[page_number] == 32'b0) begin
            // invalid page
            valid <= 1'b0;

        end else begin
            valid <= 1'b1;

            p_adr = page_table[page_number] + offset;

            if (read_write == 0) begin
                // READ
                data_out <= RAM[p_adr];

            end else begin
                // WRITE
                RAM[p_adr] <= data_in;
            end
        end

    end 


end


endmodule