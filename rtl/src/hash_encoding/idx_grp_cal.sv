module idx_grp_cal #(
  parameter  int unsigned HALF_SIZE      = 16,
  parameter  int unsigned DATA_SIZE      = 32,
  parameter  int unsigned PRIME1         = 2654435761,
  parameter  int unsigned PRIME2         = 805459861,
  parameter  int unsigned TABLE_SIZE     = 4096,
  //parameter  int unsigned TABLE_SIZE1    = 13824,
  //parameter  int unsigned TABLE_SIZE2    = 46656,
  //parameter  int unsigned TABLE_SIZE3    = 166375,
  //parameter  int unsigned TABLE_SIZE_MAX = 524288,

  localparam [2:0] IDLE         = 3'b000,
  localparam [2:0] RES_MULT     = 3'b001,
  localparam [2:0] IDX_FLOOR    = 3'b010,
  localparam [2:0] HASHING_MULT = 3'b011,
  localparam [2:0] HASHING_XOR  = 3'b100,
  localparam [2:0] HASHING_MOD  = 3'b101
) (
  input clk,
  input en,
  input [HALF_SIZE-1:0] x,
  input [HALF_SIZE-1:0] y,
  input [HALF_SIZE-1:0] z,
  input [HALF_SIZE-1:0] res,
  output logic [DATA_SIZE-1:0] hash_idx[0:7]
);

// TODO: x, y, z -> FP32, idx -> uint_32
logic [2:0] state, m_state;
logic [HALF_SIZE-1:0] m_x, m_y, m_z;
logic [HALF_SIZE-1:0] res_inter, m_res;
logic [HALF_SIZE-1:0] x_inter, y_inter, z_inter;
logic [HALF_SIZE-1:0] pos_idx_surround[0:7][0:2];
logic [HALF_SIZE-1:0] m_pos_idx_surround[0:7][0:2];
logic [HALF_SIZE-1:0] pos_idx[0:2];
logic [HALF_SIZE-1:0] m_pos_idx[0:2];
//real pos_idx[0:2];
//real m_pos_idx[0:2];

logic [DATA_SIZE-1:0] hash_idx_single[0:7][0:2];
logic [DATA_SIZE-1:0] m_hash_idx_single[0:7][0:2];
logic [DATA_SIZE-1:0] hash_idx_xor[0:7];
logic [DATA_SIZE-1:0] m_hash_idx_xor[0:7];
logic [DATA_SIZE-1:0] m_hash_idx[0:7];

always_ff @(posedge clk) begin
  state <= m_state;
  x_inter <= m_x;
  y_inter <= m_y;
  z_inter <= m_z;
  res_inter <= m_res;
  pos_idx <= m_pos_idx;
  pos_idx_surround <= m_pos_idx_surround;
  hash_idx_single <= m_hash_idx_single;
  hash_idx_xor <= m_hash_idx_xor;
  hash_idx <= m_hash_idx;
end

