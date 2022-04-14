module out_mem_arr #(
  parameter int unsigned NUM_BANK = 16,
  parameter int unsigned DATA_WIDTH = 32,
  parameter int unsigned ADDR_WIDTH = 16
) (
  input                   clk,
  input                   rstn,
  input [NUM_BANK-1:0]    rd_en,
  input [NUM_BANK-1:0]    wr_en,
  input [ADDR_WIDTH-1:0]  rd_addr[0:NUM_BANK-1], // FIXME: addr_bitwidth = 8
  input [ADDR_WIDTH-1:0]  wr_addr[0:NUM_BANK-1],
  input [DATA_WIDTH-1:0]  wr_data[0:NUM_BANK-1],
  output [DATA_WIDTH-1:0] rd_data[0:NUM_BANK-1]
);

logic [DATA_WIDTH-1:0]    rd_data2[0:NUM_BANK-1];

genvar i;
generate
  for (i = 0; i < NUM_BANK; i = i + 1) begin : out_mem_arr
    // True Dual-port BRAM
    sram_32x256 m_sram_32x256(
      .clka       (clk),
      .ena        (rd_en[i]),
      .wea        (1'b0),
      .addra      (8'(rd_addr[i])),
      .dina       ({DATA_WIDTH{1'b0}}),
      .douta      (rd_data[i]),
      .clkb       (clk),
      .enb        (wr_en[i]),
      .web        (wr_en[i]),
      .addrb      (8'(wr_addr[i])),
      .dinb       (wr_data[i]),
      .doutb      (rd_data2[i])
    );
  end
endgenerate

endmodule
