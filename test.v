module test(clk, rst, out);

   parameter COUNTER_SIZE = 32;
   parameter COUNTER_MAX = 49;
   input clk;
   input rst;
   output [7:0] out;
   reg [7:0] out;

   reg [COUNTER_SIZE-1:0] counter;
   
   always @ (posedge clk)
     begin
	if (rst)
	  begin
	     counter <= 0;
	     out <= 8'b00000001;
	  end
	else
	  begin
	     if (counter == COUNTER_MAX)
	       begin
		  counter <= 0;
		  out <= {out[6:0], out[7]};
	       end
	     else
	       begin
		  counter <= counter + 1;
		  out <= out;
	       end
	  end
     end

endmodule // test
