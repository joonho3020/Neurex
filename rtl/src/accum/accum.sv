module accum #(
  parameter  int unsigned SYS_COL = 16,
  parameter  int unsigned DATA_WIDTH = 32, // CAUTION!: 2 * DATA_WIDTH
  parameter  int unsigned ACCUM_SIZE = 4096,
  localparam int unsigned ACCUM_ROW = ACCUM_SIZE / SYS_COL,
  localparam int unsigned ADDR_WIDTH = $clog2(ACCUM_ROW)
) (
  input                   clk,
  input                   rstn,
  input [SYS_COL-1:0]     rd_en,
  input [SYS_COL-1:0]     wr_en,
  input [ADDR_WIDTH-1:0]  rd_addr[0:SYS_COL-1],
  input [ADDR_WIDTH-1:0]  wr_addr[0:SYS_COL-1],
  input [DATA_WIDTH-1:0]  wr_data[0:SYS_COL-1],
  output [DATA_WIDTH-1:0] rd_data[0:SYS_COL-1]
);

genvar i;
generate
  for (i = 0; i < SYS_COL; i = i + 1) begin : accum_arr
    accum_col #(
      .ACCUM_ROW(ACCUM_ROW), .DATA_WIDTH(DATA_WIDTH)
    )
    m_accum_col(
      .clk      (clk),
      .rstn     (rstn),
      .rd_en    (rd_en[i]),
      .wr_en    (wr_en[i]),
      .rd_addr  (rd_addr[i]),
      .wr_addr  (wr_addr[i]),
      .wr_data  (wr_data[i]),
      .rd_data  (rd_data[i])
    );
  end
endgenerate

endmodule
