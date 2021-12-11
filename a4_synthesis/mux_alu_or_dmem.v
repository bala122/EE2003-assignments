module mux_alu_or_dmem( input reset,
                       input [31:0] alu_out,
                       input [31:0] mux_alu_or_dmem_inp2,
                       input mux_alu_or_dmem_sig,
                       input mux_alu_or_dmem_enable,
                       input [31:0] reg_pc_update_val,
                       output [31:0] rwdata
                      );
    
    //Output to write data bus into reg-file
    reg [31:0] rwdata;

//MUX to decide b/w ALU o/p and DMEM output to go into regfile OR take in pc+4 based on branch
    //If not branch:
    //mux_alu_or_dmem_enable is high
    //mux_alu_or_dmem_inp1 - from ALU data output- alu_out
    //mux_alu_or_dmem_inp2 - from DMEM drdata - modified by control unit already
    //mux_alu_or_dmem_sig - decides what rwdata is going to be- if 1 then choose ALU, else dmem
    //If its branch pc value store, pc_update_path" is taken and pc+4 is written to "rd". Mux_alu_or_dmem_enable is low
    
    
    always @(*) begin
        //If value is from DMEM or ALU
        if(mux_alu_or_dmem_enable) begin
            case ( mux_alu_or_dmem_sig)
                //Choose ALU o/p for rwdata 
                1'b1: rwdata =  alu_out;
                //Choose DMEM o/p for rwdata
                1'b0: rwdata =  mux_alu_or_dmem_inp2;
            
            endcase
        end
        // If its pc update store
        else begin
            rwdata = reg_pc_update_val;
        end
    
    end
    
endmodule
    
    