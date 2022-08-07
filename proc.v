//Adapted from riscv-defines @ pulp
`define OPCODE_OP 7'h33 //Done
`define OPCODE_OPIMM 7'h13 //Done
`define OPCODE_STORE 7'h23
`define OPCODE_LOAD 7'h03
`define OPCODE_BRANCH 7'h63
`define OPCODE_JALR 7'h67
`define OPCODE_JAL 7'h6f
`define OPCODE_AUIPC 7'h17
`define OPCODE_LUI 7'h37
`define OPCODE_CSRRS 7'h73

module proc
    #(parameter CORE_ID = 32'd0)
    (
	input clk,
	input res,
	input [31 : 0] instr_read_in,
	input instr_gnt,
	input instr_r_valid,
	input [31 : 0] data_read,
	input data_gnt,
	input data_r_valid,
	input irq,
	input [4 : 0] irq_id,
	
	output [31 : 0] instr_adr,
	output instr_req,
    output [31 : 0] data_write,
	output [31 : 0] data_adr,
	output data_req,
	output data_write_enable,
	//output [3 : 0] data_be,
	output irq_ack,
	output [4 : 0] irq_ack_id
);

	//-----Wires & Registers-----

	//PC
	wire PCSrc;
	wire pc_enable;
	wire [31 : 0] Jmp_adr; // Normal Branch
	wire [31 : 0] irq_adr; // Interrupt routine vector address
	wire [31 : 0] ret_adr; // Backup register address
	wire [31 : 0] j_adr_1; // MUX1 output
	wire irq_addr_sel;     // MUX1 selection
	wire [31 : 0] j_adr_2; // MUX2 output
	wire mret_sel;         // MUX2 selection
	wire bckup_reg; // Control signal for Backup register
	wire reg_pc_select; 
	wire irq_pc_mode;

	//Instruction memory
	wire [31 : 0] instr_read;
	wire [31 : 0] instr_reg;

	//Control Unit
	wire [6 : 0] Opcode;
	wire Branch;
	wire MemtoReg;
	wire ALUSrc1; //For Reg/PC to ALU_A
	wire ALUSrc2; //For Reg/Imm to ALU_B
	wire ALUSrc1_5; // for zero
	wire ALUSrc2_5; // for 4
	wire RegWrite;
	//wire instr_pipeline; // for selecting pipelined instruction in Load / Store instructions 
	wire irq_context; // Input from CU
	wire irq_status_update; // input from CU
	reg irq_status_reg; // Output to CU
	reg [4 : 0] irq_ack_id_reg; // Output to CU

	//Register Set
	wire [4 : 0] Read_register_1;
	wire [4 : 0] Read_register_2;
	wire [4 : 0] Write_register;
	wire [31 : 0] Write_data;
	wire [31 : 0]Read_data_1;
	wire [31 : 0] Read_data_2;

	//Immediate Generation
	reg [31 : 0] imm_gen_output;
	wire [31 : 0] imm_gen_output_lshifted;

	//ALU
	wire[4 : 0] ALU_control;
	wire [31 : 0] ALU_A;
	wire [31 : 0] ALU_A_1; // for additional 0
	wire [31 : 0] ALU_B;
	wire [31 : 0] ALU_B_1; // for additional 4
	wire [31 : 0] ALU_result;
	wire Zero;

	//-----Wire Assignments-----

	//PC
	assign PCSrc = (Branch & Zero) | irq_pc_mode; // Branch ORed due to Interrupt case
	assign irq_adr = (irq_id << 2) + 32'h1C00_8000; 

	//Control Unit
	assign Opcode = instr_read[6 : 0]; //One input to CU 

	//Register Set
	assign Read_register_1 = instr_read[19 : 15];
	assign Read_register_2 = instr_read[24 : 20];
	assign Write_register = instr_read[11 : 7];

	//Immediate Generation
	//assign imm_gen_output_lshifted = imm_gen_output; //<< 1'd1 removed as multiplying 2 does not work for branch ; 
	
	//Interrupt
	assign irq_ack_id = irq_ack_id_reg;

	//-----Component definitions-----

	//PC
	MUX_2x1_32 JMP_ADR_SELECT(.I0(instr_adr + imm_gen_output), .I1(Read_data_1 + imm_gen_output), .S(reg_pc_select), .Y(Jmp_adr)); //CHECKED
	REG_DRE_32 Instruction_Backup_Reg(.D(instr_adr), .Q(ret_adr), .CLK(clk), .RES(res), .ENABLE(bckup_reg));
	MUX_2x1_32 Instruction_Select_1(.I0(Jmp_adr), .I1(irq_adr), .S(irq_addr_sel), .Y(j_adr_1));
	MUX_2x1_32 Instruction_Select_2(.I0(j_adr_1), .I1(ret_adr), .S(mret_sel), .Y(j_adr_2));
	pc PC(.CLK(clk), .RES(res), .ENABLE(pc_enable), .MODE(PCSrc), .D(j_adr_2), .PC_OUT(instr_adr)); //CHECKED

	//Instruction Memory (TODO: Instantiation)
	//Not a part of processor so only need to use outside ports for input and output
	// Pipeline try
	REG_DRE_32 INSTR_PIPELINE_REG(.D(instr_read_in), .Q(instr_read), .CLK(clk), .RES(res), .ENABLE(instr_r_valid));
	//MUX_2x1_32 INSTR_PIPELINE_MUX(.I0(instr_read_in), .I1(instr_reg), .S(instr_reg_mux), .Y(instr_read));

	//Control unit (TODO: Instantiation)

	always @(posedge clk, posedge res)
	begin
	    if(res == 1'b1)            // reset
        begin
            irq_status_reg <= 1'b0;
        end
		else if(irq_status_update)
		begin
        	irq_status_reg <= irq_context;
        end
	end

	always @(posedge clk, posedge res)
	begin
	    if(res == 1'b1)            // reset
        begin
            irq_ack_id_reg <= 5'b00000;
        end
        else if(irq_status_update)
        begin
        	irq_ack_id_reg <= irq_id;
        end
	end

	ctrl CU(.RES(res), .CLK(clk), .opcode(Opcode), .MODE(Branch), 
			.instr_req(instr_req), .instr_gnt(instr_gnt), .instr_r_valid(instr_r_valid),
			.write_enable(RegWrite), .ALUSrcMux1(ALUSrc1), .ALUSrcMux1_S(ALUSrc1_5), .ALUSrcMux2(ALUSrc2), 
			.ALUSrcMux2_S(ALUSrc2_5), .reg_pc_select(reg_pc_select),
			.alu_dm_select(MemtoReg),
			.data_write_enable(data_write_enable), .data_req(data_req), .data_gnt(data_gnt),
			.data_r_valid(data_r_valid), .bckup_reg(bckup_reg),
			.irq_addr_sel(irq_addr_sel), .mret_sel(mret_sel), .irq(irq), .irq_ack(irq_ack), .irq_context(irq_context), .irq_status(irq_status_reg),
			.irq_status_update(irq_status_update),.pc_enable(pc_enable),
			.irq_pc_mode(irq_pc_mode)); //CHECKED

	//Register Set
	//wire [31 : 0] write_addr_reg_wire;
	//REG_DRE_32 write_addr_reg(.D(Write_register), .Q(write_addr_reg_wire), .CLK(clk), .RES(res), .ENABLE(~res)); //TEMP
	regset #(.CORE_ID(CORE_ID)) Register_Set(.D(Write_data), .A_D(Write_register), .A_Q0(Read_register_1), .A_Q1(Read_register_2), // TEMP
	                    .write_enable(RegWrite), .RES(res), .CLK(clk), .Q0(Read_data_1), .Q1(Read_data_2)); //CHECKED

	//Immediate Generator
	always @(instr_read)
	begin
	   imm_gen_output <= 32'd0;
	   
		casez(instr_read[6 : 0])
			`OPCODE_OPIMM, `OPCODE_CSRRS: imm_gen_output <= { {20{instr_read[31]}}, instr_read[31 : 20] }; //CHECKED
			`OPCODE_STORE: imm_gen_output <= { {20{instr_read[31]}}, instr_read[31 : 25], instr_read[11 : 7] }; //CHECKED
			`OPCODE_LOAD: imm_gen_output <= { {20{instr_read[31]}}, instr_read[31 : 20] }; //CHECKED
			`OPCODE_BRANCH: imm_gen_output <= { {19{instr_read[31]}} ,instr_read[31], instr_read[7], instr_read[30 : 25], instr_read[11 : 8], 1'b0}; //CHECKED
			`OPCODE_JALR: imm_gen_output <= { {20{instr_read[31]}}, instr_read[31 : 20] }; //CHECKED
			`OPCODE_JAL: imm_gen_output <= { {11{instr_read[31]}}, instr_read[31], instr_read[19 : 12], instr_read[20], instr_read[30 : 21], 1'b0}; //CHECKED
			`OPCODE_AUIPC: imm_gen_output <= {instr_read[31 : 12], {12{1'b0}} }; //CHECKED
			`OPCODE_LUI: imm_gen_output <= {instr_read[31 : 12], {12{1'b0}} }; //CHECKED

			default: imm_gen_output <= 32'd0; //CHECKED

		endcase
	end
	

	//ALU 
	MUX_2x1_32 MUX_ALU_1(.I0(Read_data_1), .I1(instr_adr), .S(ALUSrc1), .Y(ALU_A_1)); //CHECKED
	MUX_2x1_32 MUX_ALU_1_5(.I0(ALU_A_1), .I1(32'd0), .S(ALUSrc1_5), .Y(ALU_A));
	
	MUX_2x1_32 MUX_ALU_2(.I0(Read_data_2), .I1(imm_gen_output), .S(ALUSrc2), .Y(ALU_B_1)); //CHECKED
	MUX_2x1_32 MUX_ALU_2_5(.I0(ALU_B_1), .I1(32'd4), .S(ALUSrc2_5), .Y(ALU_B));
	
	alu_ctrl alu_ctrl(.Instr(instr_read), .AluOp(ALU_control));
	alu ALU(.S(ALU_control), .A(ALU_A), .B(ALU_B), .CMP(Zero), .Q(ALU_result)); //CHECKED
	

	//Data Memory //Checked for now
	//Not a part of processor so only need to use outside ports for input and output
	assign data_adr = ALU_result;
	assign data_write = Read_data_2;
	//wire [31 : 0] alureg;
	//wire [31 : 0] alures;
	//REG_DRE_32 alu_reg_write_back(.D(ALU_result), .Q(alureg), .CLK(clk), .RES(res), .ENABLE(~res)); 
	//MUX_2x1_32 MUX_INSTR_PIPELINE(.I0(ALU_result), .I1(alureg), .S(instr_pipeline), .Y(alures));
	MUX_2x1_32 MUX_DATA(.I0(ALU_result), .I1(data_read), .S(MemtoReg), .Y(Write_data)); //Checked

endmodule