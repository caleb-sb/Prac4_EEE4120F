`timescale 1ns / 1ps



module WallClock(

	//inputs - these depend on board's constraint files
  input CLK100MHZ,
  input wire RESET_BTN,
  input wire INC_MIN,
  input wire INC_HOUR,
  input wire [7:0] pwm_in,

	//outputs - these depend on board's constraint files
  output wire [5:0] LED,
  output wire [7:0] SevenSegment,
  output wire [7:0] SegmentDrivers
);

	//Add the reset
	wire ResetButton;
	Delay_Reset Reset_delayed(CLK100MHZ, RESET_BTN, ResetButton);

	//Add and debounce the buttons
	wire MButton;
	wire HButton;
	reg previous_hour = 0; //Created to check for rising edge
	reg previous_min = 0; //Created to check for rising edge

	reg[1:0] CurrentState, NextState;

	//Assigning numerical values to states
	parameter [1:0] post_zero = 0;
	parameter [1:0] post_ten = 1;
	parameter [1:0] post_twenty = 2;

  //States determine the max output of hour1
  reg [3:0] max_hour1;

	// Instantiate Debounce modules here
	Debounce Min_Debounce(CLK100MHZ, INC_MIN, MButton);
	Debounce Hour_Debounce(CLK100MHZ, INC_HOUR, HButton);

	// registers for storing the time
  reg [3:0]hours1=4'd0;
	reg [3:0]hours2=4'd0;
	reg [3:0]mins1=4'd0;
	reg [3:0]mins2=4'd0;

	//Initialize seven segment
	SS_Driver SS_Driver1(
		CLK100MHZ, ResetButton,
		hours2, hours1, mins2, mins1,
		pwm_in,
		SegmentDrivers, SevenSegment
	);

		// register for storing counter
    reg [26:0]Count;

		// register for storing secs and assigning secs to LED
    reg [5:0]secs = 6'b000000;
    assign LED = secs;

	//The main logic
	always @(posedge CLK100MHZ) begin

		if(ResetButton) begin
		  CurrentState <= post_zero;
		  mins1   <= 0;
		  mins2   <= 0;
		  hours1  <= 0;
		  hours2  <= 0;
		  secs    <= 0;
		end
		else if (MButton && ~previous_min) begin    //Detecting a rising edge
				previous_min <= MButton;
				mins1 <= mins1+1;
				if (mins1+1 > 4'd9) begin
						mins1 <= 4'd0;
						mins2 <= mins2 + 4'd1;
						if (mins2+1 > 4'd5) begin
								mins2 <= 4'd0;
						end
				end
		end
		else if (HButton && ~previous_hour) begin    //Detecting a rising edge
				previous_hour <= HButton;
				hours1 <= hours1+1;
				if (hours1+1 > max_hour1) begin
						hours1 <= 4'd0;
						CurrentState <= NextState;
						hours2 <= hours2 + 4'd1;
						if (hours2+1 > 4'd2) begin
								hours2 <= 4'd0;
								CurrentState <= NextState;
						end
				end
		end

		if (~MButton) previous_min <= 0;
	  if (~HButton) previous_hour <= 0;

    if(Count == 0) begin

        if (secs < 6'b111011) begin
						// if secs > 59, then increment secs, else reset secs & increment mins
            secs <= secs + 1'b1;
        end
				else begin
            secs  <= 6'b000000;
            mins1 <= mins1+1;

            if (mins1+1 > 4'd9) begin
								// if mins1 is 9, reset mins1 & increment mins2
                mins1 <= 4'd0;
                mins2 <= mins2 + 4'd1;

                if (mins2+1 > 4'd5) begin
										// if mins2 is 5, reset mins2 & increment hours1
                    mins2 <= 4'd0;
                    hours1 <= hours1 +4'd1;

                    if (hours1+1 > max_hour1) begin
												// if hours1 is max (9,9,3), reset hours1 & increment hours2
                        hours1 <= 4'd0;
                        CurrentState <= NextState;
                        hours2 <= hours2+4'd1;

                        if (hours2+1 > 4'd2) begin
													// if hours2 is 2, reset hours2
                          hours2 <= 4'd0;
                          CurrentState <= NextState;
                        end
                    end
                end
            end
        end
    end // now increment count

		Count <= (Count <=100000000) ? Count+1 : 0;

		// NextState selection placed here
		// to avoid the dreaded inferred latch
		// Switch case statement used to change max_hour1 --
			//-- value as it changes for 09 , 19 , 23 cases
		case (CurrentState)
	       post_zero: begin
	           NextState <= post_ten;
	           max_hour1 <= 4'd9;
	       end
	       post_ten: begin
	           NextState <= post_twenty;
	           max_hour1 <= 4'd9;
	       end
	       post_twenty: begin
	           NextState <= post_zero;
	           max_hour1 <= 4'd3;
	       end
       endcase
	end
endmodule
