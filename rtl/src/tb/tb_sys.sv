`timescale 1 ps / 1 ps

module tb_sys();
parameter width_height = 4;
parameter data_size = 16;
localparam psum_size = 2 * data_size;
localparam weight_width = data_size * width_height;
localparam sum_width = 2 * data_size * width_height;
localparam data_width = data_size * width_height;

// inputs to DUT
logic clk;
logic rstn;
logic en;
logic [data_size-1:0]     datain[0:width_height-1];
logic [data_size-1:0]     win[0:width_height-1];
logic [width_height-1:0]  wwrite;

// outputs from DUT
logic [psum_size-1:0]    maccout[0:width_height-1];
logic [width_height-1:0] activeout;
logic [data_size-1:0]    dataout[0:width_height-1];

// instantiation of DUT
sys_array #(
  .SYS_ROW(width_height), .SYS_COL(width_height), .DATA_WIDTH(data_size)
)
m_sys_arr (
  .clk      (clk),
  .rstn     (rstn),
  .en       (en),
  .w_wen    (wwrite),
  .in       (datain),
  .w_in     (win),
  .psum_out (maccout),
  .en_out   (activeout)
);

always begin
  #5;
  clk = ~clk;
end // always

int i;
task sys_arr_test();
  clk = 1'b0;
  rstn = 1'b0;
  en = 1'b0;
  for (i = 0; i < width_height; i = i + 1) begin
    datain[i] = {data_size{1'b0}};
    win[i] = {data_size{1'b0}};
  end
  wwrite = 4'b0000;

  #10;
  rstn = 1'b1;

  win[0] = 16'h0001;
  win[1] = 16'h0002;
  win[2] = 16'h0003;
  win[3] = 16'h0004;
  wwrite = 4'b1111;

  #10;

  win[0] = 16'h0001;
  win[1] = 16'h0002;
  win[2] = 16'h0003;
  win[3] = 16'h0004;

  #10;

  win[0] = 16'h0001;
  win[1] = 16'h0002;
  win[2] = 16'h0003;
  win[3] = 16'h0004;

  #10;

  win[0] = 16'h0001;
  win[1] = 16'h0002;
  win[2] = 16'h0003;
  win[3] = 16'h0004;
  wwrite = 4'b0000;

  #10

  datain[0] = 16'h0000;
  datain[1] = 16'h0000;
  datain[2] = 16'h0000;
  datain[3] = 16'h0000;
  en = 1'b1;

  #10;

  datain[0] = 16'h0001;
  datain[1] = 16'h0004;
  datain[2] = 16'h0000;
  datain[3] = 16'h0000;

  #10;

  datain[0] = 16'h0002;
  datain[1] = 16'h0005;
  datain[2] = 16'h0008;
  datain[3] = 16'h0000;

  #10;

  datain[0] = 16'h0003;
  datain[1] = 16'h0006;
  datain[2] = 16'h0009;
  datain[3] = 16'h000C;

  #10;

  datain[0] = 16'h0000;
  datain[1] = 16'h0007;
  datain[2] = 16'h000A;
  datain[3] = 16'h000D;

  #10;

  datain[0] = 16'h0000;
  datain[1] = 16'h0000;
  datain[2] = 16'h000B;
  datain[3] = 16'h000E;

  #10;

  datain[0] = 16'h0000;
  datain[1] = 16'h0000;
  datain[2] = 16'h0000;
  datain[3] = 16'h000F;
  en = 1'b0;

  #10;

  datain[0] = 16'h0000;
  datain[1] = 16'h0000;
  datain[2] = 16'h0000;
  datain[3] = 16'h0000;

  #300;

endtask

initial begin
  sys_arr_test();
  $stop;
end // initial
endmodule // tb_sys
