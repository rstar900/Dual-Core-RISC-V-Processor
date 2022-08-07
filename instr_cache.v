module instr_cache
#(
parameter LOG_SIZE=5
)
(
input clk,
input res,
// Interface between processor and cache
input cached_instr_req,
input [31:0] cached_instr_adr,
output reg cached_instr_gnt,
output reg cached_instr_rvalid,
output reg [31:0] cached_instr_read,
// Interface between Cache and main memory
output reg instr_req,
output reg [31:0] instr_adr,
input instr_gnt,
input instr_rvalid,
input [31:0] instr_read
);

// Cache registers
reg [31 : 0] lines [(2 ** LOG_SIZE) - 1 : 0]; // Data inside the cache (1 word each)
reg [30 - LOG_SIZE - 1 : 0] tags [(2 ** LOG_SIZE) - 1 : 0]; // We are choosing only from 30 bits (so subtract size of Index)
reg [(2 ** LOG_SIZE) - 1 : 0] valids;

// Wires
wire hit;
wire [30 - LOG_SIZE - 1 : 0] tag;
wire [LOG_SIZE - 1 : 0] index;

// Assignments
assign index = cached_instr_adr[LOG_SIZE + 1 : 2];
assign tag = cached_instr_adr[31 : LOG_SIZE + 2];
assign hit = (valids[index] == 1'b1 && tag == tags[index]) ? 1 : 0;

// Process to keep data inside cache
always @(posedge clk) begin
    if (res == 1'b1)
        valids = {2**LOG_SIZE{1'b0}};
    else
        if (instr_rvalid == 1'b1) begin
            lines[index] <= instr_read;
            tags[index] <= instr_adr[31 : LOG_SIZE + 2]; // A bit of confusion for now (can also be tag)
            valids[index] <= 1'b1;
        end     
end

// Time Sequence controlled State machines here

// --------------------------------------------------------
// STATE TRANSITION LOGIC
// --------------------------------------------------------

localparam STATE_NUM = 4;
localparam STATE_BITS = 2;

localparam STATE_IDLE = 2'b00;
localparam STATE_LOOKUP = 2'b01;
localparam STATE_GIVE_INSTR = 2'b10;
localparam STATE_MEM_FILL = 2'b11;

reg [STATE_BITS-1:0] currentState, nextState;

always @(currentState, cached_instr_req, instr_gnt, instr_rvalid, hit, cached_instr_adr, index) begin
//always @(currentState, cached_instr_req, instr_gnt, instr_rvalid, hit, cached_instr_adr) begin

    cached_instr_gnt = 1'b0;
    cached_instr_rvalid = 1'b0;
    cached_instr_read = 'b0;
    instr_req = 1'b0;
    instr_adr = 'b0;
    
    case(currentState)
        STATE_IDLE: begin
            if (cached_instr_req) nextState = STATE_LOOKUP;
            else nextState = STATE_IDLE;
        end

        STATE_LOOKUP: begin

            if (hit == 1'b1) begin
                cached_instr_gnt = 1'b1;
                instr_adr = cached_instr_adr;

                nextState = STATE_GIVE_INSTR; // cache hit: flush

            end else begin // cache miss : request main memory for the instruction
                instr_req = 1'b1;
                instr_adr = cached_instr_adr;

                if (instr_gnt) nextState = STATE_MEM_FILL;
                else nextState = STATE_LOOKUP;
            end
        end

        STATE_GIVE_INSTR: begin
            cached_instr_rvalid = 1'b1;
            cached_instr_read = lines[index]; 
            nextState = STATE_IDLE;
        end

        STATE_MEM_FILL: begin
            if (instr_rvalid) begin
                instr_adr = cached_instr_adr;

                nextState = STATE_LOOKUP;
            end
            else nextState = STATE_MEM_FILL;
        end

        default: begin
            nextState = STATE_IDLE;
            cached_instr_gnt = 1'b0;
            cached_instr_rvalid = 1'b0;
            cached_instr_read = 'b0;
            instr_req = 1'b0;
            instr_adr = 'b0; 
        end

    endcase
end


always @(posedge clk) begin
    if (res == 1'b1) currentState <= STATE_IDLE;
    else currentState <= nextState;
end

endmodule