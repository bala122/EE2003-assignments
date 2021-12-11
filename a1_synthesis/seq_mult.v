//                              -*- Mode: Verilog -*-
// Filename        : seq-mult.v
// Description     : Sequential multiplier
// Author          : Nitin Chandrachoodan

// This implementation corresponds to a sequential multiplier, but
// most of the functionality is missing.  Complete the code so that
// the resulting module implements multiplication of two numbers in
// twos complement format.

// All the comments marked with *** correspond to something you need
// to fill in.

// This style of modeling is 'behavioural', where the desired
// behaviour is described in terms of high level statements ('if'
// statements in verilog).  This is where the real power of the
// language is seen, since such modeling is closest to the way we
// think about the operation.  However, it is also the most difficult
// to translate into hardware, so a good understanding of the
// connection between the program and hardware is important.

`define width 8
`define ctrwidth 4

//Note- The following module (esp. combinational logic part) is written in the very basic fashion to guarantee synthesizability.
module seq_mult (
		 // Outputs
		 p, rdy, 
		 // Inputs
		 clk, reset, a, b
		 ) ;
    input 		 clk, reset;
    input [`width-1:0] 	 a, b;
   // *** Output declaration for 'p'
    output [2*`width-1:0] p;
    output 		 rdy;
   
   // *** Register declarations for p, multiplier, multiplicand, rdy signal, 5 bit counter.
    reg signed [2*`width-1:0] multiplicand;
    reg signed [`width-1:0] multiplier; 
    reg signed [2*`width-1:0] p;
    reg rdy;
    //5 bit counter
    reg [`ctrwidth:0]  ctr;
    
   //*** Outputs, inputs and intermediate signals of accumulator and multiplexer modules parts of which are behaviourally modelled.
    //Output of the multiplexer to choose between 0 and the multiplicand 
    reg signed [2*`width-1:0] mux_out; 
    //neg_mux_out stores the negated value of the output of the MUX- comes to use when checking last multiplier bit.
    wire  [2*`width-1:0] neg_mux_out ;
    //mux_sel is basically the select line for the mux based on the current multiplier bit
    wire mux_sel;
    
    //acc_sig is for signalling to add or subtract multiplicand from partial product.
    wire acc_sig;
    //Output of the accumulator
    wire signed [2*`width-1:0] acc_out;
    //acc_in2 is the 2nd input to the accumulator- comes from MUX (either +ve or -ve of the MUX output)
    reg signed [2*`width-1:0] acc_in2;
    
    //Carry out signal for the 16 bit add
    wire signed [2*`width-1:0] carry;
    //carry_neg signal for negating a number, ie, complimenting each bit and adding 1'b1 overall. 
    //In the above process of adding 1'b1, we'll need a carry signal (carry_neg)
    wire  [2*`width-1:0] carry_neg;
    
    //acc_in2 is the 2nd input to accumulator 
    //wire signed [2*`width-1:0] acc_in2;
    //***Mux signals
    //Typical signals in 2x1 MUX 
    //mux_in1 -input 1
    //mux_in2 -input 0
    //mux_sel -1 bit select line 
    //wire signed [2*`width-1:0] mux_in1;
    //wire signed [2*`width-1:0] mux_in2;
     
    
    //multiplier <= a;     
    //multiplicand 	<= {{`width{b[`width-1]}}, b}; // sign-extend
                
    //reg signed [`width-1:0] multiplier_rst;
    //reg signed [2*`width-1:0] multiplicand_rst;
    
    //SEQUENTIAL PART
   
    //Signal to check if ctr is less than 8-total iterations needed
    //If 4th bit is 0 it means its less than 8
    wire ctr_sig;
    assign ctr_sig= ~ctr[3];
    
  
    
    //Following code describes a sequential multiplier which accumulates multiplicand into partial product everytime in single cycle.
    //Here, posedge reset is removed because reset signal as such is an asynchronous reset- so we stick to that.
    //If we had posedge reset-yosys doesn't synthesize because it can't set multiplier to 'a' and multiplicand to 'b'(sign-extended) at reset
    always @(posedge clk) begin 
        //If reset make rdy, partial product, counter 0 and set multiplier to a and multiplicand to a sign-extended b.
        if (reset)
            begin
                rdy <= 0;
                p  <= 0;
                ctr  <= 0;
                //multiplier <= multplier_rst value     
                multiplier <= a;     
                //multiplicand 	<= multiplicand_rst value
                multiplicand 	<= {{`width{b[`width-1]}}, b}; // sign-extend
            end
        else 
            begin
              
                //Run counter for `width number of times.
                if (ctr_sig)
                    begin
                        // *** Code for multiplication
                        //Logical Shift the multiplicand left by 1 bit
                        multiplicand <= multiplicand << 1; 
                        //Accumulator output sent into product p
                        p <= acc_out ;
                    end 
                else
                    begin
                        rdy <= 1; 		// Assert 'rdy' signal to indicate end of multiplication
                    end
                //Incrementing counter every posedge apart from when reset and ce
                //ctr <= ctr+ 5'd1;
                //The following code is for a carry lookahead add for ctr with 1'b1.
                //We can't do ripple add under a behavioural block using wires.
                ctr[0] <= ctr[0]^(1'b1);
                ctr[1] <= ctr[1]^(ctr[0]&(1'b1));
                ctr[2] <= ctr[2]^(ctr[1]&ctr[0]&(1'b1));
                ctr[3] <= ctr[3]^(ctr[2]&ctr[1]&ctr[0]&(1'b1));
                ctr[4] <= ctr[4]^(ctr[3]&ctr[2]&ctr[1]&ctr[0]&(1'b1));
                
                end
            
    end
    
    //COMBINATIONAL PART.
    //MUX input signals.
    //MUX takes in current multiplier bit and chooses if it should send multiplicand to accumulator block or not.
    assign mux_sel = multiplier[ctr];
    //MUX block
    // First choose between 0 and multiplicand based on multiplier bit
    always @(mux_sel or multiplicand)
        begin
            case (mux_sel)
                1'b1: mux_out <= multiplicand;
                1'b0: mux_out <= 0;
            endcase
        end 
    
    
    //When you have a -ve multiplier, instead of adding multiplicand to partial product when at the MSB of the multiplier (last cycle),
    //you need to subtract the multiplicand from the partial product accumulated so far.
    //Intuition is that by convention of 2s compliment if you multiply multiplicand with -ve multiplier, there will be a sign flip at the MSB and hence subtraction instead.. 
    //..of addition for the multiplicand and partial product

    //So, Control signal deciding when to subtract- when at MSB of multiplier and if it's -ve is acc_sig. 
    assign acc_sig = (ctr == `width-1 ) & (multiplier[`width-1]);
    
          
    //Actual accumulator-does subtraction or addition based on acc_sig.
    
    //Negation part
    //We negate the multiplicand based on acc_sig and do a normal add operation later in 2s compliment form which is valid.
    //Negate mux_out and store in acc_in2 based on acc_sig
    //Compliment each bit and add 1 finally
    //Following is done bitwise for synthesizability ( instead of just "-" )
      
    assign neg_mux_out[0] = (~mux_out[0])^(1'b1);
    assign carry_neg[0] = ~mux_out[0];    
    
    assign neg_mux_out[1]= (~mux_out[1])^carry_neg[0];
    assign carry_neg[1]=   (~mux_out[1])&carry_neg[0];

    assign neg_mux_out[2]= (~mux_out[2])^carry_neg[1];
    assign carry_neg[2]= (~mux_out[2])&carry_neg[1];

    assign neg_mux_out[3]= (~mux_out[3])^carry_neg[2];
    assign carry_neg[3]= (~mux_out[3])&carry_neg[2];

    assign neg_mux_out[4]= (~mux_out[4])^carry_neg[3];
    assign carry_neg[4]= (~mux_out[4])&carry_neg[3];

    assign neg_mux_out[5]= (~mux_out[5])^carry_neg[4];
    assign carry_neg[5]= (~mux_out[5])&carry_neg[4];

    assign neg_mux_out[6]= (~mux_out[6])^carry_neg[5];
    assign carry_neg[6]= (~mux_out[6])&carry_neg[5];

    assign neg_mux_out[7]= (~mux_out[7])^carry_neg[6];
    assign carry_neg[7]= (~mux_out[7])&carry_neg[6];

    assign neg_mux_out[8]= (~mux_out[8])^carry_neg[7];
    assign carry_neg[8]= (~mux_out[8])&carry_neg[7];

    assign neg_mux_out[9]= (~mux_out[9])^carry_neg[8];
    assign carry_neg[9]= (~mux_out[9])&carry_neg[8];

    assign neg_mux_out[10]= (~mux_out[10])^carry_neg[9];
    assign carry_neg[10]= (~mux_out[10])&carry_neg[9];

    assign neg_mux_out[11]= (~mux_out[11])^carry_neg[10];
    assign carry_neg[11]= (~mux_out[11])&carry_neg[10];

    assign neg_mux_out[12]= (~mux_out[12])^carry_neg[11];
    assign carry_neg[12]= (~mux_out[12])&carry_neg[11];

    assign neg_mux_out[13]= (~mux_out[13])^carry_neg[12];
    assign carry_neg[13]= (~mux_out[13])&carry_neg[12];

    assign neg_mux_out[14]= (~mux_out[14])^carry_neg[13];
    assign carry_neg[14]= (~mux_out[14])&carry_neg[13];

    assign neg_mux_out[15]= (~mux_out[15])^carry_neg[14];
    assign carry_neg[15]= (~mux_out[15])&carry_neg[14];
    
    
    //MUX to choose between +ve of mux_out or -ve of mux_out based on acc_sig.
    //Storing either +mux_out or -mux_out into 2nd input of accumulator.
    //The choice is based on acc_sig which depends on the last multiplier bit and when we're operating at that bit.
    always @(acc_sig or mux_out or neg_mux_out) begin
        case (acc_sig)
            1'b0: acc_in2<=mux_out;  //acc_out <= +mux_out + p;               
            1'b1: acc_in2<= neg_mux_out; //acc_out <= -mux_out + p;            
        endcase
    end
    
    
    //Accumulator or Adder block
    //Accumulator input signals:
    //Inputs are mux_out and acc_in2= partial product.
    //acc_sig decides whether to add or subtract.
    //Following is a normal 2s compliment 16 bit addition (neglecting 16th carry out): 
    assign acc_out[0] = p[0]^acc_in2[0];
    assign carry[0] = p[0]&acc_in2[0];
    
    assign acc_out[1]= p[1]^acc_in2[1]^carry[0];
    assign carry[1]= p[1]&acc_in2[1] | acc_in2[1]&carry[0] | p[1]&carry[0];
    assign acc_out[2]= p[2]^acc_in2[2]^carry[1];
    assign carry[2]= p[2]&acc_in2[2] | acc_in2[2]&carry[1] | p[2]&carry[1];
    assign acc_out[3]= p[3]^acc_in2[3]^carry[2];
    assign carry[3]= p[3]&acc_in2[3] | acc_in2[3]&carry[2] | p[3]&carry[2];
    assign acc_out[4]= p[4]^acc_in2[4]^carry[3];
    assign carry[4]= p[4]&acc_in2[4] | acc_in2[4]&carry[3] | p[4]&carry[3];
    assign acc_out[5]= p[5]^acc_in2[5]^carry[4];
    assign carry[5]= p[5]&acc_in2[5] | acc_in2[5]&carry[4] | p[5]&carry[4];
    assign acc_out[6]= p[6]^acc_in2[6]^carry[5];
    assign carry[6]= p[6]&acc_in2[6] | acc_in2[6]&carry[5] | p[6]&carry[5];
    assign acc_out[7]= p[7]^acc_in2[7]^carry[6];
    assign carry[7]= p[7]&acc_in2[7] | acc_in2[7]&carry[6] | p[7]&carry[6];
    assign acc_out[8]= p[8]^acc_in2[8]^carry[7];
    assign carry[8]= p[8]&acc_in2[8] | acc_in2[8]&carry[7] | p[8]&carry[7];
    assign acc_out[9]= p[9]^acc_in2[9]^carry[8];
    assign carry[9]= p[9]&acc_in2[9] | acc_in2[9]&carry[8] | p[9]&carry[8];
    assign acc_out[10]= p[10]^acc_in2[10]^carry[9];
    assign carry[10]= p[10]&acc_in2[10] | acc_in2[10]&carry[9] | p[10]&carry[9];
    assign acc_out[11]= p[11]^acc_in2[11]^carry[10];
    assign carry[11]= p[11]&acc_in2[11] | acc_in2[11]&carry[10] | p[11]&carry[10];
    assign acc_out[12]= p[12]^acc_in2[12]^carry[11];
    assign carry[12]= p[12]&acc_in2[12] | acc_in2[12]&carry[11] | p[12]&carry[11];
    assign acc_out[13]= p[13]^acc_in2[13]^carry[12];
    assign carry[13]= p[13]&acc_in2[13] | acc_in2[13]&carry[12] | p[13]&carry[12];
    assign acc_out[14]= p[14]^acc_in2[14]^carry[13];
    assign carry[14]= p[14]&acc_in2[14] | acc_in2[14]&carry[13] | p[14]&carry[13];
    assign acc_out[15]= p[15]^acc_in2[15]^carry[14];
    assign carry[15]= p[15]&acc_in2[15] | acc_in2[15]&carry[14] | p[15]&carry[14];
    
    
    
endmodule // seqmult
