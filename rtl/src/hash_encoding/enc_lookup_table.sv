module enc_lookup_table #(
  parameter  int unsigned TABLE_ROW = 32,
  parameter  int unsigned TABLE_COL = 128,
  parameter  int unsigned DATA_WIDTH = 32,
  parameter  int unsigned NUM_BANK = 8,

  localparam IDLE  = 1'b0,
  localparam ALLOC = 1'b1
) (
  input clk,
  input rstn,
  input [1:0] record_en, // 0: disabled, 1: new allocate, 2: already allocated, use target_row_id
  input sent_en,
  input return_en,
  input check_en,
  input invalid_en,
  input [NUM_BANK-1:0] feat_wr_en,
  input feat_rd_en,
  input idx_rd_en,
  input [DATA_WIDTH-1:0] target_row_id, // record / return / check / free : only one operation at a time
  input [DATA_WIDTH-1:0] target_col_id, // record / return / check / free : only one operation at a time
  input [DATA_WIDTH-1:0] feat_wr_data, // granularity: 4B
  input [DATA_WIDTH-1:0] hash_indices[0:NUM_BANK-1], // FIXME: 32B
  input [TABLE_COL-1:0] sent_in,
  input [DATA_WIDTH-1:0] ret_num, // How many hash encoding features are returned?

  output [DATA_WIDTH-1:0] feat_rd_data[0:NUM_BANK-1],
  output [DATA_WIDTH-1:0] idx_rd_data[0:NUM_BANK-1],
  output full,
  output all_returned,
  output logic allocated,
  output logic [DATA_WIDTH-1:0] alloc_row_id
);

logic state, m_state;
logic m_allocated;

logic [TABLE_ROW-1:0] valid, m_valid;

logic [TABLE_ROW-1:0] sent_en_inter, m_sent_en;
logic [TABLE_COL-1:0] sent_in_inter[0:TABLE_ROW-1], m_sent_in[0:TABLE_ROW-1];

logic [TABLE_ROW-1:0] check_en_inter, m_check_en;

logic [TABLE_ROW-1:0] return_en_inter, m_return_en;
logic [DATA_WIDTH-1:0] ret_num_inter[0:TABLE_ROW-1], m_ret_num[0:TABLE_ROW-1];
logic [TABLE_ROW-1:0] all_returned_inter;

logic [DATA_WIDTH-1:0] m_alloc_row_id;
logic [NUM_BANK-1:0] idx_wr_en, m_idx_wr_en;
logic [NUM_BANK-1:0] idx_rd_en_inter, m_idx_rd_en;
logic [DATA_WIDTH-1:0] idx_wr_addr[0:NUM_BANK-1], idx_rd_addr, m_idx_wr_addr[0:NUM_BANK-1], m_idx_rd_addr;
logic [DATA_WIDTH-1:0] idx_wr_data[0:TABLE_ROW-1], m_idx_wr_data[0:TABLE_ROW-1];
logic [DATA_WIDTH-1:0] m_hash_indices[0:TABLE_ROW-1], hash_indices_inter[0:TABLE_ROW-1];

logic [NUM_BANK-1:0] feat_wr_en_inter, m_feat_wr_en;
logic [NUM_BANK-1:0] feat_rd_en_inter, m_feat_rd_en;
logic [DATA_WIDTH-1:0] feat_wr_addr, feat_rd_addr, m_feat_wr_addr, m_feat_rd_addr;
logic [DATA_WIDTH-1:0] feat_wr_data_inter[0:TABLE_ROW-1], m_feat_wr_data[0:TABLE_ROW-1];

