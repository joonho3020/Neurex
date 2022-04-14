module in_mem_wr_ctrl #(
  parameter  int unsigned SYS_ROW = 16,
  parameter  int unsigned SYS_COL = 16,
  parameter  int unsigned DATA_WIDTH = 16,
  parameter  int unsigned ADDR_WIDTH = 16,
  parameter  int unsigned ACCUM_SIZE = 1024,
  localparam int unsigned ACCUM_ROW = ACCUM_SIZE / SYS_COL
) (
  input clk,
  input rstn,
  input in_en,
  input [DATA_WIDTH-1:0] in_data[0:SYS_ROW-1],
  //input [DATA_WIDTH-1:0] num_in, // FIXME: do not check how many the input
  //data came in
  input [DATA_WIDTH-1:0] num_common,
  output logic [SYS_ROW-1:0] in_wr_en,
  output logic [ADDR_WIDTH-1:0] in_wr_addr[0:SYS_ROW-1],
  output logic [DATA_WIDTH-1:0] in_wr_data[0:SYS_ROW-1],
  output logic [31:0] in_row_offset
);

logic [31:0] m_in_row_offset, m_in_col_offset;
logic [31:0] in_col_offset;

logic [SYS_ROW-1:0] m_in_wr_en;
logic [ADDR_WIDTH-1:0] m_in_wr_addr[0:SYS_ROW-1];
logic [DATA_WIDTH-1:0] m_in_wr_data[0:SYS_ROW-1];

always_ff @(posedge clk) begin
  in_row_offset <= m_in_row_offset;
  in_col_offset <= m_in_col_offset;

  in_wr_en <= m_in_wr_en;
  in_wr_data <= m_in_wr_data;
  in_wr_addr <= m_in_wr_addr;
end

// Store input data
int i;
always_comb begin
  m_in_row_offset = in_row_offset;
  m_in_col_offset = in_col_offset;
  
  //m_in_done_cnt = in_done_cnt;

  m_in_wr_en = {SYS_ROW{1'b0}};
  m_in_wr_data = in_wr_data;
  m_in_wr_addr = in_wr_addr;

  if (in_en) begin
    m_in_wr_addr = in_wr_addr;

    for (i = 0; i < SYS_ROW; i = i + 1) begin
      m_in_wr_data[i] = in_data[i];
    end

    m_in_wr_en = {SYS_ROW{1'b1}};
    m_in_col_offset = in_col_offset + 1;
    if (in_col_offset == ((num_common >> $clog2(SYS_ROW)) - 1)) begin
      m_in_row_offset = in_row_offset + 1;
      m_in_col_offset = 0;
    end

    for (i = 0; i < SYS_ROW; i = i + 1) begin
      m_in_wr_addr[i] = ADDR_WIDTH'((in_col_offset << $clog2(ACCUM_ROW)) + in_row_offset);
    end

    if (in_row_offset == ACCUM_ROW) begin
      m_in_col_offset = 0;
      m_in_row_offset = 0;
      //m_in_done_cnt = in_done_cnt + (num_common >> $clog2(SYS_ROW));
    end
  end else begin
    //m_in_done_cnt = 0;
    m_in_row_offset = 0;
    m_in_col_offset = 0;
    m_in_wr_en = {SYS_COL{1'b0}};
  end

  if (!rstn) begin
    //m_in_done_cnt = 0;
    m_in_row_offset = 0;
    m_in_col_offset = 0;
    m_in_wr_en = {SYS_COL{1'b0}};
    for (i = 0; i < 4; i = i + 1) begin
      m_in_wr_data[i] = 0;
    end
  end
end

endmodule
