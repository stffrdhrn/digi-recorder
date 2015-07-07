/**
 * This ADC interface provides an serial to parallel interface for
 * a ADC chip. 
 * After reset the interface just loops collecting 1 reading from the
 * ADC chip every 16 sclk cycles and stores them into its internal memory
 * at one of 4 address spaces.  The data will be refreshed every 4x16 (64 cycles)
 * So a consumer should be setup to read the data before its gone. 
 */
module adcspi  ( 
  data,
  cs_n, 
  din,
  dout,
  clk, 
  rst_n);

output [11:0]  data;
input          clk;
input          din;
output         dout;
output         cs_n;
input          rst_n;
      
reg  [11:0]   data;

reg  [4:0]    clk_count;
reg  [11:0]   din_ff;
reg  [11:0]   data_ram [0:2];

/* Handle clock counting */
always @ (posedge clk)
  if (~rst_n) 
    clk_count <= 5'd0;
  else
    if (clk_count == 5'd24)
      clk_count <= 5'd0;
    else
      clk_count <= clk_count + 1'b1;

/* if the count is over 16 then we are not transferring */      
assign cs_n = clk_count[4];
assign dout = clk_count[4]; // the address we are querying is always 00
     
/* DeSerialize DIN, use a shift register to move DIN into a 12 bit register during
 * clock cycles 4 -> 15
 */
always @ (posedge clk)
  if (~rst_n)
      din_ff <= 12'd0;
  else
    casez (clk_count)
      5'b001??, 5'b01???: din_ff <= {din_ff[10:0], din};
    endcase
     
/* Return static ram on read interface
 * Write shift register to static ram on first clock
 */ 
always @ (posedge clk) begin
  if (~rst_n)
     data <= 12'd0;
  else if (clk_count == 5'b00000) 
     data <= din_ff;
end

endmodule
