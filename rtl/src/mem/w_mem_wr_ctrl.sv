module w_mem_wr_ctrl #(
  parameter  int unsigned SYS_ROW = 16,
  parameter  int unsigned SYS_COL = 16,
  parameter  int unsigned DATA_WIDTH = 16,
  parameter  int unsigned ADDR_WIDTH = 16,
  parameter  int unsigned ACCUM_SIZE = 1024,
  localparam int unsigned ACCUM_ROW = ACCUM_SIZE / SYS_COL,
  localparam int unsigned COUNT_WIDTH = $clog2(ACCUM_ROW) + 3
) (
  input clk,
  input rstn,
  input w_en,
  input [DATA_WIDTH-1:0] w_data[0:SYS_COL-1],
  output logic [SYS_COL-1:0] w_wr_en,
  output logic [ADDR_WIDTH-1:0] w_wr_addr[0:SYS_COL-1],
  output logic [DATA_WIDTH-1:0] w_wr_data[0:SYS_COL-1]
);

logic [COUNT_WIDTH-1:0] m_w_done_cnt;
logic [COUNT_WIDTH-1:0] w_done_cnt;

logic [31:0] m_w_row_cnt;
logic [31:0] w_row_cnt;

logic [SYS_COL-1:0] m_w_wr_en;
logic [ADDR_WIDTH-1:0] m_w_wr_addr[0:SYS_COL-1];
logic [DATA_WIDTH-1:0] m_w_wr_data[0:SYS_COL-1];

// Store weight data
always_ff @(posedge clk) begin
  w_done_cnt <= m_w_done_cnt;

  w_row_cnt <= m_w_row_cnt;

  w_wr_en <= m_w_wr_en;
  w_wr_data <= m_w_wr_data;
  w_wr_addr <= m_w_wr_addr;
end

int j;
always_comb begin
  m_w_row_cnt = w_row_cnt;

  m_w_wr_en = {SYS_COL{1'b0}};
  m_w_wr_data = w_wr_data;
  m_w_wr_addr = w_wr_addr;

  m_w_done_cnt = w_done_cnt;

  if (w_en) begin
    for (j = 0; j < SYS_COL; j = j + 1) begin
      m_w_wr_data[j] = w_data[j];
    end

    m_w_wr_en = {SYS_COL{1'b1}};
    m_w_row_cnt = w_row_cnt + 1;

    for (j = 0; j < SYS_ROW; j = j + 1) begin
      m_w_wr_addr[j] = ADDR_WIDTH'((w_done_cnt << $clog2(SYS_ROW)) + SYS_ROW - 1 - w_row_cnt);
    end

    if (w_row_cnt == SYS_ROW - 1) begin
      m_w_done_cnt = w_done_cnt + 1;
      m_w_row_cnt = 0;
    end
  end else begin
    m_w_done_cnt = 0;
    m_w_row_cnt = 0;
    m_w_wr_en = {SYS_COL{1'b0}};
  end

  if (!rstn) begin
    m_w_done_cnt = 0;
    m_w_row_cnt = 0;
    m_w_wr_en = {SYS_COL{1'b0}};
  end
end

endmodule
