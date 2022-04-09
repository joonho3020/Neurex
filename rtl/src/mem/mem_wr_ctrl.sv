module mem_wr_ctrl #(
  parameter  int unsigned SYS_ROW = 16,
  parameter  int unsigned SYS_COL = 16,
  parameter  int unsigned DATA_WIDTH = 16,
  parameter  int unsigned ACCUM_SIZE = 4096,
  localparam int unsigned ACCUM_ROW = ACCUM_SIZE / SYS_COL,
  localparam int unsigned COUNT_WIDTH = $clog2(ACCUM_ROW) + 1
) (
  input                       clk,
  input                       rstn,
  input                       wr_en_in,
  input [DATA_WIDTH-1:0]      num_row, // Assumption: num_row should be less than or equal to ACCUM_ROW
  input [7:0]                 base_addr,
  output logic [SYS_ROW-1:0]  wr_en_out,
  output logic [7:0]          wr_addr[0:SYS_ROW-1], // FIXME: addr_width = 8
  output logic                wr_done
);

logic [SYS_ROW-1:0]     m_wr_en;
logic [7:0]             m_wr_addr[0:SYS_ROW-1]; // FIXME: addr_width = 8
logic [7:0]             base_addr_inter, m_base_addr;

logic [COUNT_WIDTH-1:0] wr_row_cnt;
logic [COUNT_WIDTH-1:0] m_wr_row_cnt;

logic                   wr_start;
logic                   m_wr_start;
logic                   m_wr_done;

// Write data to input or weight memory
// Parallel write
int i;
always_ff @(posedge clk) begin
  wr_en_out <= m_wr_en;
  wr_addr <= m_wr_addr;
  wr_row_cnt <= m_wr_row_cnt;
  wr_start <= m_wr_start;
  wr_done <= m_wr_done;
  base_addr_inter <= m_base_addr;
end

always_comb begin
  m_wr_start = wr_start;
  m_wr_addr = wr_addr;
  m_wr_row_cnt = wr_row_cnt;
  m_base_addr = base_addr;

  if (wr_en_in) begin
    m_wr_start = 1'b1;
    m_wr_done = 1'b0; // is it okay?
    m_base_addr = base_addr;
  end

  if (wr_start) begin
    m_wr_en = {SYS_ROW{1'b1}};

    for (i = 0; i < SYS_ROW; i = i + 1) begin
      m_wr_addr[i] = 8'(base_addr_inter + wr_row_cnt); // FIXME: different bitwidth?
    end

    m_wr_row_cnt = wr_row_cnt + 1;

    if (wr_row_cnt == num_row) begin
      m_wr_start = 1'b0;
      m_wr_en = {SYS_ROW{1'b0}};
      for (i = 0; i < SYS_ROW; i = i + 1) begin
        m_wr_addr[i] = 8'd0;
      end
      m_wr_row_cnt = {COUNT_WIDTH{1'b0}};
      m_wr_done = 1'b1;
    end
  end
  else begin
    m_wr_en = {SYS_ROW{1'b0}};
  end

  if (!rstn) begin
    m_wr_start = 1'b0;
    for (i = 0; i < SYS_ROW; i = i + 1) begin
      m_wr_addr[i] = 8'd0;
    end
    m_wr_en = {SYS_ROW{1'b0}};
    m_wr_row_cnt = {COUNT_WIDTH{1'b0}};
    m_wr_done = 1'b0;
    m_base_addr = 0;
  end
end

endmodule
