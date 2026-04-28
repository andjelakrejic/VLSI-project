module color_codes (
    input [5:0] num,
    output reg [23:0] code 
);
    
    wire [3:0] ones;
    wire [3:0] tens;

    bcd bcd_inst(.in(num), .ones(ones), .tens(tens));

    always @(*) begin
        case(ones) 
            4'd0: code[11:0] = 12'h000;
            4'd1: code[11:0] = 12'hF00;
            4'd2: code[11:0] = 12'hF80;
            4'd3: code[11:0] = 12'hFF0;
            4'd4: code[11:0] = 12'h0F0;
            4'd5: code[11:0] = 12'h0FF;
            4'd6: code[11:0] = 12'h08F;
            4'd7: code[11:0] = 12'h00F;
            4'd8: code[11:0] = 12'hF0F;
            4'd9: code[11:0] = 12'hFFF;
            default: code[11:0] = 12'h000;
        endcase
        case(tens) 
            4'd0: code[23:12] = 12'h000;
            4'd1: code[23:12] = 12'hF00;
            4'd2: code[23:12] = 12'hF80;
            4'd3: code[23:12] = 12'hFF0;
            4'd4: code[23:12] = 12'h0F0;
            4'd5: code[23:12] = 12'h0FF;
            4'd6: code[23:12] = 12'h08F;
            4'd7: code[23:12] = 12'h00F;
            4'd8: code[23:12] = 12'hF0F;
            4'd9: code[23:12] = 12'hFFF;
            default: code[11:0] = 12'h000;
        endcase
    end
endmodule