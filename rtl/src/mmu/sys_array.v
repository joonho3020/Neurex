
module sys_array #(
  parameter SYS_ROW = 16, SYS_COL = 16, DATA_WIDTH = 16
)
(
  clk,
  rstn,
  en,
  w_wen,
  in,
  w_in,
  psum_out,
);

localparam TOT_DATA_WIDTH = SYS_COL * DATA_WIDTH;
localparam TOT_PSUM_WIDTH= 2 * SYS_COL * DATA_WIDTH;

input clk;
input rstn;
input en;
input [SYS_COL-1:0] w_wen;
input [TOT_DATA_WIDTH-1:0] in;
input [TOT_DATA_WIDTH-1:0] w_in;
output [TOT_PSUM_WIDTH-1:0] psum_out;

wire [(SYS_ROW-1)*TOT_DATA_WIDTH-1:0] m_w_out;
wire [(SYS_ROW-1)*TOT_PSUM_WIDTH-1:0] m_psum_out;

wire [(SYS_ROW-1)*SYS_COL-1:0] m_en;
wire [(SYS_ROW-1)*SYS_COL-1:0] m_w_wen;

genvar i;
generate
  for (i = 0; i < SYS_ROW; i = i + 1) begin
    if (i == 0) begin
      sys_row m_first_sys_row #(
        .SYS_COL(SYS_COL),
        .DATA_WIDTH(DATA_WIDTH)
      )
      (
        .clk(clk),
        .rstn(rstn),
        .en_in(en),
        .w_wen_in(w_wen),
        .in(in[(i+1)*DATA_WIDTH-1:i*DATA_WIDTH]),
        .w_in(w_in),
        .psum_in({TOT_PSUM_WIDTH{1'b0}}),
        .w_wen_out(m_w_wen[(i+1)*SYS_COL-1:i*SYS_COL]),
        .en_out(m_en[(i+1)*SYS_COL-1:i*SYS_COL]),
        .w_out(m_wout[(i+1)*TOT_DATA_WIDTH-1:i*TOT_DATA_WIDTH]),
        .psum_out(m_psum_out[(i+1)*TOT_PSUM_WIDTH-1:i*TOT_PSUM_WIDTH])
      );
    end
    else if (i == SYS_ROW - 1) begin
      sys_row m_last_sys_row #(
        .SYS_COL(SYS_COL),
        .DATA_WIDTH(DATA_WIDTH)
      )
      (
        .clk(clk),
        .rstn(rstn),
        .en_in(m_en[i*SYS_COL]),
        .w_wen_in(m_w_wen[i*SYS_COL]),
        .in(in[(i+1)*DATA_WIDTH-1:i*DATA_WIDTH]),
        .w_in(m_w_out[(i+1)*TOT_DATA_WIDTH-1:i*TOT_DATA_WIDTH]),
        .psum_in(m_psum_out[(i+1)*TOT_PSUM_WIDTH-1:i*TOT_PSUM_WIDTH]),
        .w_wen_out(),
        .en_out(),
        .w_out(),
        .psum_out(psum_out)
      );
    end
    else begin
      sys_row m_middle_sys_row #(
        .SYS_COL(SYS_COL),
        .DATA_WIDTH(DATA_WIDTH)
      )
      (
        .clk(clk),
        .rstn(rstn),
        .en_in(m_en[i*SYS_COL]),
        .w_wen_in(m_w_wen[i*SYS_COL]),
        .in(in[(i+1)*DATA_WIDTH-1:i*DATA_WIDTH]),
        .w_in(m_w_out[(i+1)*TOT_DATA_WIDTH-1:i*TOT_DATA_WIDTH]),
        .psum_in(m_psum_out[(i+1)*TOT_PSUM_WIDTH-1:i*TOT_PSUM_WIDTH]),
        .w_wen_out(m_w_wen[(i+1)*SYS_COL-1:i*SYS_COL]),
        .en_out(m_en[(i+1)*SYS_COL-1:i*SYS_COL]),
        .w_out(m_wout[(i+1)*TOT_DATA_WIDTH-1:i*TOT_DATA_WIDTH]),
        .psum_out(m_psum_out[(i+1)*TOT_PSUM_WIDTH-1:i*TOT_PSUM_WIDTH])
      );
    end
  end
endgenerate
