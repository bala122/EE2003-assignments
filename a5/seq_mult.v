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
    reg [`ctrwidth:0]  ctr;
   //*** Outputs of accumulator and multiplexer modules behaviourally modelled.
    reg signed [2*`width-1:0] mux_out; 
    reg signed [2*`width-1:0] acc_out;
    //***Accumulator input signals
    //acc_sig is for signalling to add or subtract multiplicand from partial product.
    wire acc_sig;
    //acc_in2 is the 2nd input to accumulator 
    wire signed [2*`width-1:0] acc_in2;
    //***Mux signals
    //Typical signals in 2x1 MUX 
    //mux_in1 -input 1
    //mux_in2 -input 0
    //mux_sel -1 bit select line 
    wire signed [2*`width-1:0] mux_in1;
    wire signed [2*`width-1:0] mux_in2;
    wire mux_sel;
     
    //SEQUENTIAL PART
    //Following code describes a sequential multiplier which accumulates multiplicand into partial product everytime in single cycle.
    always @(posedge clk or posedge reset) begin 
        //If reset make rdy, partial product, counter 0.
        //Make multiplier as a and sign extend multiplicand to 2*width for correct addition with partial products.
        if (reset)
            begin
                rdy <= 0;
                p  <= 0;
                ctr  <= 0;
                multiplier <= a;     
                multiplicand 	<= {{`width{b[`width-1]}}, b}; // sign-extend
                
            end
        else 
            begin
                //Run counter for `width number of times.
                if (ctr <  `width)
                    begin
                        // *** Code for multiplication
                        //Logical Shift the multiplicand left by 1 bit
                        multiplicand <= multiplicand << 1; 
                        //Accumulator output sent into product p
                        p <= acc_out ;
                        //Incrementing counter every posedge apart from when reset until we compute product
                        ctr <= ctr+1;  
                    end 
                else if( ctr == `width)
                    begin
                        rdy <= 1; 		// Assert 'rdy' signal to indicate end of multiplication
                        //if(p<50) 
                            //$display("hi, p: %d",p);
                        //$display("a, %b, b, %b, p %b,", a,b,p);
                    end
                
            end
    end
    
    //COMBINATIONAL PART.
    //MUX input signals.
    //MUX takes in current multiplier bit and chooses if it should send multiplicand to accumulator block or not.
    assign mux_in1 = multiplicand;
    assign mux_in2 = 0;
    assign mux_sel = multiplier[ctr];
    //MUX block
    // First choose between 0 and multiplicand based on multiplier bit
    always @(mux_sel or mux_in1 or mux_in2)
        begin
            case (mux_sel)
                1'b1: mux_out <= mux_in1;
                1'b0: mux_out <= mux_in2;
            endcase
        end 
    //assign mux_out = ((mux_sel)& ()) | ( (~mux_sel)& () );
    //Accumulator or Adder/Sub block
    //Accumulator input signals
    //Inputs are mux_out and acc_in2= partial product.
    //acc_sig decides whether to add or subtract.
   
    //This becomes important when you have a -ve multiplier and instead of adding multiplicand to partial product when at the MSB of the multiplier (last cycle),
    //you need to subtract the multiplicand from the partial product accumulated so far.
    //Intuitioin is that by convention of 2s compliment if you multiply with -ve multiplier, there will be a sign flip at the MSB and hence subtraction instead of addition.
    
    assign acc_in2 = p;
    //Control signal deciding when to subtract- when at MSB of multiplier and if it's -ve. 
    assign acc_sig = (ctr == `width-1 ) & (multiplier[`width-1]);
    //Actual accumulator-does subtraction or addition based on acc_sig.
    always @(acc_sig or mux_out or acc_in2)
        begin
            case (acc_sig)
                1'b1: acc_out <= -mux_out + acc_in2;
                1'b0: acc_out <= +mux_out + acc_in2;
            endcase
        end
     
    
endmodule // seqmult
