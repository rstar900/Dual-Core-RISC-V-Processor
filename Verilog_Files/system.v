`timescale 1ns / 1ps

module system(
    input BOARD_CLK,
    input BOARD_RESN,
    input [3 : 0] BOARD_BUTTON,
    input [3 : 0] BOARD_SWITCH,
    input BOARD_UART_RX,
    
    output [3 : 0] BOARD_LED,
    output [2 : 0] BOARD_LED_RGB0,
    output [2 : 0] BOARD_LED_RGB1,
    output BOARD_VGA_HSYNC,
    output BOARD_VGA_VSYNC,
    output [3 : 0] BOARD_VGA_R,
    output [3 : 0] BOARD_VGA_G,
    output [3 : 0] BOARD_VGA_B,
    output BOARD_UART_TX
);

    wire CLK;
    wire RES;
    wire CACHE_RESET;
    
    reg [3 : 0] button_array;
    
    // reg test
    reg clk;
   
    wire data_gnt;    
    wire data_r_valid;
    
    wire data_gnt_c1;    
    wire data_r_valid_c1;
        
    wire data_gnt_c2;    
    wire data_r_valid_c2;
    
    wire [31 : 0] data_write;
    wire [31 : 0] data_adr;
    wire data_req;
    wire data_write_enable;
    wire [3 : 0] data_be;
    wire [31 : 0] data_read;
    
    wire [31:0] data_read_c1;
    wire [31:0] data_adr_c1;
    wire data_req_c1;
    wire [31 : 0] data_write_c1;
    wire data_write_enable_c1;
    
    wire [31:0] data_read_c2;
    wire [31:0] data_adr_c2;
    wire data_req_c2;
    wire [31 : 0] data_write_c2;
    wire data_write_enable_c2;
    
    // instruction signals from instruction mem
   	wire [31 : 0] instr_read;
    wire instr_gnt;
    wire instr_r_valid;
	wire [31 : 0] instr_adr;
    wire instr_req;
    
    // instruction signals sent to c1
   	wire [31 : 0] instr_read_c1;
    wire instr_gnt_c1;
    wire instr_r_valid_c1;
    wire [31 : 0] instr_adr_c1;
    wire instr_req_c1;
    
    // instruction signals sent to c2
   	wire [31 : 0] instr_read_c2;
    wire instr_gnt_c2;
    wire instr_r_valid_c2;
    wire [31 : 0] instr_adr_c2;
    wire instr_req_c2;
    
    // instruction cache signals
    wire [31 : 0] cached_instr_read_c1;
    wire cached_instr_req_c1;
    wire [31 : 0] cached_instr_adr_c1;
    wire cached_instr_gnt_c1;
    wire cached_instr_rvalid_c1;
    
    wire [31 : 0] cached_instr_read_c2;
    wire cached_instr_req_c2;
    wire [31 : 0] cached_instr_adr_c2;
    wire cached_instr_gnt_c2;
    wire cached_instr_rvalid_c2;
    
    wire irq;
    wire [4 : 0] irq_id;
    wire irq_ack;
	wire [4 : 0] irq_ack_id;
    
   
pulpus psoc(
/* BOARD SIGNALS */
     .BOARD_CLK(BOARD_CLK),
     .BOARD_RESN(BOARD_RESN),   
     
     .BOARD_LED(BOARD_LED),
     .BOARD_LED_RGB0(BOARD_LED_RGB0),
     .BOARD_LED_RGB1(BOARD_LED_RGB1),
     
     .BOARD_BUTTON(BOARD_BUTTON),
//     .BOARD_BUTTON(button_array),
     .BOARD_SWITCH(BOARD_SWITCH),
     
     .BOARD_VGA_HSYNC(BOARD_VGA_HSYNC),
     .BOARD_VGA_VSYNC(BOARD_VGA_VSYNC),
     .BOARD_VGA_R(BOARD_VGA_R),
     .BOARD_VGA_B(BOARD_VGA_B),
     .BOARD_VGA_G(BOARD_VGA_G),      
     .BOARD_UART_RX(BOARD_UART_RX),
     .BOARD_UART_TX(BOARD_UART_TX), 
      
     /* CORE SIGNALS */
         .CPU_CLK(CLK),  
         .CPU_RES(RES),
         .CACHE_RES(CACHE_RESET),
      
      // Instruction memory interface
         .INSTR_REQ(instr_req),
         .INSTR_GNT(instr_gnt),
         .INSTR_RVALID(instr_r_valid),
         .INSTR_ADDR(instr_adr),
         .INSTR_RDATA(instr_read),
   
      // Data memory interface
         .DATA_REQ(data_req),
         .DATA_GNT(data_gnt),
         .DATA_RVALID(data_r_valid),
         .DATA_WE(data_write_enable),
         .DATA_BE(4'b1111),
         .DATA_ADDR(data_adr),
         .DATA_WDATA(data_write),
         .DATA_RDATA(data_read),
         
         //Interrupt outputs
         .IRQ(irq),                 // level sensitive IR lines
         .IRQ_ID(irq_id),
         //Interrupt inputs
         .IRQ_ACK(irq_ack),             // irq ack
         .IRQ_ACK_ID(irq_ack_id)
     );
    

// dual core structure
proc #(.CORE_ID(1'd0))c1(
    .clk(CLK),
    .res(RES),
    
    .instr_read_in(cached_instr_read_c1),
    .instr_gnt(cached_instr_gnt_c1),
    .instr_r_valid(cached_instr_rvalid_c1),
    .instr_adr(cached_instr_adr_c1),
    .instr_req(cached_instr_req_c1),
    
    .data_read(data_read_c1),
    .data_gnt(data_gnt_c1),
    .data_r_valid(data_r_valid_c1),
    .data_write(data_write_c1),
    .data_adr(data_adr_c1),
    .data_req(data_req_c1),
    .data_write_enable(data_write_enable_c1),
//    .irq(irq_c1),
//    .irq_id(irq_id_c1),
//    .irq_ack(irq_ack_c1),
//    .irq_ack_id(irq_ack_id_c1)
    .irq(irq),
    .irq_id(irq_id),
    .irq_ack(irq_ack),
    .irq_ack_id(irq_ack_id)
    
);

proc #(.CORE_ID(1'd1))c2(
    .clk(CLK),
    .res(RES),
    
    .instr_read_in(cached_instr_read_c2),
    .instr_gnt(cached_instr_gnt_c2),
    .instr_r_valid(cached_instr_rvalid_c2),
    .instr_adr(cached_instr_adr_c2),
    .instr_req(cached_instr_req_c2),
    
    .data_read(data_read_c2),
    .data_gnt(data_gnt_c2),
    .data_r_valid(data_r_valid_c2),
    .data_write(data_write_c2),
    .data_adr(data_adr_c2),
    .data_req(data_req_c2),
    .data_write_enable(data_write_enable_c2),
//    .irq(irq_c2),
//    .irq_id(irq_id_c2),
//    .irq_ack(irq_ack_c2),
//    .irq_ack_id(irq_ack_id_c2)
    .irq(),
    .irq_id(),
    .irq_ack(),
    .irq_ack_id()
);

arbiter arbiter(
// input clk/res
.clk(CLK),
.res(RES),

// instr connections with c1
.instr_req_c1(instr_req_c1),
.instr_adr_c1(instr_adr_c1),
.instr_gnt_c1(instr_gnt_c1),
.instr_r_valid_c1(instr_r_valid_c1),
.instr_read_c1(instr_read_c1),

// instr connections with c2
.instr_req_c2(instr_req_c2),
.instr_adr_c2(instr_adr_c2),
.instr_gnt_c2(instr_gnt_c2),
.instr_r_valid_c2(instr_r_valid_c2),
.instr_read_c2(instr_read_c2),

// instruction signals from/to instruction mem
.instr_req(instr_req),
.instr_adr(instr_adr),
.instr_gnt(instr_gnt),
.instr_r_valid(instr_r_valid),
.instr_read(instr_read),

// main memory to arbiter
.data_gnt(data_gnt),
.data_r_valid(data_r_valid),
.data_read(data_read),

// c1 to main memory
.data_write_c1(data_write_c1),
.data_adr_c1(data_adr_c1),
.data_req_c1(data_req_c1),
.data_write_enable_c1(data_write_enable_c1),
//.data_be_c1(data_be_c1),

// c2 to main memory
.data_write_c2(data_write_c2),
.data_adr_c2(data_adr_c2),
.data_req_c2(data_req_c2),
.data_write_enable_c2(data_write_enable_c2),
//.data_be_c2(data_be_c2),

// arbiter distributes output from main memory to cores
.data_gnt_c1(data_gnt_c1),
.data_r_valid_c1(data_r_valid_c1),
.data_read_c1(data_read_c1),
.data_gnt_c2(data_gnt_c2),
.data_r_valid_c2(data_r_valid_c2),
.data_read_c2(data_read_c2),

.data_write(data_write),
.data_adr(data_adr),
.data_req(data_req),
.data_write_enable(data_write_enable),
.data_be(data_be)
);

instr_cache cache_c1(
    .clk(CLK),
    .res(CACHE_RESET),
    // Interface between processor and cache
    .cached_instr_req(cached_instr_req_c1),
    .cached_instr_adr(cached_instr_adr_c1),
    .cached_instr_gnt(cached_instr_gnt_c1),
    .cached_instr_rvalid(cached_instr_rvalid_c1),
    .cached_instr_read(cached_instr_read_c1),
    // Interface between Cache and main memory
    .instr_req(instr_req_c1),
    .instr_adr(instr_adr_c1),
    .instr_gnt(instr_gnt_c1),
    .instr_rvalid(instr_r_valid_c1),
    .instr_read(instr_read_c1)
);


instr_cache cache_c2(
    .clk(CLK),
    .res(CACHE_RESET),
    // Interface between processor and cache
    .cached_instr_req(cached_instr_req_c2),
    .cached_instr_adr(cached_instr_adr_c2),
    .cached_instr_gnt(cached_instr_gnt_c2),
    .cached_instr_rvalid(cached_instr_rvalid_c2),
    .cached_instr_read(cached_instr_read_c2),
    // Interface between Cache and main memory
    .instr_req(instr_req_c2),
    .instr_adr(instr_adr_c2),
    .instr_gnt(instr_gnt_c2),
    .instr_rvalid(instr_r_valid_c2),
    .instr_read(instr_read_c2)
);

`ifdef XILINX_SIMULATOR
// Vivado Simulator (XSim) specific code
initial
begin
clk=0;
end
always
#5 clk=~clk;

`else
always @(BOARD_CLK)
clk=BOARD_CLK;
`endif

endmodule

