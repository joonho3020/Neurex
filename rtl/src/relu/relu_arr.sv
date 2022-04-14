// combinational logic
module relu_arr #(
  parameter  int unsigned SYS_COL = 16,
  parameter  int unsigned DATA_WIDTH = 32
) (
  input                   en,
  input [DATA_WIDTH-1:0]  in[0:SYS_COL-1],
  output [DATA_WIDTH-1:0] out[0:SYS_COL-1]
);

genvar i;
generate
  for (i = 0; i < SYS_COL; i = i + 1) begin
    relu #(
      .DATA_WIDTH(DATA_WIDTH)
    ) m_relu(
      .en(en),
      .in(in[i]),
      .out(out[i])
    );
  end
endgenerate

endmodule
