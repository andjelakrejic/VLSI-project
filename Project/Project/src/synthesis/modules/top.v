module top #(
    parameter DIVISOR = 50_000_000,
    parameter FILE_NAME = "mem_init.mif",
    parameter ADDR_WIDTH = 6,
    parameter DATA_WIDTH = 16
) (
    input clk,
    input rst_n,
    input [1:0] kbd,
    input [2:0] btn,
    input [8:0] sw,
    output [13:0] mnt,
    output [9:0] led,
    output [27:0] hex
);

    wire deb_rst_n;
    debouncer debouncer_inst1(
        .clk(clk), .rst_n(1'b1), .in(rst_n), .out(deb_rst_n)
    );

    //wire [2:0] status;

    /*wire [3:0] in;
    genvar i;
    generate
        for (i = 0; i < 4; i = i + 1) begin: initialize_sw
            debouncer debouncer_inst2(
                .clk(clk), .rst_n(deb_rst_n), .in(sw[i]), .out(in[i])
            );
        end
    endgenerate
    */

    //assign led[8:5] = in;
    assign led[9] = clk_1hz;

    //Usporen clk
    wire clk_1hz;

    clk_div #(.DIVISOR(DIVISOR)) clk_div_inst(
        .clk(clk),
        .rst_n(deb_rst_n), //uredjaj se asinhrono resetuje preko prekidaca sw[9]
        .out(clk_1hz)
    );

    //PS2 -> SCAN_CODES <-> CPU
    wire [15:0] ps2_code;
    wire control;
    wire [3:0] num;

    ps2 ps2_inst(
        .clk(clk), .rst_n(deb_rst_n), 
        .ps2_clk(kbd[0]), .ps2_data(kbd[1]), .code(ps2_code)
    );

    scan_codes scan_codes_inst(
        .clk(clk), .rst_n(deb_rst_n), .code(ps2_code), 
        .status(status), .control(control), .num(num)
    );

    //Memory <-> CPU
    wire status;
    wire we;
    wire [ADDR_WIDTH-1:0] addr;
    wire [ADDR_WIDTH-1:0] sp; //preko sedmosegmentnih displeja hex[27:0]
    wire [ADDR_WIDTH-1:0] pc; //preko sedmosegmentnih displeja hex[27:0]
    wire [ADDR_WIDTH-1:0] pc_out;
    wire [DATA_WIDTH-1:0] out;
    wire [DATA_WIDTH-1:0] data;
    wire [DATA_WIDTH-1:0] mem_out;

    memory #(
        .FILE_NAME(FILE_NAME),
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH)
    ) memory_inst(
        .clk(clk_1hz), .we(we), .addr(addr), .data(data), .out(mem_out)
    );

    cpu #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH)
    ) cpu_inst(
        .clk(clk_1hz), .rst_n(deb_rst_n), .mem(mem_out),
        .in(num), .control(control), .status(status), .we(we), .addr(addr),
        .data(data), .out(out), .pc(pc), .sp(sp)
    );

    assign pc_out = pc == 0 ? 0 : pc - 1; 
    assign led[5] = status;
    assign led[4:0] = out[4:0];

    //BCD <-> CPU(PC)
    wire [3:0] pc_ones, pc_tens;

    bcd bcd_pc_inst(
        .in(pc_out), .ones(pc_ones), .tens(pc_tens)
    );

    //BCD(PC) <-> SSD(ones), SSD(tens)
    ssd ssd_pc_ones_inst(
        .in(pc_ones), .out(hex[6:0])
    );

    ssd ssd_pc_tens_inst(
        .in(pc_tens), .out(hex[13:7])
    );
    
    //BCD <-> CPU(SP)
    wire [3:0] sp_ones, sp_tens;

    bcd bcd_sp_inst(
        .in(sp), .ones(sp_ones), .tens(sp_tens)
    );

     //BCD(SP) <-> SSD(ones), SSD(tens)
    ssd ssd_sp_ones_inst(
        .in(sp_ones), .out(hex[20:14])
    );

    ssd ssd_sp_tens_inst(
        .in(sp_tens), .out(hex[27:21])
    );
    
    // COLOR_CODES -> VGA
    wire [23:0] color_code;

    color_codes color_codes_inst(
        .num(out[5:0]), .code(color_code)
    );

    vga vga_inst(
        .clk(clk), .rst_n(deb_rst_n), .code(color_code),
        .hsync(mnt[13]) , .vsync(mnt[12]), .red(mnt[11:8]), .green(mnt[7:4]), .blue(mnt[3:0])
    );
endmodule