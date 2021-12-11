module idecode( 
    input [31:0] idata,
    input reset,
    input [31:0] rrdata2,
    input [31:0] drdata,
    input [31:0] alu_out,
    output [31:0] daddr,
    output [31:0] dwdata,
    output [3:0] dwe,
    output       mux_alu_or_dmem_sig,
    output [31:0] mux_alu_or_dmem_inp2,
    output       is_pc,
    output       is_imm,
    output [31:0] mux_alu2_in2,
    output [4:0] raddr3,
    output [3:0] alu_opn,
    output [4:0] raddr1,
    output [4:0] raddr2,
    output       rwe
);
    
    //Outputs of idecode
    reg [31:0] daddr;
    reg [31:0] dwdata;
    reg [3:0] dwe;
    reg      mux_alu_or_dmem_sig;
    reg [31:0] mux_alu_or_dmem_inp2;
    reg      is_pc;
    reg      is_imm;
    reg [31:0] mux_alu2_in2;
    reg [4:0] raddr3;
    reg [3:0] alu_opn;
    reg [4:0] raddr1;
    reg [4:0] raddr2;
    reg      rwe;
    
    //NOTE- here we only use reset for "dwe" - especially for data memory writes, and reset is separately done in reg_file unit.
    //INSTRUCTION DECODE- identify big chunks of instructions with similar opcode (last 7 bits) and do the decision based on that.
    //First decide whether it's a load/store or arith instruction based on 5th bit from right.
    //If 1, it's arith. else L/S
    
    
    //always @( idata or iaddr or alu_out or drdata or rrdata2 or reset ) begin
    always @( *) begin
        case(idata[4])
            //Arithmetic ops -for sure involving register-file and o/p of ALU-> regfile
            1'b1: begin
                //$display("Arith. instr.");
                //Here, we don't want anything to do with DMEM, so we disable w.e. for DMEM.
                dwe = 4'b0000;
                
                //Enable select ALU in MUX_alu_or_dmem... because we want ALU output to go into reg-file.
                mux_alu_or_dmem_sig = 1'b1;
                
                //Now, check if it's lui/auipc - 3rd bit from right has to be 1.
                if(idata[2])
                    begin
                        //Alu Imm operation
                        is_imm = 1'b1;
                        //For ALU it's just a simple add
                        alu_opn = 4'b0000;
                        //Common Dest reg addr bits
                        raddr3 = idata[11:7];
                        
                        //6th bit is 1 => lui
                        if(idata[5])
                            begin
                                //$display("LUI");
                                //PC not being used
                                is_pc = 1'b0;
                                //Read1 from reg file- x0 value
                                raddr1 = 0;
                                
                                //Imm val inp.
                                mux_alu2_in2 = {idata[31:12],{12'b0}}; 
                                //Read2 from reg file-can be anything-preferrably x0.
                                raddr2 = 0;
                                
                                //ONCE VALUES ARE COMPUTED we have to write to some reg - so enable write
                                rwe = 1'b1;
                        
                            end
                        //else => auipc
                        else
                            begin
                                //$display("auipc");
                                //PC is used for alu_in1 instead of reg file Read1
                                is_pc = 1'b1;
                                //Read 1 from reg file-can be anything-preferrably x0.  
                                raddr1 = 0;
                                
                                //Imm val inp.
                                mux_alu2_in2 = {idata[31:12],{12'b0}};
                                //Read 2 from reg file-can be anything-preferrably x0.
                                raddr2 = 0;
                                //ONCE VALUES ARE COMPUTED we have to write to some reg - so enable write
                                rwe = 1'b1;
                            
                            end            
                    end
                //Check if it's arith. instruction involving 2 or more registers- 6th bit is 1
                else if(idata[5])
                    begin                      
                        //Neither pc nor imm val being used
                        is_pc  = 1'b0;
                        is_imm = 1'b0;
                        //default imm val.
                        mux_alu2_in2 = 0;
                        //$display("Arith. instr. involving 2 or more regs");
                        //Common rs1 source reg addr bits
                        raddr1 = idata[19:15];
                        
                        //Common rs2 source reg addr bits
                        raddr2 = idata[24:20];
                        
                        //Common Dest reg addr bits
                        raddr3 = idata[11:7];
                        
                        //ALU opn bits
                        alu_opn[2:0] = idata[14:12];
                        alu_opn[3]   = idata[30];
                        
                        //ONCE VALUES ARE COMPUTED we have to write to some reg - so enable write
                        rwe = 1'b1;
                                
                        
                    end
                //Else it's an arith. instr. involving immediate value
                else
                    begin
                        //PC not used
                        is_pc  = 1'b0;
                        is_imm = 1'b1;
                        
                        //Common rs1 source reg addr bits
                        raddr1 = idata[19:15];
                        //Common Dest reg addr bits
                        raddr3 = idata[11:7];
                        
                        //ALU opn bits
                        alu_opn[2:0] = idata[14:12];
                        
                        //$display("ALU_OPN: %b", alu_opn);
                        //Distinguish b/w shift instructions with 'shamt' immediate parameter and other imm. instrs.
                        
                        //SHIFT Instructions with 'shamt' immediate parameter
                        if( (~idata[13]) & (idata[12]) ) begin
                            //$display("Shift imm val arith. instr. ");
                            //For conflicts in first 3 LSB bits of alu_opn, we use the usual deciding factor idata[30]
                            alu_opn[3]   = idata[30];
                            
                            //Imm val inp - no sign extension
                            mux_alu2_in2 = { {27{1'b0}} , idata[24:20] };
                            
                            //ONCE VALUES ARE COMPUTED we have to write to some reg - so enable write
                            rwe = 1'b1;
                        
                            
                        end
                        
                        //Other arith. instructions : ADDI,ORI,ANDI,...etc. involving imm. parameter
                        else begin
                            //$display("Non shift imm val arith instr, raddr1 %d , raddr2 %d , imm   %d", raddr1,raddr2,mux_alu2_in2 );
                            //$display("raddr3 in control block %b", raddr3);
                            //No operation here has same alu_opn[2:0] bits so set 4th bit of alu_opn to 0
                            alu_opn[3] = 1'b0;
                            //Imm val inp. - sign extended
                            mux_alu2_in2 = { {20{idata[31]}}, idata[31:20]};
                            //ONCE VALUES ARE COMPUTED we have to write to some reg - so enable write
                            rwe = 1'b1; 
                            
                        end
                            
                    
                    end           
            end
            //L/S instructions involving memory            
            1'b0: begin
                //Disable write to reg from ALU, enable reg from DMEM path
                mux_alu_or_dmem_sig = 1'b0;
                //Common rs1 reg addr bits sent to alu
                raddr1 = idata[19:15];
                //PC not being used
                is_pc  = 1'b0;
                //Immediate val always being used
                is_imm = 1'b1;
                //Add opn for address calc
                alu_opn = 4'b0000;
                //Feeding address into memory
                daddr = alu_out;
                //$display("daddr %b", daddr);
                //Note- We assume memory is little endian
                
                //Load instr
                if(!idata[5]) begin
                    //$display("Load instr. ");
                    //Enable reg file write
                    rwe = 1'b1;
                    //Disable memory write
                    dwe = 4'b0000;
                    //Dest. register addr bits
                    raddr3 = idata[11:7];
                    //Sign extended imm val inp for address calculation
                    mux_alu2_in2 = { {20{ idata[31] }} , idata[31:20] };
                    
                    //drdata from mem just fetches the whole word in a block.
                    //We need combinational logic in between this and mux_alu_or_dmem_inp2 
                    
                    //Starting byte position decided by alu_out[1:0] - start address - byte posn in a mem block
                    //ALU gives out target address- based on 2 least significant bits we know from what location to be read
                    //Given this, we either load byte (signed or unsigned), half word or word.
                          
                    //Byte load 8 bits
                    if( (!idata[13])&(!idata[12]) ) begin
                        //No-sign extension LBU
                        if ( idata[14] ) begin 
                            case(alu_out[1:0])
                                2'b00: mux_alu_or_dmem_inp2 = { {24{1'b0}} , drdata[ (0 + 7) : (0) ]  };
                                2'b01: mux_alu_or_dmem_inp2 = { {24{1'b0}} , drdata[ (8*1 + 7) : (8*1) ]  };
                                2'b10: mux_alu_or_dmem_inp2 = { {24{1'b0}} , drdata[ (8*2 + 7) : (8*2) ]  };
                                2'b11: mux_alu_or_dmem_inp2 = { {24{1'b0}} , drdata[ (8*3 + 7) : (8*3) ]  };
                                //Invalid case
                                default : mux_alu_or_dmem_inp2 = 32'bz ;
                                    
                            //mux_alu_or_dmem_inp2 = { {24{1'b0}} , drdata[ (8*alu_out[1:0] + 7) : (8*alu_out[1:0]) ]  };
                            endcase
                        end
                        //LB
                        else  begin
                            case(alu_out[1:0])
                                2'b00: mux_alu_or_dmem_inp2 = {  { 24{drdata[(8*0 + 7)] } } , drdata[ (8*0 + 7) : (8*0) ]  };
                                2'b01: mux_alu_or_dmem_inp2 = {  { 24{drdata[(8*1 + 7)] } } , drdata[ (8*1 + 7) : (8*1) ]  };
                                2'b10: mux_alu_or_dmem_inp2 = {  { 24{drdata[(8*2 + 7)] } } , drdata[ (8*2 + 7) : (8*2) ]  };
                                2'b11: mux_alu_or_dmem_inp2 = {  { 24{drdata[(8*3 + 7)] } } , drdata[ (8*3 + 7) : (8*3) ]  };
                                //Invalid case
                                default: mux_alu_or_dmem_inp2 = 32'bz;
                            
                            endcase
                            //mux_alu_or_dmem_inp2 = {  { 24{drdata[(8*alu_out[1:0] + 7)] } } , drdata[ (8*alu_out[1:0] + 7) : (8*alu_out[1:0]) ]  };
                        end
                      
                    end
                    
                    //Half word load 16 bits
                    else if (  (!idata[13])&(idata[12]) ) begin
                        //No-sign extension LHU
                        if ( idata[14] ) begin 
                            case(alu_out[1:0])
                                2'b00: mux_alu_or_dmem_inp2 = { {16{1'b0}} , drdata[ (8*0 + 15) : (8*0) ]  };
                                2'b01: mux_alu_or_dmem_inp2 = { {16{1'b0}} , drdata[ (8*1 + 15) : (8*1) ]  };
                                2'b10: mux_alu_or_dmem_inp2 = { {16{1'b0}} , drdata[ (8*2 + 15) : (8*2) ]  };
                                2'b11: mux_alu_or_dmem_inp2 = { {16{1'b0}} , drdata[ (8*3 + 15) : (8*3) ]  };
                                //Invalid case
                                default: mux_alu_or_dmem_inp2 = 32'bz;
                            
                            endcase
                           
                            //mux_alu_or_dmem_inp2 = { {16{1'b0}} , drdata[ (8*alu_out[1:0] + 15) : (8*alu_out[1:0]) ]  };
                        end
                        //LH
                        else begin
                            case(alu_out[1:0])
                                2'b00: mux_alu_or_dmem_inp2 = { { 16{drdata[(8*0 + 15)] } } , drdata[ (8*0 + 15) : (8*0) ]  };
                                2'b01: mux_alu_or_dmem_inp2 = { { 16{drdata[(8*1 + 15)] } } , drdata[ (8*1 + 15) : (8*1) ]  };
                                2'b10: mux_alu_or_dmem_inp2 = { { 16{drdata[(8*2 + 15)] } } , drdata[ (8*2 + 15) : (8*2) ]  };
                                2'b11: mux_alu_or_dmem_inp2 = { { 16{drdata[(8*3 + 15)] } } , drdata[ (8*3 + 15) : (8*3) ]  };
                                //Invalid case
                                default: mux_alu_or_dmem_inp2 = 32'bz;
                            
                            endcase
                            //mux_alu_or_dmem_inp2 = { { 16{drdata[(8*alu_out[1:0] + 15)] } } , drdata[ (8*alu_out[1:0] + 15) : (8*alu_out[1:0]) ]  };
                        end
                    end
                    //Word load
                    else begin
                        //Load full 32 bits
                        mux_alu_or_dmem_inp2 = drdata;
                    end
                end
                
                //Store instr
                else begin
                    
                    //Disable reg file write
                    rwe = 1'b0;
                    //Give no memory output during store
                    mux_alu_or_dmem_inp2 = 32'bz;
                    
                    //Sign extended imm val inp for address calculation
                    mux_alu2_in2 = { {20{ idata[31] }} , idata[31:25] , idata[11:7] };
                    
                    //Source reg rs2 addr 
                    raddr2 = idata[24:20];
                    
                    //$display("rs2 addr: %b", raddr2,"Write data: %b ", dwdata);
                    
                    
                    //Now, we can change dwe based on the kind of store instr.
                    //Again, we can decide starting position based on 2 least significant bits of ALU output which gives target address 
                    //Now, shift "rs2" value and decide "dwe" appropriately based on sb or sh or sw and give into DMEM input write data bus
                    
                    //Note- Here we  use the reset before deciding "dwe" for safety- as to not to write to memory while reset is on
                    
                    //byte store SB
                    //$display("ALU_out last 2 bits: %b" , alu_out[1:0]);
                    if ( (!idata[13])&(!idata[12]) ) begin
                        if(!reset) begin
                        //$display("SB");
                        case (alu_out[1:0])
                            2'b00: begin 
                                dwe = 4'b0001;
                                dwdata = rrdata2 << 0;
                            end
                            2'b01: begin 
                                dwe = 4'b0010;
                                dwdata = rrdata2 << 8;
                            end
                            2'b10: begin 
                                dwe = 4'b0100;
                                dwdata = rrdata2 << 16;
                            end
                            2'b11: begin 
                                dwe = 4'b1000;
                                dwdata = rrdata2 << 24;
                            end
                            //Invalid case
                            default : dwe = 4'b0000;
                        endcase
                        end
                        
                        else 
                            dwe = 4'b0000;
                    end
                    
                    // Half word store SH
                    //This has only 3 possibilites for store (aligned):
                    //byte 4 ,3 
                    //byte 3 ,2
                    //byte 2 ,1
                    else if ( (!idata[13])&(idata[12]) ) begin
                        if(!reset) begin
                            //$display("SH, alu_out %b rrdata2 %d raddr2 %d", alu_out, rrdata2, raddr2);
                        case (alu_out[1:0])
                            2'b00: begin
                                dwe = 4'b0011;
                                dwdata = rrdata2 << 0;
                            end
                            2'b01: begin 
                                dwe = 4'b0110;
                                dwdata = rrdata2 << 8;
                            end
                            2'b10: begin 
                                dwe = 4'b1100;
                                dwdata = rrdata2 << 16;
                            end
                            //Invalid cases
                            2'b11: dwe = 4'b0000;
                            default : dwe = 4'b0000;
                        endcase
                        end
                        
                        else 
                            dwe = 4'b0000;
                            
                    end
                    //Store word
                    else  begin
                        
                        if(!reset) begin
                        //$display("SW, raddr1 %d , raddr2 %d , imm   %d", raddr1,raddr2,mux_alu2_in2 );
                        dwe = 4'b1111;
                        dwdata = rrdata2;
                        end
                        
                        else 
                            dwe = 4'b0000;
                    end
                end
            end
            
            default: begin
                //NOP
            end
        endcase
        
    end
    
endmodule 