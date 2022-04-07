module w_ff #(
  parameter DATA_WIDTH = 16
) (
  input clk,
  input rstn,
  input en,
  input [DATA_WIDTH-1:0] in,
  output logic [DATA_WIDTH-1:0] out
);

logic [DATA_WIDTH-1:0] m_out;

always_ff @(posedge clk, negedge rstn) begin
  if (!rstn) begin
    out <= {DATA_WIDTH{1'b0}};
  end begin
    out <= m_out;
  end
end

always_comb begin
  if (en) begin
    m_out = in;
  end
  else begin
    m_out = out;
  end
end

endmodule
