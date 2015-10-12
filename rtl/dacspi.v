/* Generic spi module for testing 16 bit words 
 * (called dac because that what I am using it for) 
 * 
 * On wr and clk the wr_data is registered
 * After that cs_n is brought low, and serial data 
 * is sent when done cs_n will go high.  We expect the 
 * SPI receiver to latch in the data when cs_n goes high. 
 */
module dacspi (
  wr_data,
  wr,
  
  spi_cs_n,
  spi_sclk,
  spi_sdout,
  
  clk,
  rst_n
);

input [15:0] wr_data;
input        wr;

output       spi_cs_n;
output       spi_sclk;
output       spi_sdout;

input        clk;
input        rst_n;

reg   [15:0] wr_data_r;
reg   [4:0]  count;
wire         spi_sdout;
wire         sdout_enabled;

assign sdout_enabled = count[4];
assign spi_sclk = rst_n ? clk : 1'b0;
assign spi_sdout = sdout_enabled ? wr_data_r[15] : 1'b0;
assign spi_cs_n = rst_n ? ~count[4] : 1'b1;

always @ (negedge clk)
  if (~rst_n)
  begin 
    wr_data_r <= 16'd0;
    count <= 5'd0;
  end
  else if (sdout_enabled)
  begin
    count <= count - 1'b1;
    wr_data_r <= {wr_data_r[14:0], 1'b0};
  end
  else if (wr)
  begin
    wr_data_r <= wr_data;
    count <= 5'b1_1111;
  end


endmodule