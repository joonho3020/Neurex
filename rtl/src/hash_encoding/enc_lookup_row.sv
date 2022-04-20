module enc_lookup_row #(
  parameter int unsigned TABLE_COL = 128,
  parameter int unsigned DATA_WIDTH = 32
) (
  input clk,
  input sent_en,
  input return_en,
  input [TABLE_COL-1:0] sent_in,
  input [DATA_WIDTH-1:0] ret_num, // How many hash encoding features are returned?

  output all_returned
);

logic [15:0] ret_cnt, m_ret_cnt; // MAX = 128
logic [TABLE_COL-1:0] sent, m_sent;

assign all_returned = (ret_cnt == 16'd0);

always_ff @(posedge clk) begin
  ret_cnt <= m_ret_cnt;
  sent <= m_sent;
end

always_comb begin
  m_ret_cnt = ret_cnt;
  if (return_en) begin
    m_ret_cnt = 16'(ret_cnt - ret_num);
  end
end

always_comb begin
  m_sent = sent;
  if (sent_en) begin
    m_sent = sent | sent_in;
  end
end

endmodule
