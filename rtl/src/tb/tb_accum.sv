`timescale 1 ns / 1 ps

module tb_accum();
parameter  int unsigned SYS_COL = 4;
parameter  int unsigned ACCUM_SIZE = 16;
parameter  int unsigned DATA_WIDTH = 32;
parameter  int unsigned NUM_ROW = 4;
localparam int unsigned ACCUM_ROW = ACCUM_SIZE / SYS_COL;
localparam int unsigned ADDR_WIDTH = $clog2(ACCUM_ROW);

// accum inputs
logic clk, rstn, accum_rstn;
logic wr_en_ctrl;
logic [SYS_COL-1:0] rd_en, wr_en;
logic [ADDR_WIDTH-1:0] wr_addr_ctrl;
logic [ADDR_WIDTH-1:0] rd_addr[0:SYS_COL-1];
logic [ADDR_WIDTH-1:0] wr_addr[0:SYS_COL-1];
logic [DATA_WIDTH-1:0] rd_data[0:SYS_COL-1];
logic [DATA_WIDTH-1:0] wr_data[0:SYS_COL-1];

// Module instantiation
accum #(
  .SYS_COL(SYS_COL), .DATA_WIDTH(DATA_WIDTH), .ACCUM_SIZE(ACCUM_SIZE)
) m_accum(
  .clk(clk),
  .rstn(rstn),
  .rd_en(rd_en),
  .wr_en(wr_en),
  .rd_addr(rd_addr),
  .wr_addr(wr_addr),
  .wr_data(wr_data),
  .rd_data(rd_data)
);

accum_wr_ctrl #(
  .SYS_COL(SYS_COL), .ACCUM_ROW(ACCUM_ROW)
) m_accum_wr_ctrl(
  .clk(clk),
  .rstn(rstn | accum_rstn),
  .wr_en_in(wr_en_ctrl),
  .wr_addr_in(wr_addr_ctrl),
  .wr_en_out(wr_en),
  .wr_addr_out(wr_addr)
);

always begin
  #5;
  clk = ~clk;
end

int i, j;
task accum_test();
  clk = 1'b1;
  rstn = 1'b0;
  wr_en_ctrl = 1'b0;

  #10;
  rstn = 1'b1;
  
  // Write initial psum in accum
  for (i = 0; i < 2 * NUM_ROW - 1; i = i + 1) begin
    #10;
    for (j = 0; j < SYS_COL; j = j + 1) begin
      wr_data[j] = (j <= i) ? (j+1) + 4*(i-j) : 0;
    end
    if (i < NUM_ROW) begin
      wr_addr_ctrl = i;
      wr_en_ctrl = 1'b1;
    end else begin
      wr_addr_ctrl = 0;
      wr_en_ctrl = 1'b0;
    end
  end

  #70; // Wait until skewed output is stored
  
  // Reset ctrl
  accum_rstn = 1'b0;
  #10;
  accum_rstn = 1'b1;

  // Accumulation
  for (i = 0; i < 2 * NUM_ROW - 1; i = i + 1) begin
    #10;
    for (j = 0; j < SYS_COL; j = j + 1) begin
      wr_data[j] = (j <= i) ? (j+1) + 4*(i-j) : 0;
    end
    if (i < NUM_ROW) begin
      wr_addr_ctrl = i;
      wr_en_ctrl = 1'b1;
    end else begin
      wr_addr_ctrl = 0;
      wr_en_ctrl = 1'b0;
    end
  end
  
  #70;
  // Read accumulated data
  rd_en = {SYS_COL{1'b1}};
  for (i = 0; i < NUM_ROW; i = i + 1) begin
    #10;
    for (j = 0; j < SYS_COL; j = j + 1) begin
      rd_addr[j] = i;
    end
  end

endtask

initial begin
  accum_test();
end

endmodule
