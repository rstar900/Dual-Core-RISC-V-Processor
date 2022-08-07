// For opcode parsing (Adapted from riscv-defines @ pulp)
`define OPCODE_OP 7'h33 
`define OPCODE_OPIMM 7'h13 
`define OPCODE_STORE 7'h23
`define OPCODE_LOAD 7'h03
`define OPCODE_BRANCH 7'h63
`define OPCODE_JALR 7'h67
`define OPCODE_JAL 7'h6f
`define OPCODE_AUIPC 7'h17
`define OPCODE_LUI 7'h37
`define OPCODE_CSRRS 7'h73

// For Instr parsing

// OP (MUL is extra)
`define ALU_ADD_OP 10'b0000000_000
`define ALU_SUB_OP 10'b0100000_000
`define ALU_MUL_OP 10'b0000001_000
`define ALU_AND_OP 10'b0000000_111
`define ALU_OR_OP 10'b0000000_110
`define ALU_XOR_OP 10'b0000000_100
`define ALU_SLL_OP 10'b0000000_001
`define ALU_SRA_OP 10'b0100000_101
`define ALU_SRL_OP 10'b0000000_101
`define ALU_SLT_OP 10'b0000000_010
`define ALU_SLTU_OP 10'b0000000_011

// OPIMM (Does not include SUB and MUL)
`define ALU_ADDI_OP 10'b???????_000
`define ALU_SLTI_OP 10'b???????_010
`define ALU_SLTIU_OP 10'b???????_011
`define ALU_XORI_OP 10'b???????_100
`define ALU_ORI_OP 10'b???????_110
`define ALU_ANDI_OP 10'b???????_111
`define ALU_SLLI_OP 10'b???????_001
`define ALU_SRLI_OP 10'b???????_101
`define ALU_SRAI_OP 10'b?1?????_101

// Branch
`define ALU_BEQ_OP 10'b???????_000
`define ALU_BNE_OP 10'b???????_001
`define ALU_BLT_OP 10'b???????_100 
`define ALU_BGE_OP 10'b???????_101  
`define ALU_BLTU_OP 10'b???????_110 
`define ALU_BGEU_OP 10'b???????_111 


// AluOp Outputs (Change values)

`define ADD 5'h1
`define SUB 5'h2
`define MUL 5'h3
`define AND 5'h4
`define OR 5'h5
`define XOR 5'h6
`define SLL 5'h7
`define SRA 5'h8
`define SRL 5'h9
`define SLT 5'hA
`define SLTU 5'hB

`define BEQ 5'hC
`define BNE 5'hD
`define BLT 5'hE
`define BGE 5'hF 
`define BLTU 5'h10
`define BGEU 5'h11 

`define SLLI 5'h12
`define SRLI 5'h13
`define SRAI 5'h14

`define LUI 5'h15
`define AUIPC 5'h16

module alu_ctrl( 
input [31 : 0] Instr,
output reg [4 : 0]  AluOp
);

// Dividing the instruction into parts
// Instr[6 : 0] -> opcode
// Instr[14 : 12] -> func3;
// Instr[31 : 25] -> func7;

//Opcode Parsing
// No need of default as it is taken care by AluOp = 5'h0
always @(Instr)
begin

    AluOp = 5'h0;

    casez (Instr[6 : 0])

        `OPCODE_OP : // Function to parse OP;
        begin
            casez ({Instr[31 : 25], Instr[14 : 12]})
            `ALU_ADD_OP: AluOp = `ADD;
            `ALU_SUB_OP: AluOp = `SUB;
            `ALU_MUL_OP: AluOp = `MUL;
            `ALU_AND_OP: AluOp = `AND;
            `ALU_OR_OP:  AluOp = `OR;
            `ALU_XOR_OP: AluOp = `XOR;
            `ALU_SLL_OP: AluOp = `SLL;
            `ALU_SRA_OP: AluOp = `SRA;
            `ALU_SRL_OP: AluOp = `SRL;
            `ALU_SLT_OP: AluOp = `SLT;
            `ALU_SLTU_OP: AluOp = `SLTU;
            endcase
        end

        `OPCODE_OPIMM : // Function to parse OPIMM;
        begin
            casez ({Instr[31 : 25], Instr[14 : 12]})
            `ALU_ADDI_OP: AluOp = `ADD;
            `ALU_ANDI_OP: AluOp = `AND;
            `ALU_ORI_OP:  AluOp = `OR;
            `ALU_XORI_OP: AluOp = `XOR;
            `ALU_SLLI_OP: AluOp = `SLLI;
            `ALU_SRAI_OP: AluOp = `SRAI;
            `ALU_SRLI_OP: AluOp = `SRLI;
            `ALU_SLTI_OP: AluOp = `SLT;
            `ALU_SLTIU_OP: AluOp = `SLTU;       
            endcase
        end

        `OPCODE_STORE : AluOp = `LUI;

        `OPCODE_LOAD : AluOp =  `LUI;

        `OPCODE_BRANCH :
        begin
            casez ({Instr[31 : 25], Instr[14 : 12]})
            `ALU_BEQ_OP:  AluOp = `BEQ;
            `ALU_BNE_OP:  AluOp = `BNE; 
            `ALU_BLT_OP:  AluOp = `BLT; 
            `ALU_BGE_OP:  AluOp = `BGE;  
            `ALU_BLTU_OP: AluOp = `BLTU;  
            `ALU_BGEU_OP: AluOp = `BGEU;
            endcase
        end 

        `OPCODE_JALR : AluOp = `AUIPC;

        `OPCODE_JAL :  AluOp = `AUIPC;

        `OPCODE_AUIPC : AluOp = `AUIPC;

        `OPCODE_LUI :  AluOp = `LUI;
        
        `OPCODE_CSRRS : AluOp = `LUI;

    endcase
end


endmodule