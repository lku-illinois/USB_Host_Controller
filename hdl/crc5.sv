module usbh_crc5
(
    // input crc is 5 bits for token packet
    input [4:0]     crc_i,

    // this includes 7bit Address + 4bit Endpoint
    input [10:0]    data_i,
    output [4:0]    crc_o
);

//-----------------------------------------------------------------
// Implementation
//-----------------------------------------------------------------
assign crc_o[0] =    data_i[10] ^ data_i[9] ^ data_i[6] ^ data_i[5] ^ data_i[3] ^ data_i[0] ^
                       crc_i[0] ^ crc_i[3] ^ crc_i[4];

assign crc_o[1] =    data_i[10] ^ data_i[7] ^ data_i[6] ^ data_i[4] ^ data_i[1] ^
                       crc_i[0] ^ crc_i[1] ^ crc_i[4];

assign crc_o[2] =    data_i[10] ^ data_i[9] ^ data_i[8] ^ data_i[7] ^ data_i[6] ^ data_i[3] ^ data_i[2] ^ data_i[0] ^
                       crc_i[0] ^ crc_i[1] ^ crc_i[2] ^ crc_i[3] ^ crc_i[4];

assign crc_o[3] =    data_i[10] ^ data_i[9] ^ data_i[8] ^ data_i[7] ^ data_i[4] ^ data_i[3] ^ data_i[1] ^ 
                       crc_i[1] ^ crc_i[2] ^ crc_i[3] ^ crc_i[4];

assign crc_o[4] =    data_i[10] ^ data_i[9] ^ data_i[8] ^ data_i[5] ^ data_i[4] ^ data_i[2] ^
                       crc_i[2] ^ crc_i[3] ^ crc_i[4];

endmodule