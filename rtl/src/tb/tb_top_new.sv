module tb_top();
parameter int unsigned SYS_ROW = 4;
parameter int unsigned SYS_COL = 4;
parameter int unsigned FIFO_WIDTH = SYS_COL;
parameter int unsigned FIFO_DEPTH = 2 * SYS_COL;
parameter int unsigned DATA_WIDTH = 16;
parameter int unsigned ADDR_WIDTH = 16;
parameter int unsigned ACCUM_SIZE = 32;
localparam int unsigned PSUM_WIDTH = 2 * DATA_WIDTH;

parameter int unsigned NUM_IN     = 8;
parameter int unsigned NUM_COMMON = 8;
parameter int unsigned NUM_OUT    = 16;

logic clk;
logic rstn;
logic [DATA_WIDTH-1:0] num_in;
logic [DATA_WIDTH-1:0] num_common;
logic [DATA_WIDTH-1:0] num_out;
logic in_en;
logic w_en;
logic [DATA_WIDTH-1:0] in_data[0:SYS_ROW-1];
logic [DATA_WIDTH-1:0] w_data[0:SYS_COL-1];
logic [PSUM_WIDTH-1:0] out_wr_data[0:SYS_COL-1];

// Module instantiation
top_neurex #(
  .SYS_ROW(SYS_ROW), .SYS_COL(SYS_COL), .FIFO_DEPTH(FIFO_DEPTH), .DATA_WIDTH(DATA_WIDTH), .ADDR_WIDTH(ADDR_WIDTH), .ACCUM_SIZE(ACCUM_SIZE)
) TOP_NEUREX(
  .clk(clk),
  .rstn(rstn),
  .num_in(num_in),
  .num_common(num_common),
  .num_out(num_out),
  .in_en(in_en),
  .w_en(w_en),
  .in_data(in_data),
  .w_data(w_data),
  .out_wr_data(out_wr_data)
);

always begin
  #5;
  clk = ~clk;
end

int i, j;
task full_test();
  clk = 1'b1;
  rstn = 1'b0;
  num_in = NUM_IN;
  num_common = NUM_COMMON;
  num_out = NUM_OUT;
  in_en = 1'b0;
  w_en = 1'b0;

  #10;
  rstn <= 1'b1;
  #10;
  in_en <= 1'b1;
  w_en <= 1'b1;

  for (i = 0; i < NUM_COMMON * NUM_OUT / 4; i = i + 1) begin
    //#10;
    for (j = 0; j < 4; j = j + 1) begin
      in_data[j] <= (i % 2 == 0) ? 16'(j+1) : 16'(j+5);
      w_data[j] <= 16'(i+j);
    end
    if (i >= NUM_IN * NUM_COMMON / 4) in_en <= 1'b0;
    #10;
  end

  w_en <= 1'b0;

  $stop;
endtask

initial begin
  full_test();
end

endmodule
