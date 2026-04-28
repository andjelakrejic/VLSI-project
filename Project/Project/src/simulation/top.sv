/*
vdel -lib work -all
vlib work
vmap work work

vlog -sv -coveropt 3 +cover +acc register.v top.sv
vsim -coverage work.testbench_uvm -c -do "run -all; coverage save -directive -codeAll register_cov.ucdb; quit"
vcover report -html register_cov.ucdb
*/

`include "uvm_macros.svh"
import uvm_pkg::*;

class register_item extends uvm_sequence_item;

    rand bit ld;
    rand bit cl;
    rand bit inc;
    rand bit dec;
    rand bit sr;
    rand bit ir;
    rand bit sl;
    rand bit il;
    rand bit [15:0] in;
    bit [15:0] out;

    `uvm_object_utils_begin(register_item)
        `uvm_field_int(ld, UVM_DEFAULT)
        `uvm_field_int(cl, UVM_DEFAULT)
        `uvm_field_int(inc, UVM_DEFAULT)
        `uvm_field_int(dec, UVM_DEFAULT)
        `uvm_field_int(sr, UVM_DEFAULT)
        `uvm_field_int(ir, UVM_DEFAULT)
        `uvm_field_int(sl, UVM_DEFAULT)
        `uvm_field_int(il, UVM_DEFAULT)
        `uvm_field_int(in, UVM_ALL_ON)
        `uvm_field_int(out, UVM_NOPRINT)
    `uvm_object_utils_end

    function new(string name = "register_item");
		super.new(name);
    endfunction //new()

    virtual function string my_print();
        return $sformatf(
            "ld = %1b cl = %1b inc = %1b dec = %1b sr = %1b ir = %1b sl = %1b il = %1b in = %16b out = %16b",
            ld,cl,inc,dec,sr,ir,sl,il,in,out
        );
        
    endfunction

endclass //register_item extends uvm_sequence_item\

class generator extends uvm_sequence;

	`uvm_object_utils(generator)
	
	function new(string name = "generator");
		super.new(name);
	endfunction
	
	int num = 20;
	
	virtual task body();
		for (int i = 0; i < 256; i++)begin
			register_item item = register_item::type_id::create($sformatf("exh_item%0d",i));
			start_item(item);
			item.cl 	= i[7];
			item.ld 	= i[6];
			item.inc 	= i[5];
			item.dec	= i[4];
			item.sr		= i[3];
			item.sl		= i[2];
			item.ir		= i[1];
			item.il		= i[0];
			item.randomize();
			`uvm_info("Generator",
          $sformatf("i %0d: %s", i, item.my_print()),
          UVM_LOW)
			finish_item(item);
		end

		for (int i = 0; i < num; i++) begin
			register_item item = register_item::type_id::create("item");
			start_item(item);
			item.randomize();
			`uvm_info("Generator", $sformatf("Item %0d/%0d created", i + 1, num), UVM_LOW)
			item.print();
			finish_item(item);
		end
	endtask
	
endclass

