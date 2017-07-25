/*
	"Simon ooooooooooh"
	By: Alex Green, Bilal Khan, Spencer McCoubrey and Derek Nguyen
	A CSCB58 Final Project
*/

module Simon(
		CLOCK_50,						//	On Board 50 MHz
		// Your inputs and outputs here
        KEY,
		SW,
		LEDR,
		HEX0,
		HEX1,
		HEX4,
		HEX5,
		// The ports below are for the VGA output.  Do not change.
		VGA_CLK,   						//	VGA Clock
		VGA_HS,							//	VGA H_SYNC
		VGA_VS,							//	VGA V_SYNC
		VGA_BLANK_N,						//	VGA BLANK
		VGA_SYNC_N,						//	VGA SYNC
		VGA_R,   						//	VGA Red[9:0]
		VGA_G,	 						//	VGA Green[9:0]
		VGA_B   						//	VGA Blue[9:0]
	);

	input	CLOCK_50;				//	50 MHz
	input  [3:0] KEY;
	input  [17:0] SW;
	output [17:0] LEDR;
	output [6:0] HEX0;
	output [6:0] HEX1;
	output [6:0] HEX4;
	output [6:0] HEX5;

	// Declare your inputs and outputs here
	// Do not change the following outputs
	output			VGA_CLK;   				//	VGA Clock
	output			VGA_HS;					//	VGA H_SYNC
	output			VGA_VS;					//	VGA V_SYNC
	output			VGA_BLANK_N;			//	VGA BLANK
	output			VGA_SYNC_N;				//	VGA SYNC
	output	[9:0]	VGA_R;   				//	VGA Red[9:0]
	output	[9:0]	VGA_G;	 				//	VGA Green[9:0]
	output	[9:0]	VGA_B;   				//	VGA Blue[9:0]
    
	wire [2:0] colour;
	wire [7:0] x;
	wire [7:0] y;
	wire writeEn, resetn;
	assign resetn = SW[17];
	wire check;
	wire correct;
	wire [2:0] draw;
	wire plot, redraw;
	wire [7:0] score;
	wire [7:0] IMSOHIGHscoreIAM;
	wire randomize;
	wire [19:0] pixels_drawn;
	wire [3:0] sequences;
	wire [3:0] max_sequences;
	wire initialize;
	wire [7:0] splice_counter;
	wire [7:0] check_counter;
	// Create an Instance of a VGA controller - there can be only one!
	// Define the number of colours as well as the initial background
	// image file (.MIF) for the controller.
	vga_adapter VGA(
			.resetn(1'b1),
			.clock(CLOCK_50),
			.colour(colour),
			.x(x),
			.y(y),
			.plot(writeEn),
			/* Signals for the DAC to drive the monitor. */
			.VGA_R(VGA_R),
			.VGA_G(VGA_G),
			.VGA_B(VGA_B),
			.VGA_HS(VGA_HS),
			.VGA_VS(VGA_VS),
			.VGA_BLANK(VGA_BLANK_N),
			.VGA_SYNC(VGA_SYNC_N),
			.VGA_CLK(VGA_CLK));
		defparam VGA.RESOLUTION = "160x120";
		defparam VGA.MONOCHROME = "FALSE";
		defparam VGA.BITS_PER_COLOUR_CHANNEL = 1;
		defparam VGA.BACKGROUND_IMAGE = "black.mif";

	control c0(.clk(CLOCK_50), 
			.check(check),
			.send(SW[16]), 
			.start(SW[0]), 
			.correct(correct),
			.draw(draw), 
			.plot(writeEn), 
			.random(randomize), 
			.pixels_drawn(pixels_drawn), 
			.score(score),
			.IMSOHIGHscoreIAM(IMSOHIGHscoreIAM),
			.sequences(sequences),
			.max_sequences(max_sequences),
			.resetn(resetn),
			.initialize(initialize),
			.splice_counter(splice_counter),
			.check_counter(check_counter));

	datapath d0(.clk(CLOCK_50),
			.resetn(resetn),
			.initialize(initialize),
			.randomize(randomize),
			.check(check),
			.draw(draw),
			.plot(writeEn),
			.max_sequences(max_sequences),
			.inputs(SW[4:1]),
			.correct(correct),
			.x(x),
			.y(y),
			.colour(colour),
			.pixels_drawn(pixels_drawn),
			.sequences(sequences),
			.splice_counter(splice_counter),
			.check_counter(check_counter));


	hex_display h0(.IN(score[3:0]), .OUT(HEX0));
	hex_display h1(.IN(score[7:4]), .OUT(HEX1));
	hex_display h4(.IN(IMSOHIGHscoreIAM[3:0]), .OUT(HEX4));
	hex_display h5(.IN(IMSOHIGHscoreIAM[7:4]), .OUT(HEX5));
	
	
endmodule

module hex_display(IN, OUT);
	input [3:0] IN;
	output reg [7:0] OUT;
	 
	always @(*)
	begin
		case(IN[3:0])
			4'b0000: OUT = 7'b1000000;
			4'b0001: OUT = 7'b1111001;
			4'b0010: OUT = 7'b0100100;
			4'b0011: OUT = 7'b0110000;
			4'b0100: OUT = 7'b0011001;
			4'b0101: OUT = 7'b0010010;
			4'b0110: OUT = 7'b0000010;
			4'b0111: OUT = 7'b1111000;
			4'b1000: OUT = 7'b0000000;
			4'b1001: OUT = 7'b0011000;
			4'b1010: OUT = 7'b0001000;
			4'b1011: OUT = 7'b0000011;
			4'b1100: OUT = 7'b1000110;
			4'b1101: OUT = 7'b0100001;
			4'b1110: OUT = 7'b0000110;
			4'b1111: OUT = 7'b0001110;
			default: OUT = 7'b0111111;
		endcase
	end
endmodule

module control(clk, check, send, start, correct, draw, plot, random, pixels_drawn, score, IMSOHIGHscoreIAM, sequences, max_sequences, resetn, initialize, splice_counter, check_counter);
	output reg check, plot, random, initialize; // signals for datapath
	output reg [3:0] draw; // holds which square is being drawn
	output reg [7:0] score;
	output reg [7:0] IMSOHIGHscoreIAM;
	output reg [3:0] max_sequences; // max number of sequences shown in a row
	output reg [7:0] splice_counter; 
	output reg [7:0] check_counter; 
	input send, clk, start, correct, resetn;
	input [19:0] pixels_drawn; // how many pixels have been drawn of the current square
	input [3:0] sequences; // how many sequences are left to draw
	initial max_sequences = 4'd1;
	localparam // UNITED STATES OF BILAL AND CO
	BEGIN = 20'D0, // starting state
	INITIALIZE = 20'd18, // initializes starting values
	RANDOMIZE = 20'D1, // randomizes what squares will be active
	LOAD_SQUARE_1 = 20'D2, // loads the location and colour for square 1
	DRAW_SQUARE_1 = 20'D3,	// waits while square is drawn
	LOAD_SQUARE_2 = 20'D4,
	DRAW_SQUARE_2 = 20'D5,	
	LOAD_SQUARE_3 = 20'D6,
	DRAW_SQUARE_3 = 20'D7,		
	LOAD_SQUARE_4 = 20'D8,
	DRAW_SQUARE_4 = 20'D9,		    
	REDRAW_DELAY = 20'd16, // starts counter for delay to keep squares on screen
	REDRAW_DELAY_WAIT = 20'd17, // waits for counter to finish before drawing over squares
	WAIT_UP = 20'D10, // wait for user input to be switched up
	WAIT_DOWN = 20'd19, // waits for user input to be switched down
	CHECK_WAIT = 20'd15, // tells datapath to check
	CHECK = 20'D11, // takes datapath result and goes to correct or syke
	SYKE = 20'D12, // THATS THE WRONG NUMBER OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOH
	CORRECT = 20'D13; // increase score and loop back to randomize



	
	reg [19:0] current_state, next_state;


	// waiting_thing for counter 
	reg ct_reset; // resets counter
	wire ct_go; // counter finishes
	rate_divider counting(.clk(clk), .reset(ct_reset), .start_value(25000000), .enable(ct_go));

	always @(*)
	begin: state_table
		case(current_state)
			BEGIN: next_state = start ? INITIALIZE : BEGIN;
			INITIALIZE: next_state = RANDOMIZE;
			RANDOMIZE: next_state = LOAD_SQUARE_1;
			LOAD_SQUARE_1: next_state = DRAW_SQUARE_1;
			DRAW_SQUARE_1: next_state = (pixels_drawn < 20'd256) ? DRAW_SQUARE_1 : LOAD_SQUARE_2; // only continue if all squares are drawn
			LOAD_SQUARE_2: next_state = DRAW_SQUARE_2;
			DRAW_SQUARE_2: next_state = (pixels_drawn < 20'd256) ? DRAW_SQUARE_2 : LOAD_SQUARE_3;
			LOAD_SQUARE_3: next_state = DRAW_SQUARE_3;
			DRAW_SQUARE_3: next_state = (pixels_drawn < 20'd256) ? DRAW_SQUARE_3 : LOAD_SQUARE_4; 
			LOAD_SQUARE_4: next_state = DRAW_SQUARE_4;
			DRAW_SQUARE_4: next_state = (pixels_drawn < 20'd256) ? DRAW_SQUARE_4 : REDRAW_DELAY;
			REDRAW_DELAY: next_state = REDRAW_DELAY_WAIT;
			// after the delay loop back to drawing square one if there are sequences left, otherwise go to wait
			REDRAW_DELAY_WAIT: next_state = ct_go ? ((sequences > 4'b0000) ? RANDOMIZE : WAIT_UP) : REDRAW_DELAY_WAIT;
			WAIT_UP: next_state = send ? WAIT_DOWN : WAIT_UP;
			WAIT_DOWN: next_state = send ? WAIT_DOWN : CHECK_WAIT;
			CHECK_WAIT: next_state = CHECK;
			CHECK: next_state = correct ? CORRECT : SYKE; //THATS THE WRONG NUMBER OOOOOOOOOOOOOOH
			CORRECT: next_state = INITIALIZE;
			SYKE: next_state = BEGIN;
		endcase
	end
	// does the enable signals for states corresponding to actions in the datapath
	always @(*)
	begin: enable_signals
	draw = 3'b0;
	plot = 1'b0;
	check = 1'b0;
	random = 1'b0;
	initialize = 1'b0;
	ct_reset = 1'b0;
		case(current_state)
			INITIALIZE: 
			begin
			initialize = 1'b1;
			splice_counter = 8'd0;
			check_counter = 8'd0;
			end
			RANDOMIZE:
			begin
			random = 1'b1;
			end
			LOAD_SQUARE_1: 
			begin
			draw = 3'b001;
			end
			DRAW_SQUARE_1: plot = 1'b1;
			LOAD_SQUARE_2: draw = 3'b010;
			DRAW_SQUARE_2: plot = 1'b1;
			LOAD_SQUARE_3: draw = 3'b011;
			DRAW_SQUARE_3: plot = 1'b1; 
			LOAD_SQUARE_4: draw = 3'b100;
			DRAW_SQUARE_4: plot = 1'b1;
			REDRAW_DELAY: 
			begin
				splice_counter = splice_counter + 8'd2;
				ct_reset = 1'b1;
			end
			CHECK_WAIT: check = 1'b1; 
			CHECK: check_counter = check_counter + 8'd4;
		endcase
	end
	// flip flop for setting of next state / reset
	always @(posedge clk)
	begin: state_changes
		if (~resetn)
		begin
			current_state <= BEGIN;
			//score <= 8'b00000000;
		end
		else
			current_state <= next_state;
		case(current_state)
			BEGIN:
			begin
			if (score > IMSOHIGHscoreIAM)
				IMSOHIGHscoreIAM <= score;
			score <= 8'd0;
			
			max_sequences = 4'b0001;
			end
			CORRECT: 
			begin
				score = score + 1'b1; 
				//if (max_sequences < 10) 
				//	max_sequences = max_sequences + 1'b1;
			end
		endcase
	end

endmodule

// datapath module
module datapath(clk, resetn, initialize, randomize, check, draw, plot, max_sequences, inputs, correct, x, y, colour, pixels_drawn, sequences, splice_counter, check_counter);
	input clk;
	input resetn;
	input initialize; // signal to initialize num of sequences
	input randomize; // signal to create new random numbers
	input check; // signal to check user input
	input [2:0] draw; // signal to tell which square to load info for
	input plot; // signal saying it's drawing
	input [3:0] max_sequences; // number of sequences it will show
	input [3:0] inputs; // user inputs
	input [7:0] splice_counter;
	input [7:0] check_counter;
	output reg correct; // outputs whether user input was correct
	output [7:0] x; // x value 
	output [7:0] y; // y value of pixel to draw
	output reg [2:0] colour;
	output reg [19:0] pixels_drawn;
	output reg [3:0] sequences;

	localparam // consts for positions
	// x spacing for squares 24 (s1) 16 (s2) 16 (s3) 16 (s4) 24  squares are 16 x 16
	SQUARE_1_X 	= 8'd25,
	SQUARE_1_Y	= 8'd52,

	SQUARE_2_X 	= 8'd57,
	SQUARE_2_Y	= 8'd52,

	SQUARE_3_X 	= 8'd89,
	SQUARE_3_Y	= 8'd52,

	SQUARE_4_X 	= 8'd121,
	SQUARE_4_Y	= 8'd52,

	BLACK			= 3'b000,
	WHITE 		= 3'b111,
	RED 		= 3'b100;

	// square things
	wire [3:0] x_add = pixels_drawn[3:0]; // 
	wire [3:0] y_add = pixels_drawn[7:4];
	reg [7:0] x_start;
	reg [7:0] y_start;
	assign x = x_start + x_add;
	assign y = y_start + y_add;

	// randomizer things
	reg [63:0] active_squares;
	reg [3:0] random_counter;
	initial random_counter = 4'd0;
	
	// sequences things
	reg state; // 0 state is drawing active squares, 1 state is resetting to white squares
	initial state = 0;
	

	always @(posedge clk)
	begin
	
		if (initialize == 1'b1)
		begin
			sequences = max_sequences;
		end
		
		// RANDOM NUMBER GENERATING LETS GO
		if (randomize == 1'b1 && state == 1'b0) // TODO additional sequences
		begin
			if (splice_counter < max_sequences * 4)
			begin
			active_squares[splice_counter +: 4] = random_counter;
			end
		end
		random_counter = random_counter + 1;


		// LOADING STARTING SQUARE POSITION
		if (draw == 3'b001) // load first square
		begin
			pixels_drawn = 0; // reset pixel counter
			x_start <= SQUARE_1_X; // set position to top right corner of square
			y_start <= SQUARE_1_Y;
			if (state == 1'b1) // if in the redrawing state (all squares white)
				colour = BLACK;
			else // in the normal drawing state
			begin
				if (active_squares[3] == 1'b0) // if the square isn't active make it white, otherwise red
					colour = WHITE;
				else
					colour = RED;
			end
		end
		if (draw == 3'b010) // load second square
		begin
			pixels_drawn = 0;
			x_start <= SQUARE_2_X;
			y_start <= SQUARE_2_Y;
			if (state == 1'b1)
				colour = BLACK;
			else
			begin
				if (active_squares[2] == 1'b0)
					colour = WHITE;
				else
					colour = RED;
			end
		end
		if (draw == 3'b011) // load third square
		begin
			pixels_drawn = 0;
			x_start <= SQUARE_3_X;
			y_start <= SQUARE_3_Y;
			if (state == 1'b1)
				colour = BLACK;
			else
			begin
				if (active_squares[1] == 1'b0)
					colour = WHITE;
				else
					colour = RED;
			end
		end
		if (draw == 3'b100) // load fourth square and toggle state for next draw
		begin
			pixels_drawn = 0;
			x_start <= SQUARE_4_X;
			y_start <= SQUARE_4_Y;
			if (state == 1'b1)
				begin
				colour = BLACK;
				state = 1'b0;
				if (sequences > 0)
					sequences = sequences - 4'd1; // reduce remaining number of sequencs
				end
			else
			begin
				state = 1'b1;
				if (active_squares[0] == 1'b0)
					colour = WHITE;
				else
					colour = RED;
			end
		end
		
		// DRAWING SQUARES
		if (plot == 1'b1)
		begin
			if (pixels_drawn < 20'd256)
				pixels_drawn <= pixels_drawn + 20'd1;
		end

		// CHECKING USER INPUT
		if (check == 1'b1)
		begin
		if (inputs[3:0] == active_squares[check_counter+3 -: 4])
			correct = 1'b1;
		else
			correct = 1'b0;
		end

		// RESET
		if (resetn == 1'b0)
		begin
			state = 1'b0;
		end
	end		

endmodule

module rate_divider(clk, reset, start_value, enable);
	input clk;
	input reset;
	input start_value;
	output enable;
	reg Out;
  	integer counter;
  
    always @(posedge clk)
    begin
		  if (reset)
		  begin
		      counter <= 10000000 - 1;
				Out <= 1'b0;
		  end
        else if (counter > 0)
        begin
            counter <= counter - 1;
      		Out <= 1'b0;
        end
      
        else
        begin
            counter <= 10000000 - 1;
          	Out <= 1'b1;
        end
    end
	 assign enable = Out;
endmodule
