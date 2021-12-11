module mux_alu2 ( input [31:0] mux_alu2_in2,
        input [31:0] rrdata2,
        input reset,
        input is_imm,
        output [31:0] alu_inp2
       );

    //Output to alu input 2
    reg [31:0] alu_inp2;

    //Mux_alu2-deciding between imm val or read2-regfile
    //Note- mux_alu2_in1 - from regfile read2
    //      mux_alu2_in2 - from immediate val
    //assign mux_alu2_in1 = rrdata2;
    always @(*) begin
        case(is_imm)
            1'b1: alu_inp2 = mux_alu2_in2; 
            1'b0: alu_inp2 = rrdata2;
            
        endcase
    end
    
    
endmodule