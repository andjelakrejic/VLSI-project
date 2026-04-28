module scan_codes (
    input clk,
    input rst_n,
    input [15:0] code,
    input status,
    output reg control,
    output reg [3:0] num
);
    
    wire is_break = (code[15:8] == 8'hF0);

    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            control <= 0;
            num <= 0;
        end
        else if (status == 0) begin
            control <= 0;
        end
        else if (is_break) begin
            case (code[7:0])
                8'h45: begin
                    num <= 4'd0; 
                    control <= 1;
                end
                8'h16: begin 
                    num <= 4'd1; 
                    control <= 1; 
                end
                8'h1E: begin
                    num <= 4'd2; 
                    control <= 1; 
                end
                8'h26: begin 
                    num <= 4'd3; 
                    control <= 1; 
                end
                8'h25: begin
                    num <= 4'd4; 
                    control <= 1; 
                end
                8'h2E: begin 
                    num <= 4'd5; 
                    control <= 1; 
                end
                8'h36: begin 
                    num <= 4'd6; 
                    control <= 1; 
                end
                8'h3D: begin 
                    num <= 4'd7; 
                    control <= 1; 
                end
                8'h3E: begin 
                    num <= 4'd8; 
                    control <= 1; 
                end
                8'h46: begin 
                    num <= 4'd9; 
                    control <= 1;  
                end
                default: ;
            endcase
        end
    end
endmodule