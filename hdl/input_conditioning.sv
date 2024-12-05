/*module INVX2MA10TR(
	input wire A,
	output wire Y
);
	assign Y = ~A;

endmodule */


module input_conditioning(
	input logic A, clk,
	output logic Y
);

	logic Y_buff [4];

	io_in buff1(.chipout(A), .chipin(Y_buff[0]));
	io_in buff2(.chipout(Y_buff[0]), .chipin(Y_buff[1]));
	io_in buff3(.chipout(Y_buff[1]), .chipin(Y_buff[2]));
	io_in buff4(.chipout(Y_buff[2]), .chipin(Y_buff[3]));


	always_ff @ (posedge clk) begin
		Y <= Y_buff[3];
	end

endmodule