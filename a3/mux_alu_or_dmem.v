module mux_alu_or_dmem( input reset,
                input [31:0] alu_out,
                input [31:0] mux_alu_or_dmem_inp2,
                input mux_alu_or_dmem_sig,
                output [31:0] rwdata
               );
    
    
    //Output to write data bus in regfile
    reg [31:0] rwdata;

    
    //MUX to decide b/w ALU o/p and DMEM output to go into regfile.
    //Mux_alu_or_dmem
    //mux_alu_or_dmem_inp1 - from ALU data output- alu_out
    //mux_alu_or_dmem_inp2 - from DMEM drdata - modified by control unit already
    //mux_alu_or_dmem_sig - decides what rwdata is going to be- if 1 then choose ALU, else dmem
    
    always @(mux_alu_or_dmem_inp2 or mux_alu_or_dmem_sig or alu_out ) begin
        case ( mux_alu_or_dmem_sig)
            //Choose ALU o/p for rwdata 
            1'b1:  rwdata =  alu_out;
                //$display("Choosing alu, %d rwe, %b raddr3, %b", alu_out,rwe, raddr3);
            //Choose DMEM o/p for rwdata
            1'b0: rwdata =  mux_alu_or_dmem_inp2;
        endcase
    end
    
endmodule