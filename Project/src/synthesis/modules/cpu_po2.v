    module cpu_po2 #(
    parameter ADDR_WIDTH = 6,
    parameter DATA_WIDTH = 16
) (
    input clk,
    input rst_n,
    input [DATA_WIDTH-1:0] mem,
    input [DATA_WIDTH-1:0] in,
    output reg we,
    output [ADDR_WIDTH-1:0] addr,
    output reg [DATA_WIDTH-1:0] data,
    output [DATA_WIDTH-1:0] out,
    output [ADDR_WIDTH-1:0] pc,
    output [ADDR_WIDTH-1:0] sp ,
    output [6:0] status
);


    //1 word = 16b
    //Najvisa 4b 1. reci instrukcije: Opcode
    localparam MOV = 4'b0000;
    localparam ADD = 4'b0001;
    localparam SUB = 4'b0010;
    localparam MUL = 4'b0011;
    localparam DIV = 4'b0100;
    localparam IN = 4'b0111;
    localparam OUT = 4'b1000;
    localparam STOP = 4'b1111;

    //Faze
    localparam LOAD_PC = 0, 
               FETCH_1 = 1, FETCH_1_X = 2, FETCH_2 = 3, FETCH_2_X = 4,
               DECODE = 5,
               LD_1_ADDR_D = 6, LD_1_ADDR_D_X = 7, LD_1_DATA_D = 8, LD_1_ADDR_I = 9, LD_1_ADDR_I_X = 10, LD_1_DATA_I = 11,
               LD_2_ADDR_D = 12, LD_2_ADDR_D_X = 13, LD_2_DATA_D = 14, LD_2_ADDR_I = 15, LD_2_ADDR_I_X = 16, LD_2_DATA_I = 17,
               EXECUTE_FAZE = 18,
               ST_ADDR_D = 19, ST_ADDR_D_X = 20, ST_DATA_D = 21, ST_DATA_D_X = 22, ST_ADDR_I = 23, ST_DATA_I = 24,
               LD_RET_ADDR_D = 25, LD_RET_ADDR_D_X = 26, LD_RET_DATA_D = 27, LD_RET_ADDR_I = 28, LD_RET_X_I = 29, LD_RET_DATA_I = 30,
               DISPLAY_OUT = 31,
               RESET = 32,
               FINISHED_1_ADDR_D = 33, FINISHED_1_ADDR_D_X = 34, FINISHED_1_DATA_D = 35, FINISHED_1_ADDR_I = 36, FINISHED_1_ADDR_I_X = 37, 
               FINISHED_1_DATA_I = 38, FINISHED_1_DISPLAY = 39,
               FINISHED_2_ADDR_D = 40, FINISHED_2_ADDR_D_I = 41, FINISHED_2_DATA_D = 42, FINISHED_2_ADDR_I = 43, FINISHED_2_ADDR_I_X = 44, FINISHED_2_DATA_I = 45, FINISHED_2_DISPLAY = 46,
               FINISHED_3_ADDR_D = 47, FINISHED_3_ADDR_D_X = 48, FINISHED_3_DATA_D = 49, FINISHED_3_ADDR_I = 50, FINISHED_3_ADDR_I_X = 51, FINISHED_3_DATA_I = 52, FINISHED_3_DISPLAY = 53,
               FINISHED_LOOP = 54,
               LD_RET_DATA_D_X = 55,  LD_RET_DATA_I_X = 56, LD_RET_ADDR_I_X = 57, LD_1_DATA_I_X = 58, ST_ADDR_I_X = 59,
               LD_2_DATA_D_X = 61, LD_2_DATA_I_X = 62, FINISHED_1_DATA_D_X = 63, FINISHED_1_DATA_I_X = 64, FINISHED_2_DATA_D_X = 65,
               FINISHED_2_DATA_I_X = 66, FINISHED_3_DATA_D_X = 67, FINISHED_3_DATA_I_X = 68, LD_1_DATA_D_X = 69;


    reg pc_cl, pc_dec, pc_sr, pc_ir, pc_sl, pc_il;
    reg sp_sr, sp_ir, sp_sl, sp_il;
    reg ir_cl, ir_inc, ir_dec, ir_sr, ir_ir, ir_sl, ir_il;
    reg mar_cl, mar_inc, mar_dec, mar_sr, mar_ir, mar_sl, mar_il;
    reg mdr_cl, mdr_inc, mdr_dec, mdr_sr, mdr_ir, mdr_sl, mdr_il;
    reg acc_inc, acc_dec, acc_sr, acc_ir, acc_sl, acc_il;

    //Svaki registar je jedna instanca register u okviru cpu
    //PC(6b), SP(6b), IR(32b), MAR(6b), MDR(16b), A(16b) 
    
    reg pc_ld, pc_inc;
    reg [ADDR_WIDTH-1:0] pc_in;

    reg sp_ld, sp_inc, sp_dec, sp_cl;
    reg [ADDR_WIDTH-1:0] sp_in;

    reg acc_ld, acc_cl;
    reg [DATA_WIDTH-1:0] acc_in;
    wire [DATA_WIDTH-1:0] acc_out; //vrednost

    reg mar_ld;
    reg [ADDR_WIDTH-1:0] mar_in;
    wire [ADDR_WIDTH-1:0] mar_out;

    reg mdr_ld;
    reg [DATA_WIDTH-1:0] mdr_in;
    wire [DATA_WIDTH-1:0] mdr_out; //vrednost

    reg ir_ld;
    reg [2*DATA_WIDTH-1:0] ir_in;
    wire [2*DATA_WIDTH-1:0] ir_out; //vrednost
    
    //PC - pocetna vrednost je 8
    //PC = pc, SP = sp
    register #(.DATA_WIDTH(ADDR_WIDTH)) pc_inst(
        .clk(clk), .rst_n(rst_n), .cl(pc_cl),
        .ld(pc_ld), .in(pc_in), .inc(pc_inc), 
        .dec(pc_dec), .sr(pc_sr), .ir(pc_ir),
        .sl(pc_sl), .il(pc_il), .out(pc)
    );
    //SP - prva slobodna memorijska lokacija
    register #(.DATA_WIDTH(ADDR_WIDTH)) sp_inst (
        .clk(clk), .rst_n(rst_n), .cl(sp_cl),
        .ld(sp_ld), .in(sp_in), .inc(sp_inc),
        .dec(sp_dec), .sr(sp_sr), .ir(sp_ir),
        .sl(sp_sl), .il(sp_il), .out(sp)
    );

    //ACC - accumulator
    register #(.DATA_WIDTH(DATA_WIDTH)) acc_inst (
        .clk(clk), .rst_n(rst_n), .cl(acc_cl),
        .ld(acc_ld), .in(acc_in), .inc(acc_inc),
        .dec(acc_dec), .sr(acc_sr), .ir(acc_ir),
        .sl(acc_sl), .il(acc_il), .out(acc_out)
    );

    //MAR - Memory Address Register
    register #(.DATA_WIDTH(ADDR_WIDTH)) mar_inst (
        .clk(clk), .rst_n(rst_n), .cl(mar_cl),
        .ld(mar_ld), .in(mar_in), .inc(mar_inc),
        .dec(mar_dec), .sr(mar_sr), .ir(mar_ir),
        .sl(mar_sl), .il(mar_il), .out(mar_out)
    );

    //MDR - Memory Data Register
    register #(.DATA_WIDTH(DATA_WIDTH)) mdr_inst (
        .clk(clk), .rst_n(rst_n), .cl(mdr_cl),
        .ld(mdr_ld), .in(mdr_in), .inc(mdr_inc),
        .dec(mdr_dec), .sr(mdr_sr), .ir(mdr_ir),
        .sl(mdr_sl), .il(mdr_il), .out(mdr_out)
    );

    //IR - Instruction Register (prihvatni registar instrukcije)
    register #(.DATA_WIDTH(32)) ir_inst (
        .clk(clk), .rst_n(rst_n), .cl(ir_cl),
        .ld(ir_ld), .in(ir_in), .inc(ir_inc),
        .dec(ir_dec), .sr(ir_sr), .ir(ir_ir),
        .sl(ir_sl), .il(ir_il), .out(ir_out)
    );

    //ALU unit
    reg [2:0] oc;
    reg [DATA_WIDTH-1:0] alu_a, alu_b;
    wire [DATA_WIDTH-1:0] alu_f;

    alu #(.DATA_WIDTH(DATA_WIDTH)) alu_inst(
        .oc(oc), .a(alu_a), .b(alu_b), .f(alu_f)
    ); 

    //IR reg
    wire [2:0] oper_x, oper_y, oper_z; //operandi
    wire oper_z_indirect, oper_x_indirect, oper_y_indirect;

    wire [3:0] opcode;

    assign opcode = ir_out[15:12];
    //direktno adresiranje:
    assign oper_z = ir_out[10:8]; //prvi operand
    assign oper_x = ir_out[6:4];  //drugi operand
    assign oper_y = ir_out[2:0];  //treci operand

    //indirektno adresiranje:
    assign oper_z_indirect = ir_out[11];
    assign oper_x_indirect = ir_out[7];
    assign oper_y_indirect = ir_out[3];


    reg [6:0] next_state, state_reg; 
    reg [DATA_WIDTH-1:0] out_next, out_reg;

    assign status = state_reg;
    assign out = out_reg;

    assign addr = mar_out; //?????

