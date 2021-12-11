module reg_file (
    input clk,
    input reset,
    input [4:0] raddr1,
    input [4:0] raddr2,
    input [4:0] raddr3,
    input [31:0] rwdata,
    input rwe,
    output [31:0] rrdata1,
    output [31:0] rrdata2
);
    
    integer i;
    //32 32-bit regs
    reg [31:0] reg0[0:31];
    
    //Initial config is all 0
    
    initial begin
        //count =0;
        for(i=0;i<32;i=i+1)
            begin
                reg0[i] = 32'b0;
            end
        
    end
    
    //Selecting bytes to be read
    //Simultaneous read using 2 address buses - Asynchronous
    assign rrdata1 = reg0[raddr1];
    assign rrdata2 = reg0[raddr2];
    
    //For writes we use raddr3 address bus
    always @(posedge clk)  begin
        //$display("Entering reg file");
        //If reset from core is on then simply make everything 0
        if(reset) begin
            for(i=0;i<32;i=i+1)
                begin
                    reg0[i] = 32'b0;
                end
        end
        //Only if write enable and addr isn't pointing to x0 and MAINLY RESET TO CORE IS OFF then write.
        //Synchronous write- TO ANY REG OTHER THAN x0.
        else if ( (rwe) & (raddr3!=5'b00000) &(!reset)) begin
            reg0[raddr3] <= rwdata;
            //$display(" Regfile: data written %d raddr3 %d", rwdata, raddr3);
            
        end
    end
    
endmodule