module axi_slave (
    input  logic clk,
    input  logic rst,

    //To MEM
    output   logic                           read_request_mem,
    output   logic                           write_request_mem,
    output   logic       [31:0]              write_address_mem,
    output   logic       [63:0]              write_data_mem,

    input    logic       [63:0]              read_data_mem,
    input    logic                           axi_valid_to_mem, //bmem_rvalid
    input    logic                           axi_ready_to_mem, // modified here!!!
    input    logic       [31:0]              read_address_mem,
    // write request
    input  logic [31:0] AWADDR,
    input  logic AWVALID,
    output logic AWREADY,

    // Write data
    input  logic [63:0] WDATA,   
    input  logic WVALID,
    output logic WREADY,

    // Write response
    output logic BVALID,
    input  logic BREADY,

    // read request
    input  logic [31:0] ARADDR,
    input  logic ARVALID,
    output logic ARREADY,

    // read data
    output logic [63:0] RDATA,   
    output logic RVALID,
    input  logic RREADY
);

//---- FSM state modification ----// 
localparam IDLE = 0, WRITE_REQUEST = 1, WRITE_DATA = 2, WRITE_RESP = 3, READ_REQUEST = 4, READ_RESP = 5;
logic   [2:0]   state, next_state;
always_ff @(posedge clk) begin
    if(rst) begin
        state <= IDLE;
    end else begin
        state <= next_state;
    end
end

//---- lock the data ----//
reg [31:0] temp_waddr, temp_raddr;
reg [63:0] temp_wdata, temp_rdata;
always_ff @(posedge clk) begin
    if(rst) begin
        temp_waddr <= 'd0;
        temp_wdata <= 'd0;
        temp_raddr <= 'd0; 
        temp_rdata <= 'd0;
    end else begin
        if (next_state == WRITE_REQUEST) begin
            temp_waddr <= AWADDR;
        end if(next_state == WRITE_DATA) begin 
            temp_wdata <= WDATA;
        end else if (next_state == READ_REQUEST) begin
            temp_raddr <= ARADDR; 
        end else if (next_state == READ_RESP) begin
            temp_rdata <= RDATA;
        end
    end
end


always_comb begin
    unique case (state)
    IDLE: begin
        if(!ARVALID && AWVALID) begin
            next_state = WRITE_REQUEST;
        end else if (ARVALID && !AWVALID) begin
            next_state = READ_REQUEST;
        end else begin
            next_state = IDLE;
        end
    end
    WRITE_REQUEST: begin
        next_state = WRITE_DATA;
    end
    WRITE_DATA: begin
        next_state = axi_valid_to_mem ? WRITE_RESP : WRITE_DATA;
    end
    WRITE_RESP: begin
        next_state = IDLE;
    end
    READ_REQUEST: begin
        next_state = axi_valid_to_mem ? READ_RESP: READ_REQUEST;
    end
    READ_RESP: begin
        next_state =  RREADY ? IDLE : READ_RESP ;
    end
    default : begin
        next_state = IDLE;
    end
    endcase
end
logic   ARREADY_reg;
logic ARREADY_temp;
always_ff  @(posedge clk) begin
    if(rst)begin
        ARREADY_reg <= 1'b0;
    end else begin
        ARREADY_reg <= ARREADY_temp;
    end
end

//assign ARREADY = ARREADY_reg;


always_comb begin
    unique case(state)
    IDLE: begin
        read_request_mem = 1'b0;
        write_request_mem = 1'b0;
        
        write_address_mem = 32'b0;
        write_data_mem = 64'b0;

        AWREADY =1'b1;

        WREADY = 1'b0;

        BVALID = 1'b0;
        
        if((AWVALID || ARVALID) ) begin
            ARREADY = 1'b0;
        end  else begin
            ARREADY = 1'b1;
        end
        //ARREADY = 1'b1;

        RDATA = 64'b0;
        RVALID = 1'b0;
    end
    WRITE_REQUEST: begin
        read_request_mem = 1'b0;
        write_request_mem = 1'b0;
        
        write_address_mem = 32'b0;
        write_data_mem = 64'b0;
        

        AWREADY =1'b0;

        WREADY = 1'b1;

        BVALID = 1'b0;

        ARREADY = 1'b0;

        RDATA = 64'b0;
        RVALID = 1'b0;
    end
    WRITE_DATA: begin
        read_request_mem = 1'b0;
        write_request_mem = 1'b1;
        
        write_address_mem = temp_waddr;
        write_data_mem = temp_wdata;
        

        AWREADY =1'b0;

        WREADY = 1'b0;

        BVALID = 1'b0;

        ARREADY = 1'b0;

        RDATA = 64'b0;
        RVALID = 1'b0;
    end
    WRITE_RESP: begin
        read_request_mem = 1'b0;
        write_request_mem = 1'b0;
        
        write_address_mem = 32'b0;
        write_data_mem = 64'b0;
        

        AWREADY =1'b0;

        WREADY = 1'b0;

        BVALID = 1'b1;

        ARREADY = 1'b1;

        RDATA = 64'b0;
        RVALID = 1'b0;
    end
    READ_REQUEST: begin
        read_request_mem = 1'b1;
        write_request_mem = 1'b0;
        
        write_address_mem = 32'b0;
        write_data_mem = 64'b0;
        

        AWREADY =1'b0;

        WREADY = 1'b0;

        BVALID = 1'b0;

        ARREADY = 1'b0;

        RDATA = 64'b0;
        RVALID = 1'b0;
    end
    READ_RESP: begin
        read_request_mem = 1'b0;
        write_request_mem = 1'b0;
        
        write_address_mem = 32'b0;
        write_data_mem = 64'b0;
        

        AWREADY =1'b0;

        WREADY = 1'b0;

        BVALID = 1'b0;

        ARREADY = 1'b0;

        RDATA = read_data_mem;
        RVALID = 1'b1;
    end
    default : begin
        read_request_mem = 64'b0;
        write_request_mem = 1'b0;
        
        write_address_mem = 32'b0;
        write_data_mem = 64'b0;
    

        AWREADY =1'b0;

        WREADY = 1'b0;

        BVALID = 1'b0;

        ARREADY = 1'b0;

        RDATA = 64'b0;
        RVALID = 1'b0;
    end
    endcase
end

endmodule
