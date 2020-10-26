module sequencer (
	input wire clk_in,
	input wire nrst,
	
	output reg [31:0] spi_mosi_data,
	input wire [31:0] spi_miso_data,
	output reg [5:0] spi_nbits,
	
	output reg spi_request,
	input  wire spi_ready,
	
	output reg [7:0] led_out
);

localparam 
	STATE_Whoami = 4'd0,
	STATE_Whoami_Wait = 4'd1,
	STATE_Init1 = 4'd2,
	STATE_Init1_Wait = 4'd3,
	STATE_Read = 4'd4,
	STATE_Read_Wait = 4'd5,
	STATE_LEDout = 4'd6;
	
reg [3:0] state;

reg signed [7:0] saved_acc;

/* Might be usefull to slow down things.
parameter sleeper_period = 32'd1000;

// Frequency divider 
reg [31:0] sleeper;
*/

always @(posedge clk_in or negedge nrst)
	if (nrst == 1'b0) begin		
		state <= 4'b0;
		
		spi_mosi_data <= 32'b0;
		spi_nbits <= 6'b0;
		spi_request <= 1'b0;
		led_out <= 8'b00001010;
		
		//sleeper <= 32'b0;
		
		saved_acc <= 8'b0;
	end else begin
		case (state)
		
			// 1. Init G sensor
			STATE_Whoami: begin
				state <= STATE_Whoami_Wait;
				
				spi_request <= 1'b1;
				spi_nbits <= 6'd23;
				spi_mosi_data <= 31'b00001011_00000001_11111111;
			end
			
			STATE_Whoami_Wait: begin
				if (spi_ready) begin
					state <= STATE_Init1;
				end
				spi_request <= 1'b0;
			end
			
			// 2. Set POWER_CTL (Addr 0x2D)
			STATE_Init1: begin
				state <= STATE_Init1_Wait;
				
				spi_request <= 1'b1;
				spi_nbits <= 6'd23;
				spi_mosi_data <= 31'b00001010_00101101_00000010;
			end
			
			STATE_Init1_Wait: begin
				if (spi_ready) begin
					state <= STATE_Read;
				end 
				spi_request <= 1'b0;
			end
			
			// 3. Read XDATA (Addr 0x08)
			STATE_Read: begin
				state <= STATE_Read_Wait;
				
				spi_request <= 1'b1;
				spi_nbits <= 6'd23;
				spi_mosi_data <= 31'b00001011_00001000_11111111;
			end
			
			STATE_Read_Wait: begin
				if (spi_ready) begin
					state <= STATE_LEDout;
					saved_acc <= spi_miso_data[7:0];
				end 
				spi_request <= 1'b0;
			end
			
			// 4. Set LED output according to accelerometer value
			STATE_LEDout: begin
			
				led_out <= 1 << ((saved_acc + 8'Sb1000_0000) >> 5);
				state <= STATE_Read;
				
				/* 
				// Expose directly X axis to leds.
				led_out <= saved_acc;
				
				if (sleeper != sleeper_period) begin
					sleeper <= sleeper + 1;
					state <= STATE_LEDout;
				end else begin
					sleeper <= 32'b0;
					state <= STATE_Read;
				end
				*/
				
			end
		endcase
	end

endmodule
