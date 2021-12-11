module mux_alu2 ( input [31:0] mux_alu2_in2,
        input [31:0] rrdata2,
        input reset,
        input is_imm,
        output [31:0] alu_inp2
       );

    reg [31:0] alu_inp2;

    //Mux_alu2-deciding between imm val or read2-regfile
    //Note- mux_alu2_in1 - from regfile read2
    //      mux_alu2_in2 - from immediate val
    //assign mux_alu2_in1 = rrdata2;
    //always @(rrdata2 or mux_alu2_in2 or is_imm ) begin
    always @(*) begin
        //$display("ALU_INP2 %d iaddr %d is_imm %b rrdata2 %d",mux_alu2_in2, iaddr, is_imm, rrdata2);
        case(is_imm)
            1'b1: alu_inp2 = mux_alu2_in2; 
            1'b0: alu_inp2 = rrdata2;
            
        endcase
    end
    
endmodule