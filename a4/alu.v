module alu(
    input reset,
    input [3:0]  alu_opn,
    input [31:0] alu_inp1,
    input [31:0] alu_inp2,
    output       alu_zero_sig,
    output [31:0] alu_out
);
    //Outputs of ALU
    reg        alu_zero_sig;
    reg [31:0] alu_out;
    //Checking which opn.
    //always @(alu_opn or alu_inp1 or alu_inp2) begin
    
    //Note- We use similar opcodes for Normal arithmetic/logical instructions and even condition checks
     
    always@( * ) begin
        //Will update for branching functionality
        alu_zero_sig = 0;
        case (alu_opn[2:0])
            3'b000: begin
                //SUB
                if(alu_opn[3]) begin
                    alu_out = alu_inp1 - alu_inp2;
                    //$display("SUB");
                
                end
                //ADD
                else  begin
                    alu_out = alu_inp1 + alu_inp2;
                    //$display("ADD  %d ",alu_inp1+alu_inp2);
                end
                
                //Condition check - equality
                if(alu_inp1 == alu_inp2)
                    alu_zero_sig = 1'b1;
                else 
                    alu_zero_sig = 1'b0;
                
            end
            
            //SLL shift logical left . Shift amt- lower 5 bits of alu_inp2 
            3'b001: begin
                alu_out = alu_inp1 << alu_inp2[4:0];
                //$display("SLL");
                
                //Condition check- inequality
                if(alu_inp1 != alu_inp2)
                    alu_zero_sig = 1'b1;
                else 
                    alu_zero_sig = 1'b0;
                
            end
            //SLT signed comparison
            3'b010: begin
                alu_out = { {31{1'b0}}, alu_inp1 < alu_inp2 };
                //$display("SLT ");
                
            end
            //SLTU unsigned comparison
            3'b011: begin
                //$display("SLTU");
                if (alu_inp1 < 0)
                    begin
                        //inp1 -, inp2 -
                        if(alu_inp2 < 0) begin
                            alu_out = { {31{1'b0}}, (-alu_inp1) < (-alu_inp2) };
                        end
                        //inp1 -, inp2 +
                        else begin
                            alu_out = { {31{1'b0}}, (-alu_inp1) < (alu_inp2) };
                        end
                        
                    end
                else 
                    begin
                        //inp1 +, inp2 -
                        if(alu_inp2 < 0)
                            alu_out = { {31{1'b0}}, (alu_inp1) < (-alu_inp2) };
                        //inp1 +, inp2 +
                        else
                            alu_out = { {31{1'b0}}, (alu_inp1) < (alu_inp2) };
                    end
                
            end
            
            //XOR bitwise
            3'b100: begin
                //$display("XOR");
                alu_out = alu_inp1 ^ alu_inp2;
                
                //Condition check - BLT
                if( alu_inp1 < alu_inp2)
                    alu_zero_sig = 1'b1;
                else 
                    alu_zero_sig = 1'b0;
                
            end
                      
            3'b101: begin
                //SRL shift logical right . Shift amt- lower 5 bits of alu_inp2 
                if (!alu_opn[3]) begin
                    //$display("SRL");
                    alu_out = alu_inp1 >> alu_inp2[4:0];
                end
                //SRA shift arith. right  . Shift amt- lower 5 bits of alu_inp2
                else  begin
                    //$display("SRA");
                    alu_out = alu_inp1 >>> alu_inp2[4:0];
                end
                
                //Condition check - BGE
                if( alu_inp1 >= alu_inp2)
                    alu_zero_sig = 1'b1;
                else 
                    alu_zero_sig = 1'b0;
                
            end
            //OR bitwise
            3'b110: begin
                //$display("OR");
                alu_out = alu_inp1 | alu_inp2;
                
                //Condition check- BLTU
                if(alu_inp1 < 0) begin
                    // -ve , -ve 
                    if(alu_inp2 < 0) begin
                        alu_zero_sig = (-alu_inp1) < (-alu_inp2);
                    end
                    // -ve, +ve (>=0)
                    else begin
                        alu_zero_sig = (-alu_inp1) < (+alu_inp2);
                    end
                end
                else begin
                    // +ve (>=0) , -ve
                    if(alu_inp2 < 0) begin
                        alu_zero_sig = (+alu_inp1) < (-alu_inp2);
                    end
                    // +ve (>=0) , +ve (>=0)
                    else begin
                        alu_zero_sig = (+alu_inp1) < (+alu_inp2);
                    end
                    
                end
                    
            end
            
            //AND bitwise
            3'b111: begin
                //$display("AND");
                alu_out = alu_inp1 & alu_inp2;
                
                //Condition check- BGEU
                if(alu_inp1 < 0) begin
                    // -ve , -ve 
                    if(alu_inp2 < 0) begin
                        alu_zero_sig = (-alu_inp1) >= (-alu_inp2);
                    end
                    // -ve, +ve (>=0)
                    else begin
                        alu_zero_sig = (-alu_inp1) >= (+alu_inp2);
                    end
                end
                else begin
                    // +ve (>=0) , -ve
                    if(alu_inp2 < 0) begin
                        alu_zero_sig = (+alu_inp1) >= (-alu_inp2);
                    end
                    // +ve (>=0) , +ve (>=0)
                    else begin
                        alu_zero_sig = (+alu_inp1) >= (+alu_inp2);
                    end
                
                end
            
            end
            //Invalid op- tristate the output
            default: begin
                $display("Invalid ALU opn");
                alu_out = 32'bz;
            end
            
            
        endcase
    end
    
    
    
endmodule