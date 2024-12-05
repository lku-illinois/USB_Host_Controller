module usb_host
(
    //ULPI
    input   logic           clk,
    input   logic           rst,

    input   logic           usb_debug_i,

    input   logic   [7:0]   data_i, //output for ULPI
    input   logic           dir_i,    //output for ULPI
    input   logic           nxt_i,    //output for ULPI

    output  logic   [7:0]   data_o,
    output  logic           stp_o,

    //cdc
    output  logic   [63:0]  reg_o,
    output  logic           reg_valid_o
);
    logic           host_connect_w;
    logic           reg_flush;
    logic           reg_push;
    logic   [7:0]   reg_data_i;
    logic           reg_active_read;
    logic   [63:0]  reg_o_tmp;
    logic   [3:0]   reg_count;
    logic           reg_active_IN;
    logic   [63:0]  reg_o1, reg_o2;
    logic           reg_valid_o1, reg_valid_o2;
    logic           debug_valid_start, debug_valid_done;
    logic           nxt_delay, nxt_trigger;

    new_fsm usb_fsm(
        .clk(clk),
        .rst(rst),
        .usb_debug_i(usb_debug_i),
        .data_i(data_i),
        .dir_i(dir_i),
        .nxt_i(nxt_i),
        .data_o(data_o),
        .stp_o(stp_o),
        .host_connect_o(host_connect_w),
        .new_read(reg_flush),
        .data_store_valid(reg_push),
        .data_store_o(reg_data_i),
        .active_read(reg_active_read),
        .active_IN(reg_active_IN),
        .*
    );

    always_ff @( posedge clk ) begin 
        if(rst || reg_flush) begin
            reg_o_tmp <= '0;
            reg_count <= '0;
        end
        // in rx_data + valid input data
        else if(reg_active_read && reg_push) begin
            reg_count <= reg_count + 1'b1;
            reg_o_tmp <= {reg_o_tmp[55:0],reg_data_i};
        end
        // in rx_data + no valid input data
        else begin
            reg_count <= reg_count;
            reg_o_tmp <= reg_o_tmp;
        end
    end

    always_comb begin 
        if(rst || reg_flush || ~host_connect_w) begin
            reg_o1 = '0;
            reg_valid_o1 = '0;
        end
        else if(~reg_active_read && reg_active_IN) begin
            reg_valid_o1 = 1'b1;
            case(reg_count)
                4'd3:   reg_o1 = {reg_o_tmp[23:16], 56'b0};
                4'd4:   reg_o1 = {reg_o_tmp[31:16], 48'b0};
                4'd5:   reg_o1 = {reg_o_tmp[39:16], 40'b0};
                4'd6:   reg_o1 = {reg_o_tmp[47:16], 32'b0};
                4'd7:   reg_o1 = {reg_o_tmp[55:16], 24'b0};
                4'd8:   reg_o1 = {reg_o_tmp[63:16], 16'b0};
                default: reg_o1 = '0;
            endcase
        end
        else begin
            reg_o1 = '0;
            reg_valid_o1 = 1'b0;
        end
    end

    always_ff @( posedge clk ) begin 
        if(rst) reg_o2 <= '0;
        else if(nxt_i) reg_o2 <= {reg_o2[55:0], data_i};
        else reg_o2 <= reg_o2;
    end
    always_ff @( posedge clk ) begin : blockName
        if(rst) nxt_delay <= '0;
        else nxt_delay <= nxt_i;
    end 
    assign debug_valid_start = (nxt_delay==1'b1) && (nxt_i==1'b0) && usb_debug_i;
    assign debug_valid_done = (nxt_delay==1'b0) && (nxt_i==1'b1) && usb_debug_i;
    always_ff @( posedge clk ) begin 
        if(rst) reg_valid_o2 <= '0;
        else if(debug_valid_done) reg_valid_o2 <= '0;
        else if(debug_valid_start)  reg_valid_o2 <= '1;
        else reg_valid_o2 <= reg_valid_o2;
    end

    assign reg_o = usb_debug_i ? reg_o2 : reg_o1;
    assign reg_valid_o = usb_debug_i ? reg_valid_o2 : reg_valid_o1;
endmodule