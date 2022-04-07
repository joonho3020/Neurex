`timescale 1 ps / 1 ps

module tb_input_mem();
parameter int unsigned SYS_ROW = 16;
parameter int unsigned SYS_COL = 16;
parameter int unsigned DATA_WIDTH = 16;
parameter int unsigned ACCUM_SIZE = 4096;
parameter int unsigned NUM_ROW = 8;

logic clk, rstn, rd_active, wr_active;
logic [SYS_ROW-1:0] wr_en, rd_en;
logic [7:0] wr_addr[0:SYS_ROW-1];
logic [7:0] rd_addr[0:SYS_ROW-1];
logic [DATA_WIDTH-1:0] wr_data[0:SYS_ROW-1];
logic [DATA_WIDTH-1:0] rd_data[0:SYS_ROW-1];
logic [31:0] num_row;
logic wr_done;

int i, j;

always begin
  #5
  clk = ~clk;
end

task input_mem_test();
  clk = 0;
  rstn = 0;
  for (i = 0; i < SYS_ROW; i = i + 1) begin
    wr_data[i] = 0;
  end

  #10;
  rstn = 1;
  num_row = NUM_ROW;

  wr_active = 1;
  #5;
  for (i = 0; i < NUM_ROW; i = i + 1) begin
    #10;
    for (j = 0; j < SYS_ROW; j = j + 1) begin
      wr_data[j] = i;
    end
  end
  wr_active = 0;
  wait(wr_done);
  #50;

  for (j = 0; j < 2 * NUM_ROW; j = j + 1) begin
    rd_active = 1;
    $display(rd_data);
    #10;
  end
endtask

initial begin
  input_mem_test();
  $stop;
end

mem_arr #(
  .SYS_ROW(SYS_ROW), .DATA_WIDTH(DATA_WIDTH)
) MEM(
  .clk(clk),
  .rstn(rstn),
  .rd_en(rd_en),
  .wr_en(wr_en),
  .wr_data(wr_data),
  .rd_addr(rd_addr),
  .wr_addr(wr_addr),
  .rd_data(rd_data)
);

input_mem_ctrl #(
  .SYS_ROW(SYS_ROW), .SYS_COL(SYS_COL), .DATA_WIDTH(DATA_WIDTH), .ACCUM_SIZE(ACCUM_SIZE)
) CTRL(
  .clk(clk),
  .rstn(rstn),
  .rd_en_in(rd_active),
  .wr_en_in(wr_active),
  .num_row(num_row),
  .rd_en(rd_en),
  .rd_addr(rd_addr),
  .wr_en(wr_en),
  .wr_addr(wr_addr),
  .wr_done(wr_done)
);

endmodule
