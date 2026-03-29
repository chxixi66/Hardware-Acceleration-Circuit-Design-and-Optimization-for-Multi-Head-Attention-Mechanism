interface output_data_if#(
	parameter DATA_WIDTH = 16
)();
	logic                           attention_vld; // WIRE_NEW
    logic [64*64*DATA_WIDTH-1:0]    attention0   ;
    logic [64*64*DATA_WIDTH-1:0]    attention1   ;
    logic [64*64*DATA_WIDTH-1:0]    attention2   ;
    logic [64*64*DATA_WIDTH-1:0]    attention3   ;
    logic [64*64*DATA_WIDTH-1:0]    attention4   ;
    logic [64*64*DATA_WIDTH-1:0]    attention5   ;
    logic [64*64*DATA_WIDTH-1:0]    attention6   ;
    logic [64*64*DATA_WIDTH-1:0]    attention7   ;
endinterface

