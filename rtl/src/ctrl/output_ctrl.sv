module output_ctrl #(
  parameter  int unsigned SYS_COL =16,
  parameter  int unsigned DATA_WIDTH = 16,
  parameter  int unsigned ACCUM_SIZE = 1024,
  localparam int unsigned ACCUM_ROW = ACCUM_SIZE / SYS_COL,
  localparam int unsigned ADDR_WIDTH = $clog2(ACCUM_ROW)
) (
  input clk,
  input rstn,
  input en,
  input [7:0] base_addr,
  input [DATA_WIDTH-1:0] num_row,
  output logic [ADDR_WIDTH-1:0] accum_rd_addr[0:SYS_COL-1],
  output logic [7:0] output_wr_addr[0:SYS_COL-1],
  output logic [SYS_COL-1:0] accum_rd_en,
  output logic [SYS_COL-1:0] output_wr_en,
  output logic done
);

logic m_start, start, m_start2, start2;

logic [7:0] base_addr_inter, m_base_addr;
logic [7:0] m_output_wr_addr[0:SYS_COL-1];
logic [ADDR_WIDTH-1:0] m_accum_rd_addr[0:SYS_COL-1];
logic [DATA_WIDTH-1:0] m_num_row, num_row_inter;
logic [SYS_COL-1:0] m_accum_rd_en, m_output_wr_en;
logic m_done;

always_ff @(posedge clk) begin
  start <= m_start;
  start2 <= m_start2;
  accum_rd_en <= m_accum_rd_en;
  output_wr_en <= m_output_wr_en;
  accum_rd_addr <= m_accum_rd_addr;
  output_wr_addr <= m_output_wr_addr;
  base_addr_inter <= m_base_addr;
  num_row_inter <= m_num_row;
  done <= m_done;
end

int i;
always_comb begin
  m_start = start;
  m_start2 = start2;
  m_accum_rd_en = accum_rd_en;
  m_output_wr_en = output_wr_en;
  m_accum_rd_addr = accum_rd_addr;
  m_output_wr_addr = output_wr_addr;
  m_base_addr = base_addr_inter;
  m_num_row = num_row_inter;
  m_done = done;

  if (en) begin
    m_start = 1'b1;
    m_accum_rd_en = {SYS_COL{1'b1}};
    for (i = 0; i < SYS_COL; i = i + 1) begin
      m_accum_rd_addr[i] = {ADDR_WIDTH{1'b0}};
    end
    m_base_addr = base_addr;
    m_done = 1'b0;
    m_num_row = num_row;
  end

  if (start) begin
    m_start2 = 1'b1;
    m_output_wr_en = {SYS_COL{1'b1}};
    for (i = 0; i < SYS_COL; i = i + 1) begin
      m_accum_rd_addr[i] = accum_rd_addr[i] + 1;
      m_output_wr_addr[i] = base_addr_inter;
    end
  end

  if (start2) begin
    for (i = 0; i < SYS_COL; i = i + 1) begin
      m_accum_rd_addr[i] = accum_rd_addr[i] + 1;
      m_output_wr_addr[i] = output_wr_addr[i] + 1;
    end

    if (accum_rd_addr[0] == num_row_inter - 1) begin
      m_accum_rd_en = {SYS_COL{1'b0}};
      for (i = 0; i < SYS_COL; i = i + 1) begin
        m_accum_rd_addr[i] = {ADDR_WIDTH{1'b0}};
      end
    end

    if (output_wr_addr[0] == base_addr_inter + num_row_inter - 1) begin
      m_output_wr_en = {SYS_COL{1'b0}};
      for (i = 0; i < SYS_COL; i = i + 1) begin
        m_output_wr_addr[i] = 8'd0;
      end
      m_base_addr = 8'd0;
      m_start = 1'b0;
      m_start2 = 1'b0;
      m_done = 1'b1;
      m_num_row = 0;
    end
  end
  
  if (!rstn) begin
    m_start = 0;
    m_start2 = 0;
    m_accum_rd_en = {SYS_COL{1'b0}};
    m_output_wr_en = {SYS_COL{1'b0}};
    for (i = 0; i < SYS_COL; i = i + 1) begin
      m_accum_rd_addr[i] = {ADDR_WIDTH{1'b0}};
      m_output_wr_addr[i] = 8'd0;
    end
    m_base_addr = 8'd0;
    m_num_row = {DATA_WIDTH{1'b0}};
    m_done = 1'b0;
  end
end

endmodule