//Sekvencijalna logika
    always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        state_reg <= RESET;
        out_reg <= {DATA_WIDTH{1'b0}};
    end else begin
        state_reg <= next_state;
        out_reg <= out_next;
    end
end

always @(*) begin
    //default signali
    // pc_in = {ADDR_WIDTH{1'b0}};
    // sp_in = {ADDR_WIDTH{1'b0}};
    // mar_in = {ADDR_WIDTH{1'b0}};
    // ir_in = {2*DATA_WIDTH{1'b0}};
    // acc_in = {DATA_WIDTH{1'b0}};

    pc_in = pc;
    sp_in = sp;
    mar_in = addr;
    ir_in = ir_out;
    acc_in  = acc_out;

    {pc_cl, pc_ld, pc_inc, pc_dec, pc_sr, pc_ir, pc_sl, pc_il} = 8'b0;
    {sp_cl, sp_ld, sp_inc, sp_dec, sp_sr, sp_ir, sp_sl, sp_il} = 8'b0;
    {ir_cl, ir_ld, ir_inc, ir_dec, ir_sr, ir_ir, ir_sl, ir_il} = 8'b0;
    {mar_cl, mar_ld, mar_inc, mar_dec, mar_sr, mar_ir, mar_sl, mar_il} = 8'b0;
    {mdr_cl, mdr_ld, mdr_inc, mdr_dec, mdr_sr, mdr_ir, mdr_sl, mdr_il} = 8'b0;
    {acc_cl, acc_ld, acc_inc, acc_dec, acc_sr, acc_ir, acc_sl, acc_il} = 8'b0;
    
    we = 1'b0;
    data = {DATA_WIDTH{1'b0}};
    
    alu_a = acc_out;
    alu_b = mdr_out;
    oc = 3'b000;

    out_next = out_reg;
    next_state = state_reg;

    case(state_reg)
        RESET: begin
                pc_in = 6'd8;
                pc_ld = 1'b1;

                sp_in = (1 << ADDR_WIDTH) - 1;
                sp_ld = 1'b1;

                next_state = LOAD_PC;
            end
            LOAD_PC: begin
                mar_in = pc;
                mar_ld = 1'b1;
                pc_inc = 1'b1;

                next_state = FETCH_1_X;
            end
            // cekamo sledeci takt da se adresa dovuce u memoriju
            FETCH_1_X: begin
                next_state = FETCH_1;
            end
            FETCH_1: begin
                mdr_in = mem; 
                mdr_ld = 1'b1;
                
                mar_in = pc;
                mar_ld = 1'b1;
                
                next_state = FETCH_2_X;
            end
            // cekamo sledeci takt da se adresa dovuce u memoriju
            FETCH_2_X: begin
                next_state = FETCH_2;
            end
            FETCH_2: begin
                mdr_in = mem;
                mdr_ld = 1'b1;
                ir_in = {16'b0, mdr_out};
                ir_ld = 1'b1;

                next_state = DECODE;
            end

            DECODE: begin
                ir_ld = 1'b1;
                ir_in = {mdr_out, ir_out[15:0]};

                case (opcode)
                    //MOV Z, X, 0 ---> mem[z] <= mem[x]
                    MOV:    begin
                        if ({oper_y_indirect, oper_y} == 0) //Provera da li je 3. operand y == 0
                            next_state = LD_1_ADDR_D; 
                            else
                            next_state = LOAD_PC; 
                        end
                    ADD, //mem[z] = mem[x] + mem[y]
                    SUB,
                    MUL,
                    DIV:    next_state = LD_2_ADDR_D;
                    IN:     next_state = ST_ADDR_D;
                    OUT:    next_state = LD_RET_ADDR_D;
                    STOP:   next_state = FINISHED_1_ADDR_D;
                    default: next_state = LOAD_PC;
                endcase
            end

            LD_2_ADDR_D: begin //ucitava se prvo 3. operand
                mar_ld = 1'b1;
                mar_in = oper_y;
                next_state = LD_2_ADDR_D_X;
            end

            LD_2_ADDR_D_X:
                next_state = LD_2_DATA_D;

            LD_2_DATA_D: begin
                mdr_in = mem;     
                mdr_ld = 1'b1;
                next_state = LD_2_DATA_D_X;
            end

            LD_2_DATA_D_X: begin
                if (oper_y_indirect)
                    next_state = LD_2_ADDR_I;
                else
                    next_state = LD_1_ADDR_D;
            end

            LD_2_ADDR_I: begin
                mar_ld = 1'b1;
                mar_in = mdr_out;
                next_state = LD_2_ADDR_I_X;
            end

            LD_2_ADDR_I_X:
                next_state = LD_2_DATA_I;

            LD_2_DATA_I: begin
                mdr_in = mem;
                mdr_ld = 1'b1; //mdr <= mem[mem[y]]
                next_state = LD_2_DATA_I_X;
            end
            LD_2_DATA_I_X: begin
                next_state = LD_1_ADDR_D;
            end

//z,x,y - 1. 2. 3. operand
            LD_1_ADDR_D: begin 
                acc_ld  = 1'b1;
                acc_in  = mdr_out; //privremeno cuvanje 3. operanda iz mdr u akumulatoru
                mar_ld = 1'b1;
                mar_in = oper_x; //mar <= x - 2. operand
                next_state = LD_1_ADDR_D_X;
            end

            LD_1_ADDR_D_X:
                next_state = LD_1_DATA_D;

            LD_1_DATA_D: begin
                mdr_in = mem;
                mdr_ld = 1'b1; //mdr <= mem[mar] - mem[x]
                next_state = LD_1_DATA_D_X;
            end

            LD_1_DATA_D_X: begin
                if (oper_x_indirect) 
                    next_state = LD_1_ADDR_I; //indirektno adresiranje 2. operanda
                else begin
                    case (opcode)
                        ADD,
                        SUB,
                        MUL,
                        DIV: begin
                            //Dodavanje u ALU - za EXECUTE fazu
                            alu_a = acc_out;
                            alu_b = mdr_out; //vrednost prethodno sacuvana u akumulatoru
                            case (opcode)
                                ADD: oc = 3'b000;
                                SUB: oc = 3'b001;
                                MUL: oc = 3'b010;
                                DIV: oc = 3'b011;
                            endcase
                            next_state = EXECUTE_FAZE;
                        end
                        MOV: next_state = ST_ADDR_D;
                        default: next_state = LOAD_PC;
                    endcase

                end
            end

            LD_1_ADDR_I: begin
                mar_ld = 1'b1;
                mar_in = mdr_out;
                next_state = LD_1_ADDR_I_X;
            end

            LD_1_ADDR_I_X:
                next_state = LD_1_DATA_I;

            LD_1_DATA_I: begin
                mdr_ld = 1'b1;
                mdr_in = mem;

                next_state = LD_1_DATA_I_X;
            end
            LD_1_DATA_I_X: begin
                case (opcode)
                    ADD,
                    SUB,
                    MUL,
                    DIV: begin
                        alu_a = mdr_out;
                        alu_b = acc_out;
                        case (opcode)
                            ADD: oc = 3'b000;
                            SUB: oc = 3'b001;
                            MUL: oc = 3'b010;
                            DIV: oc = 3'b011;
                        endcase
                        next_state = EXECUTE_FAZE;
                    end
                    MOV: next_state = ST_ADDR_D;
                    default: next_state = LOAD_PC;
                endcase
            end


            EXECUTE_FAZE: begin
                alu_a = mdr_out;
                alu_b = acc_out;
                case (opcode)
                    ADD: oc = 3'b000;
                    SUB: oc = 3'b001;
                    MUL: oc = 3'b010;
                    DIV: oc = 3'b011;
                endcase
                //alu_f = mem[x] +-* mem[y]
                acc_ld = 1'b1;
                acc_in = alu_f;  //U acc se sad nalazi rezultat alu koji treba da se upise u memoriju
                next_state = ST_ADDR_D;
            end

            ST_ADDR_D: begin //upis u mem[z] (1. operand)
                mar_ld = 1'b1;
                mar_in = oper_z; //mar <= z
                next_state = ST_ADDR_D_X;
            end

            ST_ADDR_D_X:
                next_state = ST_DATA_D;

            ST_DATA_D: begin
                if (oper_z_indirect) begin //indirektno adresiranje
                    mdr_in = mem;
                    mdr_ld = 1'b1; //mdr <= mem[mar]
                    next_state = ST_ADDR_I;
                end
                else begin
                    we = 1'b1; 
                    case (opcode)
                        IN: data = in;          //mem[z] <= in (podatak sa standardnog ulaza)
                        MOV: data = mdr_out;    //mem[z] <= mem[x]
                        default: data = acc_out; //ADD, SUB, MUL, DIV: mem[z] <= acc (mar = z)
                    endcase
                    next_state =  ST_DATA_D_X; //cekamo takt
                end
            end

            ST_DATA_D_X: begin
                next_state = LOAD_PC; //povratak u FETCH
            end
            
            ST_ADDR_I: begin
                mar_ld = 1'b1;
                mar_in = mdr_out; //mar <= mem[mdr]
                next_state = ST_ADDR_I_X;
            end

            ST_ADDR_I_X: begin
                next_state = ST_DATA_I;
            end

            ST_DATA_I: begin
                we = 1'b1;
                case (opcode)
                    IN: data = in; //mem[mem[oper1]] <= in
                    MOV: data = mdr_out;
                    default: data = acc_out;
                endcase
                next_state = LOAD_PC; //povratak u FETCH
            end
//OUT
            LD_RET_ADDR_D: begin
                mar_ld = 1'b1;
                mar_in = oper_z;
                next_state = LD_RET_ADDR_D_X;
            end

            LD_RET_ADDR_D_X: begin
                next_state = LD_RET_DATA_D;
            end

            LD_RET_DATA_D: begin
                mdr_in = mem;
                mdr_ld = 1'b1; //mdr = mem[z]
                if (oper_z_indirect)
                    next_state = LD_RET_ADDR_I;
                else
                    next_state = LD_RET_DATA_D_X;
            end
            LD_RET_DATA_D_X: begin
                next_state = DISPLAY_OUT;
            end

            LD_RET_ADDR_I: begin
                mar_ld = 1'b1;
                mar_in = mdr_out;
                next_state = LD_RET_ADDR_I_X;
            end

            LD_RET_ADDR_I_X: begin
                next_state = LD_RET_DATA_I;
            end

            LD_RET_DATA_I: begin
                mdr_in = mem;
                mdr_ld = 1;
                next_state = LD_RET_DATA_I_X;
            end
            LD_RET_DATA_I_X: begin
                next_state = DISPLAY_OUT;
            end

            //ispis na standardni izlaz sa adrese oper. z
            DISPLAY_OUT: begin
                out_next = mdr_out;
                next_state = LOAD_PC;
            end

//STOP
            FINISHED_1_ADDR_D: begin
                if ({oper_z_indirect, oper_z} == 0) begin //ne mora da se ispise - idemo dalje u operand 2
                    next_state = FINISHED_2_ADDR_D;
                end
                else begin
                    mar_ld = 1'b1;
                    mar_in = oper_z;
                    next_state = FINISHED_1_ADDR_D_X;
                end
            end

            FINISHED_1_ADDR_D_X:
                next_state = FINISHED_1_DATA_D;

            FINISHED_1_DATA_D: begin
                mdr_in = mem;
                mdr_ld = 1'b1;
                next_state = FINISHED_1_DATA_D_X;
            end

            FINISHED_1_DATA_D_X: begin
                if (oper_z_indirect)
                    next_state = FINISHED_1_ADDR_I;
                else
                    next_state = FINISHED_1_DISPLAY;
            end

            FINISHED_1_ADDR_I: begin
                mar_ld = 1'b1;
                mar_in = mdr_out;
                next_state = FINISHED_1_ADDR_I_X;
            end

            FINISHED_1_ADDR_I_X:
                next_state = FINISHED_1_DATA_I;

            FINISHED_1_DATA_I: begin
                mdr_in = mem;
                mdr_ld = 1'b1;
                next_state = FINISHED_1_DATA_I_X;
            end
            FINISHED_1_DATA_I_X: begin
                next_state = FINISHED_1_DISPLAY;
            end

            FINISHED_1_DISPLAY: begin 
                out_next = mdr_out; //ispis 1. oper na standardni izlaz
                next_state = FINISHED_2_ADDR_D;
            end

            FINISHED_2_ADDR_D: begin
                if ({oper_x_indirect, oper_x} == 0) begin
                    next_state = FINISHED_3_ADDR_D; //ne mora da se ispise - idemo dalje u operand 3
                end
                else begin
                    mar_ld = 1'b1;
                    mar_in = oper_x;
                    next_state = FINISHED_2_ADDR_D_I;
                end
            end

            FINISHED_2_ADDR_D_I: begin
                next_state = FINISHED_2_DATA_D;
            end

            FINISHED_2_DATA_D: begin
                mdr_in = mem;
                mdr_ld = 1'b1;
                next_state = FINISHED_2_DATA_D_X;
                
            end
            FINISHED_2_DATA_D_X: begin
                if (oper_x_indirect)
                    next_state = FINISHED_2_ADDR_I;
                else
                    next_state = FINISHED_2_DISPLAY;
            end

            FINISHED_2_ADDR_I: begin
                mar_ld = 1'b1;
                mar_in = mdr_out;
                next_state = FINISHED_2_ADDR_I_X;
            end

            FINISHED_2_ADDR_I_X: begin
                next_state = FINISHED_2_DATA_I;
            end

            FINISHED_2_DATA_I: begin
                mdr_in = mem;
                mdr_ld = 1'b1;
                next_state = FINISHED_2_DATA_I_X;            
            end

            FINISHED_2_DATA_I_X: begin
                next_state = FINISHED_2_DISPLAY;  
            end

            FINISHED_2_DISPLAY: begin
                out_next = mdr_out; //ispis 2. oper na standardni izlaz
                next_state = FINISHED_3_ADDR_D;
            end

            FINISHED_3_ADDR_D: begin
                if ({oper_y_indirect, oper_y} == 0) begin
                    next_state = FINISHED_LOOP; //ne mora da se ispise - kraj
                end
                else begin
                    mar_ld = 1'b1;
                    mar_in = oper_y;
                    next_state = FINISHED_3_ADDR_D_X;
                end
            end

            FINISHED_3_ADDR_D_X: begin
                next_state = FINISHED_3_DATA_D;
            end

            FINISHED_3_DATA_D: begin
                mdr_in = mem;
                mdr_ld = 1'b1;
                next_state = FINISHED_3_DATA_D_X;                
            end

            FINISHED_3_DATA_D_X: begin
                if (oper_y_indirect)
                    next_state = FINISHED_3_ADDR_I;
                else
                    next_state = FINISHED_3_DISPLAY;
            end

            FINISHED_3_ADDR_I: begin
                mar_ld = 1'b1;
                mar_in = mdr_out;
                next_state = FINISHED_3_ADDR_I_X;
            end

            FINISHED_3_ADDR_I_X: begin
                next_state = FINISHED_3_DATA_I;
            end

            FINISHED_3_DATA_I: begin
                mdr_in = mem;
                mdr_ld = 1'b1;
                next_state = FINISHED_3_DATA_I_X;
            end

            FINISHED_3_DATA_I_X: begin
                next_state = FINISHED_3_DISPLAY;
            end

            FINISHED_3_DISPLAY: begin
                out_next = mdr_out; //ispis 3. oper na standardni izlaz
                next_state = FINISHED_LOOP;
            end

            FINISHED_LOOP: begin
                next_state = FINISHED_LOOP;
            end

            default: begin
                next_state = LOAD_PC;
            end

        endcase
    end


        
endmodule