module interpolate_cal_grp #(
  parameter  int unsigned DATA_SIZE = 32, // 4B
  parameter  int unsigned NUM_LEVEL = 16
) (
  input clk,
  input rstn,
  input [NUM_LEVEL-1:0] en,
  input [DATA_SIZE-1:0] feat[0:7], // FIXME: large port... (32B * 4)
  input [DATA_SIZE-1:0] x[0:8],
  input [DATA_SIZE-1:0] y[0:8],
  input [DATA_SIZE-1:0] z[0:8],
  output [DATA_SIZE-1:0] interpolated_feat[0:NUM_LEVEL-1], // FIXME: 64B
  output [NUM_LEVEL-1:0] done
);

genvar i;
generate
  for (i = 0; i < NUM_LEVEL; i = i + 1) begin
    interpolate_cal #( .DATA_SIZE(DATA_SIZE) )
    m_interpolate_cal (
      .clk                (clk),
      .rstn               (rstn),
      .en                 (en[i]),
      .feat               (feat),
      .x                  (x),
      .y                  (y),
      .z                  (z),
      .interpolated_feat  (interpolated_feat[i]),
      .done               (done[i])
    );
  end
endgenerate

endmodule
