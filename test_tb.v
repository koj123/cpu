`timescale 1ns / 1ns

module test_tb;
   initial
     begin
	$dumpfile("test_tb.lxt");
	$dumpvars;
     end

   reg clk;
   reg rst;
   
   wire [7:0] out;

   test test0(clk, rst, out);
      
   initial
     begin
	clk = 0;
	rst = 1;
	#100 rst = 0;
     end

   always #5 clk = ~clk;

   initial #20000 $finish;
endmodule // test_tb
