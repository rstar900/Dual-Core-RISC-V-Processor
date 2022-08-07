
module arbiter(
    input clk,
    input res,

    // instr connections with c1
    input instr_req_c1,
    input [31 : 0] instr_adr_c1,
    output reg instr_gnt_c1,
    output reg instr_r_valid_c1,
    output reg [31 : 0] instr_read_c1,
    
    // instr connections with c2
    input instr_req_c2,
    input [31 : 0] instr_adr_c2,
    output reg instr_gnt_c2,
    output reg instr_r_valid_c2,
    output reg [31 : 0] instr_read_c2,
    
    // instruction signals from/to instruction mem
    output reg instr_req,
    output reg [31 : 0] instr_adr,
    input instr_gnt,
    input instr_r_valid,
    input [31 : 0] instr_read,
    
    // memory request from c1
    input [31 : 0] data_write_c1,
    input [31 : 0] data_adr_c1,
    input data_req_c1,
    input data_write_enable_c1,
    input [3 : 0] data_be_c1,
    
    // memory request from c2
    input [31 : 0] data_write_c2,
    input [31 : 0] data_adr_c2,
    input data_req_c2,
    input data_write_enable_c2,
    input [3 : 0] data_be_c2,
    
    // memory grant from main memory
    input data_gnt,
    input data_r_valid,
    input [31 : 0] data_read,
    
    // arbiter output to core
    output reg data_gnt_c1,
    output reg data_r_valid_c1,
    output reg [31 : 0] data_read_c1,
    output reg data_gnt_c2,
    output reg data_r_valid_c2,
    output reg [31 : 0] data_read_c2,
    
    
    // arbiter output to memory
    output reg [31 : 0] data_write,
    output reg [31 : 0] data_adr,
    output reg data_req,
    output reg data_write_enable,
    output reg [3 : 0] data_be
    );

    // States
    localparam STATE_C1_INSTR_REQ = 3'b000;
    localparam STATE_C1_INSTR_FILL = 3'b001;
    localparam STATE_C2_INSTR_REQ = 3'b010;
    localparam STATE_C2_INSTR_FILL = 3'b011;
    localparam STATE_C1_DATA_REQ = 3'b100;
    localparam STATE_C1_DATA_WRITE = 3'b101;
    localparam STATE_C2_DATA_REQ = 3'b110;
    localparam STATE_C2_DATA_WRITE = 3'b111;

    reg [2 : 0] current_state = STATE_C1_INSTR_REQ;


    // Internal reg used for timekeeping (2 bits initially)
    reg [2 : 0] ticks = 0;

    // Parameters for ticks
    localparam WAIT_TIME = 3'd1;
    localparam TRANSFER_TIME = 3'd4;

    // Registers for storing write data as they come in (sort of like a buffer)
    wire [31:0] data_write_c1_reg_wire;
    wire [31:0] data_write_c2_reg_wire;
    REG_DRE_32 data_write_c1_reg(.D(data_write_c1), .Q(data_write_c1_reg_wire), .CLK(clk), .RES(res), .ENABLE(data_req_c1));
    REG_DRE_32 data_write_c2_reg(.D(data_write_c2), .Q(data_write_c2_reg_wire), .CLK(clk), .RES(res), .ENABLE(data_req_c2));
    
    
    always @(posedge clk)
    begin
        if(res)
        begin
                instr_gnt_c1 <= 0;
                instr_r_valid_c1 <= 0;
                instr_read_c1 <= 0;
         
                instr_gnt_c2 <= 0;
                instr_r_valid_c2 <= 0;
                instr_read_c2 <= 0;
        
                instr_req <= 0;
                instr_adr <= 0;
        
                data_gnt_c1 <= 0;
                data_r_valid_c1 <= 0;
                data_read_c1 <= 0;
                data_gnt_c2 <= 0;
                data_r_valid_c2 <= 0;
                data_read_c2 <= 0;
            
                data_write <= 0;
                data_adr <= 0;
                data_req <= 0;
                data_write_enable <= 0;
                data_be <= 4'b1111;
        end
        
        else
        begin
        // Default outputs at the beginning
        instr_gnt_c1 <= 0;
        instr_r_valid_c1 <= 0;
        instr_read_c1 <= 0;
 
        instr_gnt_c2 <= 0;
        instr_r_valid_c2 <= 0;
        instr_read_c2 <= 0;

        instr_req <= 0;
        instr_adr <= 0;

        data_gnt_c1 <= 0;
        data_r_valid_c1 <= 0;
        data_read_c1 <= 0;
        data_gnt_c2 <= 0;
        data_r_valid_c2 <= 0;
        data_read_c2 <= 0;
    
        data_write <= 0;
        data_adr <= 0;
        data_req <= 0;
        data_write_enable <= 0;
        data_be <= 4'b1111;

        case(current_state)
      
            STATE_C1_INSTR_REQ:
            begin
                // 1st case is Experiment (if line is already busy)
                if(instr_r_valid || data_r_valid)
                begin
                    current_state <= STATE_C1_INSTR_REQ;
                    ticks <= 0;
                end
            
                else if(ticks >= WAIT_TIME)
                begin
                    current_state <= STATE_C2_INSTR_REQ;
                    ticks <= 0;
                end 

                else if(instr_req_c1)
                begin
                    current_state <= STATE_C1_INSTR_FILL;
                    ticks <= 0;
                end

                else
                    ticks <= ticks + 1;
            end

            STATE_C1_INSTR_FILL:
            begin
                instr_req <= instr_req_c1; 
                instr_adr <= instr_adr_c1;
                instr_gnt_c1 <= instr_gnt;
                instr_r_valid_c1 <= instr_r_valid;
                instr_read_c1 <= instr_read;

                //if(ticks >= TRANSFER_TIME)
                if (instr_r_valid)
                begin
                    current_state <= STATE_C2_INSTR_REQ;
                    ticks <= 0;
                end

                else
                    ticks <= ticks + 1;
            end

           
            STATE_C2_INSTR_REQ:
            begin
                // 1st case is Experiment (if line is already busy)
                if(instr_r_valid || data_r_valid)
                begin
                    current_state <= STATE_C2_INSTR_REQ;
                    ticks <= 0;
                end
            
                else if(ticks >= WAIT_TIME)
                begin
                    current_state <= STATE_C1_DATA_REQ;
                    ticks <= 0;
                end

                else if(instr_req_c2)
                begin
                    current_state <= STATE_C2_INSTR_FILL;
                    ticks <= 0;
                end

                else
                    ticks <= ticks + 1;
            end

            STATE_C2_INSTR_FILL:
            begin
                instr_req <= instr_req_c2; 
                instr_adr <= instr_adr_c2;
                instr_gnt_c2 <= instr_gnt;
                instr_r_valid_c2 <= instr_r_valid;
                instr_read_c2 <= instr_read;

                //if(ticks >= TRANSFER_TIME)
               if(instr_r_valid)
                begin
                    current_state <= STATE_C1_DATA_REQ;
                    ticks <= 0;
                end

                else
                    ticks <= ticks + 1;
           
            end

            STATE_C1_DATA_REQ:
            begin
                // 1st case is Experiment (if line is already busy)
                if(instr_r_valid || data_r_valid)
                begin
                    current_state <= STATE_C1_DATA_REQ;
                    ticks <= 0;
                end
            
                else if(ticks >= WAIT_TIME)
                begin
                    current_state <= STATE_C2_DATA_REQ;
                    ticks <= 0;
                end

                else if(data_req_c1)
                begin
                    current_state <= STATE_C1_DATA_WRITE;
                    ticks <= 0;
                end

                else
                    ticks <= ticks + 1;               
            end

            STATE_C1_DATA_WRITE:
            begin
                data_write_enable <= data_write_enable_c1;
                data_req <= data_req_c1;
                data_adr <= data_adr_c1;
                data_write <= data_write_c1_reg_wire;
                data_gnt_c1 <= data_gnt;
                data_r_valid_c1 <= data_r_valid;
                data_read_c1 <= data_read;

               //if(ticks >= TRANSFER_TIME)
               if(data_r_valid)
                begin
                    current_state <= STATE_C2_DATA_REQ;
                    ticks <= 0;
                end

                else
                    ticks <= ticks + 1; 

            end

            STATE_C2_DATA_REQ:
            begin
                // 1st case is Experiment (if line is already busy)
                if(instr_r_valid || data_r_valid)
                begin
                    current_state <= STATE_C2_DATA_REQ;
                    ticks <= 0;
                end
            
                else if(ticks >= WAIT_TIME)
                begin
                    current_state <= STATE_C1_INSTR_REQ;
                    ticks <= 0;
                end

                else if(data_req_c2)
                begin
                    current_state <= STATE_C2_DATA_WRITE;
                    ticks <= 0;
                end

                else
                    ticks <= ticks + 1;               

            end

            STATE_C2_DATA_WRITE:
            begin
                data_write_enable <= data_write_enable_c2;
                data_req <= data_req_c2;
                data_adr <= data_adr_c2;
                data_write <= data_write_c2_reg_wire;
                data_gnt_c2 <= data_gnt;
                data_r_valid_c2 <= data_r_valid;
                data_read_c2 <= data_read;

               //if(ticks >= TRANSFER_TIME)
               if(data_r_valid)
                begin
                    current_state <= STATE_C1_INSTR_REQ;
                    ticks <= 0;
                end

                else
                    ticks <= ticks + 1; 
            end

            default:
            begin
                current_state <= STATE_C1_INSTR_REQ;
                ticks <= 0;
            end
             
        endcase
        end
    end
    

endmodule
