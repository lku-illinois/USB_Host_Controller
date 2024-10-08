module axi_master (
    input  logic clk,
    input  logic rst,

    //To LLC
    input   logic                           read_request_llc,
    input   logic                           write_request_llc,
    input   logic       [31:0]              write_address_llc,
    input   logic       [63:0]              write_data_llc,

    output  logic       [63:0]              read_data_llc,
    output  logic                           axi_valid,
    output  logic                           axi_ready,
    output  logic       [31:0]              read_address_llc,

    // Write request
    output logic [31:0] AWADDR,
    output logic AWVALID,
    input  logic AWREADY,

    // Write data
    output logic [63:0] WDATA,   
    output logic WVALID,
    input  logic WREADY,

    // Write resp  
    input  logic BVALID,
    output logic BREADY,

    // Read request 
    output logic [31:0] ARADDR,
    output logic ARVALID,
    input  logic ARREADY,

    // Read response
    input  logic [63:0] RDATA,    
    input  logic RVALID,
    output logic RREADY
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
            temp_waddr <= write_address_llc;
            temp_wdata <= write_data_llc;
        end else if (next_state == READ_REQUEST) begin
            //temp_raddr <= read_address_llc; 
        end else if (next_state == READ_RESP) begin
            temp_rdata <= RDATA;
        end
    end
end

always_comb begin
    unique case (state)
    IDLE: begin
        if(axi_ready && write_request_llc && !read_request_llc) begin
            next_state = WRITE_REQUEST;
        end else if (axi_ready && !write_request_llc && read_request_llc) begin
            next_state = READ_REQUEST;
        end else begin
            next_state = IDLE;
        end
    end
    WRITE_REQUEST: begin
        next_state = AWREADY ? WRITE_DATA : WRITE_REQUEST;
    end
    WRITE_DATA: begin
        next_state = BVALID ? WRITE_RESP : WRITE_DATA;
    end
    WRITE_RESP: begin
        next_state = IDLE; 
    end
    READ_REQUEST: begin
        next_state = RVALID ? READ_RESP : READ_REQUEST;
    end
    READ_RESP: begin
        next_state =  IDLE;
    end
    default : begin
        next_state = IDLE;
    end
    endcase
end

always_comb begin
    unique case(state)
    IDLE: begin
        read_data_llc = 64'b0;
        axi_ready = 1'b1;
        axi_valid = 1'b1;
        read_address_llc = 32'b0;

        AWADDR = 32'b0;
        AWVALID = 1'b0;
        
        WDATA = 64'b0;
        WVALID = 1'b0;

        BREADY = 1'b0;

        ARADDR = 32'b0;
        ARVALID = 1'b0;

        RREADY = 1'b0;
    end
    WRITE_REQUEST: begin
        read_data_llc = 64'b0;
        axi_ready = 1'b0;
        axi_valid = 1'b0;
        read_address_llc = 32'b0;

        AWADDR = temp_waddr; 
        AWVALID = 1'b1;
        
        WDATA = 64'b0;
        WVALID = 1'b0;

        BREADY = 1'b0;

        ARADDR = 32'b0;
        ARVALID = 1'b0;

        RREADY = 1'b0;
    end
    WRITE_DATA: begin
        read_data_llc = 64'b0;
        axi_ready = 1'b0;
        axi_valid = 1'b0;
        read_address_llc = 32'b0;

        AWADDR = 32'b0;  
        AWVALID = 1'b0;
        
        WDATA = temp_wdata;
        WVALID = 1'b1;

        BREADY = 1'b0;

        ARADDR = 32'b0;
        ARVALID = 1'b0;

        RREADY = 1'b0;
    end
    WRITE_RESP: begin
        read_data_llc = 64'b0;
        axi_ready = 1'b0;
        axi_valid = 1'b1;
        read_address_llc = 32'b0;

        AWADDR = 32'b0;  
        AWVALID = 1'b0;
        
        WDATA = 64'b0;
        WVALID = 1'b0;

        BREADY = 1'b1;

        ARADDR = 32'b0;
        ARVALID = 1'b0;

        RREADY = 1'b0;
    end
    READ_REQUEST: begin
        read_data_llc = 64'b0;
        axi_ready = 1'b0;
        axi_valid = 1'b0;
        read_address_llc = 32'b0;

        AWADDR = 32'b0;  
        AWVALID = 1'b0;
        
        WDATA = 64'b0;  
        WVALID = 1'b0;

        BREADY = 1'b0;

        ARADDR = temp_raddr; 
        ARVALID = 1'b1;

        RREADY = 1'b1;
    end
    READ_RESP: begin
        read_data_llc = temp_rdata;
        axi_ready = 1'b0;
        axi_valid = 1'b0;
        read_address_llc = 32'b0;

        AWADDR = 32'b0;  
        AWVALID = 1'b0;
        
        WDATA = 64'b0;  
        WVALID = 1'b0;

        BREADY = 1'b0;

        ARADDR = 32'b0; 
        ARVALID = 1'b0;

        RREADY = 1'b1;
    end
    default : begin
        read_data_llc = 64'b0;
        axi_ready = 1'b0;

        AWADDR = 32'b0;  
        AWVALID = 1'b0;
        
        WDATA = 64'b0;  
        WVALID = 1'b0;

        BREADY = 1'b0;

        ARADDR = 32'b0;
        ARVALID = 1'b0;

        RREADY = 1'b0;
    end
    endcase
end
    
endmodule
