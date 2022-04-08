module fifo_out_ctrl #(
  parameter  int unsigned FIFO_WIDTH = 16,
  parameter  int unsigned FIFO_DEPTH = 16,
  localparam int unsigned COUNT_WIDTH = $clog2(FIFO_WIDTH) + 1
) (
  input clk,
  input rstn,
  input en,
  output done,
  output [FIFO_WIDTH-1:0] fifo_en,
  output [FIFO_WIDTH-1:0] w_wen
);

logic start, m_start;
logic [COUNT_WIDTH-1:0] depth_cnt, m_depth_cnt;

assign fifo_en = {FIFO_WIDTH{start}};
assign done = (start == 1'b1 && depth_cnt == FIFO_DEPTH - 1);
assign w_wen = {FIFO_WIDTH{(start == 1'b1 && depth_cnt < FIFO_DEPTH)}}; // FIXME: FIFO_DEPTH - 1?

always_ff @(posedge clk) begin
  start <= m_start;
  depth_cnt <= m_depth_cnt;
end

always_comb begin
  m_start = start;
  m_depth_cnt = depth_cnt;

  if (en && !start) begin
    m_start = 1'b1;
    m_depth_cnt = {COUNT_WIDTH{1'b0}};
  end

  if (start) begin
    m_depth_cnt = depth_cnt + 1;

    if (depth_cnt == FIFO_DEPTH - 1) begin
      m_start = 1'b0;
      m_depth_cnt = {COUNT_WIDTH{1'b0}};
    end
  end

  if (!rstn) begin
    m_start = 1'b0;
    m_depth_cnt = {COUNT_WIDTH{1'b0}};
  end
end

endmodule
