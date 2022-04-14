module top_neurex #(
  parameter  int unsigned SYS_ROW = 16,
  parameter  int unsigned SYS_COL = 16,
  parameter  int unsigned FIFO_DEPTH = 2 * SYS_ROW,
  parameter  int unsigned DATA_WIDTH = 16,
  parameter  int unsigned ADDR_WIDTH = 16,
  parameter  int unsigned ACCUM_SIZE = 1024,
  localparam int unsigned PSUM_WIDTH = 2 * DATA_WIDTH,
  localparam int unsigned FIFO_WIDTH = SYS_COL,
  localparam int unsigned ACCUM_ROW = ACCUM_SIZE / SYS_COL,
  localparam int unsigned COUNT_WIDTH = $clog2(ACCUM_ROW) + 3,

  localparam [2:0] IDLE        = 3'b000,
  localparam [2:0] INIT_W_FILL = 3'b001,
  localparam [2:0] COMPUTE     = 3'b010,
  localparam [2:0] OUT_STORE   = 3'b011
) (
  input                  clk,
  input                  rstn,
  input [DATA_WIDTH-1:0] num_in,
  input [DATA_WIDTH-1:0] num_common,
  input [DATA_WIDTH-1:0] num_out,
  input                  in_en,
  input                  w_en,
  input [DATA_WIDTH-1:0] in_data[0:SYS_ROW-1],
  input [DATA_WIDTH-1:0] w_data[0:SYS_COL-1]
);

// Weight Memory & FIFO Ports
logic [31:0] w_row_cnt;

logic [FIFO_WIDTH-1:0] fifo_in_en_out, fifo_out_en_out;
logic fifo_out_en;

logic [SYS_COL-1:0] w_wr_en;
logic [ADDR_WIDTH-1:0] w_wr_addr[0:SYS_COL-1];
logic [DATA_WIDTH-1:0] w_wr_data[0:SYS_COL-1];

logic [ADDR_WIDTH-1:0] w_rd_addr[0:SYS_ROW-1];
logic [DATA_WIDTH-1:0] w_rd_data[0:SYS_ROW-1];

logic [SYS_COL-1:0] w_wen;
logic [DATA_WIDTH-1:0] w_out[0:FIFO_WIDTH-1];

// Input Memory Ports
logic [31:0] in_row_offset;

logic [SYS_ROW-1:0] in_wr_en;
logic [ADDR_WIDTH-1:0] in_wr_addr[0:SYS_ROW-1];
logic [DATA_WIDTH-1:0] in_wr_data[0:SYS_ROW-1];

logic [SYS_ROW-1:0] in_rd_en;
logic [ADDR_WIDTH-1:0] in_rd_addr[0:SYS_ROW-1];
logic [DATA_WIDTH-1:0] in_rd_data[0:SYS_ROW-1];

// MMU Ports
logic [PSUM_WIDTH-1:0] psum_out [0:SYS_COL-1];
logic [SYS_COL-1:0] en_out;

// Controller Ports
logic in_wr_done;
logic w_wr_done;
logic fill_done; // fifo_in_ctrl output
logic drain_done; // fifo_out_ctrl output

logic fifo_in_en_ctrl, fifo_in_en_master;
logic m_fifo_in_en_ctrl, m_fifo_in_en_master;
logic [ADDR_WIDTH-1:0] w_base_addr, m_w_base_addr;
logic [ADDR_WIDTH-1:0] in_base_addr, m_in_base_addr;
logic [ADDR_WIDTH-1:0] w_offset_addr;

logic compute_ctrl_en, m_compute_ctrl_en;
logic weight_fill, weight_change; // -> compute_ctrl
logic m_weight_fill, m_weight_change;

logic in_rd_en_in; // compute_ctrl -> mem_rd_ctrl

logic fifo_data_in; // fifo_out_ctrl -> fifo_in_ctrl
logic [31:0] repeat_cnt, m_repeat_cnt; // master -> fifo_out_ctrl

logic [SYS_ROW-1:0] w_invalid, m_w_invalid;

// Accumulator side
logic accum_rstn;
logic [SYS_COL-1:0] accum_wr_en;
logic [ADDR_WIDTH-1:0] accum_wr_addr;
logic [$clog2(ACCUM_ROW)-1:0] tot_accum_wr_addr[0:SYS_COL-1];
logic [SYS_COL-1:0] accum_rd_en, m_accum_rd_en;
logic [$clog2(ACCUM_ROW)-1:0] accum_rd_addr[0:SYS_COL-1], m_accum_rd_addr[0:SYS_COL-1];
logic [PSUM_WIDTH-1:0] accum_rd_data[0:SYS_COL-1];

