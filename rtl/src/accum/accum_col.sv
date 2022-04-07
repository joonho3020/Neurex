module accum_col #(
  parameter  int unsigned ACCUM_ROW = 256,
  parameter  int unsigned DATA_WIDTH = 32,
  localparam int unsigned ADDR_WIDTH = $clog2(ACCUM_ROW)
) (
  input clk,
  input rstn,
  input rd_en,
  input wr_en,
  input [ADDR_WIDTH-1:0] rd_addr,
  input [ADDR_WIDTH-1:0] wr_addr,
  input [DATA_WIDTH-1:0] wr_data,
  output logic [DATA_WIDTH-1:0] rd_data
);

logic [DATA_WIDTH-1:0] accum_mem[0:ACCUM_ROW-1];

int i;
always_ff @(posedge clk) begin
  if (!rstn) begin
    for (i = 0; i < ACCUM_ROW; i = i + 1) begin
      accum_mem[i] <= {DATA_WIDTH{1'b0}};
    end
  end else begin
    if (wr_en) begin
      accum_mem[wr_addr] <= accum_mem[wr_addr] + wr_data;
    end

    if (rd_en) begin
      rd_data <= accum_mem[rd_addr];
    end
  end
end

endmodule