class driver extends uvm_driver #(register_item);
	
	`uvm_component_utils(driver)
	
	function new(string name = "driver", uvm_component parent = null);
		super.new(name, parent);
	endfunction
	
	virtual register_if vif;
	
	virtual function void build_phase(uvm_phase phase);
		super.build_phase(phase);
		if (!uvm_config_db#(virtual register_if)::get(this, "", "register_vif", vif))
			`uvm_fatal("Driver", "No interface.")
	endfunction
	
	virtual task run_phase(uvm_phase phase);
		super.run_phase(phase);
		forever begin
			register_item item;
			seq_item_port.get_next_item(item);
			`uvm_info("Driver", $sformatf("%s", item.my_print()), UVM_LOW)
            vif.cl <= item.cl;
			vif.ld <= item.ld;
			vif.inc <= item.inc;
            vif.dec <= item.dec;
            vif.sr <= item.sr;
            vif.ir <= item.ir;
            vif.sl <= item.sl;
            vif.il <= item.il;
			vif.in <= item.in;
			@(posedge vif.clk);
			seq_item_port.item_done();
		end
	endtask
	
endclass

class monitor extends uvm_monitor;
	
	`uvm_component_utils(monitor)
	
	function new(string name = "monitor", uvm_component parent = null);
		super.new(name, parent);
	endfunction
	
	virtual register_if vif;
	uvm_analysis_port #(register_item) mon_analysis_port;
	
	virtual function void build_phase(uvm_phase phase);
		super.build_phase(phase);
		if (!uvm_config_db#(virtual register_if)::get(this, "", "register_vif", vif))
			`uvm_fatal("Monitor", "No interface.")
		mon_analysis_port = new("mon_analysis_port", this);
	endfunction
	
	virtual task run_phase(uvm_phase phase);	
		super.run_phase(phase);
		@(posedge vif.clk);
		forever begin
			register_item item = register_item::type_id::create("item");
			@(posedge vif.clk);
			item.cl = vif.cl;
			item.ld = vif.ld;
			item.inc = vif.inc;
			item.dec = vif.dec;
			item.sr = vif.sr;
			item.ir = vif.ir;
			item.sl = vif.sl;
			item.il = vif.il;
			item.in = vif.in;
			item.out = vif.out;
			`uvm_info("Monitor", $sformatf("%s", item.my_print()), UVM_LOW)
			mon_analysis_port.write(item);
		end
	endtask
	
endclass

class agent extends uvm_agent;
	
	`uvm_component_utils(agent)
	
	function new(string name = "agent", uvm_component parent = null);
		super.new(name, parent);
	endfunction
	
	driver d0;
	monitor m0;
	uvm_sequencer #(register_item) s0;
	
	virtual function void build_phase(uvm_phase phase);
		super.build_phase(phase);
		d0 = driver::type_id::create("d0", this);
		m0 = monitor::type_id::create("m0", this);
		s0 = uvm_sequencer#(register_item)::type_id::create("s0", this);
	endfunction
	
	virtual function void connect_phase(uvm_phase phase);
		super.connect_phase(phase);
		d0.seq_item_port.connect(s0.seq_item_export);
	endfunction
	
endclass

class scoreboard extends uvm_scoreboard;
	
	`uvm_component_utils(scoreboard)
	
	function new(string name = "scoreboard", uvm_component parent = null);
		super.new(name, parent);
	endfunction
	
	uvm_analysis_imp #(register_item, scoreboard) mon_analysis_imp;
	
	virtual function void build_phase(uvm_phase phase);
		super.build_phase(phase);
		mon_analysis_imp = new("mon_analysis_imp", this);
	endfunction
	
	bit [15:0] register = 16'h0000;
	
	virtual function write(register_item item);
		if (register == item.out)
			`uvm_info("Scoreboard", $sformatf("PASS!"), UVM_LOW)
		else
			`uvm_error("Scoreboard", $sformatf("FAIL! expected = %16b, got = %16b", register, item.out))

        if(item.cl)
            register = 16'h0000;
		else if (item.ld)
			register = item.in;
		else if (item.inc)
			register = register + 16'h0001;
		else if (item.dec)
			register = register - 16'h0001;
		else if (item.sr)
			register = {item.ir,register[15:1]};
		else if (item.sl)
			register = {register[14:0],item.il};
	endfunction
	
endclass

class env extends uvm_env;
	
	`uvm_component_utils(env)
	
	function new(string name = "env", uvm_component parent = null);
		super.new(name, parent);
	endfunction
	
	agent a0;
	scoreboard sb0;
	
	virtual function void build_phase(uvm_phase phase);
		super.build_phase(phase);
		a0 = agent::type_id::create("a0", this);
		sb0 = scoreboard::type_id::create("sb0", this);
	endfunction
	
	virtual function void connect_phase(uvm_phase phase);
		super.connect_phase(phase);
		a0.m0.mon_analysis_port.connect(sb0.mon_analysis_imp);
	endfunction
	
endclass

class test extends uvm_test;

	`uvm_component_utils(test)
	
	function new(string name = "test", uvm_component parent = null);
		super.new(name, parent);
	endfunction
	
	virtual register_if vif;

	env e0;
	generator g0;
	
	virtual function void build_phase(uvm_phase phase);
		super.build_phase(phase);
		if (!uvm_config_db#(virtual register_if)::get(this, "", "register_vif", vif))
			`uvm_fatal("Test", "No interface.")
		e0 = env::type_id::create("e0", this);
		g0 = generator::type_id::create("g0");
	endfunction
	
	virtual function void end_of_elaboration_phase(uvm_phase phase);
		uvm_top.print_topology();
	endfunction
	
	virtual task run_phase(uvm_phase phase);
		phase.raise_objection(this);
		
		vif.rst_n <= 0;
		#20 vif.rst_n <= 1;
		
		g0.start(e0.a0.s0);
		phase.drop_objection(this);
	endtask

endclass

interface register_if (
	input bit clk
);

	logic rst_n;
	logic ld;
	logic cl;
    logic inc;
    logic dec;
	logic ir;
	logic sr;
	logic sl;
	logic il;
    logic [15:0] in;
    logic [15:0] out;

endinterface

module testbench_uvm;

	reg clk;
	
	register_if dut_if (
		.clk(clk)
	);
	
	register dut (
		.clk(clk),
		.rst_n(dut_if.rst_n),
        .cl(dut_if.cl),
		.ld(dut_if.ld),
		.inc(dut_if.inc),
		.dec(dut_if.dec),
		.sr(dut_if.sr),
		.ir(dut_if.ir),
		.sl(dut_if.sl),
		.il(dut_if.il),
		.in(dut_if.in),
		.out(dut_if.out)
	);

	initial begin
		clk = 0;
		forever begin
			#10 clk = ~clk;
		end
	end

	initial begin
		uvm_config_db#(virtual register_if)::set(null, "*", "register_vif", dut_if);
		run_test("test");
	end

endmodule