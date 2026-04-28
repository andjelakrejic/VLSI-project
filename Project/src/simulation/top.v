module top;

    //alu
    reg [3:0] a_top, b_top;
    reg [2:0] oc_top;
    wire [3:0] f_top;

    //register
    reg clk, rst_n, cl, ld, inc, dec, sr, sl, il, ir;
    reg [3:0] in;
    wire [3:0] out;

    reg [2:0] oc_temp;
    integer i, j;

    alu alu_top(
        .a(a_top), 
        .b(b_top), 
        .oc(oc_top), 
        .f(f_top)
    );

    register reg_top(
        .clk(clk),
        .rst_n(rst_n),
        .cl(cl),
        .ld(ld),
        .in(in),
        .inc(inc),
        .dec(dec),
        .sr(sr),
        .sl(sl),
        .ir(ir),
        .il(il),
        .out(out)
    );

    initial begin
        a_top = 4'h0; b_top = 4'h0; oc_top = 3'o0;  

         //Pobudjivanje ALU sa svim mogucim ulaznim vrednostima
        for (i = 0; i < 2**11; i = i + 1) begin
            {oc_top, a_top, b_top} = i; //11b
            #5;
        end
     
        #5;
        $stop;

        rst_n = 1'b0; clk = 1'b0; ld = 1'b0; cl = 1'b0; sr = 1'b0; sl = 1'b0;
        ir = 1'b0; il = 1'b0; inc = 1'b0; dec = 1'b0;
        in = 4'h0;

        #2 rst_n = 1'b1;

        repeat(1000) begin
            #5;
            {cl, ld, inc, dec, sr, ir, sl, il} = $urandom_range(255);
            in = $urandom_range(15);
        end
        #5;
        $finish;

    end

    initial begin
        $monitor("[ALU]: t = %0d, a = %b, b = %b, oc = %b, f = %b",
            $time, a_top, b_top, oc_top, f_top, i, j);
             
    end

    always @(out)
        $display("[REG]: t = %0d, cl = %b, ld = %b, in = %b, inc = %b, dec = %b, sr = %b, ir = %b, sl = %b, il = %b, out = %b", 
            $time, cl, ld, in, inc, dec, sr, ir, sl, il, out);
    
    always #5 clk = ~clk;

endmodule