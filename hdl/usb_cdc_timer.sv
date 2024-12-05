module usb_timer
(
    // setup
    input   logic           usb_clk,
    input   logic           axi_clk,
    input   logic           rst, 
    input   logic           usb_debug_i,
    // ULPI
    input   logic   [7:0]   data_i, //output for ULPI
    input   logic           dir_i,    //output for ULPI
    input   logic           nxt_i,    //output for ULPI
    output  logic   [7:0]   data_o,
    output  logic           stp_o,
    // AXI
    input   logic           bmem_resp,
    output  logic           bmem_wr_en,
    output  logic   [63:0]  bmem_wr_data,
    output  logic   [31:0]  bmem_wr_addr
);
    logic   [63:0]  usb_data;
    logic           usb_data_valid;

    usb_cdc usb_cdc(
        .usb_clk(usb_clk),
        .axi_clk(axi_clk),
        .rst(rst),
        .data_i(data_i),
        .dir_i(dir_i),
        .nxt_i(nxt_i),
        .data_o(data_o),
        .stp_o(stp_o),
        .usb_data_o(usb_data),
        .usb_data_valid_o(usb_data_valid),
        .usb_debug_i(usb_debug_i),
        .*
    );

    timer timer(
        .clk(axi_clk),
        .rst(rst),
        .data_i(usb_data),
        .data_valid(usb_data_valid),
        .bmem_resp(bmem_resp),
        .bmem_wr_en(bmem_wr_en),
        .bmem_wr_data(bmem_wr_data),
        .bmem_wr_addr(bmem_wr_addr),
        .*
    );

endmodule