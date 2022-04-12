module sys_row #(
  parameter  int unsigned SYS_COL = 16,
  parameter  int unsigned DATA_WIDTH = 16,
  localparam int unsigned PSUM_WIDTH = DATA_WIDTH * 2
) (
  input                             clk,
  input                             rstn,
  input [SYS_COL-1:0]               en_in,
  input [SYS_COL-1:0]               global_w_wen_in,
  input [SYS_COL-1:0]               w_wen_in,
  input [DATA_WIDTH-1:0]            in,
  input [DATA_WIDTH-1:0]            w_in[0:SYS_COL-1],
  input [PSUM_WIDTH-1:0]            psum_in[0:SYS_COL-1],

  output [SYS_COL-1:0]              w_wen_out,
  output [SYS_COL-1:0]              en_out,
  output [DATA_WIDTH-1:0]           w_out[0:SYS_COL-1],
  output [PSUM_WIDTH-1:0]           psum_out[0:SYS_COL-1]
);

logic [DATA_WIDTH-1:0]            m_pass_out[0:SYS_COL-2];
logic [SYS_COL-1:0]               m_en_out;

assign en_out = m_en_out;

genvar i;
generate
  for (i = 0; i < SYS_COL; i = i + 1) begin : pe_arr
    if (i == 0) begin
      pe #(.DATA_WIDTH(DATA_WIDTH))
      m_first_pe(
        .clk        (clk),
        .rstn       (rstn),
        .en_in      (en_in[0]),
        .global_w_wen_in(global_w_wen_in[i]),
        .w_wen_in   (w_wen_in[i]),
        .in         (in),
        .w_in       (w_in[i]),
        .psum_in    (psum_in[i]),
        .w_wen_out  (w_wen_out[i]),
        .en_out     (m_en_out[i]),
        .pass_out   (m_pass_out[i]),
        .w_out      (w_out[i]),
        .psum_out   (psum_out[i])
      );
    end else if (i == SYS_COL - 1) begin
      pe #(.DATA_WIDTH(DATA_WIDTH))
      m_last_pe(
        .clk        (clk),
        .rstn       (rstn),
        .en_in      (m_en_out[i-1]),
        .global_w_wen_in(global_w_wen_in[i]),
        .w_wen_in   (w_wen_in[i]),
        .in         (m_pass_out[i-1]),
        .w_in       (w_in[i]),
        .psum_in    (psum_in[i]),
        .w_wen_out  (w_wen_out[i]),
        .en_out     (m_en_out[i]),
        .pass_out   (),
        .w_out      (w_out[i]),
        .psum_out   (psum_out[i])
      );
    end else begin
      pe #(.DATA_WIDTH(DATA_WIDTH))
      m_middle_pe(
        .clk        (clk),
        .rstn       (rstn),
        .en_in      (m_en_out[i-1]),
        .global_w_wen_in(global_w_wen_in[i]),
        .w_wen_in   (w_wen_in[i]),
        .in         (m_pass_out[i-1]),
        .w_in       (w_in[i]),
        .psum_in    (psum_in[i]),
        .w_wen_out  (w_wen_out[i]),
        .en_out     (m_en_out[i]),
        .pass_out   (m_pass_out[i]),
        .w_out      (w_out[i]),
        .psum_out   (psum_out[i])
      );
    end
  end
endgenerate

endmodule
