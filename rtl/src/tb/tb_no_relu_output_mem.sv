module tb_no_relu_output_mem();
parameter SYS_ROW = 4;
parameter SYS_COL = 4;
parameter DATA_WIDTH = 16;
parameter ADDR_WIDTH = 8;
parameter ACCUM_SIZE = 1024;
parameter NUM_ROW = 4; // should test three cases, NUM_ROW {==, >, <} SYS_COL
localparam PSUM_WIDTH = 2 * DATA_WIDTH;
localparam FIFO_WIDTH = SYS_COL;
localparam FIFO_DEPTH = 2*SYS_ROW;
localparam ACCUM_ROW = ACCUM_SIZE / SYS_COL;

// FIFO side inputs
logic clk;
logic rstn;
logic en;
logic [DATA_WIDTH-1:0] w_in[0:FIFO_WIDTH-1];

// MMU side inputs
logic [SYS_COL-1:0] w_wen;

// CTRL side inputs
logic in_rd_en_in;
logic in_wr_en_in, w_wr_en_in;
logic [DATA_WIDTH-1:0] num_row_in, num_row_out;
logic [DATA_WIDTH-1:0] in_num_row, w_num_row;

// MEM side inputs
logic [SYS_ROW-1:0] in_rd_en;
logic [SYS_ROW-1:0] in_wr_en;
logic [DATA_WIDTH-1:0] in_wr_data[0:SYS_ROW-1];
logic [ADDR_WIDTH-1:0] in_rd_addr[0:SYS_ROW-1];
logic [ADDR_WIDTH-1:0] in_wr_addr[0:SYS_ROW-1];

logic [ADDR_WIDTH-1:0] in_base_addr;
logic [ADDR_WIDTH-1:0] w_base_addr;

logic [SYS_ROW-1:0] w_rd_en;
logic [SYS_ROW-1:0] w_wr_en;
logic [DATA_WIDTH-1:0] w_wr_data[0:SYS_ROW-1];
logic [ADDR_WIDTH-1:0] w_rd_addr[0:SYS_ROW-1];
logic [ADDR_WIDTH-1:0] w_wr_addr[0:SYS_ROW-1];

// MEM side outputs
logic [DATA_WIDTH-1:0] in_rd_data[0:SYS_ROW-1];
logic [DATA_WIDTH-1:0] w_rd_data[0:SYS_ROW-1];

// FIFO side outputs
logic [DATA_WIDTH-1:0] w_out[0:FIFO_WIDTH-1];

// MMU side outputs
logic [PSUM_WIDTH-1:0] psum_out [0:SYS_COL-1];
logic [SYS_COL-1:0] en_out;

// CTRL side outputs
logic in_wr_done;
logic w_wr_done;
logic fill_done;

logic fifo_in_en, fifo_out_en;
logic [FIFO_WIDTH-1:0] fifo_in_en_out, fifo_out_en_out;
logic [31:0] repeat_cnt;

logic weight_fill, weight_change;
logic [7:0] accum_wr_addr;
logic compute_ctrl_en;

logic accum_rstn;
logic [7:0] tot_accum_wr_addr[0:SYS_COL-1];
logic [SYS_COL-1:0] accum_wr_en;

logic fifo_data_in;

// Module instantiations
// FIFO
mem_arr #(
  .SYS_ROW(FIFO_WIDTH), .DATA_WIDTH(DATA_WIDTH)
) W_MEM(
  .clk      (clk),
  .rstn     (rstn),
  .rd_en    ({FIFO_DEPTH{1'b1}}),
  .wr_en    (w_wr_en),
  .wr_data  (w_wr_data),
  .rd_addr  (w_rd_addr),
  .wr_addr  (w_wr_addr),
  .rd_data  (w_rd_data)
);

mem_wr_ctrl #(
  .SYS_ROW(FIFO_WIDTH), .SYS_COL(FIFO_DEPTH), .DATA_WIDTH(DATA_WIDTH), .ACCUM_SIZE(ACCUM_SIZE)
) W_WR_CTRL(
  .clk        (clk),
  .rstn       (rstn),
  .wr_en_in   (w_wr_en_in),
  .num_row    (w_num_row),
  .base_addr  (w_base_addr),
  .wr_en_out  (w_wr_en),
  .wr_addr    (w_wr_addr),
  .wr_done    (w_wr_done)
);

fifo_in_ctrl #(
  .FIFO_WIDTH(FIFO_WIDTH), .FIFO_DEPTH(FIFO_DEPTH), .SYS_ROW(SYS_ROW)
) FIFO_IN_CTRL(
  .clk          (clk),
  .rstn         (rstn),
  .en           (fifo_in_en),
  .repeat_cnt   (repeat_cnt),
  .base_addr    (w_base_addr),
  .fifo_en      (fifo_in_en_out),
  .fifo_data_in (fifo_data_in),
  .w_mem_rd_addr(w_rd_addr),
  .w_mem_rd_en  ()
);

fifo_out_ctrl #(
  .SYS_ROW(SYS_ROW), .FIFO_WIDTH(FIFO_WIDTH), .FIFO_DEPTH(FIFO_DEPTH)
) FIFO_OUT_CTRL(
  .clk      (clk),
  .rstn     (rstn),
  .en       (fifo_out_en),
  .fifo_data_in(1'b1),
  .done     (fill_done),
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
  .w_wen    (w_wen),
  .in       (in_rd_data),
  .w_in     (w_out),
  .psum_out (psum_out),
  .en_out   (en_out)
);

// Input Memory
mem_arr #(
  .SYS_ROW(SYS_ROW), .DATA_WIDTH(DATA_WIDTH)
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
  .num_row  (in_num_row),
  .base_addr(in_base_addr),
  .rd_en_out(in_rd_en),
  .rd_addr  (in_rd_addr)
);

