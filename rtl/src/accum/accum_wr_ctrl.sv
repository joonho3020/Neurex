module accum_wr_ctrl #(
  parameter  int unsigned SYS_COL = 16,
  parameter  int unsigned ACCUM_ROW = 256,
  localparam int unsigned ADDR_WIDTH = $clog2(ACCUM_ROW)
) (
  input clk,
  input rstn,
  input wr_en_in,
  // FIXME: we should compute address which is offset of row id % ACCUM_ROW
  input [ADDR_WIDTH-1:0] wr_addr_in, 
  output [SYS_COL-1:0] wr_en_out,
  output [ADDR_WIDTH-1:0] wr_addr_out[0:SYS_COL-1]
);

logic [SYS_COL-2:0] wr_en_shift, m_wr_en_shift;
logic [ADDR_WIDTH-1:0] wr_addr_shift[0:SYS_COL-2];
logic [ADDR_WIDTH-1:0] m_wr_addr_shift[0:SYS_COL-2];

assign wr_en_out = {wr_en_shift, wr_en_in};
genvar i;
generate
  for (i = 0; i < SYS_COL; i = i + 1) begin
    if (i == 0) begin
      assign wr_addr_out[i] = wr_addr_in;
    end else begin
      assign wr_addr_out[i] = wr_addr_shift[i-1];
    end
  end
endgenerate

always_ff @(posedge clk) begin
  wr_en_shift <= m_wr_en_shift;
  wr_addr_shift <= m_wr_addr_shift;
end

int j;
always_comb begin
  m_wr_en_shift[0] = wr_en_in;
  m_wr_en_shift[SYS_COL-2:1] = wr_en_shift[SYS_COL-3:0];

  for (j = 0; j < SYS_COL; j = j + 1) begin
    if (j == 0) begin
      m_wr_addr_shift[0] = wr_addr_in;
    end else begin
      m_wr_addr_shift[j] = wr_addr_shift[j-1];
    end
  end

  if (!rstn) begin
    m_wr_en_shift = {SYS_COL-1{1'b0}};
  end
end
 
endmodule
