module timer
(
    // setup
    input   logic           clk,
    input   logic           rst,
    // cdc
    input   logic   [63:0]  data_i,
    input   logic           data_valid,
    // axi
    input   logic           bmem_resp,
    output  logic           bmem_wr_en,
    output  logic   [63:0]  bmem_wr_data,
    output  logic   [31:0]  bmem_wr_addr
);
    localparam TIMER_COUNT = 18'd200000;
    localparam WR_ADDR = 32'h00050000;
    
    logic           data_valid_posedge;
    logic           data_valid_w, data_valid_q;
    logic           new_request_q;
    logic   [17:0]  counter;
    logic           grant;

    // find data valid positive edge
    assign data_valid_w = data_valid;
    always_ff @( posedge clk ) begin 
        if(rst)
            data_valid_q <= '0;
        else 
            data_valid_q <= data_valid_w;
    end
    assign data_valid_posedge = ((data_valid_w==1'b1) && (data_valid_q==1'b0));

    // new request
    always_ff @( posedge clk ) begin 
        if(rst) 
            new_request_q <= 1'b0;
        else if(data_valid_posedge)
            new_request_q <= 1'b1;
        else if(bmem_resp)
            new_request_q <= 1'b0;
        else
            new_request_q <= new_request_q;
    end

    // counter
    always_ff @( posedge clk ) begin 
        if(rst) begin
            counter <= '0;
            grant   <= 1'b0;
        end
        else if(counter == TIMER_COUNT - 18'd1) begin
            counter <= '0;
            grant   <= 1'b1;
        end
        else  begin
            counter <= counter + 18'd1;
            grant   <= '0;
        end
    end

    assign bmem_wr_en = grant && new_request_q;
    assign bmem_wr_data = bmem_wr_en ? data_i : 'x;
    assign bmem_wr_addr = bmem_wr_en ? WR_ADDR : 'x;

endmodule