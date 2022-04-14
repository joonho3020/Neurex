module weight_fifo #(
  parameter int unsigned DATA_WIDTH = 16,
  parameter int unsigned FIFO_WIDTH = 16,
  parameter int unsigned FIFO_DEPTH = 16
) (
  input                   clk,
  input                   rstn,
  input [FIFO_WIDTH-1:0]  en,
  input [DATA_WIDTH-1:0]  w_in[0:FIFO_WIDTH-1],
  output [DATA_WIDTH-1:0] w_out[0:FIFO_WIDTH-1]
);

logic [DATA_WIDTH-1:0] m_w_in[0:FIFO_DEPTH-1][0:FIFO_WIDTH-1];
logic [DATA_WIDTH-1:0] m_w_out[0:FIFO_DEPTH-1][0:FIFO_WIDTH-1];

genvar i, j;
generate
for (i = 0; i < FIFO_DEPTH; i = i + 1) begin : depth
  for (j = 0; j < FIFO_WIDTH; j = j + 1) begin : width
    w_ff #(.DATA_WIDTH(DATA_WIDTH))
    m_w_ff(
      .clk(clk),
      .rstn(rstn),
      .en(en[j]),
      .in(m_w_in[i][j]),
      .out(m_w_out[i][j])
    );
  end
end
endgenerate

generate
for (i = 0; i < FIFO_DEPTH; i = i + 1) begin
  if (i == 0) begin
    assign m_w_in[i] = w_in;
  end else begin
    assign m_w_in[i] = m_w_out[i-1];
  end
end
endgenerate

assign w_out = m_w_out[FIFO_DEPTH-1];

endmodule
