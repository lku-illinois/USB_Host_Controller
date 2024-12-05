module top_tb;

    timeunit 1ps;
    timeprecision 1ps;
    
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
    bit usb_clk;
    initial begin
        #5ns;
        usb_clk = 1'b1;
        forever #8.33ns usb_clk = ~usb_clk;
    end
    // initial usb_clk = 1'b1;
    // always #8.33ns usb_clk = ~usb_clk;

    bit axi_clk;
    initial axi_clk = 1'b1;
    always #2.5ns axi_clk = ~axi_clk;
    
    logic           rst;
    logic           usb_debug_i;
    //logic   [7:0]   data_tmp;
    logic           dir_i;
    logic           nxt_i;
    //logic   [7:0]   data_io;
    logic           stp_o;
    logic           bmem_resp;
    logic           bmem_wr_en;
    logic   [63:0]  bmem_wr_data;
    logic   [31:0]  bmem_wr_addr;
    
    logic   [7:0]   data_tmp;
    wire    [7:0]   data_io;


    usb_top dut(
        .*
    );


    assign data_io = dir_i ? data_tmp : 'z;

    task do_setup();
        $display("setup");
        rst <= 1'b1;
        // data_tmp <= 8'b0;
        // data_tmp <= 1'b0;
        usb_debug_i <= 1'b0;
        bmem_resp <= 1'b0;
        dir_i <= 1'b0;
        nxt_i <= 1'b0;
        repeat(3) @(posedge usb_clk);
        rst <= 1'b0;
        @(posedge usb_clk);
    endtask;
    localparam DATA_J_LINE_STATE = 8'b00000001;
    localparam DATA_ALL_0 = 'x;
    localparam DATA_OUT_SETUP_ADDRESS = 8'b01001101; //ULPI must start at 0100 + PID
    localparam DATA_OUT_SETUP_DATA0 =8'B01000011;
    localparam DATA_OUT_SETUP_CONFIG = 8'b01001101;
    localparam DATA_OUT_SEND_ACK = 8'b01000010;
    localparam DATA_OUT_SEND_ACK_RX_CMD = 8'b00001001;//CHECK Linestate
    localparam DATA_OUT_IN_TOKEN = 8'h49;
    localparam DATA_OUT_DISCONNECT = 8'b00100000;// 5:4 10, Linestate 00
    localparam DATA_SOF = 8'b01000101;
    localparam DATA_OUT_RX_CMD_FILLING = 8'b00010000;
    task connect_device();//checked!
        // $display("connect device start");
        dir_i <= 1'b1;
        // data_tmp <= 8'b0;
        nxt_i <= 1'b0;
        @(posedge usb_clk);// turn around cycle
        data_tmp <= DATA_J_LINE_STATE;
        @(posedge usb_clk);//line state J cycle
        dir_i <= 1'b0;
        data_tmp <= DATA_ALL_0;// dir_i = 0, nxt_i = 0; 
        $display("connect device done");
    endtask

    task sof();
        // forever begin //detected that setup TX CMD 
        //     if(data_io == DATA_SOF) begin
        //         break;
        //     end
        // end
        wait (data_io == DATA_SOF);
        if(data_io == DATA_SOF) begin
            // nxt_i <= 1'b0;
            @(posedge usb_clk); 
            nxt_i <= 1'b1;
            //todo assertion check TX_CMD
            //asserted(data_io == )
            @(posedge usb_clk);
            //todo assertion check ADDR + ENP
            //asserted(data_io == )
            @(posedge usb_clk);
            //todo assertion check ENP + CRC5
            //asserted(data_io == )
            // $display("pass sof");
            forever begin
                @(posedge usb_clk);
                if(stp_o) begin
                    nxt_i <= 1'b0;
                    break;
                end
            end
            $display("pass sof");
        end
    endtask



    task device_setup_address_PID();
        // forever begin //detected that setup TX CMD 
        //     if(data_io == DATA_OUT_SETUP_ADDRESS) begin
        //         break;
        //     end
        // end
        wait(data_io == DATA_OUT_SETUP_ADDRESS);
        $display("setup PID");
        @(posedge usb_clk); 
        nxt_i <= 1'b1;
        //todo assertion check TX_CMD
        //asserted(data_io == )
        @(posedge usb_clk);
        //todo assertion check ADDR + ENP
        //asserted(data_io == )
        @(posedge usb_clk);
        //todo assertion check ENP + CRC5
        //asserted(data_io == )
        $display("pass address pid");
        forever begin
            @(posedge usb_clk);
            if(stp_o) begin
                nxt_i <= 1'b0;
                break;
            end
        end
    endtask

    task device_setup_address_data();
        // forever begin //detect TX_CMD
        //     if(data_io == DATA_OUT_SETUP_DATA0) begin
        //        nxt_i <= 1'b1; 
        //        break;
        //     end
        // end
        //todo
        wait(data_io == DATA_OUT_SETUP_DATA0);
        @(posedge usb_clk);
        nxt_i <= 1'b1;// receive TX CMD
        forever begin
            @(posedge usb_clk);
            if(stp_o) begin //8 byte data(setup config)
                nxt_i <= 1'b0;
                break;
            end
        end
    endtask

    task device_setup_config_PID();
        // forever begin
        //     if(data_io == DATA_OUT_SETUP_CONFIG) begin
        //         break;
        //     end
        // end
        
        @(data_io == DATA_OUT_SETUP_CONFIG);
        if(data_io == DATA_OUT_SETUP_CONFIG) begin
            $display("pass config pid1111");
            @(posedge usb_clk); 
            nxt_i <= 1'b1;
            //todo assertion check TX_CMD
            //asserted(data_io == )
            @(posedge usb_clk);
            //todo assertion check ADDR + ENP
            //asserted(data_io == )
            @(posedge usb_clk);
            //todo assertion check ENP + CRC5
            //asserted(data_io == )
            $display("pass config pid");
            @(stp_o); 
            @(posedge usb_clk);   
            nxt_i <= 1'b0;
                    
                
        
        end
    endtask

    task device_setup_config_data();
        @(data_io == 8'h43); 
        nxt_i <= 1'b0; 
        @(posedge usb_clk);
        nxt_i <= 1'b1; 
        $display("pass config data");
        @(posedge usb_clk);
        nxt_i <= 1'b1;// receive TX CMD
        @(stp_o); 
        @(posedge usb_clk);   
        nxt_i <= 1'b0;;
        $display("pass config data1111");
    endtask

    task Device2Host_ACK();
        dir_i <= 1'b1;
        @(posedge usb_clk); //turn around
        nxt_i <= 1'b1;
        data_tmp <= DATA_OUT_SEND_ACK; //sending ACK PID
        @(posedge usb_clk);
        dir_i <= 1'b0;
        nxt_i <= 1'b0;
        data_tmp <= DATA_ALL_0;
        @(posedge usb_clk);
        
    endtask

    task Host2Device_ACK();
        dir_i <= 1'b0;
        //todo assertion;
        
        @(data_io == DATA_OUT_SEND_ACK) 
        @(posedge usb_clk);
        nxt_i <= 1'b1; 
        @(posedge usb_clk);
        nxt_i <= 1'b0;   
    endtask

    task Host2Device_INtoken();
        
        wait (data_io == DATA_OUT_IN_TOKEN);
        // if(data_io == DATA_OUT_IN_TOKEN) begin
            // $display("caonima");
            // @(posedge usb_clk);  
            // nxt_i <= 1'b1; 
            // @(stp_o == 1'b1);
            // @(posedge usb_clk);
            // nxt_i <= 1'b0; 
        // end 
        dir_i <= 1'b0;
        $display("caonima");
        @(posedge usb_clk);  
        nxt_i <= 1'b1; 
        @(stp_o == 1'b1);
        @(posedge usb_clk);
        nxt_i <= 1'b0; 
    endtask
    task Host2Device_INtoken_delay();
        dir_i <= 1'b0;
        @(posedge usb_clk);  
        nxt_i <= 1'b1; 
        @(stp_o == 1'b1);
        @(posedge usb_clk);
        nxt_i <= 1'b0; 
               
    endtask
    

    task Device2Host_intrrupt_send1();
        nxt_i <= 1'b0;
        dir_i <= 1'b1;
        @(posedge usb_clk);

        data_tmp <= DATA_OUT_SETUP_DATA0; //PID0;
        nxt_i <= 1'b1;
        @(posedge usb_clk);

        data_tmp <= 8'h11;//make up transaction;
        @(posedge usb_clk);
        data_tmp <= 8'h12;//make up transaction;
        @(posedge usb_clk);
        data_tmp <= 8'h13;//make up transaction;
        @(posedge usb_clk);
        data_tmp <= 8'h14;//make up transaction;
        @(posedge usb_clk);
        data_tmp <= 8'h15;//make up transaction;
        @(posedge usb_clk);

        data_tmp <= 8'hff;//crc16;
        @(posedge usb_clk);
        data_tmp <= 8'hff;//crc16;
        @(posedge usb_clk);

        data_tmp <= DATA_OUT_SEND_ACK_RX_CMD; // rx_cmd
        nxt_i <= 1'b0;
        dir_i <= 1'b1;
        @(posedge usb_clk);// TURNAROUND

        nxt_i <= 1'b0;
        dir_i <= 1'b0;
        data_tmp <= DATA_ALL_0;
        @(posedge usb_clk);
    endtask
    task Device2Host_intrrupt_send2();
        nxt_i <= 1'b0;
        dir_i <= 1'b1;
        @(posedge usb_clk);

        data_tmp <= DATA_OUT_SETUP_DATA0; //PID0;
        nxt_i <= 1'b1;
        @(posedge usb_clk);

        data_tmp <= 8'h21;//make up transaction;
        @(posedge usb_clk);
        data_tmp <= 8'h22;//make up transaction;
        @(posedge usb_clk);
        data_tmp <= 8'h23;//make up transaction;
        @(posedge usb_clk);
        data_tmp <= 8'h24;//make up transaction;
        @(posedge usb_clk);
        data_tmp <= 8'h25;//make up transaction;
        @(posedge usb_clk);

        data_tmp <= 8'hff;//crc16;
        @(posedge usb_clk);
        data_tmp <= 8'hff;//crc16;
        @(posedge usb_clk);

        data_tmp <= DATA_OUT_SEND_ACK_RX_CMD; // rx_cmd
        nxt_i <= 1'b0;
        dir_i <= 1'b1;
        @(posedge usb_clk);// TURNAROUND

        nxt_i <= 1'b0;
        dir_i <= 1'b0;
        data_tmp <= DATA_ALL_0;
        @(posedge usb_clk);
    endtask
    task Device2Host_intrrupt_send3();
        nxt_i <= 1'b0;
        dir_i <= 1'b1;
        @(posedge usb_clk);

        data_tmp <= DATA_OUT_SETUP_DATA0; //PID0;
        nxt_i <= 1'b1;
        @(posedge usb_clk);

        data_tmp <= 8'h31;//make up transaction;
        @(posedge usb_clk);
        data_tmp <= 8'h32;//make up transaction;
        @(posedge usb_clk);
        data_tmp <= 8'h33;//make up transaction;
        @(posedge usb_clk);
        data_tmp <= 8'h34;//make up transaction;
        @(posedge usb_clk);
        data_tmp <= 8'h35;//make up transaction;
        @(posedge usb_clk);

        data_tmp <= 8'hff;//crc16;
        @(posedge usb_clk);
        data_tmp <= 8'hff;//crc16;
        @(posedge usb_clk);

        data_tmp <= DATA_OUT_SEND_ACK_RX_CMD; // rx_cmd
        nxt_i <= 1'b0;
        dir_i <= 1'b1;
        @(posedge usb_clk);// TURNAROUND

        nxt_i <= 1'b0;
        dir_i <= 1'b0;
        data_tmp <= DATA_ALL_0;
        @(posedge usb_clk);
    endtask
    task Device2Host_intrrupt_send4();
        nxt_i <= 1'b0;
        dir_i <= 1'b1;
        @(posedge usb_clk);

        data_tmp <= DATA_OUT_SETUP_DATA0; //PID0;
        nxt_i <= 1'b1;
        @(posedge usb_clk);

        data_tmp <= 8'h41;//make up transaction;
        @(posedge usb_clk);
        data_tmp <= 8'h42;//make up transaction;
        @(posedge usb_clk);
        data_tmp <= 8'h43;//make up transaction;
        @(posedge usb_clk);
        data_tmp <= 8'h44;//make up transaction;
        @(posedge usb_clk);
        data_tmp <= 8'h45;//make up transaction;
        @(posedge usb_clk);

        data_tmp <= 8'hff;//crc16;
        @(posedge usb_clk);
        data_tmp <= 8'hff;//crc16;
        @(posedge usb_clk);

        data_tmp <= DATA_OUT_SEND_ACK_RX_CMD; // rx_cmd
        nxt_i <= 1'b0;
        dir_i <= 1'b1;
        @(posedge usb_clk);// TURNAROUND

        nxt_i <= 1'b0;
        dir_i <= 1'b0;
        data_tmp <= DATA_ALL_0;
        @(posedge usb_clk);
    endtask
    task Device2Host_intrrupt_send_delay();
        nxt_i <= 1'b0;
        dir_i <= 1'b1;
        repeat(3) begin
            @(posedge usb_clk);
            data_tmp <= DATA_OUT_RX_CMD_FILLING;
            nxt_i <= 1'b0;
        end
        @(posedge usb_clk);
        data_tmp <= DATA_OUT_SETUP_DATA0; //PID0;
        nxt_i <= 1'b1;
        @(posedge usb_clk);

        data_tmp <= 8'h11;//make up transaction;
        @(posedge usb_clk);
        data_tmp <= 8'h12;//make up transaction;
        @(posedge usb_clk);
        data_tmp <= 8'h13;//make up transaction;
        @(posedge usb_clk);
        data_tmp <= 8'h14;//make up transaction;
        @(posedge usb_clk);
        data_tmp <= 8'h15;//make up transaction;
        @(posedge usb_clk);

        data_tmp <= 8'hff;//crc16;
        @(posedge usb_clk);
        data_tmp <= 8'hff;//crc16;
        @(posedge usb_clk);

        data_tmp <= DATA_OUT_SEND_ACK_RX_CMD;
        nxt_i <= 1'b0;
        dir_i <= 1'b1;
        @(posedge usb_clk);// TURNAROUND
        nxt_i <= 1'b0;
        dir_i <= 1'b0;
        data_tmp <= DATA_ALL_0;
        @(posedge usb_clk);
        $display("success!!!!!!");
    endtask



    task disconnect_device();
        // turnaround
        nxt_i <= 1'b0;
        dir_i <= 1'b1;
        @(posedge usb_clk);
        // rx_cmd
        data_tmp <= DATA_OUT_DISCONNECT;
        @(posedge usb_clk);
        //turnaround
        nxt_i <= 1'b0;
        dir_i <= 1'b0;
        data_tmp <= DATA_ALL_0;
    endtask

    task INIT();
        wait (data_io == 8'h84);
        if(data_io == 8'h84) begin
            // nxt_i <= 1'b0;
            @(posedge usb_clk); 
            nxt_i <= 1'b1;
            @(posedge usb_clk);
            $display("pass INIT");
            forever begin
                @(posedge usb_clk);
                if(stp_o) begin
                    nxt_i <= 1'b0;
                    break;
                end
            end
        end
    endtask

    task DeviceRst();
        wait (data_io == 8'h85);
        if(data_io == 8'h85) begin
            // nxt_i <= 1'b0;
            @(posedge usb_clk); 
            nxt_i <= 1'b1;
            @(posedge usb_clk);
            $display("pass DeviceRst");
            forever begin
                @(posedge usb_clk);
                if(stp_o) begin
                    nxt_i <= 1'b0;
                    break;
                end
            end
        end
    endtask
    task DeviceRst2();
        wait (data_io == 8'h85);
        if(data_io == 8'h85) begin
            // nxt_i <= 1'b0;
            @(posedge usb_clk); 
            nxt_i <= 1'b1;
            @(posedge usb_clk);
            $display("pass DeviceRst2");
            forever begin
                @(posedge usb_clk);
                if(stp_o) begin
                    nxt_i <= 1'b0;
                    break;
                end
            end
        end
    endtask


    task BMEM_RESP();
        wait (bmem_wr_en == 1'b1);
        if(bmem_wr_en == 1'b1) begin
            // #300;
            repeat(40) @(posedge axi_clk);
            bmem_resp <= 1'b1;
            @(posedge axi_clk);
            bmem_resp <= 1'b0;
        end
    endtask

    task debug_1();
        wait(usb_debug_i == 1'b1);
        dir_i <= 1'b1;
        nxt_i <= 1'b1;
        data_tmp <= 8'h51;
        @(posedge usb_clk);
        data_tmp <= 8'h52;
        @(posedge usb_clk);
        data_tmp <= 8'h53;
        @(posedge usb_clk);
        data_tmp <= 8'h54;
        @(posedge usb_clk);
        data_tmp <= 8'h55;
        @(posedge usb_clk);
        data_tmp <= 8'h56;
        @(posedge usb_clk);
        data_tmp <= 8'h57;
        @(posedge usb_clk);
        data_tmp <= 8'h58;
        @(posedge usb_clk);
        dir_i <= 1'b0;
        nxt_i <= 1'b0;
        $display("debug_1 data sent");
    endtask
    task debug_2();
        wait(usb_debug_i == 1'b1);
        dir_i <= 1'b1;
        nxt_i <= 1'b1;
        data_tmp <= 8'h61;
        @(posedge usb_clk);
        data_tmp <= 8'h62;
        @(posedge usb_clk);
        data_tmp <= 8'h63;
        @(posedge usb_clk);
        data_tmp <= 8'h64;
        @(posedge usb_clk);
        data_tmp <= 8'h65;
        @(posedge usb_clk);
        data_tmp <= 8'h66;
        @(posedge usb_clk);
        data_tmp <= 8'h67;
        @(posedge usb_clk);
        data_tmp <= 8'h68;
        @(posedge usb_clk);
        dir_i <= 1'b0;
        nxt_i <= 1'b0;
        $display("debug_2 data sent");
    endtask
    task debug_3();
        wait(usb_debug_i == 1'b1);
        dir_i <= 1'b1;
        nxt_i <= 1'b1;
        data_tmp <= 8'h71;
        @(posedge usb_clk);
        data_tmp <= 8'h72;
        @(posedge usb_clk);
        data_tmp <= 8'h73;
        @(posedge usb_clk);
        data_tmp <= 8'h74;
        @(posedge usb_clk);
        data_tmp <= 8'h75;
        @(posedge usb_clk);
        data_tmp <= 8'h76;
        @(posedge usb_clk);
        data_tmp <= 8'h77;
        @(posedge usb_clk);
        data_tmp <= 8'h78;
        @(posedge usb_clk);
        dir_i <= 1'b0;
        nxt_i <= 1'b0;
        $display("debug_3 data sent");
    endtask
    task debug_4();
        wait(usb_debug_i == 1'b1);
        dir_i <= 1'b1;
        nxt_i <= 1'b1;
        data_tmp <= 8'h81;
        @(posedge usb_clk);
        data_tmp <= 8'h82;
        @(posedge usb_clk);
        data_tmp <= 8'h83;
        @(posedge usb_clk);
        data_tmp <= 8'h84;
        @(posedge usb_clk);
        data_tmp <= 8'h85;
        @(posedge usb_clk);
        data_tmp <= 8'h86;
        @(posedge usb_clk);
        data_tmp <= 8'h87;
        @(posedge usb_clk);
        data_tmp <= 8'h88;
        @(posedge usb_clk);
        dir_i <= 1'b0;
        nxt_i <= 1'b0;
        $display("debug_4 data sent");
    endtask

    initial begin
        $display("begin!!!!!!!");

        do_setup();
        #15ns;
        INIT();
        DeviceRst();

        // CONNECT DEVICE
        connect_device();
        DeviceRst2();

        // SETUP ADDR
        device_setup_address_PID();
        device_setup_address_data();
        Device2Host_ACK();

        // SETUP CONFIG
        device_setup_config_PID();
        device_setup_config_data();
        Device2Host_ACK();

        // SOF
        sof();
        
        // repeat(100) @(posedge usb_clk);
        // $display("ALL TEST PASSED");
        // $finish;

        // debug pin
        repeat(20) @(posedge usb_clk);
        usb_debug_i <= 1'b0;
        repeat(10) @(posedge usb_clk);

        if(!usb_debug_i) begin
            fork
                begin
                    while(1) begin
                        BMEM_RESP();
                    end
                end
                begin
                    while(1) begin
                            sof();
                    end
                end
                begin
                        #3ms;
                        // IN
                        Host2Device_INtoken();
                        Device2Host_intrrupt_send1();
                        Host2Device_ACK();

                        #3ms;
                        // IN
                        Host2Device_INtoken();
                        Device2Host_intrrupt_send2();
                        Host2Device_ACK();
                        
                        #3ms;
                        // IN DELAY
                        Host2Device_INtoken();
                        Device2Host_intrrupt_send3();
                        Host2Device_ACK();

                        #3ms;
                        // IN DELAY
                        Host2Device_INtoken();
                        Device2Host_intrrupt_send4();
                        Host2Device_ACK();

                        #3ms;
                        repeat(10) @(posedge usb_clk);
                        disconnect_device();

                        repeat(10) @(posedge usb_clk);
                        $display("ALL TEST PASSED");
                        $finish;
                end
            join
        end
        else begin
            fork
                begin
                    while(1) begin
                        BMEM_RESP();
                    end
                end
                begin
                    if(usb_debug_i == 1'b1) begin
                        #3ms;
                        debug_1();      //51-58
                        #3ms;
                        debug_2();      //61-68
                        #3ms;
                        debug_3();      //71-78
                        #3ms;
                        debug_4();      //81-88
                        #3ms;
                        repeat(100) @(posedge usb_clk);
                        $display("ALL TEST PASSED");
                        $finish;
                    end
                end
            join
        end
    end

    //----------------------------------------------------------------------
    // Timeout.
    //----------------------------------------------------------------------
    initial begin
        #5000000000ns;
        $fatal("Timeout!");
    end

endmodule