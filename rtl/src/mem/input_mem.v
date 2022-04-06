
module input_mem_arr #(
  parameter SYS_ROW = 16, DATA_WIDTH = 16
)
(
  input clk,
  input rstn,
  input [SYS_ROW-1:0] rd_en,
  input [SYS_ROW-1:0] wr_en,
  input [SYS_ROW*DATA_WIDTH-1:0] wr_data,
  input [SYS_ROW*8-1:0] rd_addr, // FIXME: addr_bitwidth = 8
  input [SYS_ROW*8-1:0] wr_addr,
  output [SYS_ROW*DATA_WIDTH-1:0] rd_data
);

genvar i;
generate
  for (i = 0; i < SYS_ROW - 1; i = i + 1) begin: mem_arr
    sram_input_16x1024 m_sram_input_16x1024(
      .clka(clk),
      .ena(rd_en[i]),
      .wea(1'b0),
      .addra(rd_addr[(i+1)*8-1:i*8]),
      .dina(16'd0),
      .clkb(clk),
      .enb(wr_en[i]),
      .web(wr_en[i]),
      .addrb(wr_addr[(i+1)*8-1:i*8]),
      .dinb(wr_data[(i+1)*DATA_WIDTH-1:i*DATA_WIDTH])
    );
  end
endgenerate
endmodule
