module mux_alu1( input reset,
                input [31:0] rrdata1,
                input [31:0] iaddr,
                input is_pc,
                output [31:0] alu_inp1
               );
    
    //Output to ALU inp1
    reg [31:0] alu_inp1;
 //I/p to ALU are two mux outputs- one after Read1-regfile o/p and other after Read2-regfile o/p  
    
    //Mux_alu1-deciding between pc_val or read1-regfile
    //Note- mux_alu1_in1 - from regfile read1
    //      mux_alu1_in2 - from PC         
    //assign mux_alu1_in1 = rrdata1;
    //assign mux_alu1_in2 = iaddr;
    always @(*) begin
        case(is_pc)
            1'b1: alu_inp1 = iaddr; 
            1'b0: alu_inp1 = rrdata1;
            
        endcase
    end
    
endmodule