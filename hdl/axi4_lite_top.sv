module axi4_lite_top#(
    parameter DATA_WIDTH = 64,
    parameter ADDR_WIDTH = 32
    )(
        input   logic                           clk,
        input   logic                           rst,
        //---------- TO CPU LLC ------------//
        input   logic                           read_request,
        input   logic                           write_request,
        input   logic       [ADDR_WIDTH-1:0]    write_address,
        input   logic       [DATA_WIDTH-1:0]    write_data,

        output  logic       [DATA_WIDTH-1:0]    read_data,
        output  logic                           axi_valid,
        output  logic                           axi_ready,
        output  logic       [ADDR_WIDTH-1:0]    read_address,
        //-----------TO MEMORY -------------//

        output   logic                           read_request_mem,
        output   logic                           write_request_mem,
        output   logic       [31:0]              write_address_mem,
        output   logic       [63:0]              write_data_mem,

        input    logic       [63:0]              read_data_mem,
        input    logic                           axi_valid_to_mem, //bmem_rvalid
        input    logic                           axi_ready_to_mem,// modified here!!!
        input    logic       [31:0]              read_address_mem
    );
    



    
    logic [31:0]    AWADDR;
    logic           AWVALID;
    logic           AWREADY;
    logic [63:0]    WDATA;
    logic           WVALID;
    logic           WREADY;
    logic           BVALID;
    logic           BREADY;
    logic [31:0]    ARADDR;
    logic           ARVALID;
    logic           ARREADY;
    logic [63:0]    RDATA;
    logic           RVALID;
    logic           RREADY;

    //--------INSTANT AND CONNECTION-----//
    axi_master master(
        .clk(clk),
        .rst(rst),
        .AWADDR(AWADDR),
        .AWVALID(AWVALID),
        .AWREADY(AWREADY),
        .WDATA(WDATA),
        .WVALID(WVALID),
        .WREADY(WREADY),
        .BVALID(BVALID),
        .BREADY(BREADY),
        .ARADDR(ARADDR),
        .ARVALID(ARVALID),
        .ARREADY(ARREADY),
        .RDATA(RDATA),
        .RVALID(RVALID),
        .RREADY(RREADY), 

        .read_request_llc(read_request), 
        .write_request_llc(write_request),
        .read_address_llc(read_address),
        .write_address_llc(write_address),
        .write_data_llc(write_data),
        .read_data_llc(read_data),
        .axi_valid(axi_valid),
        .axi_ready(axi_ready)





    );

    axi_slave slave(
        .clk(clk),
        .rst(rst),
        .AWADDR(AWADDR),
        .AWVALID(AWVALID),
        .AWREADY(AWREADY),
        .WDATA(WDATA),
        .WVALID(WVALID),
        .WREADY(WREADY),
        .BVALID(BVALID),
        .BREADY(BREADY),
        .ARADDR(ARADDR),
        .ARVALID(ARVALID),
        .ARREADY(ARREADY),
        .RDATA(RDATA),
        .RVALID(RVALID),
        .RREADY(RREADY),


        .read_request_mem(read_request_mem),
        .write_request_mem(write_request_mem),
        .read_address_mem(read_address_mem),
        .write_address_mem(write_address_mem),
        .write_data_mem(write_data_mem),
        .read_data_mem(read_data_mem),
        .axi_valid_to_mem(axi_valid_to_mem),
        .axi_ready_to_mem(axi_ready_to_mem)
    );



endmodule