module cpu(clk, rst);
   input clk;
   input rst;

   //////////////////////////////////////////////////////////////////////
   // Parameters.
   //////////////////////////////////////////////////////////////////////
   parameter CELL_BITS = 32;
   parameter MEM_SIZE = 2048;
   parameter STACK_SIZE = 64;
   parameter RSTACK_SIZE = 64;
   parameter SP_SIZE = 6;
   parameter RSP_SIZE = 6;
   parameter ICOUNT_BITS = 3;
   parameter ICOUNT = 7;
   
   parameter MSB = CELL_BITS - 1;
   //////////////////////////////////////////////////////////////////////

   
   //////////////////////////////////////////////////////////////////////
   // Registers and memory.
   //////////////////////////////////////////////////////////////////////
   reg [MSB:0] pmem[MEM_SIZE-1:0];
   
   reg [MSB:0] stack[STACK_SIZE-1:0];
   reg [MSB:0] rstack[RSTACK_SIZE-1:0];

   reg [SP_SIZE-1:0]   sp;
   reg [RSP_SIZE-1:0]  rsp;

   reg [MSB:0] tos;
   reg [MSB:0] nos;

   reg [MSB:0] tors;

   reg [MSB:0] a;
   
   reg [MSB:0] ip;
   reg [MSB:0] ir;

   reg [ICOUNT_BITS-1:0] icount;
   //////////////////////////////////////////////////////////////////////


   //////////////////////////////////////////////////////////////////////
   // Opcode.
   //////////////////////////////////////////////////////////////////////
   wire [3:0] 		 opcode;
   wire [5:0] 		 opcodex;
   wire [MSB-6:0] 	 jump_target;
   wire [MSB-4:0] 	 literal;
   
   assign opcode = ir[MSB:MSB-3];
   assign opcodex = ir[MSB:MSB-5];
   assign jump_target = ir[MSB-6:0];
   assign literal = ir[MSB-4:0];
   //////////////////////////////////////////////////////////////////////

   
   //////////////////////////////////////////////////////////////////////
   // Control signals.
   //////////////////////////////////////////////////////////////////////
   wire 		 condition;

   assign condition = |tos;
   //////////////////////////////////////////////////////////////////////
   
   
   //////////////////////////////////////////////////////////////////////
   // ALU
   //////////////////////////////////////////////////////////////////////
   wire [MSB:0] 	 alu_a;
   wire [MSB:0] 	 alu_b;
   reg [MSB:0] 		 alu_out;

   assign alu_a = nos;
   assign alu_b = tos;
   
   always @ (ir)
     case (opcode)
       4'b0000: alu_out = 0;
       4'b0001: alu_out = alu_a + alu_b;
       4'b0010: alu_out = ~(alu_a & alu_b);
       4'b0011: alu_out = alu_a ^ alu_b;
       4'b0100: alu_out = alu_b << 1;
       4'b0101: alu_out = alu_b >> 1;
       default: alu_out = 0;
     endcase
   //////////////////////////////////////////////////////////////////////

   
   //////////////////////////////////////////////////////////////////////
   // Instruction register/pointer/counter.
   //////////////////////////////////////////////////////////////////////
   always @ (posedge clk)
     if (rst)
       begin
	  ir <= 0;
	  ip <= 0;
	  icount <= 0;
       end
     else
       begin
	  // Unconditional branch.
	  if (opcodex == 6'b111000 || opcodex == 6'b111010)
	    begin
	       ir <= pmem[{6'b000000, jump_target}];
	       ip <= {6'b000000, jump_target} + 1;
	       icount <= ICOUNT;
	    end
	  // Conditional branch.
	  else if ((opcodex == 6'b111001 || opcodex == 6'b111011)
		   && (tos != 0))
	    begin
	       ir <= pmem[{6'b000000, jump_target}];
	       ip <= {6'b000000, jump_target} + 1;
	       icount <= ICOUNT;
	    end
	  // Unconditional return.
	  else if (opcode == 4'b0110)
	    begin
	       ir <= pmem[tors];
	       ip <= tors + 1;
	       icount <= ICOUNT;
	    end
	  // Conditional return.
	  else if (opcode == 4'b1101 && tos != 0)
	    begin
	       ir <= pmem[tors];
	       ip <= tors + 1;
	       icount <= ICOUNT;
	    end
	  // Literal.
	  else if (opcode == 4'b1111)
	    begin
	       ir <= pmem[ip];
	       ip <= ip + 1;
	       icount <= ICOUNT;
	    end
	  // Normal instruction.
	  else
	    begin
	       if (icount == 0)
		 begin
		    ir <= pmem[ip];
		    ip <= ip + 1;
		    icount <= ICOUNT;
		 end
	       else
		 begin
		    ir <= ir << 4;
		    icount <= icount - 1;
		    ip <= ip;
		 end
	    end
       end
   //////////////////////////////////////////////////////////////////////
   
   
   //////////////////////////////////////////////////////////////////////
   // Data stack.
   //////////////////////////////////////////////////////////////////////
   always @ (posedge clk)
     begin
	if (rst)
	  begin
	     sp <= (STACK_SIZE-1);
	     tos <= 0;
	     nos <= 0;
	  end
	else
	  case (opcode)
	    // NOP.
	    4'b0000:
	      begin
		 tos <= tos;
		 nos <= nos;
		 sp <= sp;
	      end
	    // ADD.
	    4'b0001:
	      begin
		 tos <= alu_out;
		 nos <= stack[sp+1];
		 sp <= sp + 1;
	      end
	    // NAND.
	    4'b0010:
	      begin
		 tos <= alu_out;
		 nos <= stack[sp+1];
		 sp <= sp + 1;
	      end
	    // XOR.
	    4'b0011:
	      begin
		 tos <= alu_out;
		 nos <= stack[sp+1];
		 sp <= sp + 1;
	      end
	    // SHR.
	    4'b0100:
	      begin
		 tos <= alu_out;
		 nos <= nos;
		 sp <= sp;
	      end
	    // SHL.
	    4'b0101:
	      begin
		 tos <= alu_out;
		 nos <= nos;
		 sp <= sp;
	      end
	    // >R.
	    4'b0110:
	      begin
		 nos <= stack[sp+1];
		 tos <= nos;
		 sp <= sp + 1;
	      end
	    // R>.
	    4'b0111:
	      begin
		 stack[sp] <= nos;
		 nos <= tos;
		 tos <= tors;
		 sp <= sp - 1;
	      end
	    // >A.
	    4'b1000:
	      begin
		 nos <= stack[sp+1];
		 tos <= nos;
		 sp <= sp + 1;
	      end
	    // A>.
	    4'b1001:
	      begin
		 stack[sp] <= nos;
		 nos <= tos;
		 tos <= a;
		 sp <= sp - 1;
	      end
	    // FETCH.
	    4'b1010:
	      begin
		 stack[sp] <= nos;
		 nos <= tos;
		 tos <= pmem[a];
		 sp <= sp - 1;
	      end
	    // STORE.
	    4'b1011:
	      begin
		 nos <= stack[sp+1];
		 tos <= nos;
		 pmem[a] <= tos;
		 sp <= sp + 1;
	      end
	    // RETURN.
	    4'b1100:
	      begin
		 nos <= nos;
		 tos <= tos;
		 sp <= sp;
	      end
	    // CRETURN.
	    4'b1101:
	      begin
		 if (condition)
		   begin
		      nos <= stack[sp+1];
		      tos <= nos;
		      sp <= sp + 1;
		   end
		 else
		   begin
		      nos <= nos;
		      tos <= tos;
		      sp <= sp;
		   end
	      end
	    // BRANCH.
	    4'b1110:
	      begin
		 case (opcodex)
		   // JMP.
		   6'b111000:
		     begin
			nos <= nos;
			tos <= tos;
			sp <= sp;
		     end
		   // CJMP.
		   6'b111001:
		     begin
			if (condition)
			  begin
			     nos <= stack[sp+1];
			     tos <= nos;
			     sp <= sp + 1;
			  end
			else
			  begin
			     nos <= nos;
			     tos <= tos;
			     sp <= sp;
			  end
		     end
		   // CALL.
		   6'b111010:
		     begin
			nos <= nos;
			tos <= tos;
			sp <= sp;
		     end
		   // CCALL.
		   6'b111011:
		     begin
			if (condition)
			  begin
			     nos <= stack[sp+1];
			     tos <= nos;
			     sp <= sp + 1;
			  end
			else
			  begin
			     nos <= nos;
			     tos <= tos;
			     sp <= sp;
			  end
		     end
		 endcase
	      end
	    // LITERAL.
	    4'b1111:
	      begin
		 stack[sp] <= nos;
		 nos <= tos;
		 tos <= {4'b0000, literal};
		 sp <= sp - 1;
	      end
	  endcase
     end
   //////////////////////////////////////////////////////////////////////
   

   //////////////////////////////////////////////////////////////////////
   // Return stack.
   //////////////////////////////////////////////////////////////////////
   always @ (posedge clk)
     begin
	if (rst)
	  begin
	     rsp <= (RSTACK_SIZE-1);
	     tors <= 0;
	  end
	else
	  begin
	     case (opcode)
	       // NOP.
	       4'b0000:
		 begin
		    tors <= tors;
		    rsp <= rsp;
		 end
	       // ADD.
	       4'b0001:
		 begin
		    tors <= tors;
		    rsp <= rsp;
		 end
	       // NAND.
	       4'b0010:
		 begin
		    tors <= tors;
		    rsp <= rsp;
		 end
	       // XOR.
	       4'b0011:
		 begin
		    tors <= tors;
		    rsp <= rsp;
		 end
	       // SHR.
	       4'b0100:
		 begin
		    tors <= tors;
		    rsp <= rsp;
		 end
	       // SHL.
	       4'b0101:
		 begin
		    tors <= tors;
		    rsp <= rsp;
		 end
	       // >R.
	       4'b0110:
		 begin
		    rstack[rsp] <= tors;
		    tors <= tos;
		    rsp <= rsp - 1;
		 end
	       // R>.
	       4'b0111:
		 begin
		    tors <= rstack[rsp+1];
		    rsp <= rsp + 1;
		 end
	       // >A.
	       4'b1000:
		 begin
		    tors <= tors;
		    rsp <= rsp;
		 end
	       // A>.
	       4'b1001:
		 begin
		    tors <= tors;
		    rsp <= rsp;
		 end
	       // FETCH.
	       4'b1010:
		 begin
		    tors <= tors;
		    rsp <= rsp;
		 end
	       // STORE.
	       4'b1011:
		 begin
		    tors <= tors;
		    rsp <= rsp;
		 end
	       // RETURN.
	       4'b1100:
		 begin
		    tors <= rstack[rsp+1];
		    rsp <= rsp + 1;
		 end
	       // CRETURN.
	       4'b1101:
		 begin
		    if (condition)
		      begin
			 tors <= rstack[rsp+1];
			 rsp <= rsp + 1;
		      end
		    else
		      begin
			 tors <= tors;
			 rsp <= rsp;
		      end
		 end
	       // BRANCH.
	       4'b1110:
		 begin
		 case (opcodex)
		   // JMP.
		   6'b111000:
		     begin
			tors <= tors;
			rsp <= rsp;
		     end
		   // CJMP.
		   6'b111001:
		     begin
			tors <= tors;
			rsp <= rsp;
		     end
		   // CALL.
		   6'b111010:
		     begin
			rstack[rsp] <= tors;
			tors <= ip + 1;
			rsp <= rsp - 1;
		     end
		   // CCALL.
		   6'b111011:
		     begin
			if (condition)
			  begin
			     rstack[rsp] <= tors;
			     tors <= ip + 1;
			     rsp <= rsp - 1;
			  end
			else
			  begin
			     tors <= tors;
			     rsp <= rsp;
			  end
		     end
		 endcase
		 end
	       // LITERAL.
	       4'b1111:
		 begin
		    tors <= tors;
		    rsp <= rsp;
		 end
	     endcase
	  end
     end
   //////////////////////////////////////////////////////////////////////


   //////////////////////////////////////////////////////////////////////
   // Address register.
   //////////////////////////////////////////////////////////////////////
   always @ (posedge clk)
     if (rst)
       begin
	  a <= 0;
       end
     else if (opcode == 4'b1000)
       begin
	  a <= tos;
       end
     else
       begin
	  a <= a;
       end
endmodule // cpu
