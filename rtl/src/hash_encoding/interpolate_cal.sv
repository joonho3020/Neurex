module interpolate_cal #(
  parameter  int unsigned HALF_SIZE = 16, // 2B
  parameter  int unsigned DATA_SIZE = 32, // 4B

  localparam [3:0] IDLE    = 4'b1111,
  localparam [3:0] X_MINUS = 4'b0000,
  localparam [3:0] X_DIV   = 4'b0001,
  localparam [3:0] X_MULT  = 4'b0010,
  localparam [3:0] X_ADD   = 4'b0011,

  localparam [3:0] Y_MINUS = 4'b0100,
  localparam [3:0] Y_DIV   = 4'b0101,
  localparam [3:0] Y_MULT  = 4'b0110,
  localparam [3:0] Y_ADD   = 4'b0111,

  localparam [3:0] Z_MINUS = 4'b1000,
  localparam [3:0] Z_DIV   = 4'b1001,
  localparam [3:0] Z_MULT  = 4'b1010,
  localparam [3:0] Z_ADD   = 4'b1011
) (
  input clk,
  input rstn,
  input en,
  input [DATA_SIZE-1:0] feat[0:7],
  input [DATA_SIZE-1:0] x[0:8], // idx 8 = target point
  input [DATA_SIZE-1:0] y[0:8],
  input [DATA_SIZE-1:0] z[0:8],
  output logic [DATA_SIZE-1:0] interpolated_feat,
  output logic done
);
// FIXME: 1) integer multiplication -> floating point multiplication
//        2) FP16 operation for features, FP32 operation for coordinates

logic m_done;

// FF
logic [DATA_SIZE-1:0] f01, f01_0, f01_1, f01_upper0, f01_lower, f01_upper1;
logic [DATA_SIZE-1:0] f23, f23_0, f23_1, f23_upper0, f23_lower, f23_upper1;
logic [DATA_SIZE-1:0] f45, f45_0, f45_1, f45_upper0, f45_lower, f45_upper1;
logic [DATA_SIZE-1:0] f67, f67_0, f67_1, f67_upper0, f67_lower, f67_upper1;
logic [DATA_SIZE-1:0] f0123, f0123_0, f0123_1, f0123_upper0, f0123_lower, f0123_upper1;
logic [DATA_SIZE-1:0] f4567, f4567_0, f4567_1, f4567_upper0, f4567_lower, f4567_upper1;
logic [DATA_SIZE-1:0] fout_0, fout_1, fout_upper0, fout_lower, fout_upper1;

// wire
logic [DATA_SIZE-1:0] m_f01, m_f01_0, m_f01_1, m_f01_upper0, m_f01_lower, m_f01_upper1;
logic [DATA_SIZE-1:0] m_f23, m_f23_0, m_f23_1, m_f23_upper0, m_f23_lower, m_f23_upper1;
logic [DATA_SIZE-1:0] m_f45, m_f45_0, m_f45_1, m_f45_upper0, m_f45_lower, m_f45_upper1;
logic [DATA_SIZE-1:0] m_f67, m_f67_0, m_f67_1, m_f67_upper0, m_f67_lower, m_f67_upper1;
logic [DATA_SIZE-1:0] m_f0123, m_f0123_0, m_f0123_1, m_f0123_upper0, m_f0123_lower, m_f0123_upper1;
logic [DATA_SIZE-1:0] m_f4567, m_f4567_0, m_f4567_1, m_f4567_upper0, m_f4567_lower, m_f4567_upper1;
logic [DATA_SIZE-1:0] m_fout_0, m_fout_1, m_fout_upper0, m_fout_lower, m_fout_upper1;
logic [DATA_SIZE-1:0] m_interpolated_feat;

logic [3:0] state, m_state;

