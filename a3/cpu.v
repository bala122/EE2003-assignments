module cpu (
    input clk, 
    input reset, 
    output [31:0] iaddr,
    input [31:0] idata,
    output [31:0] daddr,
    input [31:0] drdata,
    output [31:0] dwdata,
    output [3:0] dwe
);
    
    //Outputs of the CPU
    reg [31:0] iaddr;
    wire [31:0] daddr;
    wire signed [31:0] dwdata;
    wire [3:0]  dwe;

    //ALU inputs and outputs for ALU and MUX wires
    
    //ALU inputs
    //To decide what kind of operation
    wire [3:0] alu_opn;
    //32 bit operand 1
    wire signed [31:0] alu_inp1;
    //32 bit operand 2 - this could be imm. operand.
    wire signed [31:0] alu_inp2;
    
    //Alu outputs
    //32 bit output
    wire signed [31:0] alu_out;
    //0 signal for branches (later)
    wire              alu_zero_sig;
    
    //MUX_ALU1 wires - for the mux between "rs1" and "alu_inp1"
    //To check if alu op involves pc
    wire is_pc;
    //Inp1 is "rs1"
    //Inp2 is pc
 
    //MUX_ALU2 wires - for the mux between "rs2" and "alu_inp2"
    //To check if alu op is imm or not
    wire is_imm;
    //Inp1 is "rs2"
    //Immediate value 2nd input
    wire signed [31:0] mux_alu2_in2;
    //reg signed [31:0] mux_alu2_out;
    
    //MUX_ALU_OR_DMEM inputs - for mux to decide which output goes into regfile.
    //Inp1 - ALU output (mux_alu_or_dmem_inp1)
    //Inp2 - DMEM output
    wire signed [31:0] mux_alu_or_dmem_inp2;
    //Deciding select signal
    wire                mux_alu_or_dmem_sig;
    
    
    //REG-FILE inputs and output
    //addresses for rs1, rs2 and rd.
    wire        [4:0]  raddr1;
    wire        [4:0]  raddr2;
    wire        [4:0]  raddr3;
    //Write data input buses and write enable
    wire signed [31:0] rwdata;
    wire               rwe;
    //Output data buses
    wire signed [31:0] rrdata1;
    wire signed [31:0] rrdata2;
    
    
    //Note- This module itself will act as the main control unit with instantiation of other units:
    
    //DETAILS ON STRUCTURE:
    //The structure of the cpu is mostly similar to what's given in the pattenson book. However, One small change is in the reg-file ALU interface.
    //We have 2 read outputs of the Regfile "rs1" and "rs2".
    //The "rs1" value is muxed with the PC  and fed into "alu_inp1"- This is done for the "auipc" instruction
    //The "rs2" value is muxed with an immediate value and fed into "alu_inp2". This is done as per the conventional design.
    
    
    
    
     //Idecode instantiation
    idecode idc( .idata(idata), .reset(reset), .rrdata2(rrdata2), .drdata(drdata), .daddr(daddr), .dwdata(dwdata), .dwe(dwe), .mux_alu_or_dmem_sig(mux_alu_or_dmem_sig), .mux_alu_or_dmem_inp2(mux_alu_or_dmem_inp2), .is_pc(is_pc), .is_imm(is_imm), .mux_alu2_in2(mux_alu2_in2), .raddr3(raddr3), .alu_opn(alu_opn), .raddr1(raddr1), .raddr2(raddr2), .rwe(rwe) , .alu_out(alu_out));
    
    //MUX_alu1 instantiation
    mux_alu1 mal1(.rrdata1(rrdata1), .iaddr(iaddr), .is_pc(is_pc), .alu_inp1(alu_inp1) , .reset(reset) );
    //MUX_ALU2 instantiation
    mux_alu2 mal2( .mux_alu2_in2(mux_alu2_in2), .rrdata2(rrdata2), .reset(reset), .is_imm(is_imm), .alu_inp2(alu_inp2));
    
    //MUX_ALU_OR_DMEM instantiation
    mux_alu_or_dmem madm( .alu_out(alu_out), .mux_alu_or_dmem_inp2(mux_alu_or_dmem_inp2), .mux_alu_or_dmem_sig(mux_alu_or_dmem_sig), .rwdata(rwdata) , .reset(reset) );
 
    //ALU Instantiation
    
    alu cpu_1 (  .alu_opn(alu_opn), .alu_inp1(alu_inp1), .alu_inp2(alu_inp2), .alu_zero_sig(alu_zero_sig), .alu_out(alu_out) , .reset(reset)  );
   
    //Reg File Instantiation
    
    reg_file cpu_2 ( .clk(clk), .raddr1(raddr1) , .reset(reset) , .raddr2(raddr2), .raddr3(raddr3), .rwdata(rwdata), .rwe(rwe), .rrdata1(rrdata1), .rrdata2(rrdata2)   );
    
    //Reset is made asynchronous for combinational sig. outputs  
    always @(posedge clk) begin 
            //    $display( "clk count core %d Instruction: %b ", count, idata);
        if (reset) begin
            iaddr <= 0;
            //daddr <= 0;
            //dwdata <= 0;
            //dwe <= 0;
        end else begin
            //PC increment
            iaddr <= iaddr + 4;
            //$display("daddr: %b," ,daddr ,"dwdata: %b," ,dwdata ,"dwe: %b," ,dwe , "rwe %b ", rwe, "iaddr %b", iaddr , "rwdata %d", rwdata);            
        end
    end

endmodule