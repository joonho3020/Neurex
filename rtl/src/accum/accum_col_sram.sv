module accum_col_sram #(
  parameter  int unsigned ACCUM_ROW = 256,
  parameter  int unsigned DATA_WIDTH = 32,
  localparam int unsigned ADDR_WIDTH = $clog2(ACCUM_ROW)
) (
  input                   clk,
  input                   rstn,
  input                   rd_en,
  input                   wr_en,
  input [ADDR_WIDTH-1:0]  rd_addr,
  input [ADDR_WIDTH-1:0]  wr_addr,
  input [DATA_WIDTH-1:0]  wr_data,
  output [DATA_WIDTH-1:0] rd_data
);

//logic [DATA_WIDTH-1:0] accum_mem[0:ACCUM_ROW-1];
logic [DATA_WIDTH-1:0] wr_accum_data;

//sram_32x256 m_sram_32x256(
//  .rstn       (rstn),
//  .clka       (clk),
//  .ena        (rd_en),
//  .wea        (1'b0),
//  .addra      (8'(rd_addr)),
//  .dina       ({DATA_WIDTH{1'b0}}),
//  .douta      (rd_data),
//  .clkb       (clk),
//  .enb        (wr_en),
//  .web        (wr_en),
//  .addrb      (8'(wr_addr)),
//  .dinb       (wr_accum_data),
//  .doutb      ()
//);

always_ff @(posedge clk) begin
  if (wr_en) begin
    wr_accum_data <= wr_data + rd_data;
  end
end

endmodule
