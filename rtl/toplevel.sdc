#create_clock -period "20ns" CLOCK_50
create_clock -period "10ns" clk
derive_pll_clocks
derive_clock_uncertainty
