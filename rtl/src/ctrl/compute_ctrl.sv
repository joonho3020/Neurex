module compute_ctrl #(
  parameter  int unsigned DATA_WIDTH = 16,

  localparam [1:0] IDLE             = 2'b00,
  localparam [1:0] W_FILL           = 2'b01,
  localparam [1:0] READ_AND_COMPUTE = 2'b10
) (
  input clk,
  input rstn,
  input en,
  input [DATA_WIDTH-1:0] num_row_in,
  input fill_done,
  input sys_done,
  input weight_fill, // if already double buffered, weight_fill = 0
  input weight_change, // is double buffering is needed?
  output logic [7:0] accum_wr_addr,
  output logic [DATA_WIDTH-1:0] num_row_out,
  output logic fifo_out_ctrl_en,
  output logic mem_rd_ctrl_en
);

logic m_fifo_out_ctrl_en, m_mem_rd_ctrl_en;

logic [1:0] fill_state, m_fill_state;
logic [1:0] compute_state, m_compute_state;

logic fill_done_inter, m_fill_done;
logic weight_change_inter, m_weight_change;

logic [DATA_WIDTH-1:0] num_row_inter, m_num_row;

logic [7:0] m_accum_wr_addr;

always_ff @(posedge clk) begin
  fifo_out_ctrl_en <= m_fifo_out_ctrl_en;
  mem_rd_ctrl_en <= m_mem_rd_ctrl_en;
  fill_state <= m_fill_state;
  compute_state <= m_compute_state;
  fill_done_inter <= m_fill_done;
  weight_change_inter <= m_weight_change;
  num_row_inter <= m_num_row;
  accum_wr_addr <= m_accum_wr_addr;
end

// Fill weight to systolic array
always_comb begin
  unique case (fill_state)
    IDLE: begin
      m_fill_state = IDLE;
      m_fifo_out_ctrl_en = 1'b0;
      m_fill_done = 1'b0;

      if (en) begin
        if (weight_fill) begin
          m_fill_state = W_FILL;
          m_fifo_out_ctrl_en = 1'b1;
        end else if (!weight_fill) begin
          m_fill_done = 1'b1;
        end
        m_weight_change = weight_change;
        m_num_row = num_row_in;
      end else begin
        m_weight_change = weight_change_inter;
        m_num_row = num_row_inter;
      end

      if (weight_change_inter) begin
        m_fill_state = W_FILL;
        m_fifo_out_ctrl_en = 1'b1;
        m_weight_change = 1'b0;
      end
    end
    W_FILL: begin
      m_fill_state = W_FILL;
      m_fifo_out_ctrl_en = 1'b0;
      m_fill_done = fill_done;
      m_num_row = num_row_in;
      m_weight_change = weight_change;

      if (fill_done) begin
        m_fill_state = IDLE;
      end
    end
    default: begin
      if (!rstn) begin
        m_fill_state = IDLE;
        m_fifo_out_ctrl_en = 1'b0;
        m_fill_done = 1'b0;
        m_num_row = {DATA_WIDTH{1'b0}};
        m_weight_change = 1'b0;
      end
    end
  endcase
end

// Read input & Start computation
assign num_row_out = num_row_inter;

always_comb begin
  unique case (compute_state)
    IDLE: begin
      m_compute_state = IDLE;
      m_mem_rd_ctrl_en = 1'b0;

      if (fill_done_inter) begin
        m_compute_state = READ_AND_COMPUTE;
        m_mem_rd_ctrl_en = 1'b1;
      end
    end
    READ_AND_COMPUTE: begin
      m_mem_rd_ctrl_en = 1'b0;

      if (sys_done) begin
        m_compute_state = IDLE;
      end
    end
    default: begin
      if (!rstn) begin
        m_compute_state = IDLE;
        m_mem_rd_ctrl_en = 1'b0;
      end
    end
  endcase
end

// Accumulate psum in accumulators
always_comb begin
  if (sys_done) begin
    m_accum_wr_addr = accum_wr_addr + {7'd0, sys_done}; // timing check! m_accum_wr_addr & accum_wr_addr
  end else begin
    m_accum_wr_addr = 8'd0;
  end

  if (m_accum_wr_addr == num_row_inter) begin
    m_accum_wr_addr = 8'd0;
  end

  if (!rstn) begin
    m_accum_wr_addr = 8'd0;
  end
end

// Another implementation
/* 
always_comb begin
  m_accum_wr_addr = accum_wr_addr;
  if (sys_done) begin
    m_accum_wr_addr = accum_wr_addr + 1;
  end
  if (accum_wr_addr == num_row_inter - 1) begin
    m_accum_wr_addr = 0;
  end
end
*/

endmodule