always_ff @(posedge clk) begin
  state <= m_state;

  done <= m_done;

  f01 <= m_f01;
  f01_0 <= m_f01_0;
  f01_1 <= m_f01_1;
  f01_upper0 <= m_f01_upper0;
  f01_upper1 <= m_f01_upper1;
  f01_lower <= m_f01_lower;

  f23 <= m_f23;
  f23_0 <= m_f23_0;
  f23_1 <= m_f23_1;
  f23_upper0 <= m_f23_upper0;
  f23_upper1 <= m_f23_upper1;
  f23_lower <= m_f23_lower;

  f45 <= m_f45;
  f45_0 <= m_f45_0;
  f45_1 <= m_f45_1;
  f45_upper0 <= m_f45_upper0;
  f45_upper1 <= m_f45_upper1;
  f45_lower <= m_f45_lower;

  f67 <= m_f67;
  f67_0 <= m_f67_0;
  f67_1 <= m_f67_1;
  f67_upper0 <= m_f67_upper0;
  f67_upper1 <= m_f67_upper1;
  f67_lower <= m_f67_lower;

  f0123 <= m_f0123;
  f0123_0 <= m_f0123_0;
  f0123_1 <= m_f0123_1;
  f0123_upper0 <= m_f0123_upper0;
  f0123_upper1 <= m_f0123_upper1;
  f0123_lower <= m_f0123_lower;

  f4567 <= m_f4567;
  f4567_0 <= m_f4567_0;
  f4567_1 <= m_f4567_1;
  f4567_upper0 <= m_f4567_upper0;
  f4567_upper1 <= m_f4567_upper1;
  f4567_lower <= m_f4567_lower;

  interpolated_feat <= m_interpolated_feat;
  fout_0 <= m_fout_0;
  fout_1 <= m_fout_1;
  fout_upper0 <= m_fout_upper0;
  fout_upper1 <= m_fout_upper1;
  fout_lower <= m_fout_lower;
end

