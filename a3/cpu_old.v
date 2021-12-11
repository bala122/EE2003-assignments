module cpu_old (
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
    reg [31:0] daddr;
    reg signed [31:0] dwdata;
    reg [3:0]  dwe;

    //ALU inputs and outputs for ALU and MUX wires
    
    //ALU inputs
    //To decide what kind of operation
    reg [3:0] alu_opn;
    //32 bit operand 1
    reg signed [31:0] alu_inp1;
    //32 bit operand 2 - this could be imm. operand.
    reg signed [31:0] alu_inp2;
    
    //Alu outputs
    wire signed [31:0] alu_out;
    wire              alu_zero_sig;
    
    //MUX_ALU1 wires
    //To check if alu op involves pc
    reg is_pc;
 
    //MUX_ALU2 wires
    //To check if alu op is imm or not
    reg is_imm;
    //wire signed [31:0] mux_alu2_in1;
    reg signed [31:0] mux_alu2_in2;
    //reg signed [31:0] mux_alu2_out;
    reg      enab_mux2;
    
    //MUX_ALU_OR_DMEM inputs
    wire signed [31:0] mux_alu_or_dmem_inp1;
    reg signed [31:0] mux_alu_or_dmem_inp2;
    reg                mux_alu_or_dmem_sig;
    
    
    //REG-FILE inputs and output
    reg        [4:0]  raddr1;
    reg        [4:0]  raddr2;
    reg        [4:0]  raddr3;
    reg signed [31:0] rwdata;
    reg               rwe;
    //Comb. output signal for above two for writes in next clk cycle.
    //reg signed [31:0] rwdata_sig;
    //reg               rwe_sig;
    //reg        [4:0]  raddr1_sig;
    wire signed [31:0] rrdata1;
    wire signed [31:0] rrdata2;
    
    
    //Note- This module itself will act as the main control unit with 2 submodules
    //Instantiation of other units:
    
    
  
 
    
    //INSTRUCTION DECODE- identify big chunks of instructions with similar opcode (last 7 bits) and do the decision based on that.
    //First decide whether it's a load/store or arith instruction based on 5th bit from right.
    //If 1, it's arith. else L/S
    
    //always @( idata or iaddr or alu_out or drdata or rrdata2 or reset ) begin
    always @( *) begin
         if(reset) begin
            daddr = 0;
            dwdata = 0;
            dwe = 4'b0000;
            rwe = 0;
            $display("RESET , iaddr %b",iaddr);
        end
        else begin
        case(idata[4])
            //Arithmetic ops -for sure involving register-file and o/p of ALU-> regfile
            1'b1: begin
                //$display("Arith. instr.");
                //Here, we don't want anything to do with DMEM, so we disable w.e. for DMEM.
                dwe = 4'b0000;
                
                
                //Enable select ALU in MUX_alu_or_dmem...
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
                                $display("LUI");
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
                                $display("auipc");
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
                        
                        //Instructions with 'shamt' immediate parameter
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
                            //$display("Non-shift imm. value arith. instr.");
                            //$display("rrdata 1 , raddr 2: %b %b",rrdata1, raddr2);
                            //$display("raddr3 in control block %b", raddr3);
                            //No opn here has same alu_opn[2:0] bits
                            alu_opn[3] = 1'b0;
                            enab_mux2=  1'b1;
                            //Imm val inp. - sign extended
                            mux_alu2_in2 = { {20{idata[31]}}, idata[31:20]};
                            //ONCE VALUES ARE COMPUTED we have to write to some reg - so enable write
                            rwe = 1'b1;
                            $display("is imm ? %d",is_imm);
                            $display("Alu out %b:", alu_out);
                            $display("mux_alu2_in2: %d", mux_alu2_in2);
                              
                                
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
                    
                    //$display("rs2 addr: %b", raddr2);
                    //$display("Write data: %b ", dwdata);
                    //Now, we can change dwe based on the kind of store instr.
                    //Give lower bytes of rs2 data to write_data_to_mem signal based on sb or sh or sw
                    
                    //byte store SB
                    //$display("ALU_out last 2 bits: %b" , alu_out[1:0]);
                    if ( (!idata[13])&(!idata[12]) ) begin 
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
                    
                    // Half word store SH
                    //This has only 3 possibilites for store (aligned):
                    //byte 4 ,3 
                    //byte 3 ,2
                    //byte 2 ,1
                    else if ( (!idata[13])&(idata[12]) ) begin
                        $display("SH, iaddr %d rrdata2 %d raddr2 %d", iaddr, rrdata2, raddr2);
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
                    //Store word
                    else  begin
                        //$display("SW, raddr1 %d , raddr2 %d , imm   %d", raddr1,raddr2,mux_alu2_in2 );
                        dwe = 4'b1111;
                        dwdata = rrdata2;
                    end
                end
            end
            
            default: begin
                //NOP
            end
        endcase
        end
       
    end
    
    //I/p to ALU are two mux outputs- one after Read1-regfile o/p and other after Read2-regfile o/p  
    
    //Mux_alu1-deciding between pc_val or read1-regfile
    //Note- mux_alu1_in1 - from regfile read1
    //      mux_alu1_in2 - from PC         
    //assign mux_alu1_in1 = rrdata1;
    //assign mux_alu1_in2 = iaddr;
    always @(rrdata1 or iaddr or is_pc or reset ) begin
        case(is_pc)
            1'b1: alu_inp1 = iaddr; 
            1'b0: begin alu_inp1 = rrdata1;
                //$display("rrdata1, alu_inp1, %d", rrdata1);
            end
            
        endcase
    end
    
    
    //Mux_alu2-deciding between imm val or read2-regfile
    //Note- mux_alu2_in1 - from regfile read2
    //      mux_alu2_in2 - from immediate val
    //assign mux_alu2_in1 = rrdata2;
    always @(rrdata2 or mux_alu2_in2 or is_imm or reset) begin
        $display("ALU_INP2 %d iaddr %d is_imm %b rrdata2 %d",mux_alu2_in2, iaddr, is_imm, rrdata2);
        case(is_imm)
            1'b1: alu_inp2 = mux_alu2_in2; 
            1'b0: alu_inp2 = rrdata2;
            
        endcase
    end
    
    
    //reg [12:0] count;
    //initial begin
    //count = 0;
    //end
    
    //MUX to decide b/w ALU o/p and DMEM output to go into regfile.
    //Mux_alu_or_dmem
    //mux_alu_or_dmem_inp1 - from ALU data output- alu_out
    //mux_alu_or_dmem_inp2 - from DMEM drdata - modified by control unit already
    //mux_alu_or_dmem_sig - decides what rwdata is going to be- if 1 then choose ALU, else dmem
    
    //assign mul_alu_or_dmem_inp1 = alu_out;
    always @(mux_alu_or_dmem_inp2 or mux_alu_or_dmem_sig or alu_out ) begin
        case ( mux_alu_or_dmem_sig)
            //Choose ALU o/p for rwdata 
            1'b1: begin rwdata =  alu_out;
                $display("Choosing alu, %d rwe, %b raddr3, %b", alu_out,rwe, raddr3);
            end
            //Choose DMEM o/p for rwdata
            1'b0: rwdata =  mux_alu_or_dmem_inp2;
        endcase
    end
    
        //ALU Instantiation
    
    alu cpu_1 (  .alu_opn(alu_opn), .alu_inp1(alu_inp1), .alu_inp2(alu_inp2), .alu_zero_sig(alu_zero_sig), .alu_out(alu_out) , .reset(reset)  );
   
    //Reg File Instantiation
    
    reg_file cpu_2 ( .clk(clk), .raddr1(raddr1) , .reset(reset) , .raddr2(raddr2), .raddr3(raddr3), .rwdata(rwdata), .rwe(rwe), .rrdata1(rrdata1), .rrdata2(rrdata2)   );
    
    //Reset is synchronous for combinational sig. outputs ? - Synthesizability is a qn. Hence, commented  
    always @(posedge clk) begin 
           // count <= count +1;
           //if(count < 20) begin
            //    $display( "clk count core %d Instruction: %b ", count, idata);
            //   $display( "rwe %b rwdata %d  raddr1 %d raddr2 %d raddr3 %d ", rwe, rwdata,raddr1,raddr2,raddr3);
            //end
         
        if (reset) begin
            iaddr <= 0;
            //daddr <= 0;
            //dwdata <= 0;
            //dwe <= 0;
        end else begin
            //PC increment
            iaddr <= iaddr + 4;
            if(iaddr<20) begin
            $display("daddr: %b," ,daddr ,"dwdata: %b," ,dwdata ,"dwe: %b," ,dwe , "iaddr %b", iaddr , "rwdata %d", rwdata);
            end
        end
    end

endmodule