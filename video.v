// Horizontal timings
//
// 25.175 MHz dot clock => 39.72194637537239 ns pixel period
// horizontal frequency 31.4686 kHz => 31.77770857299022 us line period
// Front porch 0.94 us => 23.6645 pixels
// HSync pulse 3.77 us => 94.90975 pixels
// Back porch 1.89 us => 47.58075 pixels
// Active video 25.42204568023833e us => 640 pixels
// One line 32.022 us => 807 pixels

// Vertical timings
//
// Front porch 0.35 ms => 10.93 lines
// VSync pulse 0.06 ms => 1.9737 lines
// Back porch 1.02 ms => 31.953 lines
// Active video 15.25 ms => 480 lines
// One frame 16.68 ms => 525 lines
// Sync polarity is negative.

module video(clk, rst, r, g, b, h, v);
   input clk;
   input rst;
   output [2:0] r;
   output [2:0] g;
   output [2:0] b;
   output 	h;
   output 	v;

   reg 		r;
   reg 		g;
   reg 		b;
   
   reg [9:0] 	pixel_counter;
   reg [9:0] 	row_counter;

   reg [2:0] 	clk_counter;
   wire 	clk25;
   assign clk25 = clk_counter[1];
   always @ (posedge clk)
     if (rst)
       begin
	  clk_counter <= 0;
       end
     else
       begin
	  clk_counter <= clk_counter + 1;
       end
   
   assign v = ~(row_counter >= 11 && row_counter <= 12);
   assign h = ~(pixel_counter >= 24 && pixel_counter <= 118);

   always @ (pixel_counter or row_counter)
     begin
	if (row_counter >= 45 && pixel_counter >= 167)
	  begin
	     r = row_counter - 11;
	     g = pixel_counter - 167;
	     b = 0;
	  end
	else
	  begin
	     r = 0;
	     g = 0;
	     b = 0;
	  end
   end
   
   always @ (posedge clk25 or posedge rst)
     if (rst)
       pixel_counter <= 0;
     else if (pixel_counter == 806)
       pixel_counter <= 0;
     else
       pixel_counter <= pixel_counter + 1;
   
   always @ (posedge clk25 or posedge rst)
     if (rst)
       row_counter <= 0;
     else if (pixel_counter == 806)
       begin
	  if (row_counter == 524)
	    row_counter <= 0;
	  else
	    row_counter <= row_counter + 1;
       end

endmodule // video