always_comb begin
  m_f01 = f01;
  m_f01_0 = f01_0;
  m_f01_1 = f01_1;
  m_f01_upper0 = f01_upper0;
  m_f01_upper1 = f01_upper1;
  m_f01_lower= f01_lower;

  m_f23 = f23;
  m_f23_0 = f23_0;
  m_f23_1 = f23_1;
  m_f23_upper0 = f23_upper0;
  m_f23_upper1 = f23_upper1;
  m_f23_lower= f23_lower;

  m_f45 = f45;
  m_f45_0 = f45_0;
  m_f45_1 = f45_1;
  m_f45_upper0 = f45_upper0;
  m_f45_upper1 = f45_upper1;
  m_f45_lower= f45_lower;

  m_f67 = f67;
  m_f67_0 = f67_0;
  m_f67_1 = f67_1;
  m_f67_upper0 = f67_upper0;
  m_f67_upper1 = f67_upper1;
  m_f67_lower= f67_lower;

  m_f0123 = f0123;
  m_f0123_0 = f0123_0;
  m_f0123_1 = f0123_1;
  m_f0123_upper0 = f0123_upper0;
  m_f0123_upper1 = f0123_upper1;
  m_f0123_lower= f0123_lower;

  m_f4567 = f4567;
  m_f4567_0 = f4567_0;
  m_f4567_1 = f4567_1;
  m_f4567_upper0 = f4567_upper0;
  m_f4567_upper1 = f4567_upper1;
  m_f4567_lower= f4567_lower;
  
  m_interpolated_feat = 0;
  m_fout_0 = fout_0;
  m_fout_1 = fout_1;
  m_fout_upper0 = fout_upper0;
  m_fout_upper1 = fout_upper1;
  m_fout_lower= fout_lower;

  m_done = done;

  unique case (state)
    IDLE: begin
      m_state = IDLE;
      m_done = 1'b0;

      if (en) begin
        m_state = X_MINUS;
      end
    end
    X_MINUS: begin
      m_state = X_DIV;

      m_f01_upper0 = x[8] - x[0];
      m_f01_upper1 = x[1] - x[8];
      m_f01_lower  = x[1] - x[0];

      m_f23_upper0 = x[8] - x[2];
      m_f23_upper1 = x[3] - x[8];
      m_f23_lower  = x[3] - x[2];

      m_f45_upper0 = x[8] - x[4];
      m_f45_upper1 = x[5] - x[8];
      m_f45_lower  = x[5] - x[4];

      m_f67_upper0 = x[8] - x[6];
      m_f67_upper1 = x[7] - x[8];
      m_f67_lower  = x[7] - x[6];
    end
    X_DIV: begin
      m_state = X_MULT;

      m_f01_0 = f01_upper0 / f01_lower;
      m_f01_1 = f01_upper1 / f01_lower;

      m_f23_0 = f23_upper0 / f23_lower;
      m_f23_1 = f23_upper1 / f23_lower;

      m_f45_0 = f45_upper0 / f45_lower;
      m_f45_1 = f45_upper1 / f45_lower;

      m_f67_0 = f67_upper0 / f67_lower;
      m_f67_1 = f67_upper1 / f67_lower;
    end
    X_MULT: begin
      m_state = X_ADD;

      m_f01_0 = f01_0 * feat[1];
      m_f01_1 = f01_0 * feat[0];

      m_f23_0 = f23_0 * feat[1];
      m_f23_1 = f23_0 * feat[0];

      m_f45_0 = f45_0 * feat[1];
      m_f45_1 = f45_0 * feat[0];

      m_f67_0 = f67_0 * feat[1];
      m_f67_1 = f67_0 * feat[0];
    end
    X_ADD: begin
      m_state = Y_MINUS;

      m_f01 = f01_0 + f01_1;
      m_f23 = f23_0 + f23_1;
      m_f45 = f45_0 + f45_1;
      m_f67 = f67_0 + f67_1;
    end
    Y_MINUS: begin
      m_state = Y_DIV;

      m_f0123_upper0 = y[8] - y[2];
      m_f0123_upper1 = y[0] - y[8];
      m_f0123_lower = y[0] - y[2];

      m_f4567_upper0 = y[8] - y[6];
      m_f4567_upper1 = y[4] - y[8];
      m_f4567_lower = y[4] - y[6];
    end
    Y_DIV: begin
      m_state = Y_MULT;

      m_f0123_0 = f0123_upper0 / f0123_lower;
      m_f0123_1 = f0123_upper1 / f0123_lower;

      m_f4567_0 = f4567_upper0 / f4567_lower;
      m_f4567_1 = f4567_upper1 / f4567_lower;
    end
    Y_MULT: begin
      m_state = Y_ADD;

      m_f0123_0 = f0123_0 * f01;
      m_f0123_1 = f0123_1 * f23;

      m_f4567_0 = f4567_0 * f45;
      m_f4567_1 = f4567_1 * f67;
    end
    Y_ADD: begin
      m_state = Z_MINUS;

      m_f0123 = f0123_0 + f0123_1;
      m_f4567 = f4567_0 + f4567_1;
    end
    Z_MINUS: begin
      m_state = Z_DIV;

      m_fout_upper0 = z[8] - z[4];
      m_fout_upper1 = z[0] - z[8];
      m_fout_lower  = z[0] - z[4];
    end
    Z_DIV: begin
      m_state = Z_MULT;

      m_fout_0 = fout_upper0 / fout_lower;
      m_fout_1 = fout_upper1 / fout_lower;
    end
    Z_MULT: begin
      m_state = Z_ADD;

      m_fout_0 = fout_0 * f0123;
      m_fout_1 = fout_1 * f4567;
    end
    Z_ADD: begin
      m_state = IDLE;

      m_interpolated_feat = fout_0 + fout_1;
      m_done = 1'b1;
    end
    default: begin
      m_state = IDLE;
    end
  endcase

  if (!rstn) begin
  end
end

endmodule
