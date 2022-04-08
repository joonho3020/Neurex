`timescale 1 ns / 1 ps

module tb_mem_fifo_sys_arr();
parameter SYS_ROW = 4;
parameter SYS_COL = 4;
parameter DATA_WIDTH = 16;
parameter ADDR_WIDTH = 8;
parameter ACCUM_SIZE = 1024;
parameter NUM_ROW = 4; // should test three cases, NUM_ROW {==, >, <} SYS_COL
localparam PSUM_WIDTH = 2 * DATA_WIDTH;
localparam FIFO_WIDTH = SYS_COL;
localparam FIFO_DEPTH = SYS_ROW;

// FIFO side inputs
logic clk;
logic rstn;
logic en;
logic [DATA_WIDTH-1:0] w_in[0:FIFO_WIDTH-1];

// MMU side inputs
logic active;
logic [SYS_COL-1:0] w_wen;

// CTRL side inputs
logic rd_active, wr_active;
logic [DATA_WIDTH-1:0] num_row;

// MEM side inputs
logic [SYS_ROW-1:0] rd_en;
logic [SYS_ROW-1:0] wr_en;
logic [DATA_WIDTH-1:0] wr_data[0:SYS_ROW-1];
logic [ADDR_WIDTH-1:0] rd_addr[0:SYS_ROW-1];
logic [ADDR_WIDTH-1:0] wr_addr[0:SYS_ROW-1];

// MEM side outputs
logic [DATA_WIDTH-1:0] rd_data[0:SYS_ROW-1];

// FIFO side outputs
logic [DATA_WIDTH-1:0] w_out[0:FIFO_WIDTH-1];

// MMU side outputs
logic [PSUM_WIDTH-1:0] psum_out [0:SYS_COL-1];
logic [SYS_COL-1:0] en_out;

// CTRL side outputs
logic wr_done;

// Module instantiations
sys_array #(
  .SYS_ROW(SYS_ROW), .SYS_COL(SYS_COL), .DATA_WIDTH(DATA_WIDTH)
) m_sys_arr (
  .clk      (clk),
  .rstn     (rstn),
  .en       (rd_en[0]),
  .w_wen    (w_wen),
  .in       (rd_data),
  .w_in     (w_in),
  .psum_out (psum_out),
  .en_out   (en_out)
);

weight_fifo #(
  .FIFO_WIDTH(FIFO_WIDTH), .FIFO_DEPTH(FIFO_DEPTH), .DATA_WIDTH(DATA_WIDTH)
) m_weight_fifo (
  .clk      (clk),
  .rstn     (rstn),
  .en       ({FIFO_WIDTH{en}}),
  .w_in     (w_in),
  .w_out    (w_out)
);

mem_arr #(
  .SYS_ROW(SYS_ROW), .DATA_WIDTH(DATA_WIDTH)
) MEM(
  .clk      (clk),
  .rstn     (rstn),
  .rd_en    (rd_en),
  .wr_en    (wr_en),
  .wr_data  (wr_data),
  .rd_addr  (rd_addr),
  .wr_addr  (wr_addr),
  .rd_data  (rd_data)
);

input_mem_ctrl #(
  .SYS_ROW(SYS_ROW), .SYS_COL(SYS_COL), .DATA_WIDTH(DATA_WIDTH), .ACCUM_SIZE(ACCUM_SIZE)
) CTRL(
  .clk      (clk),
  .rstn     (rstn),
  .rd_en_in (rd_active),
  .wr_en_in (wr_active),
  .num_row  (num_row),
  .rd_en_out(rd_en),
  .rd_addr  (rd_addr),
  .wr_en_out(wr_en),
  .wr_addr  (wr_addr),
  .wr_done  (wr_done)
);

always begin
  #5;
  clk = ~clk;
end // always

int i, j;
task tpu_test();
  clk = 1'b1;
  rstn = 1'b0;
  for (i = 0; i < SYS_ROW; i = i + 1) begin
    wr_data[i] = 0;
  end
  w_in[0] = 16'h0000;
  w_in[1] = 16'h0000;
  w_in[2] = 16'h0000;
  w_in[3] = 16'h0000;

  en = 1'b0;
  active = 1'b0;
  w_wen = 4'b0000;

  #10;
  rstn = 1'b1;
  num_row = NUM_ROW;
  
  wr_active = 1;
  #10;
  // write input & weight to MEM & weight_fifo
  for (i = 0; i < NUM_ROW; i = i + 1) begin
    #10;
    en = 1'b1;
    for (j = 0; j < SYS_ROW; j = j + 1) begin
      wr_data[j] = 4 * j + i;
      w_in[j] = j + 1;
    end
  end

  #10;
  en = 0;
  wr_active = 0;
  wait(wr_done);

  // write weight to sys_arr
  en = 1'b1;
  w_wen = 4'b1111;

  #40; // Q: not 40?

  en = 1'b0;
  w_wen = 4'b0000;
  rd_active = 1'b1;

  // read input from mem & start MM
  #10; // Read: 1 or 2 cycle? -> timing check!
  rd_active = 1'b0;

  #20;
  active = 1'b1;
  
  #10;

  wait(en_out[0]);
  $stop;
endtask

initial begin
  tpu_test();
end

endmodule
