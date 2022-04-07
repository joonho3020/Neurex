module fifo_in_ctrl #(
  parameter  int unsigned FIFO_WIDTH = 16,
  parameter  int unsigned FIFO_DEPTH = 16,
  localparam int unsigned COUNT_WIDTH = $clog2(FIFO_DEPTH) + 1
) (
  input clk,
  input rstn,
  input en,
  output logic [FIFO_WIDTH-1:0] fifo_en,
  output logic [7:0] w_mem_rd_addr [0:FIFO_WIDTH-1], // FIXME: addr_width = 8
  output logic [FIFO_WIDTH-1:0] w_mem_rd_en
);

// CAUTION: Should consider when read data is came out
logic start, m_start, start2, m_start2, start3, m_start3, start4, m_start4;
logic [COUNT_WIDTH-1:0] depth_cnt, m_depth_cnt;

logic [7:0] m_w_mem_rd_addr [0:FIFO_WIDTH-1]; // FIXME: addr_width = 8
logic [FIFO_WIDTH-1:0] m_w_mem_rd_en;

assign fifo_en = {FIFO_WIDTH{start4 && start3}}; // FIXME: For timing problem...

always_ff @(posedge clk) begin
  start <= m_start;
  depth_cnt <= m_depth_cnt;
  w_mem_rd_en <= m_w_mem_rd_en;
  w_mem_rd_addr <= m_w_mem_rd_addr;
  start2 <= m_start2;
  start3 <= m_start3;
  start4 <= m_start4;
end

int i;
always_comb begin
  m_start = start;
  m_start2 = start; // For 2-cycle read latency
  m_start3 = start2; // For 2-cycle read latency
  m_start4 = start3; // For 2-cycle read latency

  m_depth_cnt = depth_cnt;

  if (en) begin
    m_start = 1'b1;
  end

  if (start) begin
    m_start2 = start;

    m_depth_cnt = depth_cnt + 1;
    m_w_mem_rd_en = {FIFO_WIDTH{1'b1}};
    for (i = 0; i < FIFO_WIDTH; i = i + 1) begin
      m_w_mem_rd_addr[i] = depth_cnt;
    end

    if (depth_cnt == FIFO_DEPTH) begin
      m_start = 1'b0;
      m_depth_cnt = {COUNT_WIDTH{1'b0}};
      m_w_mem_rd_en = {FIFO_WIDTH{1'b0}};
      for (i = 0; i < FIFO_WIDTH; i = i + 1) begin
        m_w_mem_rd_addr[i] = 8'h00;
      end
    end
  end else begin
    m_w_mem_rd_en = {FIFO_WIDTH{1'b0}};
  end

  if (!rstn) begin
    m_start = 1'b0;
    m_depth_cnt = {COUNT_WIDTH{1'b0}};
    m_w_mem_rd_en = {FIFO_WIDTH{1'b0}};
    for (i = 0; i < FIFO_WIDTH; i = i + 1) begin
      m_w_mem_rd_addr[i] = 8'h00;
    end
  end
end

endmodule