assign full = &valid;
assign all_returned = (check_en == 1'b1) ? all_returned_inter[target_row_id] : 1'b0;

genvar i;
generate
  for (i = 0; i < NUM_BANK; i = i + 1) begin : feat
    sram_32x4096 m_sram_32x4096( // TABLE_COL / NUM_BANK * BATCH_SIZE = 2^12
      .clka       (clk),
      .ena        (feat_rd_en_inter[i]),
      .wea        (1'b0),
      .addra      (8'(feat_rd_addr[i])),
      .dina       (),
      .douta      (feat_rd_data[i]),
      .clkb       (clk),
      .enb        (feat_wr_en_inter[i]),
      .web        (feat_wr_en_inter[i]),
      .addrb      (8'(feat_wr_addr)),
      .dinb       (feat_wr_data_inter),
      .doutb      ()
    );
  end

  for (i = 0; i < NUM_BANK; i = i + 1) begin : idx
    sram_32x4096 m_sram_32x4096( // TABLE_COL / NUM_BANK * BATCH_SIZE = 2^12
      .clka       (clk),
      .ena        (idx_rd_en_inter[i]),
      .wea        (1'b0),
      .addra      (8'(idx_rd_addr)),
      .dina       (),
      .douta      (idx_rd_data[i]),
      .clkb       (clk),
      .enb        (idx_wr_en[i]),
      .web        (idx_wr_en[i]),
      .addrb      (8'(idx_wr_addr[i])),
      .dinb       (idx_wr_data[i]),
      .doutb      ()
    );
  end

  for (i = 0; i < TABLE_ROW; i = i + 1) begin : row
    enc_lookup_row #(
      .TABLE_COL(TABLE_COL), .DATA_WIDTH(DATA_WIDTH)
    ) m_enc_lookup_row(
      .clk(clk),
      .sent_en(sent_en_inter[i]),
      .return_en(return_en_inter[i]),
      .sent_in(sent_in_inter[i]),
      .ret_num(ret_num_inter[i]),
      .all_returned(all_returned_inter[i])
    );
  end
endgenerate

always_ff @(posedge clk) begin
  state <= m_state;

  allocated <= m_allocated;
  alloc_row_id <= m_alloc_row_id;

  idx_wr_en <= m_idx_wr_en;
  idx_wr_addr <= m_idx_wr_addr;
  idx_wr_data <= m_idx_wr_data;
  hash_indices_inter <= m_hash_indices;

  idx_rd_en_inter <= m_idx_rd_en;
  idx_rd_addr <= m_idx_rd_addr;

  feat_wr_en_inter <= m_feat_wr_en;
  feat_wr_addr <= m_feat_wr_addr;
  feat_wr_data_inter <= m_feat_wr_data;

  feat_rd_en_inter <= m_feat_rd_en;
  feat_rd_addr <= m_feat_rd_addr;

  return_en_inter <= m_return_en;
  ret_num_inter <= m_ret_num;

  sent_en_inter <= m_sent_en;
  sent_in_inter <= m_sent_in;
end

// Index allocation
int j, k;
always_comb begin
  unique case (state)
    IDLE: begin
      m_state = IDLE;
      m_allocated = 1'b0;
      m_alloc_row_id = alloc_row_id;
      m_idx_wr_addr = idx_wr_addr;
      m_idx_wr_data = idx_wr_data;
      // New allocation
      if (record_en == 2'b01) begin // FIXME: could be heavy...
        m_hash_indices = hash_indices;
        for (j = 0; j < TABLE_ROW; j = j + 1) begin
          if (valid[j] == 1'b0) break;
        end
        if (j == TABLE_ROW) m_state = IDLE;
        else begin
          m_state = ALLOC;
          m_allocated = 1'b1;
          m_alloc_row_id = j;
        end
      end else if (record_en == 2'b11) begin // Already allocated
        m_idx_wr_en = {NUM_BANK{1'b1}};
        for (k = 0; k < NUM_BANK; k = k + 1) begin
          m_idx_wr_addr[k] = target_row_id << $clog2(TABLE_COL / NUM_BANK) + target_col_id;
          m_idx_wr_data[k] = hash_indices[k];
        end
      end
    end
    ALLOC: begin
      m_state = IDLE;
      m_idx_wr_en = {NUM_BANK{1'b1}};
      for (k = 0; k < NUM_BANK; k = k + 1) begin
        m_idx_wr_addr[k] = alloc_row_id << $clog2(TABLE_COL / NUM_BANK) + target_col_id;
        m_idx_wr_data[k] = hash_indices_inter[k];
      end
    end
  endcase
end

// Feature allocation
always_comb begin
  m_feat_wr_en = {NUM_BANK{1'b0}};
  m_feat_wr_addr = feat_wr_addr;
  m_feat_wr_data = feat_wr_data_inter;

  if (|feat_wr_en == 1'b1) begin
    m_feat_wr_en = feat_wr_en;
    m_feat_wr_addr = target_row_id << $clog2(TABLE_COL / NUM_BANK) + target_col_id;
    m_feat_wr_data = feat_wr_data;
  end
end

// Index read
always_comb begin
  m_idx_rd_en = {NUM_BANK{1'b0}};
  m_idx_rd_addr = idx_rd_addr;

  if (idx_rd_en) begin
    m_idx_rd_en = {NUM_BANK{1'b1}};
    m_idx_rd_addr = target_row_id << $clog2(TABLE_COL / NUM_BANK) + target_col_id;
  end
end

// Feature read
always_comb begin
  m_feat_rd_en = {NUM_BANK{1'b0}};
  m_feat_rd_addr = feat_rd_addr;

  if (feat_rd_en) begin
    m_feat_rd_en = {NUM_BANK{1'b1}};
    m_feat_rd_addr = target_row_id << $clog2(TABLE_COL / NUM_BANK) + target_col_id;
  end
end

always_comb begin
  m_return_en = 0;
  m_ret_num = ret_num_inter;
  if (return_en) begin
    m_return_en[target_row_id] = 1'b1;
    m_ret_num[target_row_id] = ret_num;
  end
end

always_comb begin
  m_valid = valid;
  if (invalid_en) begin
    m_valid[target_row_id] = 1'b0;
  end

  if (state == ALLOC) begin
    m_valid[alloc_row_id] = 1'b1;
  end

  if (!rstn) begin
    m_valid = 0;
  end
end

always_comb begin
  m_sent_en = 0;
  m_sent_in = sent_in_inter;
  if (sent_en) begin
    m_sent_en[target_row_id] = 1'b1;
    m_sent_in[target_row_id] = sent_in;
  end
end

endmodule