// Output Memory Ports
logic [DATA_WIDTH-1:0] out_wr_cnt, m_out_wr_cnt;
logic [SYS_COL-1:0] out_wr_en, m_out_wr_en;
logic [ADDR_WIDTH-1:0] out_wr_addr[0:SYS_COL-1], m_out_wr_addr[0:SYS_COL-1];
logic [ADDR_WIDTH-1:0] out_rd_addr[0:SYS_COL-1], m_out_rd_addr[0:SYS_COL-1];
logic [PSUM_WIDTH-1:0] out_rd_data[0:SYS_COL-1], out_wr_data[0:SYS_COL-1];

// Systolic Array Done Ports
logic sys_done;
logic prev_sys_done;
logic cur_sys_done, m_cur_sys_done;

// Master Controller Ports
logic [2:0] state, m_state;
logic [DATA_WIDTH-1:0] num_tile_row, m_num_tile_row;
logic [DATA_WIDTH-1:0] tile_row_cnt, m_tile_row_cnt, tile_col_cnt, m_tile_col_cnt;

// Module Instantiation
// Weight Memory & FIFO & Controllers
mem_arr #(
  .NUM_BANK(FIFO_WIDTH), .DATA_WIDTH(DATA_WIDTH)
) W_MEM(
  .clk      (clk),
  .rstn     (rstn),
  .rd_en    ({FIFO_WIDTH{1'b1}}),
  .wr_en    (w_wr_en),
  .wr_data  (w_wr_data),
  .rd_addr  (w_rd_addr),
  .wr_addr  (w_wr_addr),
  .rd_data  (w_rd_data)
);

w_mem_wr_ctrl #(
  .SYS_ROW(SYS_ROW), .SYS_COL(SYS_COL), .DATA_WIDTH(DATA_WIDTH), .ADDR_WIDTH(ADDR_WIDTH), .ACCUM_SIZE(ACCUM_SIZE)
) W_MEM_WR_CTRL(
  .clk       (clk),
  .rstn      (rstn),
  .w_en      (w_en),
  .w_data    (w_data),
  .w_wr_en   (w_wr_en),
  .w_wr_addr (w_wr_addr),
  .w_wr_data (w_wr_data)
);

fifo_in_ctrl #(
  .SYS_ROW(SYS_ROW), .FIFO_WIDTH(FIFO_WIDTH), .FIFO_DEPTH(FIFO_DEPTH)
) FIFO_IN_CTRL(
  .clk          (clk),
  .rstn         (rstn),
  .en           (fifo_in_en_ctrl | fifo_in_en_master),
  .repeat_cnt   (repeat_cnt),
  .base_addr    (w_base_addr),
  .offset_addr  (w_offset_addr),
  .fifo_data_in (fifo_data_in),
  .fifo_en      (fifo_in_en_out),
  .w_mem_rd_addr(w_rd_addr),
  .w_mem_rd_en  (),
  .done         (fill_done)
);

fifo_out_ctrl #(
  .SYS_ROW(SYS_ROW), .FIFO_WIDTH(FIFO_WIDTH)
) FIFO_OUT_CTRL(
  .clk      (clk),
  .rstn     (rstn),
  .en       (fifo_out_en),
  .fifo_data_in(fifo_data_in),
  .done     (drain_done),
  .fifo_en  (fifo_out_en_out),
  .w_wen    (w_wen)
);

weight_fifo #(
  .FIFO_WIDTH(FIFO_WIDTH), .FIFO_DEPTH(FIFO_DEPTH), .DATA_WIDTH(DATA_WIDTH)
) W_FIFO(
  .clk      (clk),
  .rstn     (rstn),
  .en       (fifo_in_en_out | fifo_out_en_out),
  .w_in     (w_rd_data),
  .w_out    (w_out)
);

// Systolic Array
sys_array #(
  .SYS_ROW(SYS_ROW), .SYS_COL(SYS_COL), .DATA_WIDTH(DATA_WIDTH)
) SYS_ARR (
  .clk      (clk),
  .rstn     (rstn),
  .en       (in_rd_en[0]),
  .w_invalid(w_invalid),
  .w_wen    (w_wen),
  .in       (in_rd_data),
  .w_in     (w_out),
  .psum_out (psum_out),
  .en_out   (en_out)
);

