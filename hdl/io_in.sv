module io_in (
    input   wire    chipout,
    output  wire    chipin
);

BUFZX2MA10TR in_buf ( .A(chipout), .OE(1'b1), .Y(chipin) );

endmodule