`timescale 1ns / 1ps



module WallClock(
	//inputs - these will depend on your board's constraint files
    input CLK100MHZ,
    input wire RESET_BTN,
    input wire INC_MIN,
    input wire INC_HOUR,
    input wire [7:0] pwm_in,
	//outputs - these will depend on your board's constraint files
    output wire [5:0] LED,
    output wire [7:0] SevenSegment,
    output wire [7:0] SegmentDrivers
);

	//Add the reset
	wire ResetButton;
	Delay_Reset Reset_delayed(CLK100MHZ, RESET_BTN, ResetButton);
	//Add and debounce the buttons
	wire MButton; //Will be the debounced value?
	wire HButton; //Will be the debounced value?
	
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
	// You will need to change some signals depending on you constraints
	SS_Driver SS_Driver1(
		CLK100MHZ, ResetButton,
		hours2, hours1, mins2, mins1, // Used temporary test values before adding hours2, hours1, mins2, mins1
		pwm_in,
		SegmentDrivers, SevenSegment
	);
    
    reg [26:0]Count;
    
    reg [5:0]secs = 6'b000000;
    assign LED = secs;
	//The main logic
	always @(posedge CLK100MHZ) begin
		// implement your logic here
		if(ResetButton) begin
		  CurrentState <= post_zero;
		  mins1   <= 0;
		  mins2   <= 0;
		  hours1  <= 0;
		  hours2  <= 0;
		  secs    <= 0;
		end else begin
            if(Count == 0) begin
              if (secs < 6'b111011) begin
                  secs <= secs + 1'b1;
              end else begin
                  secs  <= 6'b000000;
                  mins1 <= mins1+1;
                  if (mins1+1 > 4'd9) begin
                      mins1 <= 4'd0;
                      mins2 <= mins2 + 4'd1;
                      if (mins2+1 > 4'd5) begin
                          mins2 <= 4'd0;
                          hours1 <= hours1 +4'd1;
                          if (hours1+1 > max_hour1) begin
                              hours1 <= 4'd0;
                              CurrentState <= NextState;
                              hours2 <= hours2+4'd1;
                              if (hours2+1 > 4'd2) begin
                                hours2 <= 4'd0;
                                CurrentState <= NextState;
                              end
                          end
                      end
                  end
              end
          end
		end
		Count <= (Count <=250000) ? Count+1 : 0;
		
		// NextState selection placed here
		// to avoid the dreaded inferred latch
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