// Input Memory & Controllers
mem_arr #(
  .NUM_BANK(SYS_ROW), .DATA_WIDTH(DATA_WIDTH)
) IN_MEM(
  .clk      (clk),
  .rstn     (rstn),
  .rd_en    (in_rd_en),
  .wr_en    (in_wr_en),
  .wr_data  (in_wr_data),
  .rd_addr  (in_rd_addr),
  .wr_addr  (in_wr_addr),
  .rd_data  (in_rd_data)
);

mem_rd_ctrl #(
  .SYS_ROW(SYS_ROW), .SYS_COL(SYS_COL), .DATA_WIDTH(DATA_WIDTH), .ACCUM_SIZE(ACCUM_SIZE)
) IN_RD_CTRL(
  .clk      (clk),
  .rstn     (rstn),
  .rd_en_in (in_rd_en_in),
  .num_row  (num_in),
  .base_addr(in_base_addr),
  .rd_en_out(in_rd_en),
  .rd_addr  (in_rd_addr)
);

in_mem_wr_ctrl #(
  .SYS_ROW(SYS_ROW), .SYS_COL(SYS_COL), .DATA_WIDTH(DATA_WIDTH), .ADDR_WIDTH(ADDR_WIDTH), .ACCUM_SIZE(ACCUM_SIZE)
) IN_MEM_WR_CTRL(
  .clk            (clk),
  .rstn           (rstn),
  .in_en          (in_en),
  .in_data        (in_data),
  .num_common     (num_common),
  .in_wr_en       (in_wr_en),
  .in_wr_addr     (in_wr_addr),
  .in_wr_data     (in_wr_data),
  .in_row_offset  (in_row_offset)
);

