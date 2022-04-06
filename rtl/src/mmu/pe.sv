// Output:
// psum_out = in * w_in + psum_in
// pass_out = in

module pe #(
  parameter  int unsigned DATA_WIDTH = 16,
  localparam int unsigned PSUM_WIDTH = 2 * DATA_WIDTH
)
(
  input                         clk,
  input                         rstn, // FIXME: is it really need?
  input                         en_in,
  input                         w_wen_in,
  input [DATA_WIDTH-1:0]        in,
  input [DATA_WIDTH-1:0]        w_in,
  input [PSUM_WIDTH-1:0]        psum_in,

  output logic                  w_wen_out,
  output logic                  en_out,
  output logic [DATA_WIDTH-1:0] pass_out,
  output logic [DATA_WIDTH-1:0] w_out,
  output logic [PSUM_WIDTH-1:0] psum_out
);

logic                  m_w_wen;
logic                  m_en;
logic [DATA_WIDTH-1:0] m_pass_out;
logic [PSUM_WIDTH-1:0] m_psum_out;

logic [DATA_WIDTH-1:0] w; // weight register

logic [DATA_WIDTH-1:0] m_w;
logic [DATA_WIDTH-1:0] m_w_out;

always_ff @(posedge clk, negedge rstn) begin
  if (!rstn) begin
    w_wen_out <= 1'b0;
    en_out <= 1'b0;
    pass_out <= {DATA_WIDTH{1'd0}};
    psum_out <= {PSUM_WIDTH{1'd0}};
    w <= {DATA_WIDTH{1'd0}};
    w_out <= {DATA_WIDTH{1'd0}};
  end
  else begin
    w_wen_out <= m_w_wen;
    en_out <= m_en;
    pass_out <= m_pass_out;
    psum_out <= m_psum_out;
    w <= m_w;
    w_out <= m_w_out;
  end
end

// mac
always_comb begin
  m_en = en_in;

  if (en_in) begin
    m_pass_out = in;
    m_psum_out = in * w + psum_in;
  end
  else begin
    m_pass_out = pass_out;
    m_psum_out = psum_out;
  end
end

// store weight
always_comb begin
  m_w_wen = w_wen_in;

  if (w_wen_in || w_wen_out) begin
    m_w = w_in;
    m_w_out = w;
  end
  else begin
    m_w = w;
    m_w_out = {DATA_WIDTH{1'd0}};
  end
end

endmodule