always_comb begin
  m_x = x_inter;
  m_y = y_inter;
  m_z = z_inter;
  m_res = res_inter;
  m_pos_idx = pos_idx;
  m_pos_idx_surround = pos_idx_surround;
  m_hash_idx_single = hash_idx_single;
  m_hash_idx_xor = hash_idx_xor;
  m_hash_idx = hash_idx;

  unique case (state)
    IDLE: begin
      m_state = IDLE;
      if (en) begin
        m_state = RES_MULT;
        m_x = x;
        m_y = y;
        m_z = z;
        m_res = res;
      end
    end
    RES_MULT: begin
      m_state = IDX_FLOOR;

      m_pos_idx[0] = x_inter * res_inter;
      //m_pos_idx_upper[0] = x_inter_upper * res_inter_upper;
      //m_pos_idx_middle[0] = x_inter_upper * res_inter_lower + x_inter_lower * res_inter_upper;
      //m_pos_idx_lower[0] = x_inter_lower * res_inter_lower;

      m_pos_idx[1] = y_inter * res_inter;
      //m_pos_idx_upper[1] = y_inter_upper * res_inter_upper;
      //m_pos_idx_middle[1] = y_inter_upper * res_inter_lower + y_inter_lower * res_inter_upper;
      //m_pos_idx_lower[1] = y_inter_lower * res_inter_lower;

      m_pos_idx[2] = z_inter * res_inter;
      //m_pos_idx_upper[2] = z_inter_upper * res_inter_upper;
      //m_pos_idx_middle[2] = z_inter_upper * res_inter_lower + z_inter_lower * res_inter_upper;
      //m_pos_idx_lower[2] = z_inter_lower * res_inter_lower;
    end
    IDX_FLOOR: begin // INT32
      m_state = HASHING_MULT;

      m_pos_idx_surround[0][0] = pos_idx[0];
      m_pos_idx_surround[0][1] = pos_idx[1];
      m_pos_idx_surround[0][2] = pos_idx[2];

      m_pos_idx_surround[1][0] = pos_idx[0] + 1;
      m_pos_idx_surround[1][1] = pos_idx[1];
      m_pos_idx_surround[1][2] = pos_idx[2];

      m_pos_idx_surround[2][0] = pos_idx[0];
      m_pos_idx_surround[2][1] = pos_idx[1] + 1;
      m_pos_idx_surround[2][2] = pos_idx[2];

      m_pos_idx_surround[3][0] = pos_idx[0] + 1;
      m_pos_idx_surround[3][1] = pos_idx[1] + 1;
      m_pos_idx_surround[3][2] = pos_idx[2];

      m_pos_idx_surround[4][0] = pos_idx[0];
      m_pos_idx_surround[4][1] = pos_idx[1];
      m_pos_idx_surround[4][2] = pos_idx[2] + 1;

      m_pos_idx_surround[5][0] = pos_idx[0] + 1;
      m_pos_idx_surround[5][1] = pos_idx[1];
      m_pos_idx_surround[5][2] = pos_idx[2] + 1;

      m_pos_idx_surround[6][0] = pos_idx[0];
      m_pos_idx_surround[6][1] = pos_idx[1] + 1;
      m_pos_idx_surround[6][2] = pos_idx[2] + 1;

      m_pos_idx_surround[7][0] = pos_idx[0] + 1;
      m_pos_idx_surround[7][1] = pos_idx[1] + 1;
      m_pos_idx_surround[7][2] = pos_idx[2] + 1;
    end
    HASHING_MULT: begin // INT multiplication
      m_state = HASHING_XOR;

      m_hash_idx_single[0][0] = 32'(pos_idx_surround[0][0]);
      m_hash_idx_single[0][1] = pos_idx_surround[0][1] * PRIME1[15:0];
      m_hash_idx_single[0][2] = pos_idx_surround[0][2] * PRIME2[15:0];

      m_hash_idx_single[1][0] = 32'(pos_idx_surround[1][0]);
      m_hash_idx_single[1][1] = pos_idx_surround[1][1] * PRIME1[15:0];
      m_hash_idx_single[1][2] = pos_idx_surround[1][2] * PRIME2[15:0];

      m_hash_idx_single[2][0] = 32'(pos_idx_surround[2][0]);
      m_hash_idx_single[2][1] = pos_idx_surround[2][1] * PRIME1[15:0];
      m_hash_idx_single[2][2] = pos_idx_surround[2][2] * PRIME2[15:0];

      m_hash_idx_single[3][0] = 32'(pos_idx_surround[3][0]);
      m_hash_idx_single[3][1] = pos_idx_surround[3][1] * PRIME1[15:0];
      m_hash_idx_single[3][2] = pos_idx_surround[3][2] * PRIME2[15:0];

      m_hash_idx_single[4][0] = 32'(pos_idx_surround[4][0]);
      m_hash_idx_single[4][1] = pos_idx_surround[4][1] * PRIME1[15:0];
      m_hash_idx_single[4][2] = pos_idx_surround[4][2] * PRIME2[15:0];

      m_hash_idx_single[5][0] = 32'(pos_idx_surround[5][0]);
      m_hash_idx_single[5][1] = pos_idx_surround[5][1] * PRIME1[15:0];
      m_hash_idx_single[5][2] = pos_idx_surround[5][2] * PRIME2[15:0];

      m_hash_idx_single[6][0] = 32'(pos_idx_surround[6][0]);
      m_hash_idx_single[6][1] = pos_idx_surround[6][1] * PRIME1[15:0];
      m_hash_idx_single[6][2] = pos_idx_surround[6][2] * PRIME2[15:0];

      m_hash_idx_single[7][0] = 32'(pos_idx_surround[7][0]);
      m_hash_idx_single[7][1] = pos_idx_surround[7][1] * PRIME1[15:0];
      m_hash_idx_single[7][2] = pos_idx_surround[7][2] * PRIME2[15:0];
    end
    HASHING_XOR: begin
      m_state = HASHING_MOD;

      m_hash_idx_xor[0] = hash_idx_single[0][0] ^ hash_idx_single[0][1] ^ hash_idx_single[0][2];
      m_hash_idx_xor[1] = hash_idx_single[1][0] ^ hash_idx_single[1][1] ^ hash_idx_single[1][2];
      m_hash_idx_xor[2] = hash_idx_single[2][0] ^ hash_idx_single[2][1] ^ hash_idx_single[2][2];
      m_hash_idx_xor[3] = hash_idx_single[3][0] ^ hash_idx_single[3][1] ^ hash_idx_single[3][2];
      m_hash_idx_xor[4] = hash_idx_single[4][0] ^ hash_idx_single[4][1] ^ hash_idx_single[4][2];
      m_hash_idx_xor[5] = hash_idx_single[5][0] ^ hash_idx_single[5][1] ^ hash_idx_single[5][2];
      m_hash_idx_xor[6] = hash_idx_single[6][0] ^ hash_idx_single[6][1] ^ hash_idx_single[6][2];
      m_hash_idx_xor[7] = hash_idx_single[7][0] ^ hash_idx_single[7][1] ^ hash_idx_single[7][2];
    end
    HASHING_MOD: begin
      m_state = IDLE;

      m_hash_idx[0] = hash_idx_xor % TABLE_SIZE;
      m_hash_idx[1] = hash_idx_xor % TABLE_SIZE;
      m_hash_idx[2] = hash_idx_xor % TABLE_SIZE;
      m_hash_idx[3] = hash_idx_xor % TABLE_SIZE;
      m_hash_idx[4] = hash_idx_xor % TABLE_SIZE;
      m_hash_idx[5] = hash_idx_xor % TABLE_SIZE;
      m_hash_idx[6] = hash_idx_xor % TABLE_SIZE;
      m_hash_idx[7] = hash_idx_xor % TABLE_SIZE;
    end
    default: begin
      m_state = IDLE;
    end
  endcase
end

endmodule
