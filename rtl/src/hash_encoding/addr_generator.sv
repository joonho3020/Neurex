module addr_generator #(
  parameter int unsigned LEVEL_OFFSET = 4096 * 4,
  parameter int unsigned DATA_WIDTH = 32
) (
  input clk,
  input en,
  input [DATA_WIDTH-1:0] enc_idx,
  output logic [63:0] addr
);

logic [63:0] m_addr;

always_ff @(posedge clk) begin
  addr <= m_addr;
end

always_comb begin
  m_addr = addr;
  if (en) begin
    m_addr = 64'(LEVEL_OFFSET + (enc_idx << 2)); // addr = level_offset + idx * 4
  end
end

endmodule
