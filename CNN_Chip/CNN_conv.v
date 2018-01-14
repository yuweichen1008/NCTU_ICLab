//synopsys translate_off
`include "/usr/synthesis/dw/sim_ver/DW02_mult.v"
`include "/usr/synthesis/dw/sim_ver/DW01_add.v"
//synopsys translate_on

`include "../04_MEM/RA1SH.v"

module CNN(
    clk,
    rst_n,
    in_valid_1,
    in_valid_2,
    in_data,
    out_valid,
    number_2,
    number_4,
    number_6,
);

// INPUT AND OUTPUT DECLARATION                         
input clk; 
input rst_n;
input in_valid_1;
input in_valid_2;
input [14:0]in_data;

output reg out_valid;
output reg number_2;
output reg number_4;
output reg number_6;
//---------------------------------------------------------------------
// PARAMETER DECLARATION
//---------------------------------------------------------------------
integer i, j, counter;           
parameter   S_IDLE       = 3'b000;
parameter   S_INPUT_1 = 3'b001;
parameter   S_INPUT_2 = 3'b010;
parameter   S_CONV     = 3'b011;
parameter   S_POOL      = 3'b100;
parameter   S_AFF_1     = 3'b101;
parameter   S_AFF_2     = 3'b110;
parameter   S_OUTPUT  = 3'b111;
//---------------------------------------------------------------------
//   WIRE AND REG DECLARATION                             
//---------------------------------------------------------------------

wire [14:0]  Q;
reg   [14:0]  Q_cs; // output data
reg 	[6:0]   	A;  // address
reg 	[14:0]  D;  //data input
reg 				WEN; // Write Enable Negative
reg 	[2:0]    c_state, n_state;
reg 	[14:0]  image_buf[7:0][7:0];
reg 	[3:0]   	column, row;
reg	[15:0] 	weight_buf[11:0];
reg				done;
reg	[1:0] 	number;
// Synopsys DesignWare Tool
wire				CO[2:0];
wire [15:0] 	RESULT_1, RESULT_2, RESULT_3;
wire	[16:0]	 RESULT_4, RESULT_5;
wire	[17:0]	RESULT_6;
reg 	[7:0]	m_1, m_2, m_3, weight_1, weight_2, weight_3;
reg	[15:0] 	result_1, result_2, result_3,adder[5:0];
reg	[16:0]	result_4, result_5;
reg	[17:0]	result_6;
reg				ci[2:0], co[2:0];
reg 	[1:0]	inner_cont;
reg 	[9:0]  	convolution_buf[8:0];
reg 	[16:0]   conimg_buf[5:0][5:0][2:0];
//---------------------------------------------------------------------
//   Synopsys DesignWare                      
//---------------------------------------------------------------------
DW02_mult #(8,8) M_1(.A(m_1), .B(weight_1),.TC(1'b1), .PRODUCT(RESULT_1));
DW02_mult #(8,8) M_2(.A(m_2),.B(weight_2),.TC(1'b1), .PRODUCT(RESULT_2));
DW02_mult #(8,8) M_3(.A(m_3),.B(weight_3),.TC(1'b1), .PRODUCT(RESULT_3));
DW01_add #(16) A_1(.A(adder[0]),.B(adder[1]),.CI(ci[0]),.SUM(RESULT_4),.CO(CO[0]));
DW01_add #(16) A_2(.A(adder[2]),.B(adder[3]),.CI(ci[1]),.SUM(RESULT_5),.CO(CO[1]));
DW01_add #(17) A_3(.A(adder[4]),.B(adder[5]),.CI(ci[2]),.SUM(RESULT_6),.CO(CO[2]));

// carry out buffer
always@(*) begin
	co[0] = CO[0];
	co[1] = CO[1];
	co[2] = CO[2];
end
// result_1 to result_6 buffer
always@(*) begin
	result_1 = RESULT_1;
	result_2 = RESULT_2;
	result_3 = RESULT_3;
	result_4 = RESULT_4;
	result_5 = RESULT_5;
	result_6 = RESULT_6;
end
//---------------------------------------------------------------------
// PIPELINE MULTI AND ADD
//---------------------------------------------------------------------
// weight_1 weight_2 weight_3
always@(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		weight_1 <= 8'b0;
		weight_2 <= 8'b0;
		weight_3 <= 8'b0;
	end else case(c_state)
		S_CONV: begin
			case(inner_cont)
				1: begin
					weight_1 <= weight_buf[0][7:0];
					weight_2 <= weight_buf[1][7:0];
					weight_3 <= weight_buf[2][7:0];
				end
				2: begin
					weight_1 <= weight_buf[3][7:0];
					weight_2 <= weight_buf[4][7:0];
					weight_3 <= weight_buf[5][7:0];
				end
				0: begin
					weight_1 <= weight_buf[6][7:0];
					weight_2 <= weight_buf[7][7:0];
					weight_3 <= weight_buf[8][7:0];
				end
			endcase
		end
		default: begin
			weight_1 <= weight_1;
			weight_2 <= weight_2;
			weight_3 <= weight_3;
		end
	endcase
end
// m_1 m_2 m_3 buffer
always@(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		m_1 <= 8'b0;
		m_2 <= 8'b0;
		m_3 <= 8'b0;
	end else case(c_state)
		S_CONV: begin
			case(inner_cont)
				1: begin
					m_1 <= convolution_buf[0];
					m_2 <= convolution_buf[1];
					m_3 <= convolution_buf[2];
				end
				2: begin
					m_1 <= convolution_buf[3];
					m_2 <= convolution_buf[4];
					m_3 <= convolution_buf[5];
				end
				0: begin
					m_1 <= convolution_buf[6];
					m_2 <= convolution_buf[7];
					m_3 <= convolution_buf[8];
				end
				default: begin
					m_1 <= m_1;
					m_2 <= m_2;
					m_3 <= m_3;
				end
			endcase
		end
		default: begin
			m_1 <= m_1;
			m_2 <= m_2;
			m_3 <= m_3;
		end
	endcase
end
// a_1 a_2 a_3 a_4 a_5 a_6 buffer
always@(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		for(i = 0; i < 6; i = i + 1)
			adder[i] <= 16'b0;
	end else case(c_state)
		S_CONV: begin
			adder[0] <= result_1;
			adder[1] <= result_2;
			adder[2] <= result_3;
			case(inner_cont)
				2:	adder[3] <= weight_buf[9];
				0:	adder[3] <= weight_buf[10];
				1: adder[3] <= weight_buf[11];
				default: adder[3] <= adder[3];
			endcase
			adder[4] <= {{ 1{co[0]}} ,result_4[16:0]};
			adder[5] <= {{ 1{co[1]}} ,result_5[16:0]};
		end
		default: begin
			for(i = 0; i < 6; i = i + 1)
				adder[i] <= adder[i];
		end
	endcase
end
//---------------------------------------------------------------------
//   MEMORY                           
//---------------------------------------------------------------------
RA1SH mem(
   .Q(Q),
   .CLK(clk),
   .CEN(1'b0),
   .WEN(WEN),
   .A(A),
   .D(D),
   .OEN(1'b0)
);
//---------------------------------------------------------------------
//   Finite State Machine                                         
//---------------------------------------------------------------------
//---------------   state 
always@(posedge clk or negedge rst_n)   begin
    if(!rst_n)
        c_state <= S_IDLE;
    else
        c_state <= n_state;
end

always@(*) begin
    case(c_state)
        S_IDLE: begin
            if(in_valid_1)
                n_state = S_INPUT_1;
            else if(in_valid_2)
                n_state = S_INPUT_2;
            else
                n_state = c_state;
        end
        S_INPUT_1: begin
            if(!in_valid_1)
                n_state = S_IDLE;
            else
                n_state = c_state;
        end
        S_INPUT_2: begin
            if(!in_valid_2)
                n_state = S_CONV;
            else
                n_state = c_state;
        end
        S_CONV: begin
            if(done)
                n_state = S_OUTPUT;
        end
		S_AFF_1: begin
			if(done)
				n_state = S_AFF_2;
		end
		S_AFF_2: begin
			if(done)
				n_state = S_OUTPUT;
		end
        S_OUTPUT: begin
            n_state = S_IDLE;
        end
        default:
            n_state = c_state;
    endcase
end

//---------------------------------------------------------------------
//   Design Description                                          
//---------------------------------------------------------------------

//---------------   Data Output from memory
always@(posedge clk or negedge rst_n) begin
    Q_cs <= Q;
end

//--------------- Weight Input for memory
always@(posedge clk or negedge rst_n) begin
    if(!rst_n || c_state == S_IDLE) begin
        A <= 0;
        D <= 0;
        WEN <= 1;
    end else if(in_valid_1 || c_state == S_INPUT_1) begin
        A <= counter;
        D <= in_data;
        WEN <= 0;
    end else case(c_state)
		S_INPUT_2: begin
			case(counter)
				3,4,5,6,7,8,16,17,18,24,25,26: begin
					A <= counter+3;
					WEN <= 1;
				end
				default: begin
					A <= A;
					WEN <= 1;
				end
			endcase
		end
		default: begin
			A <= 0;
			WEN <= 1;
		end
	endcase
end

// weight_buf
always@(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		for(i = 0; i < 12; i= i + 1)
			weight_buf[i] <= 16'b0;
	end else if(in_valid_2) begin
		case(counter)
			6:   weight_buf[0] <= Q_cs[14:8];
			7:   weight_buf[1] <= Q_cs[14:8];
			8:   weight_buf[2] <= Q_cs[14:8];
			9:   weight_buf[3] <= Q_cs[14:8];
			10: weight_buf[4] <= Q_cs[14:8];
			11: weight_buf[5] <= Q_cs[14:8];
			19: weight_buf[6] <= Q_cs[14:8];
			20: weight_buf[7] <= Q_cs[14:8];
			21: weight_buf[8] <= Q_cs[14:8];
			27: weight_buf[9] <= Q_cs;
			28: weight_buf[10] <= Q_cs;
			29: weight_buf[11] <= Q_cs;
			default: begin
				for(i = 0; i < 12; i= i + 1)
					weight_buf[i] <= weight_buf[i];
			end
		endcase
	end else begin
		for(i = 0; i < 9; i= i + 1)
			weight_buf[i] <= weight_buf[i];
	end
end

//--------------- Data input for image
// image_buf
always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        for(i = 0;  i< 8; i = i+1) begin
			for(j = 0; j< 8; j = j+1)
				image_buf[i][j] <= 15'b0;
		end
    end else if(in_valid_2) begin
        if(counter < 8)
            image_buf[0][counter      ] <= in_data;
        else if(counter < 16)
            image_buf[1][counter-   8] <= in_data;
        else if(counter < 24)
            image_buf[2][counter- 16] <= in_data;
        else if(counter < 32)
            image_buf[3][counter- 24] <= in_data;
        else if(counter < 40)
            image_buf[4][counter- 32] <= in_data;
        else if(counter < 48)
            image_buf[5][counter- 40] <= in_data;
        else if(counter < 56)
            image_buf[6][counter- 48] <= in_data;
        else if(counter < 64)
            image_buf[7][counter- 56] <= in_data;
    end
end

//---------------   Counter
always@(posedge clk or negedge rst_n)   begin
    if(!rst_n)
        counter <= 7'd0;
    else if(in_valid_1 || in_valid_2)
        counter <= counter + 1;
    else case(c_state)
		S_CONV:
			counter <= counter + 1;
		S_OUTPUT:
			counter <= 7'b0;
		S_IDLE:
			counter <= 7'b0;
		default:
			counter <= counter;
	endcase
end

//-------------- Done Flag 
always@(posedge clk or negedge rst_n) begin
	if(!rst_n)
		done <= 0;
	else case(c_state)
		S_CONV:
			if(counter ==106)
				done <= 1;
			else
				done <= done;
		default:
			done <= 0;
	endcase
end


// column
always@(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		column <= 0;
	end else case(c_state)
		S_CONV: begin
			if(inner_cont == 2)
				column <= column + 1;
			else if(column == 6 && row < 6)
				column <= 0;
			else
				column <= column;
		end
		
		default:
			column <= 0;
	endcase
end

// row
always@(posedge clk or negedge rst_n) begin
	if(!rst_n)
		row <= 0;
	else case(c_state)
		S_CONV: begin
			if(column == 6 && row < 6)
				row <= row + 1;
			else
				row <= row;
		end
		default:
			row <= 0;
	endcase
end

//---------------------------------------------------------------------
//  Convolutional Layer
//---------------------------------------------------------------------

// inner_cont
always@(posedge clk or negedge rst_n) begin
	if(!rst_n)
		inner_cont <= 2'b0;
	else if(c_state == S_CONV) begin
		case(inner_cont)
			0: inner_cont <= 1;
			1: inner_cont <= 2;
			2: inner_cont <= 0;
			default: inner_cont <= inner_cont;
		endcase
	end 
end

// convolution_buf
always@(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		for(i = 0; i < 9; i  = i + 1) begin
			convolution_buf[i] <= 8'b0;
		end
	end else if(c_state == S_CONV) begin
		convolution_buf[0]	<= image_buf[row+2][column]     >> 7;
		convolution_buf[1]	<= image_buf[row+2][column+1] >> 7;
		convolution_buf[2]	<= image_buf[row+2][column+2] >> 7;
		convolution_buf[3]	<= image_buf[row][column]         >> 7;
		convolution_buf[4]	<= image_buf[row][column+1]     >> 7;
		convolution_buf[5]	<= image_buf[row][column+2]     >> 7;
		convolution_buf[6]	<= image_buf[row+1][column]     >> 7;
		convolution_buf[7]	<= image_buf[row][column+1]     >> 7;
		convolution_buf[8]	<= image_buf[row][column+2]     >> 7;
	end else begin
		for(i = 0; i < 9; i  = i + 1) begin
			convolution_buf[i] <= convolution_buf[i];
		end
	end
end
// conimg_buf
always@(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		for(i = 0; i < 6; i = i + 1) begin
			for(j= 0 ; j <6; j = j + 1) begin
				for(counter = 0; counter < 3; counter = counter + 1) begin
					conimg_buf[i][j][counter] <= 8'b0;
				end
			end
		end
	end else if(c_state == S_CONV) begin
		if(counter == 3)
			conimg_buf[row][column][0] <= result_6 >> 10;
/*		
		else if(counter ==106)
			conimg_buf[5][5][0] <= result_6 >> 10;
		else if(counter ==107)
			conimg_buf[5][5][1] <= result_6 >> 10;
		else if(counter ==108)
			conimg_buf[5][5][2] <= result_6 >> 10;
*/
		else case(inner_cont)
			0:conimg_buf[row][column][0]        <= result_6 >> 10;
			1:conimg_buf[row-1][column-1][1]  <= result_6 >> 10;
			2:conimg_buf[row-1][column-1][2]  <= result_6 >> 10;
		endcase
	end
end

//   Output part                                      
always@(posedge clk or negedge rst_n) begin
    if(!rst_n)
        out_valid <= 1'b0;
    else if(c_state == S_OUTPUT)
        out_valid <= 1'b1;
    else
        out_valid <= 1'b0;
end

// number
always@(posedge clk or negedge rst_n)   begin
    if(!rst_n) begin
        number_2 <= 1'b0;
        number_4 <= 1'b0;
        number_6 <= 1'b0;
    end else if(c_state == S_OUTPUT)    begin
        case(2)
            0: number_2 <= 1'b1;
            1: number_4 <= 1'b1;
            2: number_6 <= 1'b1;
            default: begin
                number_2 <= 1'b0;
                number_4 <= 1'b0;
                number_6 <= 1'b0;
            end
        endcase
    end
    else begin
        number_2 <= 1'b0;
        number_4 <= 1'b0;
        number_6 <= 1'b0;
    end
end

//synopsys dc_script_begin
//set_implementation pparch M_1
//set_implementation pparch M_2
//set_implementation pparch M_3
//set_implementation apparch A_1
//set_implementation apparch A_2
//set_implementation apparch A_3
//synopsys dc_script_end

endmodule