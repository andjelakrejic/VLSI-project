module cpu #(
    parameter ADDR_WIDTH = 6,
    parameter DATA_WIDTH = 16
) (
    input clk,
    input rst_n,
    input [DATA_WIDTH-1:0] mem,
    input [DATA_WIDTH-1:0] in,
    input control,
    output reg status,
    output reg we,
    output [ADDR_WIDTH-1:0] addr,
    output reg [DATA_WIDTH-1:0] data,
    output [DATA_WIDTH-1:0] out,
    output [ADDR_WIDTH-1:0] pc,
    output [ADDR_WIDTH-1:0] sp
);
    
    reg pc_cl, pc_ld, pc_inc, pc_dec, pc_sr, pc_ir, pc_sl, pc_il;
    reg sp_cl, sp_ld, sp_inc, sp_dec, sp_sr, sp_ir, sp_sl, sp_il;
    reg ir_cl, ir_ld, ir_inc, ir_dec, ir_sr, ir_ir, ir_sl, ir_il;
    reg mar_cl, mar_ld, mar_inc, mar_dec, mar_sr, mar_ir, mar_sl, mar_il;
    reg mdr_cl, mdr_ld, mdr_inc, mdr_dec, mdr_sr, mdr_ir, mdr_sl, mdr_il;
    reg a_cl, a_ld, a_inc, a_dec, a_sr, a_ir, a_sl, a_il;

    reg [ADDR_WIDTH-1:0] pc_in, sp_in, mar_in;
    reg [2*DATA_WIDTH-1:0] ir_in;
    reg [DATA_WIDTH-1:0] a_in, mdr_in;
    
    wire [2*DATA_WIDTH-1:0] ir_out;
    wire [DATA_WIDTH-1:0] mdr_out, a_out;

    register #(.DATA_WIDTH(ADDR_WIDTH)) pc_reg (
        .clk(clk), .rst_n(rst_n),
        .cl(pc_cl), .ld(pc_ld), .inc(pc_inc), .dec(pc_dec),
        .sr(pc_sr), .ir(pc_ir), .sl(pc_sl), .il(pc_il),
        .in(pc_in), .out(pc)
    );

    register #(.DATA_WIDTH(ADDR_WIDTH)) sp_reg (
        .clk(clk), .rst_n(rst_n),
        .cl(sp_cl), .ld(sp_ld), .inc(sp_inc), .dec(sp_dec),
        .sr(sp_sr), .ir(sp_ir), .sl(sp_sl), .il(sp_il),
        .in(sp_in), .out(sp)
    );

    register #(.DATA_WIDTH(DATA_WIDTH * 2)) ir_reg (
        .clk(clk), .rst_n(rst_n),
        .cl(ir_cl), .ld(ir_ld), .inc(ir_inc), .dec(ir_dec),
        .sr(ir_sr), .ir(ir_ir), .sl(ir_sl), .il(ir_il),
        .in(ir_in), .out(ir_out)
    );

    register #(.DATA_WIDTH(ADDR_WIDTH)) mar_reg (
        .clk(clk), .rst_n(rst_n),
        .cl(mar_cl), .ld(mar_ld), .inc(mar_inc), .dec(mar_dec),
        .sr(mar_sr), .ir(mar_ir), .sl(mar_sl), .il(mar_il),
        .in(mar_in), .out(addr)
    );

    register #(.DATA_WIDTH(DATA_WIDTH)) mdr_reg (
        .clk(clk), .rst_n(rst_n),
        .cl(mdr_cl), .ld(mdr_ld), .inc(mdr_inc), .dec(mdr_dec),
        .sr(mdr_sr), .ir(mdr_ir), .sl(mdr_sl), .il(mdr_il),
        .in(mdr_in), .out(mdr_out)
    );

    register #(.DATA_WIDTH(DATA_WIDTH)) a_reg (
        .clk(clk), .rst_n(rst_n),
        .cl(a_cl), .ld(a_ld), .inc(a_inc), .dec(a_dec),
        .sr(a_sr), .ir(a_ir), .sl(a_sl), .il(a_il),
        .in(a_in), .out(a_out)
    );

    reg [2:0] oc;
    reg [DATA_WIDTH-1:0] alu_a, alu_b;
    wire [DATA_WIDTH-1:0] alu_f;

    alu #(.DATA_WIDTH(DATA_WIDTH)) alu_instance (
        .oc(oc), .a(alu_a), .b(alu_b), .f(alu_f)
    );

    localparam MOV = 4'b0000;
    localparam ADD = 4'b0001;
    localparam SUB = 4'b0010;
    localparam MUL = 4'b0011;
    localparam DIV = 4'b0100;
    localparam BEQ = 4'b0101;
    localparam JSR = 4'b110;
    localparam IN = 4'b0111;
    localparam OUT = 4'b1000;
    localparam RTS = 4'b1001;
    localparam STOP = 4'b1111;

    localparam init = 3'b000;
    localparam fetch = 3'b001;
    localparam decode = 3'b010;
    localparam execute = 3'b011;
    localparam writeback = 3'b100;
    localparam finish = 3'b101;

    localparam init_do = 5'd0;

    localparam fetch_load_mar = 5'd0;
    localparam fetch_wait_mem = 5'd1;
    localparam fetch_read_mem = 5'd2;
    localparam fetch_load_ir = 5'd3;
    localparam fetch_wait_mdr = 5'd4;

    localparam decode_mov_load_mar = 5'd0;
    localparam decode_mov_ind_wait_mem = 5'd1;
    localparam decode_mov_wait_mem = 5'd2;
    localparam decode_mov_ind_read_mem = 5'd3;
    localparam decode_mov_ind_mdr_to_mar = 5'd4;
    localparam decode_mov_read_mem = 5'd5;
    localparam decode_mov_mdr_to_acc = 5'd6;

    localparam decode_mov_imm_load_mar = 5'd0;
    localparam decode_mov_imm_wait_mem = 5'd1;
    localparam decode_mov_imm_read_mem = 5'd2;
    localparam decode_mov_imm_to_acc = 5'd3;

    localparam decode_alu_y_to_mar = 5'd0;
    localparam decode_alu_y_ind_wait_mem = 5'd1;
    localparam decode_alu_y_wait_mem = 5'd2;
    localparam decode_alu_y_ind_read_mem = 5'd3;
    localparam decode_alu_y_ind_mdr_to_mar = 5'd4;
    localparam decode_alu_y_read_mem = 5'd5;
    localparam decode_alu_y_mdr_to_acc = 5'd6;
    localparam decode_alu_z_to_mar = 5'd7;
    localparam decode_alu_z_ind_wait_mem = 5'd8;
    localparam decode_alu_z_wait_mem = 5'd9;
    localparam decode_alu_z_ind_read_mem = 5'd10;
    localparam decode_alu_z_ind_mdr_to_mar = 5'd11;
    localparam decode_alu_z_read_mem = 5'd12;
    localparam decode_alu_z_wait_2_mem = 5'd13;

    localparam decode_beq_operand_to_mar = 5'd0;
    localparam decode_beq_wait_mem = 5'd1;
    localparam decode_beq_read_mem = 5'd2;
    localparam decode_beq_mdr_to_acc = 5'd3;
    localparam decode_beq_compare_zero = 5'd4;
    localparam decode_beq_read_next_word = 5'd5;
    localparam decode_beq_y_to_mar = 5'd6;
    localparam decode_beq_wait_y_mem = 5'd7;
    localparam decode_beq_read_y_mem = 5'd8;
    localparam decode_beq_wait_next_word_mem = 5'd9;
    localparam decode_beq_compare_2 = 5'd10;
    localparam decode_beq_read_next_word_mem = 5'd11;
    localparam decode_beq_jump = 5'd12;

    localparam decode_jsr_addr_to_acc = 5'd0;
    localparam decode_jsr_pc_to_mdr = 5'd1;
    localparam decode_jsr_update_pc = 5'd2;
    localparam decode_jsr_update_sp = 5'd3;
    localparam decode_jsr_store_mem = 5'd4;
    localparam decode_jsr_wait_mem = 5'd5;
    localparam decode_jsr_sp_to_mar = 5'd6;

    localparam decode_rts_find_sp = 5'd0;
    localparam decode_rts_sp_to_mar = 5'd1;
    localparam decode_rts_wait_mem = 5'd2;
    localparam decode_rts_mdr_to_pc = 5'd3;
    localparam decode_rts_wait_mdr = 5'd4;
    localparam decode_rts_read_mem = 5'd5;
    localparam decode_rts_return_to_fetch = 5'd6;

    localparam decode_in_load_acc = 5'd0;

    localparam decode_out_x_to_mar = 5'd0;
    localparam decode_out_x_ind_wait_mem = 5'd1;
    localparam decode_out_x_wait_mem = 5'd2;
    localparam decode_out_x_ind_read_mem = 5'd3;
    localparam decode_out_x_ind_mdr_to_mar = 5'd4;
    localparam decode_out_x_read_mem = 5'd5;
    localparam decode_out_x_mdr_to_out = 5'd6;
    localparam decode_out_x_wait_mdr = 5'd7;

    localparam decode_stop_x_to_mar = 5'd0;
    localparam decode_stop_x_ind_wait_mem = 5'd1;
    localparam decode_stop_x_wait_mem = 5'd2;
    localparam decode_stop_x_ind_read_mem = 5'd3;
    localparam decode_stop_x_ind_mdr_to_mar = 5'd4;
    localparam decode_stop_x_read_mem = 5'd5;
    localparam decode_stop_x_mdr_to_out = 5'd6;
    localparam decode_stop_y_to_mar = 5'd7;
    localparam decode_stop_y_ind_wait_mem = 5'd8;
    localparam decode_stop_y_wait_mem = 5'd9;
    localparam decode_stop_y_ind_read_mem = 5'd10;
    localparam decode_stop_y_ind_mdr_to_mar = 5'd11;
    localparam decode_stop_y_read_mem = 5'd12;
    localparam decode_stop_y_mdr_to_out = 5'd13;
    localparam decode_stop_z_to_mar = 5'd14;
    localparam decode_stop_z_ind_wait_mem = 5'd15;
    localparam decode_stop_z_wait_mem = 5'd16;
    localparam decode_stop_z_ind_read_mem = 5'd17;
    localparam decode_stop_z_ind_mdr_to_mar = 5'd18;
    localparam decode_stop_z_read_mem = 5'd19;
    localparam decode_stop_z_mdr_to_out = 5'd20;

    localparam execute_do = 5'd0;

    localparam store_x_to_mar = 5'd0;
    localparam store_x_ind_wait_mem = 5'd1;
    localparam store_x_ind_read_mem = 5'd2;
    localparam store_x_ind_mdr_to_mar = 5'd3;
    localparam store_x_acc_to_mdr = 5'd4;
    localparam store_x_write_mem = 5'd5;
    localparam store_x_wait_mem = 5'd6;

    localparam finish_do = 5'd0;

    reg [2:0] state_next, state_reg;
    reg [4:0] substate_next, substate_reg;

    reg [DATA_WIDTH-1:0] out_next, out_reg;

    assign out = out_reg;
    
    wire [3:0] opcode = ir_out[15:12];
    wire x_ind = ir_out[11]; // 0 - dir, 1 - indir
    wire [2:0] x_addr = ir_out[10:8]; // adresa operanda
    wire y_ind = ir_out[7];
    wire [2:0] y_addr = ir_out[6:4];
    wire z_ind = ir_out[3];
    wire [2:0] z_addr = ir_out[2:0];

    // assign status = state_reg;

    always @(posedge clk, negedge rst_n) begin
        if (!rst_n) begin
            state_reg <= init;
            substate_reg <= init_do;
            out_reg <= {DATA_WIDTH{1'b0}};
        end 
        else begin
            state_reg <= state_next;
            substate_reg <= substate_next;
            out_reg <= out_next;
        end
    end

    always @(*) begin
        state_next = state_reg;
        substate_next = substate_reg;
        out_next = out_reg;

        {pc_cl, pc_ld, pc_inc, pc_dec, pc_sr, pc_ir, pc_sl, pc_il} = 8'b0;
        {sp_cl, sp_ld, sp_inc, sp_dec, sp_sr, sp_ir, sp_sl, sp_il} = 8'b0;
        {ir_cl, ir_ld, ir_inc, ir_dec, ir_sr, ir_ir, ir_sl, ir_il} = 8'b0;
        {mar_cl, mar_ld, mar_inc, mar_dec, mar_sr, mar_ir, mar_sl, mar_il} = 8'b0;
        {mdr_cl, mdr_ld, mdr_inc, mdr_dec, mdr_sr, mdr_ir, mdr_sl, mdr_il} = 8'b0;
        {a_cl, a_ld, a_inc, a_dec, a_sr, a_ir, a_sl, a_il} = 8'b0;

        we = 1'b0;
        data = {DATA_WIDTH{1'b0}};

        pc_in = pc;
        sp_in = sp;
        mar_in = addr;
        mdr_in = mdr_out;
        ir_in = ir_out;
        a_in  = a_out;

        alu_a = a_out;
        alu_b = mdr_out; 
        oc    = 3'b000;

        case (state_reg) 
            init: begin
                pc_in = 6'd8;
                pc_ld = 1'b1;

                sp_in = 6'd63;
                sp_ld = 1'b1;

                state_next = fetch;
                substate_next = fetch_load_mar;
            end
            
            fetch: begin
                case (substate_reg)
                    fetch_load_mar: begin
                        mar_in = pc;
                        mar_ld = 1'b1;
                        pc_inc = 1'b1;

                        substate_next = fetch_wait_mem;
                    end 
                    
                    fetch_wait_mem: begin
                        // cekamo sledeci takt da se adresa dovuce u memoriju
                        substate_next = fetch_read_mem;
                    end

                    fetch_read_mem: begin
                        mdr_in = mem;
                        mdr_ld = 1'b1;

                        substate_next = fetch_wait_mdr;
                    end
                    fetch_wait_mdr: begin
                        // cekamo sledeci takt da se podatak dovuce iz memorije
                        substate_next = fetch_load_ir;
                    end
               
                    fetch_load_ir: begin
                        ir_in = {16'b0, mdr_out};
                        ir_ld = 1'b1;

                        state_next = decode;
                        substate_next = 5'd0;
                    end
                endcase
            end

            decode: begin
                case (opcode)
                    MOV: begin
                        if ({z_ind, z_addr} == 4'b0000) begin
                            case (substate_reg)
                                decode_mov_load_mar: begin
                                    mar_in = {3'b000, y_addr};
                                    mar_ld = 1'b1;

                                    if (y_ind == 1'b1)
                                        substate_next = decode_mov_ind_wait_mem;
                                    else
                                        substate_next = decode_mov_wait_mem;
                                end
                                decode_mov_ind_wait_mem: begin
                                    // cekamo sledeci takt za memoriju
                                    substate_next = decode_mov_ind_read_mem;
                                end
                                decode_mov_ind_read_mem: begin
                                    mdr_in = mem;
                                    mdr_ld = 1'b1;

                                    substate_next = decode_mov_ind_mdr_to_mar;
                                end 
                                decode_mov_ind_mdr_to_mar: begin
                                    mar_in = mdr_out[5:0];
                                    mar_ld = 1'b1;

                                    substate_next = decode_mov_wait_mem;
                                end
                                decode_mov_wait_mem: begin
                                    // cekamo sledeci takt za memoriju
                                    substate_next = decode_mov_read_mem;
                                end
                                decode_mov_read_mem: begin
                                    mdr_in = mem;
                                    mdr_ld = 1'b1;

                                    substate_next = decode_mov_mdr_to_acc;
                                end
                                decode_mov_mdr_to_acc: begin
                                    // podatak cuvamo privremeno u acc, pre nego sto
                                    // ga upisemo na adresu X
                                    a_in = mdr_out;
                                    a_ld = 1'b1;

                                    state_next = writeback;
                                    substate_next = store_x_to_mar;
                                end
                            endcase 
                        end
                        else if ({z_ind, z_addr == 4'b1000}) begin
                            case (substate_reg)
                                decode_mov_imm_load_mar: begin
                                    mar_in = pc;
                                    mar_ld = 1'b1;
                                    pc_inc = 1'b1;

                                    substate_next = decode_mov_imm_wait_mem;
                                end
                                decode_mov_imm_wait_mem: begin
                                    // cekamo sledeci takt za memoriju
                                    substate_next = decode_mov_imm_read_mem;
                                end
                                decode_mov_imm_read_mem: begin
                                    mdr_in = mem;
                                    mdr_ld = 1'b1;

                                    substate_next = decode_mov_imm_to_acc;
                                end
                                decode_mov_imm_to_acc: begin
                                    // podatak cuvamo privremeno u acc, pre nego sto
                                    // ga upisemo na adresu X
                                    a_in = mdr_out;
                                    a_ld = 1'b1;

                                    state_next = writeback;
                                    substate_next = store_x_to_mar;
                                end
                            endcase
                        end
                        else begin
                            state_next = fetch;
                            substate_next = 5'd0;
                        end
                    end
                    ADD, SUB, MUL, DIV: begin
                        case (substate_reg)
                            decode_alu_y_to_mar: begin
                                mar_in = y_addr;
                                mar_ld = 1'b1;
                                if (y_ind == 1'b1)
                                    substate_next = decode_alu_y_ind_wait_mem;
                                else
                                    substate_next = decode_alu_y_wait_mem;

                            end 
                            decode_alu_y_ind_wait_mem: begin
                                // cekamo sledeci takt za memoriju
                                substate_next = decode_alu_y_ind_read_mem;
                            end
                            decode_alu_y_ind_read_mem: begin
                                mdr_in = mem;
                                mdr_ld = 1'b1;

                                substate_next = decode_alu_y_ind_mdr_to_mar;
                            end
                            decode_alu_y_ind_mdr_to_mar: begin
                                mar_in = mdr_out[5:0];
                                mar_ld = 1'b1;

                                substate_next = decode_alu_y_wait_mem;
                            end
                            decode_alu_y_wait_mem: begin
                                // cekamo sledeci takt za memoriju
                                substate_next = decode_alu_y_read_mem;
                            end
                            decode_alu_y_read_mem: begin
                                mdr_in = mem;
                                mdr_ld = 1'b1;

                                substate_next = decode_alu_y_mdr_to_acc;
                            end
                            decode_alu_y_mdr_to_acc: begin
                                a_in = mdr_out;
                                a_ld = 1'b1;

                                substate_next = decode_alu_z_to_mar;
                            end
                            decode_alu_z_to_mar: begin
                                mar_in = z_addr;
                                mar_ld = 1'b1;
                                if (z_ind == 1'b1)
                                    substate_next = decode_alu_z_ind_wait_mem;
                                else
                                    substate_next = decode_alu_z_wait_mem; 
                            end 
                            decode_alu_z_ind_wait_mem: begin
                                // cekamo sledeci takt za memoriju
                                substate_next = decode_alu_z_ind_read_mem;
                            end
                            decode_alu_z_ind_read_mem: begin
                                mdr_in = mem;
                                mdr_ld = 1'b1;

                                substate_next = decode_alu_z_ind_mdr_to_mar;
                            end
                            decode_alu_z_ind_mdr_to_mar: begin
                                mar_in = mdr_out[5:0];
                                mar_ld = 1'b1;

                                substate_next = decode_alu_z_wait_mem;
                            end
                            decode_alu_z_wait_mem: begin
                                // cekamo sledeci takt za memoriju
                                substate_next = decode_alu_z_read_mem;
                            end
                            decode_alu_z_read_mem: begin
                                mdr_in = mem;
                                mdr_ld = 1'b1;

                                substate_next = decode_alu_z_wait_2_mem;
                            end
                            decode_alu_z_wait_2_mem: begin
                                
                                state_next = execute;
                                substate_next = execute_do;
                            end
                        endcase
                    end
                    BEQ: begin
                        case (substate_reg)

                            decode_beq_operand_to_mar: begin
                                mar_in = {x_ind, x_addr};
                                mar_ld = 1'b1;

                                substate_next = decode_beq_wait_mem;
                            end
                            decode_beq_wait_mem:
                                substate_next = decode_beq_read_mem;

                            decode_beq_read_mem: begin
                                mdr_in = mem;
                                mdr_ld = 1'b1;

                                if ({x_ind, x_addr} == 4'b0000) begin
                                    substate_next = decode_beq_compare_zero;
                                end
                                else
                                    substate_next = decode_beq_mdr_to_acc;
                            end

                            decode_beq_compare_zero: begin
                                if (mdr_out == 16'd0) begin
                                    if ({z_ind, z_addr} == 4'b1000)
                                        substate_next = decode_beq_read_next_word;
                                    else begin
                                        state_next = fetch;
                                        substate_next = fetch_load_mar;
                                    end
                                end 
                                else begin
                                    state_next = fetch;
                                    substate_next = fetch_load_mar;
                                end
                            end
                            decode_beq_mdr_to_acc: begin
                                a_in = mdr_out;
                                a_ld = 1'b1;

                                substate_next = decode_beq_y_to_mar;
                            end
                            decode_beq_y_to_mar: begin
                                mar_in = {y_ind, y_addr};
                                mar_ld = 1'b1;
                                substate_next = decode_beq_wait_y_mem;
                            end
                            decode_beq_wait_y_mem:
                                substate_next = decode_beq_read_y_mem;

                            decode_beq_read_y_mem: begin
                                mdr_in = mem;
                                mdr_ld = 1'b1;

                                if ({y_ind, y_addr} == 4'b0000) begin
                                    substate_next = decode_beq_compare_zero;    
                                end
                                substate_next = decode_beq_compare_2;
                            end
                            decode_beq_compare_2: begin
                                if (a_out == mdr_out) begin
                                    if ({z_ind,z_addr} == 4'b1000)
                                        substate_next = decode_beq_read_next_word;
                                    else begin
                                        state_next = fetch;
                                        substate_next = fetch_load_mar;
                                    end
                                end 
                                else begin
                                    state_next = fetch;
                                    substate_next = fetch_load_mar;
                                end
                            end
                            decode_beq_read_next_word: begin
                                mar_in = pc;
                                mar_ld = 1'b1;
                                pc_inc = 1'b1;

                                substate_next = decode_beq_wait_next_word_mem;
                            end
                            decode_beq_wait_next_word_mem:
                                substate_next = decode_beq_read_next_word_mem;

                            decode_beq_read_next_word_mem: begin
                                mdr_in = mem;
                                mdr_ld = 1'b1;

                                substate_next = decode_beq_jump;
                            end
                            decode_beq_jump: begin
                                pc_in = mdr_out[5:0];
                                pc_ld = 1'b1;

                                state_next = fetch;
                                substate_next = fetch_load_mar;
                            end
                        endcase
                    end
                    JSR: begin
                        case(substate_reg)
                            decode_jsr_addr_to_acc: begin
                                a_in = {y_addr[1:0], z_ind, z_addr};
                                a_ld = 1'b1;

                                substate_next = decode_jsr_sp_to_mar;
                            end
                            decode_jsr_sp_to_mar: begin
                                mar_in = sp;
                                mar_ld = 1'b1;

                                substate_next = decode_jsr_pc_to_mdr;
                            end
                            decode_jsr_pc_to_mdr: begin
                                mdr_in = {10'b0, pc};
                                mdr_ld = 1'b1;

                                substate_next = decode_jsr_store_mem;
                            end
                            decode_jsr_store_mem: begin
                                we = 1'b1;
                                data = mdr_out;

                                substate_next = decode_jsr_wait_mem;
                            end
                            decode_jsr_wait_mem: 
                                substate_next = decode_jsr_update_sp;
                            
                            decode_jsr_update_sp: begin
                                sp_dec = 1'b1;

                                substate_next = decode_jsr_update_pc;
                            end
                            decode_jsr_update_pc: begin
                                pc_in = a_out;
                                pc_ld = 1'b1;

                                state_next = fetch;
                                substate_next = fetch_load_mar;
                            end
                        endcase
                    end
                    RTS: begin
                        case(substate_reg)
                            decode_rts_find_sp: begin
                                sp_inc = 1'b1;

                                substate_next = decode_rts_sp_to_mar;
                            end
                            decode_rts_sp_to_mar: begin
                                mar_in = sp;
                                mar_ld = 1'b1;

                                substate_next = decode_rts_wait_mem;
                            end
                            decode_rts_wait_mem:
                                substate_next = decode_rts_read_mem;

                            decode_rts_read_mem: begin
                                mdr_in = mem;
                                mdr_ld = 1'b1;

                                substate_next = decode_rts_wait_mdr;
                            end
                            decode_rts_wait_mdr:
                                substate_next = decode_rts_mdr_to_pc;

                            decode_rts_mdr_to_pc: begin
                                pc_in = mdr_out[5:0];
                                pc_ld = 1'b1;

                                substate_next = decode_rts_return_to_fetch;
                            end
                            decode_rts_return_to_fetch: begin
                                state_next = fetch;
                                substate_next = fetch_load_mar;
                            end
                        endcase
                    end
                    IN: begin
                        case (substate_reg)
                            decode_in_load_acc: begin
                                status = 1'b1; // CPU je spreman za ucitavanje podatka
                                if (control == 1'b1) begin
                                    a_in = in;
                                    a_ld = 1'b1;

                                    state_next = writeback;
                                    substate_next = store_x_to_mar; 
                                end
                                else begin
                                    // vrtimo se u ovom stanju, jer je blokirajuca instrukcija
                                    substate_next = decode_in_load_acc;
                                end 
                            end
                        endcase
                    end
                    OUT: begin
                        case (substate_reg)
                            decode_out_x_to_mar: begin
                                mar_in = x_addr;
                                mar_ld = 1'b1;

                                if (x_ind == 1'b1)
                                    substate_next = decode_out_x_ind_wait_mem;
                                else
                                    substate_next = decode_out_x_wait_mem;
                            end
                            decode_out_x_ind_wait_mem: begin
                                // cekamo sledeci takt
                                substate_next = decode_out_x_ind_read_mem;
                            end
                            decode_out_x_ind_read_mem: begin
                                mdr_in = mem;
                                mdr_ld = 1'b1;

                                substate_next = decode_out_x_ind_mdr_to_mar;
                            end 
                            decode_out_x_ind_mdr_to_mar: begin
                                mar_in = mdr_out[5:0];
                                mar_ld = 1'b1;

                                substate_next = decode_out_x_wait_mem;
                            end
                            decode_out_x_wait_mem: begin
                                // cekamo sledeci takt
                                substate_next = decode_out_x_read_mem;
                            end                            
                            decode_out_x_read_mem: begin
                                mdr_in = mem;
                                mdr_ld = 1'b1;

                                substate_next = decode_out_x_wait_mdr;
                            end
                            decode_out_x_wait_mdr: begin
                                // cekamo sledeci takt
                                substate_next = decode_out_x_mdr_to_out;
                            end
                            decode_out_x_mdr_to_out: begin
                                out_next = mdr_out;

                                state_next = fetch;
                                substate_next = fetch_load_mar;
                            end
                        endcase
                    end
                    STOP: begin
                        case (substate_reg)
                            decode_stop_x_to_mar: begin
                                mar_in = x_addr;
                                mar_ld = 1'b1;

                                if (x_ind == 1'b1) 
                                    substate_next = decode_stop_x_ind_wait_mem;
                                else if (x_addr != 3'b000)
                                    substate_next = decode_stop_x_wait_mem;
                                else 
                                    substate_next = decode_stop_y_to_mar;
                            end
                            decode_stop_x_ind_wait_mem: begin
                                // cekamo sledeci takt
                                substate_next = decode_stop_x_ind_read_mem;
                            end
                            decode_stop_x_ind_read_mem: begin
                                mdr_in = mem;
                                mdr_ld = 1'b1;

                                substate_next = decode_stop_x_ind_mdr_to_mar;
                            end
                            decode_stop_x_ind_mdr_to_mar: begin
                                mar_in = mdr_out[5:0];
                                mar_ld = 1'b1;

                                substate_next = decode_stop_x_wait_mem;
                            end
                            decode_stop_x_wait_mem: begin
                                // cekamo sledeci takt
                                substate_next = decode_stop_x_read_mem;
                            end
                            decode_stop_x_read_mem: begin
                                mdr_in = mem;
                                mdr_ld = 1'b1;

                                substate_next = decode_stop_x_mdr_to_out;
                            end
                            decode_stop_x_mdr_to_out: begin
                                out_next = mdr_out;

                                substate_next = decode_stop_y_to_mar;
                            end
                            decode_stop_y_to_mar: begin
                                mar_in = y_addr;
                                mar_ld = 1'b1;

                                if (y_ind == 1'b1) 
                                    substate_next = decode_stop_y_ind_wait_mem;
                                else if (y_addr != 3'b000)
                                    substate_next = decode_stop_y_wait_mem;
                                else 
                                    substate_next = decode_stop_z_to_mar;
                            end
                            decode_stop_y_ind_wait_mem: begin
                                // cekamo sledeci takt
                                substate_next = decode_stop_y_ind_read_mem;
                            end
                            decode_stop_y_ind_read_mem: begin
                                mdr_in = mem;
                                mdr_ld = 1'b1;

                                substate_next = decode_stop_y_ind_mdr_to_mar;
                            end
                            decode_stop_y_ind_mdr_to_mar: begin
                                mar_in = mdr_out[5:0];
                                mar_ld = 1'b1;

                                substate_next = decode_stop_y_wait_mem;
                            end
                            decode_stop_y_wait_mem: begin
                                // cekamo sledeci takt
                                substate_next = decode_stop_y_read_mem;
                            end
                            decode_stop_y_read_mem: begin
                                mdr_in = mem;
                                mdr_ld = 1'b1;

                                substate_next = decode_stop_y_mdr_to_out;
                            end
                            decode_stop_y_mdr_to_out: begin
                                out_next = mdr_out;

                                substate_next = decode_stop_z_to_mar;
                            end
                            decode_stop_z_to_mar: begin
                                mar_in = z_addr;
                                mar_ld = 1'b1;

                                if (z_ind == 1'b1) 
                                    substate_next = decode_stop_z_ind_wait_mem;
                                else if (z_addr != 3'b000)
                                    substate_next = decode_stop_z_wait_mem;
                                else begin
                                    state_next = finish;
                                    substate_next = finish_do;
                                end
                            end
                            decode_stop_z_ind_wait_mem: begin
                                // cekamo sledeci takt
                                substate_next = decode_stop_z_ind_read_mem;
                            end
                            decode_stop_z_ind_read_mem: begin
                                mdr_in = mem;
                                mdr_ld = 1'b1;

                                substate_next = decode_stop_z_ind_mdr_to_mar;
                            end
                            decode_stop_z_ind_mdr_to_mar: begin
                                mar_in = mdr_out[5:0];
                                mar_ld = 1'b1;

                                substate_next = decode_stop_z_wait_mem;
                            end
                            decode_stop_z_wait_mem: begin
                                // cekamo sledeci takt
                                substate_next = decode_stop_z_read_mem;
                            end
                            decode_stop_z_read_mem: begin
                                mdr_in = mem;
                                mdr_ld = 1'b1;

                                substate_next = decode_stop_z_mdr_to_out;
                            end
                            decode_stop_z_mdr_to_out: begin
                                out_next = mdr_out;

                                state_next = finish;
                                substate_next = finish_do;
                            end
                        endcase
                    end
                endcase
            end

            execute: begin
                case (substate_reg)
                    execute_do: begin 
                        case (opcode)
                            ADD: oc = 3'b000;
                            SUB: oc = 3'b001;
                            MUL: oc = 3'b010;
                            DIV: oc = 3'b011;
                        endcase
                        a_in = alu_f;
                        a_ld = 1'b1;

                        state_next = writeback;
                        substate_next = store_x_to_mar;
                    end 
                endcase
            end

            writeback: begin
                case (substate_reg)
                    store_x_to_mar: begin
                        mar_in = x_addr;
                        mar_ld = 1'b1;

                        if (x_ind == 1'b1) 
                            substate_next = store_x_ind_wait_mem; 
                        else 
                            substate_next = store_x_acc_to_mdr;
                    end
                    store_x_ind_wait_mem: begin
                        // cekamo sledeci takt
                        substate_next = store_x_ind_read_mem;
                    end
                    store_x_ind_read_mem: begin
                        mdr_in = mem;
                        mdr_ld = 1'b1;

                        substate_next = store_x_ind_mdr_to_mar;
                    end 
                    store_x_ind_mdr_to_mar: begin
                        // izvlacimo adresu u kojoj ce se upsivati vrednost u memoriji
                        mar_in = mdr_out[5:0];
                        mar_ld = 1'b1;

                        substate_next = store_x_acc_to_mdr;
                    end
                    store_x_acc_to_mdr: begin
                        mdr_in = a_out;
                        mdr_ld = 1'b1;

                        substate_next = store_x_write_mem;
                    end
                    store_x_write_mem: begin
                        we = 1'b1;
                        data = mdr_out;

                        substate_next = store_x_wait_mem;
                    end
                    store_x_wait_mem: begin
                        state_next = fetch;
                        substate_next = fetch_load_mar;
                    end
                endcase 
            end

            finish: begin
                case (substate_reg)
                    finish_do:  begin
                       state_next = finish;
                       substate_next = finish_do; 
                    end
                endcase
            end
        endcase    
    end
endmodule