mem_wr_ctrl #(
  .SYS_ROW(SYS_ROW), .SYS_COL(SYS_COL), .DATA_WIDTH(DATA_WIDTH), .ACCUM_SIZE(ACCUM_SIZE)
) IN_WR_CTRL(
  .clk        (clk),
  .rstn       (rstn),
  .wr_en_in   (in_wr_en_in),
  .num_row    (in_num_row),
  .base_addr  (in_base_addr),
  .wr_en_out  (in_wr_en),
  .wr_addr    (in_wr_addr),
  .wr_done    (in_wr_done)
);

// Accumulator
accum #(
  .SYS_COL(SYS_COL), .DATA_WIDTH(2*DATA_WIDTH), .ACCUM_SIZE(ACCUM_SIZE)
) ACCUM(
  .clk        (clk),
  .rstn       (rstn),
  .rd_en      (),
  .wr_en      (accum_wr_en),
  .rd_addr    (),
  .wr_addr    (tot_accum_wr_addr),
  .wr_data    (psum_out),
  .rd_data    ()
);

accum_wr_ctrl #(
  .SYS_COL(SYS_COL), .ACCUM_ROW(ACCUM_ROW)
) ACCUM_WR_CTRL(
  .clk        (clk),
  .rstn       (rstn | accum_rstn),
  .wr_en_in   (en_out[0]),
  .wr_addr_in (accum_wr_addr),
  .wr_en_out  (accum_wr_en),
  .wr_addr_out(tot_accum_wr_addr)
);

// Main controller: compute_ctrl
compute_ctrl #(
  .DATA_WIDTH(DATA_WIDTH)
) COMPUTE_CTRL(
  .clk            (clk),
  .rstn           (rstn),
  .en             (compute_ctrl_en),
  .num_row_in     (num_row_in),
  .fill_done      (fill_done),
  .sys_done       (en_out[0]),
  .weight_fill    (weight_fill),
  .weight_change  (weight_change),
  .accum_wr_addr  (accum_wr_addr),
  .num_row_out    (num_row_out),
  .fifo_out_ctrl_en(fifo_out_en),
  .mem_rd_ctrl_en (in_rd_en_in)
);

always begin
  #5;
  clk = ~clk;
end

int i, j;
task full_test();
  clk = 1'b1;
  rstn = 1'b0;
  for (i = 0; i < SYS_ROW; i = i + 1) begin
    in_wr_data[i] = 0;
    w_wr_data[i] = 0;
  end
  in_wr_en_in = 1'b0;
  w_wr_en_in = 1'b0;
  compute_ctrl_en = 1'b0;
  fifo_in_en = 1'b0;

  #10;
  rstn = 1'b1;

  #10;
  in_num_row = SYS_COL; // M = K = N
  w_num_row = SYS_COL;
  
  #10;
  // Write weight to weight memory
  w_wr_en_in <= 1'b1;
  w_base_addr <= 0;
  #10;
  for (i = 0; i < 2*SYS_ROW; i = i + 1) begin
    #10;
    for (j = 0; j < SYS_COL; j = j + 1) begin
      w_wr_data[j] <= j + 1; // is it okay? unrolling issue
    end
  end
  #10;
  w_wr_en_in <= 1'b0;

  wait(w_wr_done);
  #20;
  
  // Write input to input memory
  in_wr_en_in <= 1'b1;
  in_base_addr <= 0;
  #10;
  for (i = 0; i < NUM_ROW; i = i + 1) begin
    #10;
    for (j = 0; j < SYS_ROW; j = j + 1) begin
      in_wr_data[j] <= 4 * j + i;
    end
  end
  #10;
  in_wr_en_in <= 1'b0;

  wait(in_wr_done);

  
  #10;
  // Fill weight to FIFO
  fifo_in_en <= 1'b1;
  repeat_cnt <= 32'd2;
  #10;
  fifo_in_en <= 1'b0;

  #100;
  // Start compute controller
  compute_ctrl_en <= 1'b1;
  num_row_in <= SYS_COL;
  weight_fill <= 1'b1; // fill weight
  weight_change <= 1'b1;  // weight double buffering

  #10;
  compute_ctrl_en <= 1'b0;
  weight_fill <= 1'b0;
  weight_change <= 1'b0;
  
  wait(en_out[0]);
  $stop;
endtask

initial begin
  full_test();
end

endmodule