// Accumulator & Controller
accum #(
  .SYS_COL(SYS_COL), .DATA_WIDTH(PSUM_WIDTH), .ACCUM_SIZE(ACCUM_SIZE)
) ACCUM(
  .clk        (clk),
  .rstn       (rstn & accum_rstn),
  .rd_en      ({SYS_COL{1'b1}}),
  .wr_en      (accum_wr_en),
  .rd_addr    (accum_rd_addr),
  .wr_addr    (tot_accum_wr_addr),
  .wr_data    (psum_out),
  .rd_data    (accum_rd_data)
);

accum_wr_ctrl #(
  .SYS_COL(SYS_COL), .ACCUM_ROW(ACCUM_ROW)
) ACCUM_WR_CTRL(
  .clk        (clk),
  .rstn       (rstn),
  .wr_en_in   (en_out[0]),
  .wr_addr_in (accum_wr_addr[$clog2(ACCUM_ROW)-1:0]),
  .wr_en_out  (accum_wr_en),
  .wr_addr_out(tot_accum_wr_addr)
);

// ReLU
relu_arr #(
  .SYS_COL(SYS_COL), .DATA_WIDTH(PSUM_WIDTH)
) RELU(
  .en   (out_wr_en[0]),
  .in   (accum_rd_data),
  .out  (out_wr_data)
);

// Output Memory
out_mem_arr #(
  .NUM_BANK(SYS_COL), .DATA_WIDTH(PSUM_WIDTH)
) OUT_MEM(
  .clk      (clk),
  .rstn     (rstn),
  .rd_en    ({FIFO_WIDTH{1'b1}}),
  .wr_en    (out_wr_en),
  .wr_data  (out_wr_data),
  .rd_addr  (out_rd_addr),
  .wr_addr  (out_wr_addr),
  .rd_data  (out_rd_data)
);

// Main Controller: COMPUTE_CTRL
compute_ctrl #(
  .SYS_ROW(SYS_ROW), .DATA_WIDTH(DATA_WIDTH)
) COMPUTE_CTRL(
  .clk            (clk),
  .rstn           (rstn),
  .en             (compute_ctrl_en),
  .num_row_in     (num_in),
  .drain_done     (drain_done),
  .sys_done       (sys_done),
  .sys_en_out     (en_out[0]),
  .weight_fill    (weight_fill),
  .weight_change  (weight_change),
  .accum_wr_addr  (accum_wr_addr),
  .fifo_in_ctrl_en(fifo_in_en_ctrl),
  .fifo_out_ctrl_en(fifo_out_en),
  .mem_rd_ctrl_en (in_rd_en_in),
  .w_offset_addr  (w_offset_addr)
);

/////////////////////////////////////////////////////////////////////////////////////////
// Master Controller

always_ff @(posedge clk) begin
  state <= m_state;
  fifo_in_en_master <= m_fifo_in_en_master;
  w_base_addr <= m_w_base_addr;

  compute_ctrl_en <= m_compute_ctrl_en;
  weight_fill <= m_weight_fill;
  weight_change <= m_weight_change;
  in_base_addr <= m_in_base_addr;

  repeat_cnt <= m_repeat_cnt;
  num_tile_row <= m_num_tile_row;
  tile_row_cnt <= m_tile_row_cnt;
  tile_col_cnt <= m_tile_col_cnt;

  w_invalid <= m_w_invalid;

  accum_rd_addr <= m_accum_rd_addr;
  accum_rd_en <= m_accum_rd_en;

  out_wr_addr <= m_out_wr_addr;
  out_wr_cnt <= m_out_wr_cnt;
  out_wr_en <= m_out_wr_en;
end

int k;
always_comb begin
  unique case (state)
    IDLE: begin
      m_state = IDLE;

      m_fifo_in_en_master = 1'b0;
      m_w_base_addr = 0;

      m_compute_ctrl_en = 1'b0;
      m_weight_fill = 1'b0;
      m_weight_change = 1'b0;
      m_in_base_addr = 0;

      m_repeat_cnt = 32'd0;
      m_num_tile_row = 0;
      m_tile_row_cnt = 0;
      m_tile_col_cnt = 0;

      accum_rstn = 1'b1;
      for (k = 0; k < SYS_COL; k = k + 1) begin
        m_accum_rd_addr[k] = 0;
        m_out_wr_addr[k] = 0;
      end
      m_accum_rd_en = 0;
      m_out_wr_cnt = 0;
      m_out_wr_en = 0;

      //if (in_done_cnt == (num_common >> $clog2(SYS_ROW)) << $clog2(ACCUM_ROW)) begin
      if (in_row_offset == num_in) begin
        m_state = INIT_W_FILL;
        m_fifo_in_en_master = 1'b1; // OR with fifo_in_ctrl_en of compute_ctrl
        m_w_base_addr = 0;
        m_repeat_cnt = 32'd2; // FIXME: different repeat cnt for various FIFO_DEPTH, current = SYS_ROW * 2
      end
    end
    INIT_W_FILL: begin
      m_state = INIT_W_FILL;

      m_fifo_in_en_master = 1'b0;
      m_w_base_addr = 0;

      m_compute_ctrl_en = 1'b0;
      m_weight_fill = 1'b0;
      m_weight_change = 1'b0;
      m_in_base_addr = in_base_addr;

      m_repeat_cnt = 32'd2;
      m_num_tile_row = 0;
      m_tile_row_cnt = 0;
      m_tile_col_cnt = 0;

      m_w_invalid = {SYS_ROW{1'b0}};

      accum_rstn = 1'b1;
      for (k = 0; k < SYS_COL; k = k + 1) begin
        m_accum_rd_addr[k] = 0;
        m_out_wr_addr[k] = 0;
      end
      m_accum_rd_en = 0;
      m_out_wr_cnt = 0;
      m_out_wr_en = 0;

      if (fill_done) begin
        m_state = COMPUTE;
        m_compute_ctrl_en = 1'b1;
        m_w_base_addr = ADDR_WIDTH'(SYS_COL << 1); // FIXME: assume FIFO_DEPTH = 2 * SYS_COL
        m_in_base_addr = tile_row_cnt << $clog2(ACCUM_ROW);
        m_weight_fill = 1'b1;
        m_weight_change = 1'b1;
      end
    end
    COMPUTE: begin
      m_state = COMPUTE;

      m_fifo_in_en_master = 1'b0;
      m_w_base_addr = w_base_addr;

      m_compute_ctrl_en = 1'b0;
      m_weight_fill = 1'b0;
      m_weight_change = 1'b1;
      m_in_base_addr = in_base_addr;

      m_repeat_cnt = 32'd1;
      m_num_tile_row = num_common >> $clog2(SYS_ROW);
      m_tile_row_cnt = tile_row_cnt;
      m_tile_col_cnt = tile_col_cnt;

      m_w_invalid = {SYS_ROW{1'b0}};

      accum_rstn = 1'b1;
      for (k = 0; k < SYS_COL; k = k + 1) begin
        m_accum_rd_addr[k] = 0;
        m_out_wr_addr[k] = 0;
      end
      m_accum_rd_en = 0;
      m_out_wr_cnt = 0;
      m_out_wr_en = 0;

      if (sys_done) begin
        if ((tile_row_cnt & (m_num_tile_row - 1)) == m_num_tile_row - 1) begin // one tile column done
          m_state = OUT_STORE;
          m_tile_row_cnt = 0;
          //m_tile_row_cnt = tile_row_cnt + 1;
        end else begin
          m_tile_row_cnt = tile_row_cnt + 1;
          m_compute_ctrl_en = 1'b1;
          m_w_base_addr = ADDR_WIDTH'(w_base_addr + SYS_COL);
          m_in_base_addr = (tile_row_cnt + 1) << $clog2(ACCUM_ROW);
        end
        m_w_invalid = {SYS_ROW{1'b1}};
      end
    end
    OUT_STORE: begin
      m_state = OUT_STORE;

      m_fifo_in_en_master = 1'b0;
      m_w_base_addr = w_base_addr;

      m_compute_ctrl_en = 1'b0;
      m_weight_fill = 1'b0;
      m_weight_change = 1'b0;

      m_repeat_cnt = 32'd0;
      m_num_tile_row = 0;
      m_tile_row_cnt = tile_row_cnt;
      m_tile_col_cnt = tile_col_cnt;

      m_w_invalid = {SYS_ROW{1'b0}};

      accum_rstn = 1'b1;
      for (k = 0; k < SYS_COL; k = k + 1) begin
        m_accum_rd_addr[k] = 0;
        m_out_wr_addr[k] = 0;
      end
      m_accum_rd_en = accum_rd_en;
      m_out_wr_cnt = out_wr_cnt;
      m_out_wr_en = out_wr_en;

      if (out_wr_cnt < ACCUM_ROW) begin
        for (k = 0; k < SYS_COL; k = k + 1) begin
          m_out_wr_addr[k] = (out_wr_cnt * (num_out >> $clog2(SYS_COL))) + tile_col_cnt; // FIXME: * is heavy!
          m_accum_rd_addr[k] = out_wr_cnt;
        end
        m_out_wr_en = {SYS_COL{1'b1}};
        m_out_wr_cnt = out_wr_cnt + 1;

        m_accum_rd_en = {SYS_COL{1'b1}};
      end

      if (out_wr_cnt == ACCUM_ROW) begin
        accum_rstn = 1'b0;
        if (tile_col_cnt == (num_out >> $clog2(SYS_COL)) - 1) begin
          m_state = IDLE;
          m_tile_col_cnt = 0;
          m_w_base_addr = 0;
        end else begin
          m_state = COMPUTE;
          m_compute_ctrl_en = 1'b1;
          m_in_base_addr = tile_row_cnt << $clog2(ACCUM_ROW);
          m_w_base_addr = ADDR_WIDTH'(w_base_addr + SYS_COL);
          m_weight_fill = 1'b0;
          m_weight_change = 1'b1;
          m_tile_col_cnt = tile_col_cnt + 1;
        end
      end
      
    end
    default: begin
      m_state = IDLE;

      m_fifo_in_en_master = 1'b0;

      m_compute_ctrl_en = 1'b0;
      m_weight_fill = 1'b0;
      m_weight_change = 1'b0;

      m_repeat_cnt = 32'd0;
      m_num_tile_row = 0;
      m_tile_row_cnt = 0;
      m_tile_col_cnt = 0;
      accum_rstn = 1'b0;

      for (k = 0; k < SYS_COL; k = k + 1) begin
        m_accum_rd_addr[k] = 0;
        m_out_wr_addr[k] = 0;
      end
      m_accum_rd_en = 0;
      m_out_wr_cnt = 0;
      m_out_wr_en = 0;
    end
  endcase

  if (!rstn) begin
      m_state = IDLE;

      m_fifo_in_en_master = 1'b0;

      m_compute_ctrl_en = 1'b0;
      m_weight_fill = 1'b0;
      m_weight_change = 1'b0;

      m_repeat_cnt = 32'd0;
      m_num_tile_row = 0;
      m_tile_col_cnt = 0;
      m_tile_row_cnt = 0;

      m_w_invalid = {SYS_ROW{1'b0}};

      accum_rstn = 1'b0;
      for (k = 0; k < SYS_COL; k = k + 1) begin
        m_accum_rd_addr[k] = 0;
        m_out_wr_addr[k] = 0;
      end
      m_accum_rd_en = 0;
      m_out_wr_cnt = 0;
      m_out_wr_en = 0;
  end
end


/////////////////////////////////////////////////////////////////////////////////////////
assign sys_done = prev_sys_done && !cur_sys_done;

always_ff @(posedge clk) begin
  cur_sys_done <= m_cur_sys_done;
  prev_sys_done <= cur_sys_done;
end

int l;
always_comb begin
  m_cur_sys_done = 0;
  for (l = 0; l < SYS_COL; l = l + 1) begin
    m_cur_sys_done = m_cur_sys_done | en_out[l];
  end
end

endmodule
