module idecode( 
    input [31:0] idata,
    input reset,
    input [31:0] rrdata2,
    input [31:0] drdata,
    input [31:0] alu_out,
    input        alu_zero_sig,
    input [31:0]      iaddr,
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
    output       rwe,
    output [31:0] pc_from_reg,
    output [31:0] reg_pc_update_val,
    output        mux_alu_or_dmem_enable,
    output [1:0]    mux_pc_update_sig,
    output [31:0] imm_pc_off
);    

    //Outputs of Idecode
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
    reg [31:0] pc_from_reg;
    reg [31:0] reg_pc_update_val;
    reg        mux_alu_or_dmem_enable;
    reg        mux_pc_update_sig;
    reg [31:0]    imm_pc_off;
    
    //NOTE- here we only use reset for "dwe" - especially for data memory writes, and reset is separately done in reg_file unit.
    //    - For synthesizability a lot of wires unrelated to the instruction decoded in the block are given "fake" values to prevent creating LATCHES.
    
    //INSTRUCTION DECODE- identify big chunks of instructions with similar opcode (last 7 bits) and do the decision based on that.
    //First decide whether it's a load/store or arith instruction based on 5th bit from right.
    //If 1, it's arith. else L/S
    
    //always @( idata or iaddr or alu_out or drdata or rrdata2 or alu_zero_sig or alu_out ) begin
    always @* begin    
        case(idata[4])
            //Arithmetic ops -for sure involving register-file and o/p of ALU-> regfile
            1'b1: begin
                //Fake imm pc off
                imm_pc_off = 32'bz;
                //Fake pc_from_reg (only jalr- for direct pc update)
                pc_from_reg       = 32'bz;
                //Fake reg_pc_update_val (only for JAL/JALR)
                reg_pc_update_val = 32'bz;
                //Feeding fake address into memory
                daddr = 32'bz;
                //Fake write data
                dwdata = 32'bz;
                //Give no memory output into during arith ops
                mux_alu_or_dmem_inp2 = 32'bz;
                //Normal PC update
                mux_pc_update_sig = 2'b00;
                //$display("Arith. instr.");
                //Here, we don't want anything to do with DMEM, so we disable w.e. for DMEM.
                dwe = 4'b0000;
                //We have to write to some reg finally- so enable write
                rwe = 1'b1;
                
                //Enable select ALU in MUX_alu_or_dmem...
                mux_alu_or_dmem_enable = 1'b1;
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
                        
                            end            
                    end
                //Check if it's arith. R type instruction involving 2 or more registers- 6th bit is 1
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
                        
                    end
                //Else it's an arith. instr. involving immediate value
                else
                    begin
                        //PC not used
                        is_pc  = 1'b0;
                        //Common rs1 source reg addr bits
                        raddr1 = idata[19:15];
                        
                        //Imm val used
                        is_imm = 1'b1;
                        //Read2 from reg file-can be anything-preferrably x0.
                        raddr2 = 0;
                        
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
                            
                        end
                        
                        //Other arith. instructions : ADDI,ORI,ANDI,...etc. involving imm. parameter
                        else begin
                            //$display("Non shift imm val arith instr, raddr1 %d , raddr2 %d , imm   %d", raddr1,raddr2,mux_alu2_in2 );
                            //$display("Non-shift imm. value arith. instr.");
                            //$display("rrdata 1 , raddr 2: %b %b",rrdata1, raddr2);
                            //$display("Alu out %b:", alu_out);
                            
                            //$display("raddr3 in control block %b", raddr3);
                            //No opn here has same alu_opn[2:0] bits
                            alu_opn[3] = 1'b0;
                            //Imm val inp. - sign extended
                            mux_alu2_in2 = { {20{idata[31]}}, idata[31:20]};
                            
                        end
                        
                    end
                
            end
            //L/S instructions involving memory OR Branch           
            1'b0: begin
                //For branch or not we check if 7th bit is 1
                //If 7th bit is not 1, then its L/S :
                
                //Load or Store-
                if(!idata[6]) begin
                    //Normal PC update
                    mux_pc_update_sig = 2'b00;
                    //Fake imm pc off
                    imm_pc_off = 32'bz;
                    //Fake pc_from_reg (only jalr- for direct pc update)
                    pc_from_reg       = 32'bz;
                    //Fake reg_pc_update_val (only for JAL/JALR)
                    reg_pc_update_val = 32'bz;
                    //Disable write to reg from ALU, enable reg from DMEM path
                    mux_alu_or_dmem_enable = 1'b1;
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
                        //Fake write data
                        dwdata = 32'bz;
                        //Dest. register addr bits
                        raddr3 = idata[11:7];
                        
                        //Sign extended imm val inp for address calculation
                        mux_alu2_in2 = { {20{ idata[31] }} , idata[31:20] };
                        //Read2 from reg file-can be anything-preferrably x0.
                        raddr2 = 0;
                        
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
                        //Write addr to regfile set to 0
                        raddr3 = 0;
                        
                        //Give no memory output during store
                        mux_alu_or_dmem_inp2 = 32'bz;
                        
                        //Sign extended imm val inp for address calculation
                        mux_alu2_in2 = { {20{ idata[31] }} , idata[31:25] , idata[11:7] };
                        //Source reg rs2 addr 
                        raddr2 = idata[24:20];
                        
                        
                        //Now, we can change dwe based on the kind of store instr.
                        //Give lower bytes of rs2 data to write_data_to_mem signal based on sb or sh or sw
                        
                        if(!reset) begin
                            if ( (!idata[13]) ) begin 
                                case (alu_out[1:0]) 
                                    2'b00: dwdata = rrdata2 << 0;
                                    2'b01: dwdata = rrdata2 << 8;
                                    2'b10: dwdata = rrdata2 << 16;
                                    2'b11: dwdata = rrdata2 << 24;
                                endcase
                                //byte store SB
                                //$display("ALU_out last 2 bits: %b" , alu_out[1:0]);
                                if((!idata[12])) begin
                                    //$display("SB");
                                    case (alu_out[1:0])
                                        2'b00: begin 
                                            dwe = 4'b0001;
                                            //dwdata = rrdata2 << 0;
                                        end
                                        2'b01: begin 
                                            dwe = 4'b0010;
                                            //dwdata = rrdata2 << 8;
                                        end
                                        2'b10: begin 
                                            dwe = 4'b0100;
                                            //dwdata = rrdata2 << 16;
                                        end
                                        2'b11: begin 
                                            dwe = 4'b1000;
                                            //dwdata = rrdata2 << 24;
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
                                else if ( idata[12]) begin
                                    //$display("SH");
                                    case (alu_out[1:0])
                                        2'b00: begin 
                                            dwe = 4'b0011;
                                            //dwdata = rrdata2 << 0;
                                        end
                                        2'b01: begin 
                                            dwe = 4'b0110;
                                            //dwdata = rrdata2 << 8;
                                        end
                                        2'b10: begin 
                                            dwe = 4'b1100;
                                            //dwdata = rrdata2 << 16;
                                        end
                                        //Invalid cases
                                        2'b11: dwe = 4'b0000;
                                        default : dwe = 4'b0000;
                                    endcase
                                    
                                end
                                
                            end
                            //Store word
                            else  begin
                                //$display("SW, raddr1 %d , raddr2 %d , imm   %d", raddr1,raddr2,mux_alu2_in2 );
                                dwe = 4'b1111;
                                dwdata = rrdata2;
                            end
                        end
                        //If reset don't give write access to DMEM
                        else begin
                            dwe = 4'b0000;
                            dwdata = 32'bz;
                        end
                        
                    end
                end
                
                //Branch Instr
                else begin
                    //No memory writes
                    dwe = 4'b0000;
                    //Fake write data
                    dwdata = 32'bz;
                    //Feeding fake address into memory
                    daddr = 32'bz;
                    //Give no memory output into reg during branch
                    mux_alu_or_dmem_inp2 = 32'bz;
                    //fake mux_alu_or_dmem_sig
                    mux_alu_or_dmem_sig = 1'bz;
                    
                    // Condition check branches (BEQ...) if 3rd bit from right is 0
                    if(!idata[2]) begin
                        //We mainly use the ALU for only conditional checks. Rest additions are separately done.
                        //No register writes
                        rwe = 0;
                        raddr3 = 0;
                        
                        //Default imm inp value to alu = 0
                        mux_alu2_in2 = 0;
                        
                        //No writes to reg file here
                        mux_alu_or_dmem_enable = 1'bz;
                        
                        //Fake reg_pc_update_val (only for JAL/JALR) - ra store
                        reg_pc_update_val = 32'bz;
                        //Fake pc_from_reg (only jalr- for direct pc update)
                        pc_from_reg       = 32'bz;
                        
                        //Source reg rs1 addr bits
                        raddr1 = idata[19:15];
                        //Source reg rs2 addr bits
                        raddr2 = idata[24:20];
                        //Setting to read rs1,rs2
                        is_imm = 1'b0;
                        is_pc  = 1'b0;
                        
                        //Immediate offset val is 12 bit assign to bits [12:1] , set LSB to 0 then sign extend                        
                        imm_pc_off = {  {19{idata[31]}} , {idata[31]} , { idata[7] } , {idata[30:25]} , {idata[11:8]} , 1'b0 };
                        
                        //Condition checks
                        //Sending opcode to ALU
                        alu_opn[2:0] = idata[14:12];
                        //Keep 4th bit by default 0
                        alu_opn[3]   = 1'b0;
                        
                        
                        //alu_zero_sig - branch or not signal tells whether condn is satisfied
                        if(alu_zero_sig)
                            mux_pc_update_sig = 2'b01;
                        //If condn fails- sequential update
                        else
                            mux_pc_update_sig = 2'b00;
                    end
                    
                    //Else either jal or jalr
                    //Note- Here for JAL and JALR, while writing pc + 4 into 'rd', we DONT use the ALU. We use a separate adder and for update into reg-file, a separate "pc_update_path" is chosen.
                    //This is done because we need the ALU in jalr for doing rs1 + imm_value to store into pc for branch
                    //For JAL- the immediate val is added into pc and stored in it via the "pc_update_path", ALU not used here.
                    
                    //If 4th bit is 1, then JAL 
                    else if (idata[3]) begin
                        //Default imm inp value to alu = 0
                        mux_alu2_in2 = 0;
                        
                        //reg write enable
                        rwe = 1'b1;
                        
                        //Nothing given to alu
                        //Set default alu opn
                        alu_opn = 4'b0000;
                        //Pc not being fed to alu
                        is_pc = 1'b0;
                        //Imm val not being fed into alu
                        is_imm = 1'b0;
                        raddr1 = 5'bz;
                        raddr2 = 5'bz;
                        
                        //Fake pc_from_reg (only jalr- for direct pc update)
                        pc_from_reg       = 32'bz;
                        
                        //Dest reg address bits
                        raddr3 = idata[11:7];
                        //Immediate offset val, sign extended, multiple of 2 bytes
                        imm_pc_off = {  {12{idata[31]}} , {idata[31]}, {idata[19:12] } , {idata[20]},{idata[30:21]},1'b0};
                        //Setting pc rel offset type update
                        mux_pc_update_sig = 2'b01;
                        //Choosing "pc_update_path" instead of ALU or DMEM
                        mux_alu_or_dmem_enable = 1'b0;
                        //Storing pc + 4 in rd
                        reg_pc_update_val = iaddr + 4;
                        
                    end
                    
                    //Else jalr
                    else begin
                        //reg write enable
                        rwe = 1'b1;
                        //Dest reg address bits
                        raddr3 = idata[11:7];
                        //Fake imm pc off(here its not PC rel)
                        imm_pc_off = 32'bz;
                        //rs1 addr bits
                        raddr1 = idata[19:15];
                        is_pc = 1'b0;
                        //Immediate val for addition, with sign extension - needn't be multiple of 2
                        is_imm = 1'b1;
                        //Fake rs2 addr
                        raddr2 = 5'bz;
                        
                        mux_alu2_in2 = { {20{idata[31]}} , {idata[31:20]}} ;
                        //Add
                        alu_opn = {1'b0, {idata[14:12]} };
                        //Choosing direct pc update from reg path:
                        mux_pc_update_sig = 2'b10;
                        // Storing alu_out into reg that directly updates pc and setting LSB to 0
                        pc_from_reg = { {alu_out[31:1]} , {1'b0} };
                        //Storing pc + 4 into 'rd'
                        //Choosing "pc_update_path" instead of ALU or DMEM
                        mux_alu_or_dmem_enable = 1'b0;
                        //Storing pc+4 in rd
                        reg_pc_update_val = iaddr + 4;
                    end
                    
                end
            end
            
            default: begin
                //NOP
            end
            
        endcase
        
    end
     
endmodule
