module usb_top
(
    // setup
    input   logic           usb_clk,
    input   logic           axi_clk,
    input   logic           rst, 
    input   logic           usb_debug_i,
    // ULPI
    // input   logic   [7:0]   data_i, //output for ULPI
    input   logic           dir_i,    //output for ULPI
    input   logic           nxt_i,    //output for ULPI
    // output  logic   [7:0]   data_o,
    inout   wire    [7:0]   data_io,
    output  logic           stp_o,
    // AXI
    input   logic           bmem_resp,
    output  logic           bmem_wr_en,
    output  logic   [63:0]  bmem_wr_data,
    output  logic   [31:0]  bmem_wr_addr
);
    logic   [7:0]   data_o;
    logic   [7:0]   data_i,data_i_pre;

    generate for (genvar i = 0; i<8; i++) begin :tristate_pins
            io_tri USB_data_io (.chipout(data_io[i]), .i(data_i[i]), .o(data_o[i]), .t(dir_i));
            // io_tri USB_data_io (.chipout(data_io[i]), .i(data_o[i]), .o(data_i[i]), .t(dir_i));
    end endgenerate

    // logic rst_i, dir, nxt;
    // input_conditioning rst_cond (.A(rst), .clk(usb_clk), .Y(rst_i));
    // input_conditioning dir_cond (.A(dir_i), .clk(usb_clk), .Y(dir));
    // input_conditioning nxt_cond (.A(nxt_i), .clk(usb_clk), .Y(nxt));

        usb_timer usb_timer(
        .*
        );
    // usb_timer usb_timer(
    //     // .rst(rst_i),
    //     // .nxt_i(nxt),
    //     // .dir_i(dir),
    //     .*
    // );


endmodule