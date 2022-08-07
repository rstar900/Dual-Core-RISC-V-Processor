// ALU Operations

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


module alu (
input [ 4 : 0 ] S ,
input [ 31 : 0 ] A,
input [ 31 : 0 ] B,
output reg CMP,
output reg [ 31 : 0 ] Q
);

	always @( S , A, B)

		begin

			Q=32'd0 ; CMP = 0;

			// If several cases apply, only the first case is executed

			casez ( S )

				`SUB: Q = $signed(A) - $signed(B);
				`ADD: Q = $signed(A) + $signed(B);
                `MUL: Q = $signed(A) * $signed(B);

				`AND: Q = A & B;
				`OR: Q = A | B;
				`XOR: Q = A ^ B; 

				`SLL: Q = A << B;
				`SRA: Q = $signed(A) >>> $signed(B);
				`SRL: Q = A >> B;

				`SLT: begin Q = ($signed(A) < $signed(B)) ? 32'd1 : 32'd0; 
							 CMP = ($signed(A) < $signed(B)) ? 1 : 0;
							 end 

				`SLTU: begin Q = (A < B) ? 32'd1 : 32'd0; 
				              CMP = (A < B) ? 1 : 0;
				              end

				`BEQ: CMP = (A == B) ? 1 : 0;
				`BNE: CMP = (A != B) ? 1 : 0;
				`BLT: CMP = ($signed(A) < $signed(B)) ? 1 : 0;
				`BGE: CMP = ($signed(A) >= $signed(B)) ? 1 : 0;
				`BLTU: CMP = (A < B) ? 1 : 0;
				`BGEU: CMP = (A >= B) ? 1 : 0;


				`SLLI: Q = A << B[4 : 0];
				`SRAI: Q = $signed(A) >>> $signed(B[4 : 0]);
				`SRLI: Q = A >> B[4 : 0];

				`AUIPC: begin Q = A + B;
                              CMP = 1;
				            end

				`LUI: Q = A + B;	
						  		  

			endcase

		end


endmodule