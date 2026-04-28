module vga (
    input clk,
    input rst_n,
    input [23:0] code,
    output hsync,
    output vsync,
    output [3:0] red,
    output [3:0] green,
    output [3:0] blue
);

    localparam X_DISPLAY = 800;
    localparam X_FRONT_PORCH = 56;
    localparam X_SYNC_PULSE = 120;
    localparam X_BACK_PORCH = 64;

    localparam Y_DISPLAY = 600;
    localparam Y_FRONT_PORCH = 37;
    localparam Y_SYNC_PULSE = 6;
    localparam Y_BACK_PORCH = 23;

    reg [10:0] x_next, x_reg; // 1040px zauzima jedna horizontalna linija 
    reg [9:0] y_next, y_reg; // 666px zauzima jedna vertikalna linija

    // provera - na levoj polovini monitora visih dvanaest bita, a na desnoj nizih dvanaest
    assign {red, green, blue} = (x_reg < X_DISPLAY && y_reg < Y_DISPLAY) ?
    (x_reg < (X_DISPLAY/2) ? code[23:12] : code[11:0]) : 0; 

    assign hsync = (x_reg >= (X_DISPLAY + X_FRONT_PORCH) && 
        x_reg < X_DISPLAY + X_FRONT_PORCH + X_SYNC_PULSE);
    assign vsync = (y_reg >= (Y_DISPLAY + Y_FRONT_PORCH) && 
        y_reg < Y_DISPLAY + Y_FRONT_PORCH + Y_SYNC_PULSE);

    always @(posedge clk, negedge rst_n) begin
        if (!rst_n) begin
            x_reg <= 0;
            y_reg <= 0;
        end
        else begin
            x_reg <= x_next;
            y_reg <= y_next;
        end
    end

    always @(*) begin
        if (x_reg == (X_DISPLAY + X_FRONT_PORCH + X_SYNC_PULSE + X_BACK_PORCH - 1)) begin
            x_next = 0;
            if (y_reg == (Y_DISPLAY + Y_FRONT_PORCH + Y_SYNC_PULSE + Y_BACK_PORCH - 1))
                y_next = 0;
            else
                y_next = y_reg + 1; // spustamo se u red ispod
        end 
        else begin
            x_next = x_reg + 1; // pomeramo se u istom redu
            y_next = y_reg; // ostajemo u istom redu
        end
    end
    
endmodule