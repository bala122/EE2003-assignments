module mux_pc_update( input reset,
                     input [31:0] iaddr,
                     input [31:0] imm_pc_off,
                     input [31:0] pc_from_reg,
                     input [1:0] mux_pc_update_sig,
                     output [31:0] iaddr_wdata
                    );
    
//MUX to decide between sequential code flow / PC-rel-branch / jalr
    //Mux_pc_update
    //Inputs:
    //mux_pc_update_sig for deciding between the following:
    //1. pc + 4 -> seq update
    //2. pc + imm_pc_off -> pc rel offset
    //3. pc_from_reg -> using jalr direct update of pc
    
    //Output: iaddr_wdata - update to pc
    
    reg [31:0] iaddr_wdata;
    always@(* ) begin
        if(!reset) begin
        case ( mux_pc_update_sig)
            //Normal sequential update
            2'b00: iaddr_wdata = iaddr + 4;
            //Pc- relative update
            2'b01: iaddr_wdata = iaddr + imm_pc_off;
            //Update pc based on reg value after jalr instr.
            2'b10: iaddr_wdata = pc_from_reg;
            //Invalid
            2'b11: iaddr_wdata = 0; 
        endcase
        end
        else begin
            iaddr_wdata = 0;
        end
    end
endmodule