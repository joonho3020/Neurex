
module input_mem_ctrl #(
  parameter SYS_ROW = 16, DATA_WIDTH = 16, ACCUM_ROW = 128
)
(
  input clk,
  input rstn,
  input rd_en_in,
  input wr_en_in,
  input [DATA_WIDTH-1:0] num_row, // Assumption: num_row should be less than or equal to ACCUM_ROW
  output reg [SYS_ROW-1:0] rd_en,
  output reg [SYS_ROW*8-1:0] rd_addr, // FIXME: addr_width = 8
  output reg [SYS_ROW-1:0] wr_en,
  output reg [SYS_ROW*8-1:0] wr_addr, // FIXME: addr_width = 8
  output reg wr_done
);

localparam COUNT_WIDTH = $clog2(ACCUM_ROW) + 1;

reg [SYS_ROW-1:0] m_rd_en;
reg [SYS_ROW*8-1:0] m_rd_addr; // FIXME: addr_width = 8
reg [SYS_ROW*8-1:0] tmp_m_rd_addr; // FIXME: addr_width = 8
reg [SYS_ROW-1:0] m_wr_en;
reg [SYS_ROW*8-1:0] m_wr_addr; // FIXME: addr_width = 8

reg [COUNT_WIDTH-1:0] rd_row_cnt;
reg [COUNT_WIDTH-1:0] m_rd_row_cnt;

reg [COUNT_WIDTH-1:0] wr_row_cnt;
reg [COUNT_WIDTH-1:0] m_wr_row_cnt;

reg rd_start;
reg m_rd_start;
reg wr_start;
reg m_wr_start;
reg m_wr_done;

// Read data to systolic array
// Skewed read
always @(posedge clk) begin
  rd_en <= m_rd_en;
  rd_addr <= m_rd_addr;
  rd_row_cnt <= m_rd_row_cnt;
  rd_start <= m_rd_start;
end

integer i;
always@* begin
  m_rd_start = rd_start;
  m_rd_addr = rd_addr;
  tmp_m_rd_addr = rd_addr;
  m_rd_row_cnt = rd_row_cnt;

  if (rd_en_in) begin
    m_rd_start = 1'b1;
  end

  if (rd_start) begin
    if (rd_row_cnt >= ACCUM_ROW || rd_row_cnt >= num_row) begin
      m_rd_en = rd_en << 1;
    end
    else begin
      m_rd_en = rd_en << 1 + 1'b1;
    end

    for (i = 0; i < SYS_ROW; i = i + 1) begin
      tmp_m_rd_addr[i*8+:8] = {7'd0, rd_en[i]};
    end
    m_rd_addr = rd_addr + tmp_m_rd_addr;

    m_rd_row_cnt = rd_row_cnt + 1'b1;

    if (m_rd_row_cnt == 2 * ACCUM_ROW - 1 || m_rd_row_cnt == 2 * num_row - 1) begin
      m_rd_start = 1'b0;
      m_rd_addr = {SYS_ROW*8{1'b0}};
      m_rd_row_cnt = {COUNT_WIDTH{1'b0}};
    end
  end
  else begin
    m_rd_en = {SYS_ROW{1'b0}};
  end

  if (!rstn) begin
    m_rd_start = 1'b0;
    m_rd_addr = {SYS_ROW*8{1'b0}};
    m_rd_en = {SYS_ROW{1'b0}};
    m_rd_row_cnt = {COUNT_WIDTH{1'b0}};
  end
end

// Write data to input memory
// Parallel write
always @(posedge clk) begin
  wr_en <= m_wr_en;
  wr_addr <= m_wr_addr;
  wr_row_cnt <= m_wr_row_cnt;
  wr_start <= m_wr_start;
  wr_done <= m_wr_done;
end

always @* begin
  m_wr_start = wr_start;
  m_wr_addr = wr_addr;
  m_wr_row_cnt = wr_row_cnt;

  if (wr_en_in) begin
    m_wr_start = 1'b1;
    m_wr_done = 1'b0; // is it okay?
  end

  if (wr_start) begin
    m_wr_en = {SYS_ROW{1'b1}};

    for (i = 0; i < SYS_ROW; i = i + 1) begin
      m_wr_addr[i*8+:8] = wr_row_cnt; // FIXME: different bitwidth?
    end

    m_wr_row_cnt = wr_row_cnt + 1;

    if (wr_row_cnt == 2 * num_row - 1) begin
      m_wr_start = 1'b0;
      m_wr_addr = {SYS_ROW*8{1'b0}};
      m_wr_row_cnt = {COUNT_WIDTH{1'b0}};
      m_wr_done = 1'b1;
    end
  end
  else begin
    m_wr_en = {SYS_ROW{1'b0}};
  end

  if (!rstn) begin
    m_wr_start = 1'b0;
    m_wr_addr = {SYS_ROW*8{1'b0}};
    m_wr_en = {SYS_ROW{1'b0}};
    m_wr_row_cnt = {COUNT_WIDTH{1'b0}};
    m_wr_done = 1'b0;
  end
end

endmodule
