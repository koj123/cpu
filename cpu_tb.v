`timescale 1ns / 1ns

module cpu_tb;
   reg clk;
   reg rst;

   cpu cpu0(clk, rst);

   integer i;
   
   initial
     begin
	for (i = 0; i < 2048; i = i+1)
	  begin
	     cpu0.pmem[i] = 0;
	  end
	cpu0.pmem[0] = 32'hF0000100;
	cpu0.pmem[1] = 32'hF0000101;
	cpu0.pmem[2] = 32'h18992000;
     end 
   
   initial
     begin
	$dumpfile("cpu_tb.lxt");
	$dumpvars;
     end

   initial
     begin
	clk = 0;
	rst = 1;
	#20 rst = 0;
     end

   always #5 clk = ~clk;
   
   initial #100000 $finish;   

endmodule // cpu_tb
