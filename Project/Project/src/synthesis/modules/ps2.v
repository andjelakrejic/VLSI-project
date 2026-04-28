module ps2 (
    input clk,
    input rst_n,
    input ps2_clk,
    input ps2_data,
    output reg [15:0] code
);
    
    reg [3:0] bit_count; // brojimo bitove do 16 odnosno do 2 bajta
    reg [7:0] shift_reg; // cekamo popunjenje frejma od 8 bita u paketu od 11 bita, format [0 xxxxxxxx parity_bit 1]
    reg parity_bit; // odd_parity

    // wire parity_check = ^{shift_reg, parity_bit}; // XORujemo sve shift bite i parity_bit
    // 0 -> paran broj jedinica, 1 -> neparan broj jedinica
    wire ps2_deb;
    debouncer deb_inst1(
        .clk(clk), .rst_n(rst_n), .in(ps2_clk), .out(ps2_deb)
    );
    always @(negedge ps2_deb or negedge rst_n) begin
        if(!rst_n) begin
            code <= 0;
            bit_count <= 0;
            shift_reg <= 0;
        end
        else begin
            case (bit_count)
                0: begin
                    if(ps2_data == 0)
                        bit_count <= 1; 
                end
                1, 2, 3, 4, 5, 6, 7, 8: begin
                    shift_reg <= {ps2_data, shift_reg[7:1]};
                    bit_count <= bit_count + 1;
                end
                9: begin
                    parity_bit <= ps2_data;
                    bit_count <= 10;
                end
                10: begin
                    if (ps2_data == 1) begin
                        code <= {code[7:0], shift_reg};
                    end
                    bit_count <= 0;
                end
                default: bit_count <= 0;
            endcase
        end
    end
endmodule