module VGAMEMORY(
	input clk,
	input [15:0] Data,
	output reg [9:0] Address,
	output reg [15:0] coord,
	output reg [15:0] col,
	output reg [15:0] dim,
	output reg [1:0] state,
	output reg reset
	);
	// rate divided clock
	wire slowclk;
	// divide rate so controller has time to draw object
	RATEDIV vgadivider(
		.clkin(clk),
		.Rate(3'b100),
		.clkout(slowclk),
		.Clear(1'b0)
		);
	always @(posedge slowclk)
	begin
		if(Data == 16'b1111111111111111) begin // null terminating char
			Address <= 10'd0;
			reset <= 1'b0;
		end
		else if(Address == 10'b0000000000) begin // Read in the offset value (if 0, then this will continue, i.e. idle)
			Address <= Data;
			reset <= 1'b1;
		end
		else begin // go through memory read states
			if(state == 2'b00) begin
				coord <= Data;
			end
			else if(state == 2'b01) begin
				col <= Data;
			end
			else if(state == 2'b10) begin
				dim <= Data;
			end
			else begin
				state <= 2'b00;
			end
			state <= state + 1'b1;
			if(state != 2'b11) begin
				Address <= Address + 1'b1;
			end
		end
	end
endmodule

module VGACONTROLLER(
	input clk,
	input [1:0] state,
	input [15:0] coordinates,
	input [15:0] colours,
	input [15:0] dimensions,
	output [7:0] x,
	output [6:0] y,
	output [14:0] colour,
	output reg clkout,
	output reg draw
	);
	// split the registers
	assign colour = colours[5:0];
	// potential ability to draw letters and symbols not yet implemented properly
	wire [7:0] ascii;
	wire isText;
	assign ascii = colours[15:8];
	assign isText = colours[7:6];
	//create char decoder not yet implemented
	reg [127:0] charbmp;
	// split reg into wires
	wire [7:0] width, height;
	assign width = dimensions[7:0];
	assign height = dimensions[15:8];
	// start coordinates of the box
	wire [7:0] start_x;
	wire [6:0] start_y;
	assign start_x = coordinates[7:0];
	assign start_y = coordinates[15:9];
	// current draw coordinates
	reg [7:0] current_x;
	reg [6:0] current_y;
	assign x = current_x;
	assign y = current_y;
	//update at CLOCK_50
	always @(posedge clk)
	begin
		if(draw == 1'b1) begin // draw mode
		current_x <= current_x + 1;
			if(current_x >= (start_x + width - 1)) 
			begin
				current_x <= start_x;
				current_y <= current_y + 1;
				if(current_y >= (start_y + height))
				begin
					current_x <= start_x;
					current_y <= start_y;
					draw <= 1'b0; // done drawing
				end
			end
		end
		else if(draw == 1'b0) begin // fetch data mode
				if(state == 2'b11) begin
					draw = 1'b1;
				end
				if(clkout == 1'b1) begin
					clkout <= 1'b0;
				end
				else begin
					clkout <= 1'b1;
				end
		end
	end
endmodule
