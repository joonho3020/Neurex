`timescale 1 ns / 1 ps

module tb_weight_mem_fifo();
parameter int unsigned FIFO_WIDTH = 16;
parameter int unsigned FIFO_DEPTH = 16;
parameter int unsigned DATA_WIDTH = 16;

logic clk;
logic rstn;
logic fifo_in_en, fifo_out_en;
logic [FIFO_WIDTH-1:0] fifo_in_en_out, fifo_out_en_out;

logic done;
logic [FIFO_WIDTH-1:0] w_wen;

logic [DATA_WIDTH-1:0] rd_data[0:FIFO_WIDTH-1];
logic [DATA_WIDTH-1:0] wr_data[0:FIFO_WIDTH-1];
logic [DATA_WIDTH-1:0] w_out[0:FIFO_WIDTH-1];

logic [7:0] rd_addr [0:FIFO_WIDTH-1]; // FIXME: addr_width = 8
logic [7:0] wr_addr[0:FIFO_WIDTH-1];
logic [FIFO_WIDTH-1:0] wr_en;

// Module instantiation
fifo_in_ctrl #(
  .FIFO_WIDTH(FIFO_WIDTH), .FIFO_DEPTH(FIFO_DEPTH)
) IN_CTRL(
  .clk(clk),
  .rstn(rstn),
  .en(fifo_in_en),
  .fifo_en(fifo_in_en_out),
  .w_mem_rd_addr(rd_addr),
  .w_mem_rd_en()
);

fifo_out_ctrl #(
  .FIFO_WIDTH(FIFO_WIDTH), .FIFO_DEPTH(FIFO_DEPTH)
) OUT_CTRL(
  .clk(clk),
  .rstn(rstn),
  .en(fifo_out_en),
  .done(done),
  .fifo_en(fifo_out_en_out),
  .w_wen(w_wen)
);

weight_fifo #(
  .FIFO_WIDTH(FIFO_WIDTH), .FIFO_DEPTH(FIFO_DEPTH), .DATA_WIDTH(DATA_WIDTH)
) W_FIFO(
  .clk(clk),
  .rstn(rstn),
  .en(fifo_in_en_out | fifo_out_en_out),
  .w_in(rd_data),
  .w_out(w_out)
);

mem_arr #(
  .SYS_ROW(FIFO_WIDTH), .DATA_WIDTH(DATA_WIDTH)
) MEM(
  .clk(clk),
  .rstn(rstn),
  .rd_en({FIFO_WIDTH{1'b1}}),
  .wr_en(wr_en),
  .wr_data(wr_data),
  .rd_addr(rd_addr),
  .wr_addr(wr_addr),
  .rd_data(rd_data)
);

always begin
  #5;
  clk = ~clk;
end

int i, j;
task fifo_test();
  clk = 1'b1;
  rstn = 1'b0;
  fifo_in_en = 1'b0;
  fifo_out_en = 1'b0;
  #10;
  rstn = 1'b1;

  // write data to memory
  wr_en = {FIFO_WIDTH{1'b1}};
  for (i = 0; i < FIFO_DEPTH; i = i + 1) begin
    //#10;
    for (j = 0; j < FIFO_WIDTH; j = j + 1) begin
      wr_addr[j] = i;
      wr_data[j] = 4 * j + i;
    end
    #10;
  end
  #10;
  wr_en = {FIFO_WIDTH{1'b0}};
  
  #10;
  // read data from memory to weight_fifo
  fifo_in_en = 1'b1;
  #10;
  fifo_in_en = 1'b0;
  
  #300;
  // pop data from weight_fifo to sys_arr
  fifo_out_en = 1'b1;
  #10;
  fifo_out_en = 1'b0;

  wait(done);
  $stop;
endtask

initial begin
  fifo_test();
end

endmodule
