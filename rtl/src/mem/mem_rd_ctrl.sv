module mem_rd_ctrl #(
  parameter  int unsigned SYS_ROW = 16,
  parameter  int unsigned SYS_COL = 16,
  parameter  int unsigned DATA_WIDTH = 16,
  parameter  int unsigned ACCUM_SIZE = 4096,
  localparam int unsigned ACCUM_ROW = ACCUM_SIZE / SYS_COL,
  localparam int unsigned COUNT_WIDTH = $clog2(ACCUM_ROW) + 1
) (
  input                       clk,
  input                       rstn,
  input                       rd_en_in,
  input [DATA_WIDTH-1:0]      num_row, // Assumption: num_row should be less than or equal to ACCUM_ROW
  output logic [SYS_ROW-1:0]  rd_en_out,
  output logic [7:0]          rd_addr[0:SYS_ROW-1] // FIXME: addr_width = 8
);

logic [SYS_ROW-1:0]     rd_en;
logic [SYS_ROW-1:0]     m_rd_en, rd_en2, m_rd_en2, rd_en3, m_rd_en3;
logic [7:0]             m_rd_addr[0:SYS_ROW-1]; // FIXME: addr_width = 8

logic [COUNT_WIDTH-1:0] rd_row_cnt;
logic [COUNT_WIDTH-1:0] m_rd_row_cnt;

logic                   rd_start;
logic                   m_rd_start;

assign rd_en_out = rd_en3; // 2-cycle read latency

// Read data to systolic array
// Skewed read
always_ff @(posedge clk) begin
  rd_en <= m_rd_en;
  rd_en2 <= m_rd_en2;
  rd_en3 <= m_rd_en3;
  rd_addr <= m_rd_addr;
  rd_row_cnt <= m_rd_row_cnt;
  rd_start <= m_rd_start;
end

int i;
always_comb begin
  m_rd_start = rd_start;
  m_rd_addr = rd_addr;
  m_rd_row_cnt = rd_row_cnt;

  m_rd_en2 = rd_en;
  m_rd_en3 = rd_en2;

  if (rd_en_in) begin
    m_rd_start = 1'b1;
    for (i = 0; i < SYS_ROW; i = i + 1) begin
      m_rd_addr[i] = 8'h00;
    end
  end

  if (rd_start) begin
    if (rd_row_cnt >= ACCUM_ROW -1 || rd_row_cnt >= num_row - 1) begin
      //m_rd_en = rd_en << 1'b1;
      m_rd_en = {rd_en[SYS_ROW-2:0], 1'b0};
    end else begin
      //m_rd_en = rd_en << 1'b1 + 1'b1;
      m_rd_en = {rd_en[SYS_ROW-2:0], 1'b1};
    end

    for (i = 0; i < SYS_ROW; i = i + 1) begin
      m_rd_addr[i] = rd_addr[i] + {7'd0, rd_en[i]};
    end

    m_rd_row_cnt = rd_row_cnt + 1'b1;

    if (m_rd_row_cnt == 2 * ACCUM_ROW || m_rd_row_cnt == 2 * num_row) begin
      m_rd_start = 1'b0;
      for (i = 0; i < SYS_ROW; i = i + 1) begin
        m_rd_addr[i] = 8'hFF;
      end
      m_rd_row_cnt = {COUNT_WIDTH{1'b0}};
    end
  end else begin
    m_rd_en = {SYS_ROW{1'b0}};
  end

  if (!rstn) begin
    m_rd_start = 1'b0;
    for (i = 0; i < SYS_ROW; i = i + 1) begin
      m_rd_addr[i] = 8'hFF;
    end
    m_rd_en = {SYS_ROW{1'b0}};
    m_rd_row_cnt = {COUNT_WIDTH{1'b0}};
  end
end

endmodule
