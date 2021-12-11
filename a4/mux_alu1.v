module mux_alu1( input reset,
                input [31:0] rrdata1,
                input [31:0] iaddr,
                input is_pc,
                output [31:0] alu_inp1
               );
    //Mux_alu1-deciding between pc_val or read1-regfile
    //I/p to ALU are two mux outputs- one after Read1-regfile o/p and other after Read2-regfile o/p  
    //Note- mux_alu1_in1 - from regfile read1
    //      mux_alu1_in2 - from PC 
     
    
    //Output - alu_input 1
    reg [31:0] alu_inp1;
    
    always @(*) begin
        case(is_pc)
            1'b1: alu_inp1 = iaddr; 
            1'b0: alu_inp1 = rrdata1;
            
        endcase
    end
    
endmodule