// combinational logic
module relu #(
  parameter int unsigned DATA_WIDTH = 32
) (
  input                         en,
  input [DATA_WIDTH-1:0]        in,
  output logic [DATA_WIDTH-1:0] out
);

always_comb begin
  if (en) begin
    out = $signed(in) > 0 ? $signed(in) : {DATA_WIDTH{1'b0}};
  end else begin
    out = {DATA_WIDTH{1'b0}};
  end
end

endmodule
