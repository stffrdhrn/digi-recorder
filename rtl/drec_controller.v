/* Digital recorder controller
   This module interfaces with Buttons, ADC, DAC and SDRAM
   The buttons allow the recorded to switch states
     - Standby
     - Record 
     - Play
     
    In `Record` mode the controller reads data from the ADC and writes it
    to SDRAM
    
    In `Play` mode the controller reads data from the SDRAM and writes to the DAC
    
    In standby mode the recorder doesnt do much of anything
 */
module drec_controller (
  adc_data, adc_enable,
  
  dac_data, dac_enable,
  
  sdram_wr_data,
  sdram_wr_addr,
  sdram_wr_enable,
  
  sdram_rd_data,
  sdram_rd_addr,
  sdram_rd_enable,
  sdram_rd_data_rdy,
  sdram_rd_data_ack,
  
  ctl_play, ctl_rec, ctl_ack,
  
  clk, rst_n
);

output[15:0] dac_data;
output       dac_enable;

input [15:0] adc_data;   // every 44,000 hz
output       adc_enable;

output[15:0] sdram_wr_data;
output[23:0] sdram_wr_addr;
output       sdram_wr_enable;

input [15:0] sdram_rd_data;
output[23:0] sdram_rd_addr;
output       sdram_rd_enable;
input        sdram_rd_data_rdy;
output       sdram_rd_data_ack;

input        ctl_play;
input        ctl_rec;
output       ctl_ack;

input        clk;
input        rst_n;

reg  [15:0]  dac_data;   // every 44,000 hz
reg          dac_enable; 

reg          adc_enable;

reg [15:0]   sdram_wr_data;
reg          sdram_wr_enable;

reg          sdram_rd_enable;
reg          sdram_rd_data_ack;

reg          ctl_ack;

/* Internals */
reg  [1:0]   state;
reg  [1:0]   next;

reg [23:0] sdram_addr_r;

reg [4:0]  rd_wr_cntr;  // clock is at 1.1Mhz, every 25 cycles is 44K
wire       rd_wr_enable;

assign     rd_wr_enable = (rd_wr_cntr == 5'd24);
assign     sdram_wr_addr = sdram_addr_r;
assign     sdram_rd_addr = sdram_addr_r;

localparam   IDLE   = 2'b00,
             PLAY   = 2'b01,
             RECORD = 2'b10;

/* Handle button presses and state changes */
always @ (*) 
case (state)
  IDLE:
   if (ctl_play)
     next = PLAY;
   else if (ctl_rec)
     next = RECORD;
   else 
     next = IDLE;
  PLAY:
   if (ctl_rec)
     next = IDLE;
   else 
     next = PLAY;
  RECORD:
   if (ctl_play)
     next = IDLE;
   else 
     next = RECORD;
  default:
    next = IDLE;
endcase
             
always @ (posedge clk)
if (~rst_n)
  state <= IDLE;
else 
  state <= next;

always @ (posedge clk)
if (~rst_n)
  ctl_ack <= 1'b0;
else 
  ctl_ack <= (ctl_play | ctl_rec);

/* Handle generating signle every 44000 hz */  
always @ (posedge clk)
if (~rst_n)
  rd_wr_cntr <= 5'd0;
else 
  if (rd_wr_enable) 
    rd_wr_cntr <= 5'd0;
  else
    rd_wr_cntr <= rd_wr_cntr + 1'b1;

/* Handle incrementing the read/write address counter */
always @ (posedge clk)
if (~rst_n)
  sdram_addr_r <= 24'd0;
else 
  if (rd_wr_enable)
    case(state)
      PLAY, RECORD:
        sdram_addr_r <= sdram_addr_r + 1'b1;
      default:
        sdram_addr_r <= 24'd0;
     endcase

/* Handle Play & Record */
always @ (posedge clk)
if (~rst_n)
  begin
  sdram_wr_data <= 16'd0;
  dac_data <= 16'd0;
  end
else
  begin
  if (state == RECORD & rd_wr_enable)
    begin
    sdram_wr_data <= adc_data;
    adc_enable <= 1'b1;
    sdram_wr_enable <= 1'b1;
    end
  else 
    begin
    adc_enable <= 1'b0;
    sdram_wr_enable <= 1'b0;
    end
  
  if (state == PLAY & rd_wr_enable)
    sdram_rd_enable <= 1'b1;
  else 
    sdram_rd_enable <= 1'b0;
   
  if (sdram_rd_data_rdy)  
    begin
    dac_data <= sdram_rd_data;
    sdram_rd_data_ack <= 1'b1;
    dac_enable <= 1'b1;
    end
  else 
    begin
    sdram_rd_data_ack <= 1'b0;
    dac_enable <= 1'b0;
    end
  end
  
endmodule