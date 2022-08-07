// A register set of 32 x 32-Bit Registers with asynchronous read and synchronous write
module regset
    #(parameter CORE_ID=32'd0)
    (
    input [31 : 0] D,
    input [4 : 0] A_D,
    input [4 : 0] A_Q0,
    input [4 : 0] A_Q1,
    input write_enable,
    input RES,
    input CLK,
    output [31 : 0] Q0,
    output [31 : 0]  Q1
);

    //Creating 31 x 32-bit regs
    // R0 is additional register but provides 0 only
    reg [31 : 0] regs [31 : 1];  
    integer i;

    // Synchronous write
    always @(posedge CLK)
    begin    

        if(RES == 1'b1) begin
            for (i = 1; i < 32; i = i + 1) begin
                regs[i] <= 32'd0;
            end
            regs[5] <= CORE_ID;
        end

        else if((write_enable == 1'b1) && (A_D != 5'd0)) begin
            regs[A_D] <= D;
        end         
    end 

    // Asynchronous read
    assign Q0 = (A_Q0 != 5'd0) ? regs[A_Q0] : 32'd0;
    assign Q1 = (A_Q1 != 5'd0) ? regs[A_Q1] : 32'd0;

endmodule
