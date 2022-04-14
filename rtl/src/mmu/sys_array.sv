module sys_array #(
  parameter  int unsigned SYS_ROW = 16,
  parameter  int unsigned SYS_COL = 16,
  parameter  int unsigned DATA_WIDTH = 16,
  localparam int unsigned PSUM_WIDTH = DATA_WIDTH * 2
) (
  input                   clk,
  input                   rstn,
  input                   en,
  input [SYS_ROW-1:0]     w_invalid,
  input [SYS_COL-1:0]     w_wen,
  input [DATA_WIDTH-1:0]  in[0:SYS_ROW-1],
  input [DATA_WIDTH-1:0]  w_in[0:SYS_COL-1],
  output [PSUM_WIDTH-1:0] psum_out[0:SYS_COL-1],
  output [SYS_COL-1:0]    en_out
);

logic [DATA_WIDTH-1:0]    m_w_out[0:SYS_ROW-2][0:SYS_COL-1];
logic [PSUM_WIDTH-1:0]    m_psum_out[0:SYS_ROW-2][0:SYS_COL-1];

logic [SYS_COL-1:0]       m_en[0:SYS_ROW-2];
logic [SYS_COL-1:0]       m_w_wen[0:SYS_ROW-2];

logic [PSUM_WIDTH-1:0]    zero_psum[0:SYS_COL-1];

genvar i;
generate
  for (i = 0; i < SYS_ROW; i = i + 1) begin : sys_row_arr
    if (i == 0) begin
      sys_row #(
        .SYS_COL(SYS_COL),
        .DATA_WIDTH(DATA_WIDTH)
      ) m_first_sys_row
      (
        .clk        (clk),
        .rstn       (rstn),
        .en_in      ({SYS_COL{en}}),
        .w_invalid  (w_invalid[i]),
        .global_w_wen_in(w_wen),
        .w_wen_in   (w_wen),
        .in         (in[i]),
        .w_in       (w_in),
        .psum_in    (zero_psum),
        .w_wen_out  (m_w_wen[i]),
        .en_out     (m_en[i]),
        .w_out      (m_w_out[i]),
        .psum_out   (m_psum_out[i])
      );
    end else if (i == SYS_ROW - 1) begin
      sys_row #(
        .SYS_COL(SYS_COL),
        .DATA_WIDTH(DATA_WIDTH)
      ) m_last_sys_row 
      (
        .clk        (clk),
        .rstn       (rstn),
        .en_in      (m_en[i-1]),
        .w_invalid  (w_invalid[i]),
        .global_w_wen_in(w_wen),
        .w_wen_in   (m_w_wen[i-1]),
        .in         (in[i]),
        .w_in       (m_w_out[i-1]),
        .psum_in    (m_psum_out[i-1]),
        .w_wen_out  (),
        .en_out     (en_out),
        .w_out      (),
        .psum_out   (psum_out)
      );
    end else begin
      sys_row #(
        .SYS_COL(SYS_COL),
        .DATA_WIDTH(DATA_WIDTH)
      ) m_middle_sys_row 
      (
        .clk        (clk),
        .rstn       (rstn),
        .en_in      (m_en[i-1]),
        .w_invalid  (w_invalid[i]),
        .global_w_wen_in   (w_wen),
        .w_wen_in   (m_w_wen[i-1]),
        .in         (in[i]),
        .w_in       (m_w_out[i-1]),
        .psum_in    (m_psum_out[i-1]),
        .w_wen_out  (m_w_wen[i]),
        .en_out     (m_en[i]),
        .w_out      (m_w_out[i]),
        .psum_out   (m_psum_out[i])
      );
    end
  end
endgenerate

int j;
always_comb begin
  for (j = 0; j < SYS_COL; j = j + 1) begin
    zero_psum[j] = {PSUM_WIDTH{1'b0}};
  end
end

endmodule
