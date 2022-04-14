module compute_ctrl #(
  parameter  int unsigned DATA_WIDTH = 16,
  parameter  int unsigned ADDR_WIDTH = 16,
  parameter  int unsigned SYS_ROW    = 16,

  localparam [1:0] IDLE             = 2'b00,
  localparam [1:0] W_FILL           = 2'b01,
  localparam [1:0] READ_AND_COMPUTE = 2'b10
) (
  input                         clk,
  input                         rstn,
  input                         en,
  input [DATA_WIDTH-1:0]        num_row_in,
  input                         drain_done,
  input                         sys_done,
  input                         sys_en_out,
  input                         weight_fill, // if already double buffered, weight_fill = 0
  input                         weight_change, // is double buffering is needed?
  output logic [ADDR_WIDTH-1:0] accum_wr_addr,
  output logic                  fifo_out_ctrl_en,
  output logic                  fifo_in_ctrl_en,
  output logic                  mem_rd_ctrl_en,
  output logic [ADDR_WIDTH-1:0] w_offset_addr
);

logic m_fifo_out_ctrl_en, m_mem_rd_ctrl_en;
logic m_fifo_in_ctrl_en;

logic [1:0] state, m_state;

logic drain_done_inter, m_drain_done;
logic weight_change_inter, m_weight_change;

logic [DATA_WIDTH-1:0] num_row_inter, m_num_row;

logic [ADDR_WIDTH-1:0] m_accum_wr_addr, m_w_offset_addr;


always_ff @(posedge clk) begin
  state <= m_state;
  fifo_out_ctrl_en <= m_fifo_out_ctrl_en;
  fifo_in_ctrl_en <= m_fifo_in_ctrl_en;
  mem_rd_ctrl_en <= m_mem_rd_ctrl_en;
  drain_done_inter <= m_drain_done;
  weight_change_inter <= m_weight_change;
  num_row_inter <= m_num_row;
  accum_wr_addr <= m_accum_wr_addr;
  w_offset_addr <= m_w_offset_addr;
end

/* assign num_row_out = num_row_inter; */

// Fill weight to systolic array -> Read input & Start computation
always_comb begin
  unique case (state)
    IDLE: begin
      m_state = IDLE;
      m_fifo_in_ctrl_en = 1'b0;
      m_fifo_out_ctrl_en = 1'b0;
      m_mem_rd_ctrl_en = 1'b0;
      m_drain_done = 1'b0;
      m_w_offset_addr = {ADDR_WIDTH{1'b0}};

      if (en) begin
        m_state = W_FILL;
        if (weight_fill) begin
          m_fifo_in_ctrl_en = 1'b1;
          m_fifo_out_ctrl_en = 1'b1;
        end else begin
          m_drain_done = 1'b1;
        end
        m_weight_change = weight_change;
        m_num_row = num_row_in;
      end else begin
        m_weight_change = 1'b0;
        m_num_row = num_row_inter;
      end
    end
    W_FILL: begin
      m_state = W_FILL;
      m_fifo_in_ctrl_en = 1'b0;
      m_fifo_out_ctrl_en = 1'b0;
      m_mem_rd_ctrl_en = 1'b0;
      m_drain_done = drain_done;
      m_num_row = num_row_inter;
      m_weight_change = weight_change_inter;
      m_w_offset_addr = {ADDR_WIDTH{1'b0}};

      if (drain_done_inter) begin
        m_state = READ_AND_COMPUTE;
        m_mem_rd_ctrl_en = 1'b1;
        if (weight_change_inter) begin
          m_fifo_in_ctrl_en = 1'b1;
          m_fifo_out_ctrl_en = 1'b1;
          m_w_offset_addr = ADDR_WIDTH'(SYS_ROW);
        end
      end
    end
    READ_AND_COMPUTE: begin
      m_state = READ_AND_COMPUTE;
      m_mem_rd_ctrl_en = 1'b0;
      m_fifo_in_ctrl_en = 1'b0;
      m_fifo_out_ctrl_en = 1'b0;
      m_drain_done = drain_done;
      m_num_row = num_row_inter;
      m_weight_change = weight_change_inter;
      m_w_offset_addr = {ADDR_WIDTH{1'b0}};

      if (sys_done) begin // drain_done (SYS_ROW cycle) -> sys_done ((SYS_ROW + SYS_COL + NUM_IN - 1) cycle)
        m_state = IDLE;
      end
    end
    default: begin
      if (!rstn) begin
        m_state = IDLE;
        m_fifo_out_ctrl_en = 1'b0;
        m_drain_done = 1'b0;
        m_num_row = {DATA_WIDTH{1'b0}};
        m_weight_change = 1'b0;
      end
    end
  endcase
end

// Accumulate psum in accumulators
always_comb begin
  if (sys_en_out) begin
    m_accum_wr_addr = accum_wr_addr + {(ADDR_WIDTH-1)'(0), sys_en_out}; // timing check! m_accum_wr_addr & accum_wr_addr
  end else begin
    m_accum_wr_addr = ADDR_WIDTH'(0);
  end

  if (m_accum_wr_addr == num_row_inter) begin
    m_accum_wr_addr = ADDR_WIDTH'(0);
  end

  if (!rstn) begin
    m_accum_wr_addr = ADDR_WIDTH'(0);
  end
end

// Another implementation
/* 
always_comb begin
  m_accum_wr_addr = accum_wr_addr;
  if (sys_en_out) begin
    m_accum_wr_addr = accum_wr_addr + 1;
  end
  if (accum_wr_addr == num_row_inter) begin
    m_accum_wr_addr = 0;
  end
end
*/

endmodule
