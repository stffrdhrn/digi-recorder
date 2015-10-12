module dacspi_tb();

reg rst_n, clk;
reg [15:0] wr_data;
reg        wr;
wire spi_cs_n, spi_sclk, spi_sdout;

initial 
begin
  rst_n = 1;
  clk = 0;
  wr_data = 16'b1010_0110_1100_1101;
  wr = 0;
end

always 
  #1  clk <= ~clk;

initial
begin
  #4 rst_n = 0;
  #4 rst_n = 1;

  #4 wr = 1;
  #4 wr = 0;

  #16 if (spi_sdout != 1) 
  begin
    $display("Expected spi_sdout to be high after 16 cycles");
    $finish(1);
  end
  
end
  
dacspi dacspi (
  .wr_data(wr_data),
  .wr(wr),
  
  .spi_cs_n(spi_cs_n),
  .spi_sclk(spi_sclk),
  .spi_sdout(spi_sdout),
  
  .clk(clk),
  .rst_n(rst_n)
);
  
endmodule
