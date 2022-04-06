
module sys_row #(
  parameter SYS_COL = 16, DATA_WIDTH = 16
)
(
  input clk,
  input rstn,
  input en_in,
  input [SYS_COL-1:0] w_wen_in,
  input signed [DATA_WIDTH-1:0] in,
  input signed [SYS_COL*DATA_WIDTH-1:0] w_in,
  input signed [2*SYS_COL*DATA_WIDTH-1:0] psum_in,

  output [SYS_COL-1:0] w_wen_out,
  output [SYS_COL-1:0] en_out,
  output signed [SYS_COL*DATA_WIDTH-1:0] w_out,
  output signed [2*SYS_COL*DATA_WIDTH-1:0] psum_out
);

reg [(SYS_COL-1)*DATA_WIDTH-1:0] m_pass_out;
reg [SYS_COL-1:0] m_en_out;

assign en_out = m_en_out;

genvar i;
generate
  for (i = 0; i < SYS_COL; i = i + 1) begin: pe_arr
    if (i == 0) begin
      pe m_first_pe(
        .clk(clk),
        .rstn(rstn),
        .en_in(en_in),
        .w_wen_in(w_wen_in[i]),
        .in(in),
        .w_in(w_in[(i+1)*DATA_WIDTH-1:i*DATA_WIDTH]),
        .psum_in(psum_in[2*(i+1)*DATA_WIDTH-1:2*i*DATA_WIDTH]),
        .w_wen_out(w_wen_out[i]),
        .en_out(m_en_out[i]),
        .pass_out(m_pass_out[(i+1)*DATA_WIDTH-1:i*DATA_WIDTH]),
        .w_out(w_out[(i+1)*DATA_WIDTH-1:i*DATA_WIDTH]),
        .psum_out(psum_out[2*(i+1)*DATA_WIDTH-1:2*i*DATA_WIDTH])
      );
    end
    else if (i == SYS_COL - 1) begin
      pe m_last_pe(
        .clk(clk),
        .rstn(rstn),
        .en_in(m_en_out[i-1]),
        .w_wen_in(w_wen_in[i]),
        .in(m_pass_out[i*DATA_WIDTH-1:(i-1)*DATA_WIDTH]),
        .w_in(w_in[(i+1)*DATA_WIDTH-1:i*DATA_WIDTH]),
        .psum_in(psum_in[2*(i+1)*DATA_WIDTH-1:2*i*DATA_WIDTH]),
        .w_wen_out(w_wen_out[i]),
        .en_out(m_en_out[i]),
        .pass_out(),
        .w_out(w_out[(i+1)*DATA_WIDTH-1:i*DATA_WIDTH]),
        .psum_out(psum_out[2*(i+1)*DATA_WIDTH-1:2*i*DATA_WIDTH])
      );
    end
    else begin
      pe m_middle_pe(
        .clk(clk),
        .rstn(rstn),
        .en_in(m_en_out[i-1]),
        .w_wen_in(w_wen_in[i]),
        .in(m_pass_out[i*DATA_WIDTH-1:(i-1)*DATA_WIDTH]),
        .w_in(w_in[(i+1)*DATA_WIDTH-1:i*DATA_WIDTH]),
        .psum_in(psum_in[2*(i+1)*DATA_WIDTH-1:2*i*DATA_WIDTH]),
        .w_wen_out(w_wen_out[i]),
        .en_out(m_en_out[i]),
        .pass_out(m_pass_out[(i+1)*DATA_WIDTH-1:i*DATA_WIDTH]),
        .w_out(w_out[(i+1)*DATA_WIDTH-1:i*DATA_WIDTH]),
        .psum_out(psum_out[2*(i+1)*DATA_WIDTH-1:2*i*DATA_WIDTH])
      );
    end
  end
endgenerate

endmodule
