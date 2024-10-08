module top_tb;

    timeunit 1ps;
    timeprecision 1ps;
    parameter DATA_WIDTH = 64;
    parameter ADDR_WIDTH = 32;  
    //----------------------------------------------------------------------
    // Waveforms.
    //----------------------------------------------------------------------
    initial begin
        $fsdbDumpfile("dump.fsdb");
        $fsdbDumpvars(0, "+all");
    end

    //----------------------------------------------------------------------
    // Generate the clock.
    //----------------------------------------------------------------------
    bit clk;
    initial clk = 1'b1;
    always #5ns clk = ~clk;


    //----------------------------------------------------------------------
    // Generate the reset.
    //----------------------------------------------------------------------
    bit rst;
    // task do_reset();
    //     rst = 1'b1;
    //     repeat (5) @(posedge clk);
    //     rst = 1'b0;
    // endtask

    
    //----------------------------------------------------------------------
    // DUT instance.
    //----------------------------------------------------------------------
    logic read_request;
    logic write_request;
    logic [ADDR_WIDTH-1:0] read_address;
    logic [ADDR_WIDTH-1:0] write_address;
    logic [DATA_WIDTH-1:0] write_data;
    logic [DATA_WIDTH-1:0] read_data;

    logic axi_valid;
    logic axi_ready;

    logic read_request_mem;
    logic write_request_mem;
    logic [31:0] read_address_mem;
    logic [31:0] write_address_mem;
    logic [63:0] write_data_mem;
    logic [63:0] read_data_mem;
    logic axi_valid_to_mem;
    logic axi_ready_to_mem;

    axi4_lite_top #(
        .DATA_WIDTH(DATA_WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH)
    ) dut (
        .clk(clk),
        .rst(rst),
        .read_request(read_request),
        .write_request(write_request),
        .read_address(read_address),
        .write_address(write_address),
        .write_data(write_data),
        .read_data(read_data),
        .axi_valid(axi_valid),
        .axi_ready(axi_ready),
        .read_request_mem(read_request_mem),
        .write_request_mem(write_request_mem),
        .read_address_mem(read_address_mem),
        .write_address_mem(write_address_mem),
        .write_data_mem(write_data_mem),
        .read_data_mem(read_data_mem),
        .axi_valid_to_mem(axi_valid_to_mem),
        .axi_ready_to_mem(axi_ready_to_mem)
    );

    task do_reset();
        rst = 1'b1;
        read_request = 1'b0;
        write_request = 1'b0;
        write_address = 32'b0;
        write_data = 64'b0;
        axi_valid_to_mem = 1'b0;
        axi_ready_to_mem = 1'b0;
        read_address_mem = 32'b0;
        repeat (5) @(posedge clk);
        rst = 1'b0;
    endtask
    //----------------------------------------------------------------------
    // Verification tasks/functions
    //----------------------------------------------------------------------
    logic   [63:0] last_written_data[1023:0];
    task rand_init();
        for(int i = 0; i < 1024; i++) begin
            last_written_data[i] <= 32'b0; 
        end
        @(posedge clk);
        //check
        for(int i = 0; i < 1024; i++) begin
            assert(last_written_data[i] == 64'b0) else $display("INIT ERROR!");
            //$display("%d,  %h", i, last_written_data[i]);
        end
    endtask


    integer rand_cycle;

    task do_read(input bit [31:0] addr);
        read_request = 1'b1;
        write_address = addr;
        rand_cycle = $urandom_range(10,20);
        repeat(rand_cycle) @(posedge clk);

        axi_valid_to_mem = 1'b1;
        axi_ready_to_mem = 1'b1;
        read_request = 1'b0;
        read_data_mem = 32'habcd1234;


        repeat(3) @(posedge clk);

    endtask


    task do_write(input bit [31:0] addr, input bit [63:0] data);
        write_request = 1'b1;
        write_address = addr;
        write_data = data;
        rand_cycle = $urandom_range(10,20);
        repeat(rand_cycle) @(posedge clk);
        axi_valid_to_mem = 1'b1;
        axi_ready_to_mem = 1'b1;
        write_request = 1'b0;
    endtask


    bit transaction_type;
    bit [31:0] addr_index;
    
    
    //----------------------------------------------------------------------
    // Main process.
    //----------------------------------------------------------------------
    logic [31:0] addr;
    logic [63:0] data;
    initial begin
        $display("start");
        @(posedge clk);
        do_reset();

        @(posedge clk);
        addr = 32'h12345678;
        
        data = 64'habcd1234eceb1234;
        do_read(addr);
        //do_write(addr, data);
        repeat(1000) @(posedge clk);
        
        // end 
        $finish;
    end

    //----------------------------------------------------------------------
    // Timeout.
    //----------------------------------------------------------------------
    initial begin
        #50us;
        $fatal("Timeout!");
    end

endmodule