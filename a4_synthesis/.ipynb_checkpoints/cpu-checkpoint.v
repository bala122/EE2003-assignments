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

    //PC update signal
    wire [31:0] iaddr_wdata;
    
    //ALU inputs and outputs for ALU and MUX wires
    
    //ALU inputs
    //To decide what kind of operation
    wire [3:0] alu_opn;
    //32 bit operand 1
    wire signed [31:0] alu_inp1;
    //32 bit operand 2 - this could be imm. operand.
    wire signed [31:0] alu_inp2;
    
    //Alu outputs
    wire signed [31:0] alu_out;
    //Condition check signal
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
    //wire signed [31:0] mux_alu2_out;
    
    //MUX_ALU_OR_DMEM inputs  - for the mux to decide which output goes into regfile.
    //Inp1 - Alu output- (mux_alu_or_dmem_inp1)
    //Inp2 - DMEM output
    wire signed [31:0] mux_alu_or_dmem_inp2;
    //Either updated pc store/ (Dmem or alu o/p store)
    wire signed   mux_alu_or_dmem_enable;
    //Either ALU or dmem store
    wire                mux_alu_or_dmem_sig;
    //To store pc + 4 in rd
    wire signed [31:0] reg_pc_update_val;
    
    
    //MUX_pc_update inputs and outputs - for the mux to decide what kind of PC update
    //Deciding signal
    wire        [1:0]  mux_pc_update_sig;
    //PC- relative computed offset
    wire        [31:0] imm_pc_off;
    // For jalr - absolute pc update
    wire        [31:0] pc_from_reg;
    
    //REG-FILE inputs and output
    //"rs1","rs2","rd" addresses
    wire        [4:0]  raddr1;
    wire        [4:0]  raddr2;
    wire        [4:0]  raddr3;
    //Input 32 bit write data bus
    wire signed [31:0] rwdata;
    //Write enable
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
    
    //Regarding branching:
    //1. The PC update happens in one of three ways using a multiplexer to the "iaddr_wdata" signal:
    //   -Sequential PC+4 update
    //   -PC relative update (BEQ,..,JAL instructions)
    //   -Absolute PC update (JALR)
    //
    //2. Writing to Regfile again happens via a mux from one of three ways:
    //  -From ALU output
    //  -From DMEM output
    //  -via "reg_pc_update" value - which basically stores PC+4 - the return address to be stored. 
    //   This is done because the ALU is used for computing the branch address (in jalr). So, we need a separate write to regfile pathway.
    
    //ALU Instantiation
    
    alu cpu_1 ( .reset(reset),  .alu_opn(alu_opn), .alu_inp1(alu_inp1), .alu_inp2(alu_inp2), .alu_zero_sig(alu_zero_sig), .alu_out(alu_out)   );
    
    //MUX_alu1 instantiation
    mux_alu1 mal1(.rrdata1(rrdata1), .iaddr(iaddr), .is_pc(is_pc), .alu_inp1(alu_inp1) , .reset(reset) );
    
    //MUX_ALU2 instantiation
    mux_alu2 mal2( .mux_alu2_in2(mux_alu2_in2), .rrdata2(rrdata2), .reset(reset), .is_imm(is_imm), .alu_inp2(alu_inp2)  );
    //Reg File Instantiation
    
    reg_file cpu_2 ( .clk(clk), .raddr1(raddr1) , .reset(reset) , .raddr2(raddr2), .raddr3(raddr3), .rwdata(rwdata), .rwe(rwe), .rrdata1(rrdata1), .rrdata2(rrdata2)   );
    
    //MUX_ALU_OR_DMEM instantiation
    mux_alu_or_dmem madm( .alu_out(alu_out), .mux_alu_or_dmem_inp2(mux_alu_or_dmem_inp2), .mux_alu_or_dmem_sig(mux_alu_or_dmem_sig), .rwdata(rwdata) , .reg_pc_update_val(reg_pc_update_val) , .reset(reset) , .mux_alu_or_dmem_enable(mux_alu_or_dmem_enable) );
    
    
    //MUX_pc_update instantiation
    mux_pc_update mpu( .reset(reset),  .iaddr(iaddr) , .imm_pc_off(imm_pc_off), .pc_from_reg(pc_from_reg), .mux_pc_update_sig(mux_pc_update_sig), .iaddr_wdata(iaddr_wdata) );
    
    
   //Idecode instantiation
    idecode idc( .idata(idata),        .reset(reset),        .rrdata2(rrdata2), .drdata(drdata), .daddr(daddr), .dwdata(dwdata), .dwe(dwe), .mux_alu_or_dmem_sig(mux_alu_or_dmem_sig), .mux_alu_or_dmem_inp2(mux_alu_or_dmem_inp2), .is_pc(is_pc), .is_imm(is_imm), .mux_alu2_in2(mux_alu2_in2), .raddr3(raddr3), .alu_opn(alu_opn), .raddr1(raddr1), .raddr2(raddr2), .rwe(rwe) , .alu_out(alu_out), .pc_from_reg(pc_from_reg) , .reg_pc_update_val(reg_pc_update_val), .mux_alu_or_dmem_enable(mux_alu_or_dmem_enable), .mux_pc_update_sig(mux_pc_update_sig) , .imm_pc_off(imm_pc_off) , .alu_zero_sig(alu_zero_sig) , .iaddr(iaddr) );
    
    
    
    
    //Reset is asynchronous for combinational sig. outputs  
    always @(posedge clk) begin 
            //    $display( "clk count core %d Instruction: %b ", count, idata);
            //   $display( "rwe %b rwdata %d  raddr1 %d raddr2 %d raddr3 %d ", rwe, rwdata,raddr1,raddr2,raddr3);
         
        if (reset) begin
            iaddr <= 0;
            //daddr <= 0;
            //dwdata <= 0;
            //dwe <= 0;
        end else begin
            //PC update
            iaddr <= iaddr_wdata;
        end
        
    end

endmodule