`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05/11/2022 08:16:36 AM
// Design Name: 
// Module Name: ctrl
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module ctrl(
    //Control Unit Management port
    input wire RES,
    input wire CLK,
    
    //Program Counter
    output reg pc_enable,

    //CPU Instruction input port
    input wire [6 : 0] opcode,
    
    //Program Counter Control port
    output reg MODE,                // 0-means increment by 4
    
    //Instruction Memory Control port
    //output reg data_write_enable, // 0-means read; 1-means write 
    output reg instr_req,
    input wire instr_gnt,
    input wire instr_r_valid,
    
    //Register set Control port
    output reg write_enable,        // 0-means read; 1-means write
    
    //MUX(ALU) Control port
    output reg ALUSrcMux1,          // 0-means Q0; 1-means Program Counter Value
    output reg ALUSrcMux2,          // 0-means Q1; 1-means Immediate value
    output reg ALUSrcMux1_S,        // 0-means ALUSrcMux1; 1-means constant 0(for NOP Instruction)
    output reg ALUSrcMux2_S,        // 0-means ALUSrcMux2 Output; 1-means Constant 4
    
    //PC ADDER CONTROL
    output reg reg_pc_select,       // 0 means PC value, 1 means Q0 value
    
    //Register Bank Write Control
    output reg alu_dm_select,       // 0 means ALU Output value, 1 means Data Memory value
    
    //Data Memory Control port
    output reg  data_write_enable,   // 0-means read; 1-means write 
    output reg data_req,
    input wire data_gnt,
    input wire data_r_valid,
    
    //Interrrupt
    input wire irq,
    input wire irq_status,
    output reg irq_ack,
    output reg irq_status_update,
    output reg irq_context,
    output reg irq_addr_sel,
    output reg bckup_reg,
    output reg mret_sel,
    output reg irq_pc_mode
);

    localparam [3:0]
        Ready = 4'b0000,
        instruction_fetch = 4'b0001,
        process_instruction = 4'b0010,
        wait_for_regset_write = 4'b0011,
        wait_for_data_read = 4'b0100,
        wait_for_data_write = 4'b0101,
        process_interrupt = 4'b0110,
        send_interrupt_acknowledge = 4'b0111,
        wait_for_regset_write_JI = 4'b1000;
    
    reg [3:0] stateMoore_reg, stateMoore_next;

    always @(posedge CLK, posedge RES)
    begin
        if(RES == 1'b1)            // reset
        begin
            stateMoore_reg <= Ready;
        end
        else
        begin
            stateMoore_reg <= stateMoore_next;
        end
    end
    
    always @(stateMoore_reg, instr_gnt, instr_r_valid, opcode, data_gnt, data_r_valid, irq, irq_status)
    begin
        // store current state as next, required: when no case statement is satisfied
        stateMoore_next = stateMoore_reg;
        
        //Default Signals
        pc_enable = 1'b0;
        MODE = 1'b0;                        // Program counter increment by 4
        
        instr_req = 1'b0;
        ALUSrcMux1 = 1'b0;
        ALUSrcMux1_S = 1'b0;    // A = ALUSrcMux1 Value
        ALUSrcMux2 = 1'b0;
        ALUSrcMux2_S = 1'b0;
        reg_pc_select = 1'b0;
        alu_dm_select = 1'b0;
        write_enable = 1'b0;
        
        //Data Memory
        data_write_enable = 1'b0;         // Default state is read
        data_req = 1'b0;
        
        //Interrupt
        irq_status_update = 1'b0;
        irq_context = 1'b0;
        irq_ack = 1'b0;
        irq_addr_sel = 1'b0;
        bckup_reg = 1'b0;
        mret_sel = 1'b0;
        irq_pc_mode = 1'b0;
        
        casez(stateMoore_reg)
            Ready:
            begin
                instr_req = 1'b1;
                if(instr_gnt == 1'b1)
                begin
                    stateMoore_next = instruction_fetch;
                end
                
                //Interrrupt Section:
                if((irq == 1'b1) && (irq_status == 0))
                begin
                    stateMoore_next = process_interrupt;
                end
            end
            
            instruction_fetch:
            begin
                //instr_req = 1'b1; // FIXME
                if(instr_r_valid == 1'b1)
                begin
                    stateMoore_next = process_instruction;
                end
                
                //Interrrupt Section:
                if((irq == 1'b1) && (irq_status == 0))
                begin
                    stateMoore_next = process_interrupt;
                end
            end
                    
            process_instruction:
            begin
                    casez(opcode)
                    
                        7'b0110111:     //LUI
                        begin
                            ALUSrcMux1 = 1'b0;      // A = don't care
                            ALUSrcMux2 = 1'b1;      // B = Immediate value
                            ALUSrcMux1_S = 1'b1;    // A = 0
                            write_enable = 1'b1;
                            stateMoore_next = wait_for_regset_write;
                        end
                        
                        7'b0010111:     //AUIPC
                        begin
                            ALUSrcMux1 = 1'b1;      // A = Program Counter Value
                            ALUSrcMux2 = 1'b1;      // B = Immediate value
                            write_enable = 1'b1;
                            stateMoore_next = wait_for_regset_write;
                        end
                        
                        7'b0010011:     //I-type Instruction
                        begin
                            ALUSrcMux1 = 1'b0;      // A = Q0
                            ALUSrcMux2 = 1'b1;      // B = Immediate value
                            write_enable = 1'b1;
                            stateMoore_next = wait_for_regset_write;
                        end
                        
                        7'b0110011:     //R-type Instruction
                        begin
                            ALUSrcMux1 = 1'b0;      // A = Q0
                            ALUSrcMux2 = 1'b0;      // B = Q1
                            write_enable = 1'b1;
                            stateMoore_next = wait_for_regset_write;
                        end
                        
                        7'b1101111:     //JAL Instruction
                        begin
                            ALUSrcMux1 = 1'b1;      // A = PC Value
                            ALUSrcMux2 = 1'b0;      // Don't Care
                            ALUSrcMux2_S = 1'b1;    // B = Constant 4
                            write_enable = 1'b1;
                            reg_pc_select = 1'b0;
                              
                            MODE = 1'b1;
                            pc_enable = 1'b1;
                            stateMoore_next = wait_for_regset_write_JI;
                        end
                        
                        7'b1100111:     //JALR Instruction
                        begin
                            ALUSrcMux1 = 1'b1;      // A = PC Value
                            ALUSrcMux2 = 1'b0;      // Don't Care
                            ALUSrcMux2_S = 1'b1;    // B = Constant 4
                            write_enable = 1'b1;
                            reg_pc_select = 1'b1; 
                            
                            MODE = 1'b1;
                            pc_enable = 1'b1;
                            stateMoore_next = wait_for_regset_write_JI;
                        end
                        
                        7'b1100011:     //Branch Instruction
                        begin
                            ALUSrcMux1 = 1'b0;      // A = Q0 Value
                            ALUSrcMux2 = 1'b0;      // Select Q1 Value
                            ALUSrcMux2_S = 1'b0;    // B = Q1 Value
                            write_enable = 1'b0;
                            reg_pc_select = 1'b0;
                            
                            pc_enable = 1'b1;
                            MODE = 1'b1;
                            stateMoore_next = Ready;
                        end
                        
                        7'b0000011:     //LW Instruction
                        begin
                            ALUSrcMux1 = 1'b0;      // A = Q0 Value
                            ALUSrcMux2 = 1'b1;      // Select Immediate Value
                            ALUSrcMux2_S = 1'b0;    // B = ALUSrcMux2 Value
                            write_enable = 1'b0;
                            reg_pc_select = 1'b0;
                            alu_dm_select = 1'b1;
                            MODE = 1'b0;
                            data_write_enable = 1'b0;
                            data_req = 1'b1;        // Send Read request
                            if(data_gnt == 1'b1)
                            begin
                                stateMoore_next = wait_for_data_read;
                            end
                        end
                        
                        7'b0100011:     //SW Instruction
                        begin
                            ALUSrcMux1 = 1'b0;      // A = Q0 Value
                            ALUSrcMux2 = 1'b1;      // Select Immediate Value
                            ALUSrcMux2_S = 1'b0;    // B = ALUSrcMux2 Value
                            write_enable = 1'b0;
                            reg_pc_select = 1'b0;
                            alu_dm_select = 1'b0;
                            MODE = 1'b0;
                            data_write_enable = 1'b1;
                            data_req = 1'b1;        // Send Write request
                            instr_req = 1'b0;
                            if(data_gnt == 1'b1)
                            begin
                                stateMoore_next = wait_for_data_write;
                            end
                        end
                        
                        7'b1110011:     // MRET Interrupt
                        begin
                            pc_enable = 1'b1;
                            stateMoore_next = Ready;
                            ALUSrcMux1 = 1'b0;
                            ALUSrcMux2 = 1'b0;
                            ALUSrcMux1_S = 1'b0;    // A = ALUSrcMux1 Value
                            ALUSrcMux2_S = 1'b0;
                            reg_pc_select = 1'b0;
                            alu_dm_select = 1'b0;
                            write_enable = 1'b0;
                            //Interrupt
                            irq_status_update = 1'b1;
                            irq_context = 1'b0;     // ISR is Over
                            irq_pc_mode = 1'b1;            // Load PC = Backup register
                            irq_addr_sel = 1'b0;
                            bckup_reg = 1'b0;
                            mret_sel = 1'b1;
                        end
                        
                        default:
                        begin
                            stateMoore_next = Ready;
                            pc_enable = 1'b0;
                            ALUSrcMux1 = 1'b0;
                            ALUSrcMux2 = 1'b0;
                            ALUSrcMux1_S = 1'b0;    // A = ALUSrcMux1 Value
                            ALUSrcMux2_S = 1'b0;
                            reg_pc_select = 1'b0;
                            alu_dm_select = 1'b0;
                            write_enable = 1'b0;
                            //Interrupt
                            irq_status_update = 1'b0;
                            irq_context = 1'b0;
                            irq_ack = 1'b0;
                            irq_addr_sel = 1'b0;
                            bckup_reg = 1'b0;
                            mret_sel = 1'b0;
                            irq_pc_mode = 1'b0;
                        end
                    endcase
                
                //Interrrupt Section:
                if((irq == 1'b1) && (irq_status == 0))
                begin
                    stateMoore_next = process_interrupt;
                end
            end
            
            wait_for_regset_write:
            begin
                stateMoore_next = Ready;
                pc_enable = 1'b1;
                
                //Interrrupt Section:
                if((irq == 1'b1) && (irq_status == 0))
                begin
                    stateMoore_next = process_interrupt;
                end
            end
            
            wait_for_regset_write_JI: //Jump Instruction - reg write case 
            begin
                stateMoore_next = Ready;
                
                //Interrrupt Section:
                if((irq == 1'b1) && (irq_status == 0))
                begin
                    stateMoore_next = process_interrupt;
                end
            end
            
            wait_for_data_read:
            begin
                data_req = 1'b0;
                if(data_r_valid == 1'b1)
                begin
                    ALUSrcMux1 = 1'b0;      // A = Q0 Value
                    ALUSrcMux2 = 1'b1;      // Select Immediate Value
                    ALUSrcMux2_S = 1'b0;    // B = ALUSrcMux2 Value
                    write_enable = 1'b1;
                    reg_pc_select = 1'b0;
                    alu_dm_select = 1'b1;   // Data memory output
                    MODE = 1'b0;
                    stateMoore_next = wait_for_regset_write;
                end
                
                //Interrrupt Section:
                if((irq == 1'b1) && (irq_status == 0))
                begin
                    stateMoore_next = process_interrupt;
                end
            end
            
            wait_for_data_write:
            begin
                data_req = 1'b0;
                pc_enable = 1'b1;
                stateMoore_next = Ready;
                
                //Interrrupt Section:
                if((irq == 1'b1) && (irq_status == 0))
                begin
                    stateMoore_next = process_interrupt;
                end
            end
            
            process_interrupt:
            begin
                pc_enable = 1'b1;
                irq_pc_mode = 1'b1;
                bckup_reg = 1'b1;
                irq_addr_sel = 1'b1;
                
                irq_status_update = 1'b1;
                irq_context = 1'b1;
                stateMoore_next = send_interrupt_acknowledge;                
            end
            
            send_interrupt_acknowledge:
            begin
                irq_ack = 1'b1;
                stateMoore_next = Ready;
            end
            
            default:
            begin
                stateMoore_next = Ready;
                pc_enable = 1'b0;
                ALUSrcMux1 = 1'b0;
                ALUSrcMux2 = 1'b0;
                ALUSrcMux1_S = 1'b0;    // A = ALUSrcMux1 Value
                ALUSrcMux2_S = 1'b0;
                reg_pc_select = 1'b0;
                alu_dm_select = 1'b0;
                write_enable = 1'b0;
                //Interrupt
                irq_status_update = 1'b0;
                irq_context = 1'b0;
                irq_ack = 1'b0;
                irq_addr_sel = 1'b0;
                bckup_reg = 1'b0;
                mret_sel = 1'b0;
                irq_pc_mode = 1'b0;
            end
        endcase
    end
    
endmodule