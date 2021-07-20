module LCD_CTRL(clk, reset, cmd, cmd_valid, IROM_Q, IROM_rd, IROM_A, IRAM_valid, IRAM_D, IRAM_A, busy, done);
input clk;
input reset;
input [3:0] cmd;
input cmd_valid;
input [7:0] IROM_Q;
output reg IROM_rd;
output reg [5:0] IROM_A;
output reg IRAM_valid;
output reg [7:0] IRAM_D;
output reg [5:0] IRAM_A;
output reg busy;
output reg done;

//parameter
parameter read=3'd0,rcmd=3'd1,op=3'd2,write=3'd3,fin=3'd4;

//reg or wire
reg [2:0]cs,ns;
reg [5:0]count;
reg [5:0]p0;
wire [5:0]p1,p2,p3;
reg [7:0]image[63:0];
reg [7:0]max,min,ave;
reg [10:0]sum;
reg [3:0]A;

//state

 always@(posedge clk or posedge reset)
    begin
        if (reset) cs <= read;
        else cs <= ns;
    end
	 
	  always@(*)
    begin
        case(cs)
            read:
            begin
                if (IROM_A == 6'd63) ns <= rcmd;
                else ns <= read;
            end
            rcmd:
            begin
				 ns<=op;
            end
            op:
            begin
                 if (A!= 4'd0) ns <=rcmd;
                else if (A== 4'd0) ns <= write;
                else ns = op;
            end
            write:
            begin
                if(IRAM_A==6'd63)ns <= fin;
					 else ns<=write;
            end
				fin:
				begin
				  ns <= fin;
				end
        endcase
    end
	always@(posedge clk)
	 begin
	 case(cs)
	 read:begin
	      IROM_rd=1'd1;
	      IRAM_valid=1'd0;
	      busy=1'd1;
			done=1'd0;
			end
	 
	 rcmd:begin
	      IROM_rd=1'd0;
	      IRAM_valid=1'd0;
	      busy=1'd0;
			done=1'd0;
			end
			
	 op:begin
	      IROM_rd=1'd0;
	      IRAM_valid=1'd0;
	      busy=1'd1;
			done=1'd0;
			end
	
	 write:begin
	      IROM_rd=1'd0;
	      IRAM_valid=1'd1;
	      busy=1'd1;
			done=1'd0;
			end
	 fin:begin
	      IROM_rd=1'd0;
	      IRAM_valid=1'd0;
	      busy=1'd0;
			done=1'd1;
			end
			endcase
	 end
	 
//datapath
    
	 //IROM_A
	 always@(posedge clk )
	 begin
	 if(reset==1'd1)IROM_A<=6'd0;
	 else if(IROM_rd==1'd1)
	    begin
		  if(IROM_A==6'h3f)IROM_A<=6'd0;
		  else IROM_A<=IROM_A+6'd1;
	    end
	   end
	
	 //p0 1 2 3
	 assign p1=p0+6'd1;
	 assign p2=p0+6'd8;
	 assign p3=p0+6'd9;
	//catch A
	always@(*)
	begin
	A<=cmd;
	end
	 //image
	 always@(posedge clk)
	 begin
	 case(cs)
	 read:
	 begin
	if(IROM_rd==1'd1)image[IROM_A]<=IROM_Q;
	end
	 rcmd:begin
	 	 
	 end
	 op:begin
case(A)
	 4'd5:begin
	      image[p0]<=image[max];
			image[p1]<=image[max];
			image[p2]<=image[max];
			image[p3]<=image[max];
			end
	 4'd6:begin
	      image[p0]<=image[min];
			image[p1]<=image[min];
			image[p2]<=image[min];
			image[p3]<=image[min];
			end
	4'd7:begin
	      image[p0]<=ave;
			image[p1]<=ave;
			image[p2]<=ave;
			image[p3]<=ave;
			end
	 //Rclock
	 4'd8:begin
	      image[p2]<=image[p0];
			image[p0]<=image[p1];
			image[p3]<=image[p2];
			image[p1]<=image[p3];
			end
	 //clock
	 4'd9:begin
	      image[p1]<=image[p0];
			image[p3]<=image[p1];
			image[p0]<=image[p2];
			image[p2]<=image[p3];
			end
	//x
	4'd10:begin
	      image[p2]<=image[p0];
			image[p3]<=image[p1];
			image[p0]<=image[p2];
			image[p1]<=image[p3];
			end
	//y
	4'd11:begin
	      image[p1]<=image[p0];
			image[p0]<=image[p1];
			image[p3]<=image[p2];
			image[p2]<=image[p3];
			end
	
	 endcase
	    end
	 write:
	 begin
	 if(IRAM_valid==1'd1)IRAM_D<=image[count];
	 end
	 fin:begin
	     end
	 endcase
	 end
	 //op p0 shift
	 always@(posedge clk)
	 begin
	 if(reset==1'd1)p0<=6'h1b;
	 else
	 begin
	 if(cs==op)
	 begin
	 case(A)
	 //up 
	 4'd1:begin
	      if(p0<6'd8)p0<=p0;
			else p0<=p0-6'd8;
			end
	 //down		
	 4'd2:begin
	      if(p0>6'h2f)p0<=p0;
			else p0<=p0+6'd8;
			end
	 //left		
	 4'd3:begin
	      if(p0==6'h0||p0==6'h8||p0==6'h10||p0==6'h18||p0==6'h18||
			p0==6'h20||p0==6'h28||p0==6'h30||p0==6'h38)p0<=p0;
			else p0<=p0-6'd1;
			end
	 //right
	 4'd4:begin
	      if(p0==6'h6||p0==6'he||p0==6'h16||p0==6'h1e||p0==6'h26||
			p0==6'h2e||p0==6'h36||p0==6'h3e)p0<=p0;
			else p0<=p0+6'd1;
			end
    
	
	 endcase
	end
	end
	 end
	//count
	 //max
	      always@(*)
			begin
	      if(image[p0]>=image[p1]&&image[p0]>=image[p2]&&image[p0]>=image[p3])max=p0;
			else if(image[p1]>=image[p0]&&image[p1]>=image[p2]&&image[p1]>=image[p3])max=p1;
			else if(image[p2]>=image[p0]&&image[p2]>=image[p1]&&image[p2]>=image[p3])max=p2;
			else max=p3;
			end
	 //min
	      always@(*)
			begin
	      if(image[p0]<=image[p1]&&image[p0]<=image[p2]&&image[p0]<=image[p3])min=p0;
			else if(image[p1]<=image[p0]&&image[p1]<=image[p2]&&image[p1]<=image[p3])min=p1;
			else if(image[p2]<=image[p0]&&image[p2]<=image[p1]&&image[p2]<=image[p3])min=p2;
			else min=p3;
	      end
	 //average
	      always@(*)
			begin
	      sum=image[p0]+image[p1]+image[p2]+image[p3];
			ave=sum[9:2];
			end
			 
	 	 
  //IRAM_A
  always@(posedge clk )
	 begin
	 if(reset==1'd1)count<=6'd0;
	 else if(IRAM_valid==1'd1)
	    begin
		  if(count==6'h3f)count<=6'd0;
		  else count<=count+6'd1;
	    end
	   end
	
	always@(posedge clk)
	begin
	IRAM_A<=count;
	end

endmodule



