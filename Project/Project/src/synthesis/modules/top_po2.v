module top_po2 #(
    parameter DIVISOR = 50_000_000,
    parameter FILE_NAME = "mem_init.mif",
    parameter ADDR_WIDTH = 6,
    parameter DATA_WIDTH = 16
) (
    input clk,
    input rst_n,
    input [2:0] btn,
    input [8:0] sw,
    output [9:0] led,
    output [27:0] hex
);

    wire deb_rst_n;
    debouncer debouncer_inst1(
        .clk(clk), .rst_n(1'b1), .in(rst_n), .out(deb_rst_n)
    );

    wire [4:0] in;
    //wire [3:0] in;
    genvar i;
    generate
        for (i = 0; i < 4; i = i + 1) begin: initialize_sw
            debouncer debouncer_inst2(
                .clk(clk), .rst_n(deb_rst_n), .in(sw[i]), .out(in[i])
            );
        end
    endgenerate

    assign led[8:5] = in;
    assign led[9] = clk_1hz;

    //Usporen clk
    wire clk_1hz;

    clk_div #(.DIVISOR(DIVISOR)) clk_div_inst(
        .clk(clk),
        .rst_n(deb_rst_n), //uredjaj se asinhrono resetuje preko prekidaca sw[9]
        .out(clk_1hz)
    );

    //Memory <-> CPU
    wire we;
    wire [ADDR_WIDTH-1:0] addr;
    wire [ADDR_WIDTH-1:0] sp; //hex[27:0]
    wire [ADDR_WIDTH-1:0] pc; //hex[27:0]
    wire [ADDR_WIDTH-1:0] pc_out;
    wire [DATA_WIDTH-1:0] data;
    wire [DATA_WIDTH-1:0] mem_out;

    wire [6:0] status;

    memory #(
        .FILE_NAME(FILE_NAME),
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH)
    ) memory_inst(
        .clk(clk_1hz),
        .we(we),
        .addr(addr),
        .data(data),
        .out(mem_out)
    );

    cpu_po2 #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH)
    ) cpu_inst(
        .clk(clk_1hz), .rst_n(deb_rst_n), .mem(mem_out),
        .in(in), .we(we), .addr(addr),
        .data(data), .out(led[4:0]), .pc(pc), .sp(sp), .status(status)
    );

    assign pc_out = pc == 0 ? 0 : pc - 1;

    /////////////////
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
    
    //////////////////
    //BCD <-> CPU(SP)
    wire [3:0] sp_ones, sp_tens;

    bcd bcd_sp_inst(
        .in(status), .ones(sp_ones), .tens(sp_tens)
    );

    //BCD(SP) <-> SSD(ones), SSD(tens)
    ssd ssd_sp_ones_inst(
        .in(sp_ones), .out(hex[20:14])
    );

    ssd ssd_sp_tens_inst(
        .in(sp_tens), .out(hex[27:21])
    );
    

endmodule