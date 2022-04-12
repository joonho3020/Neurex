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
  input                         global_w_wen_in,
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

logic [DATA_WIDTH-1:0] w;  // weight register
logic [DATA_WIDTH-1:0] w2; // weight register (double buffering)

logic [DATA_WIDTH-1:0] m_w;
logic [DATA_WIDTH-1:0] m_w2;
logic [DATA_WIDTH-1:0] m_w_out;

logic                  valid, valid2;
logic                  m_valid, m_valid2;

always_ff @(posedge clk, negedge rstn) begin
  w_wen_out <= m_w_wen;
  en_out <= m_en;
  pass_out <= m_pass_out;
  psum_out <= m_psum_out;
  w <= m_w;
  w2 <= m_w2;
  w_out <= m_w_out;
  valid <= m_valid;
  valid2 <= m_valid2;
end

// mac
always_comb begin
  m_en = en_in;

  if (en_in) begin
    m_pass_out = in;
    m_psum_out = in * w + psum_in;
  end else begin
    m_pass_out = pass_out;
    m_psum_out = psum_out;
  end

  if (!rstn) begin
    m_en = 1'b0;
    m_pass_out = {DATA_WIDTH{1'd0}};
    m_psum_out = {PSUM_WIDTH{1'd0}};
  end
end

// store weight
always_comb begin
  m_w_wen = w_wen_in;

  if (global_w_wen_in && w_wen_in) begin
    m_w2 = w_in;
    //m_w_out = w2;
    m_w_out = w_in;
    m_valid2 = 1'b1;
  end else begin
    m_w2 = w2;
    m_w_out = {DATA_WIDTH{1'b0}};
    m_valid2 = valid2;
  end

  if (!en_in && !valid && valid2) begin
    m_w = w2;
    m_valid = 1'b1;
    m_valid2 = 1'b0;
  end else begin
    m_w = w;
    m_valid = valid;
  end

  if (!rstn) begin
    m_w_wen = 1'b0;
    m_w = {DATA_WIDTH{1'b0}};
    m_w2 = {DATA_WIDTH{1'b0}};
    m_w_out = {DATA_WIDTH{1'b0}};
    m_valid = 1'b0;
    m_valid2 = 1'b0;
  end
end

endmodule






