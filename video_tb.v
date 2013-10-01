`timescale 1ns / 1ns

module video_tb;
   reg clk;
   reg rst;

   wire [2:0] r;
   wire [2:0] g;
   wire [2:0] b;

   wire       h;
   wire       v;

   video video0(clk, rst, r, g, b, h, v);
   
   initial
     begin
	$dumpfile("video_tb.lxt");
	$dumpvars;
     end

   initial
     begin
	clk = 0;
	rst = 1;
	#100 rst = 0;
     end

   always #5 clk = ~clk;
   
   initial #20000000 $finish;   
endmodule // video_tb
