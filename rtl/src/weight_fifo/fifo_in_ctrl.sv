module fifo_in_ctrl #(
  parameter  int unsigned FIFO_WIDTH = 16,
  parameter  int unsigned FIFO_DEPTH = 16,
  parameter  int unsigned SYS_ROW = 16,
  parameter  int unsigned ADDR_WIDTH = 16,
  localparam int unsigned COUNT_WIDTH = $clog2(FIFO_DEPTH) + 3
) (
  input                         clk,
  input                         rstn,
  input                         en,
  input [31:0]                  repeat_cnt,
  input [ADDR_WIDTH-1:0]        base_addr,
  input [ADDR_WIDTH-1:0]        offset_addr,
  output logic                  fifo_data_in,
  output logic [FIFO_WIDTH-1:0] fifo_en,
  output logic [ADDR_WIDTH-1:0] w_mem_rd_addr [0:FIFO_WIDTH-1], // FIXME: addr_width = 16
  output logic [FIFO_WIDTH-1:0] w_mem_rd_en,
  output logic                  done
);

// CAUTION: Should consider when read data is came out
logic start, m_start, start2, m_start2, start3, m_start3, start4, m_start4;

logic [COUNT_WIDTH-1:0] depth_cnt, m_depth_cnt;

logic [ADDR_WIDTH-1:0] m_w_mem_rd_addr[0:FIFO_WIDTH-1]; // FIXME: addr_width = 8
logic [FIFO_WIDTH-1:0] m_w_mem_rd_en;

logic [ADDR_WIDTH-1:0] base_addr_inter, m_base_addr;
logic [ADDR_WIDTH-1:0] offset_addr_inter, m_offset_addr;

logic [31:0] repeat_cnt_inter, m_repeat_cnt;

logic m_done;

assign fifo_en = {FIFO_WIDTH{start4 & start3}}; // FIXME: should change for DRAM...
assign fifo_data_in = start4 & start3;

always_ff @(posedge clk) begin
  start <= m_start;
  depth_cnt <= m_depth_cnt;
  w_mem_rd_en <= m_w_mem_rd_en;
  w_mem_rd_addr <= m_w_mem_rd_addr;
  start2 <= m_start2;
  start3 <= m_start3;
  start4 <= m_start4;
  base_addr_inter <= m_base_addr;
  offset_addr_inter <= m_offset_addr;
  repeat_cnt_inter <= m_repeat_cnt;
  done <= m_done;
end

int i;
always_comb begin
  m_start = start;
  // FIXME: should change for DRAM
  m_start2 = start; // For 2-cycle read latency
  m_start3 = start2; // For 2-cycle read latency
  m_start4 = start3; // For 2-cycle read latency

  m_base_addr = base_addr_inter;
  m_offset_addr = offset_addr_inter;
  m_repeat_cnt = repeat_cnt_inter;

  m_depth_cnt = depth_cnt;
  m_done = 1'b0;

  if (en) begin
    m_start = 1'b1;
    m_base_addr = base_addr;
    m_offset_addr = offset_addr;
    m_repeat_cnt = repeat_cnt;
  end

  if (start) begin
    m_start2 = start;

    m_depth_cnt = depth_cnt + 1;
    m_w_mem_rd_en = {FIFO_WIDTH{1'b1}};
    for (i = 0; i < FIFO_WIDTH; i = i + 1) begin
      m_w_mem_rd_addr[i] = ADDR_WIDTH'(base_addr_inter + offset_addr_inter + depth_cnt);
    end

    if (depth_cnt == repeat_cnt_inter << $clog2(SYS_ROW)) begin
      m_start = 1'b0;
      m_depth_cnt = {COUNT_WIDTH{1'b0}};
      m_w_mem_rd_en = {FIFO_WIDTH{1'b0}};
      for (i = 0; i < FIFO_WIDTH; i = i + 1) begin
        m_w_mem_rd_addr[i] = {ADDR_WIDTH{1'b0}};
      end
      m_base_addr = 0;
      m_offset_addr = 0;
      m_done = 1'b1;
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
    m_base_addr = 0;
    m_repeat_cnt = 0;
  end
end

endmodule
