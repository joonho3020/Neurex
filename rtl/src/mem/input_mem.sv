module input_mem_arr #(
  parameter int unsigned SYS_ROW = 16,
  parameter int unsigned DATA_WIDTH = 16
) (
  input                   clk,
  input                   rstn,
  input [SYS_ROW-1:0]     rd_en,
  input [SYS_ROW-1:0]     wr_en,
  input [DATA_WIDTH-1:0]  wr_data[0:SYS_ROW-1],
  input [7:0]             rd_addr[0:SYS_ROW-1], // FIXME: addr_bitwidth = 8
  input [7:0]             wr_addr[0:SYS_ROW-1],
  output [DATA_WIDTH-1:0] rd_data[0:SYS_ROW-1]
);

logic [DATA_WIDTH-1:0]    rd_data2[0:SYS_ROW-1];

genvar i;
generate
  for (i = 0; i < SYS_ROW; i = i + 1) begin : mem_arr
    sram_input_16x256 m_sram_input_16x256(
      .clka       (clk),
      .ena        (rd_en[i]),
      .wea        (1'b0),
      .addra      (rd_addr[i]),
      .dina       (16'd0),
      .douta      (rd_data[i]),
      .clkb       (clk),
      .enb        (wr_en[i]),
      .web        (wr_en[i]),
      .addrb      (wr_addr[i]),
      .dinb       (wr_data[i]),
      .doutb      (rd_data2[i])
    );
  end
endgenerate

endmodule
