module top #(
    parameter DIVISOR = 50_000_000,
    parameter FILE_NAME = "mem_init.mif",
    parameter ADDR_WIDTH = 6,
    parameter DATA_WIDTH = 16
) (
    input clk,
    input rst_n,
    input [2:0] btn,
    input [8:0] sw,
    output [9:0] led,
    output [27:0] hex
);

    // -------------------
    // Clock Divider
    // -------------------
    wire out_clk_div;

    clk_div #(.DIVISOR(DIVISOR)) clock_divisor (
        .clk(clk), .rst_n(rst_n), .out(out_clk_div)
    );

    // -------------------
    // CPU and Memory
    // -------------------
    wire we_cpu;
    wire [ADDR_WIDTH-1:0] addr_cpu;
    wire [DATA_WIDTH-1:0] data_cpu;
    wire [ADDR_WIDTH-1:0] pc_cpu;
    wire [ADDR_WIDTH-1:0] sp_cpu;
    wire [DATA_WIDTH-6:0] leftover_cpu_out;
    wire [DATA_WIDTH-1:0] mem_to_cpu;

    cpu #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH)
    ) cpu_instance (
        .clk(out_clk_div),
        .rst_n(rst_n),
        .mem(mem_to_cpu),
        .in({12'h000, sw[3:0]}),
        .btn(btn[2]),
        .we(we_cpu),
        .addr(addr_cpu),
        .data(data_cpu),
        .out({leftover_cpu_out[DATA_WIDTH-6:0], led[4:0]}),
        .pc(pc_cpu),
        .sp(sp_cpu)
    );

    memory #(
        .FILE_NAME(FILE_NAME),
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH)
    ) memory_instance (
        .clk(out_clk_div),
        .we(we_cpu),
        .addr(addr_cpu),
        .data(data_cpu),
        .out(mem_to_cpu)
    );
    
    // -------------------
    // BCD Conversion
    // -------------------
    wire [3:0] pc_bcd_ones;
    wire [3:0] pc_bcd_tens;

    bcd pc_bcd(
        .in(pc_cpu),
        .ones(pc_bcd_ones),
        .tens(pc_bcd_tens)
    );

    wire [3:0] sp_bcd_ones;
    wire [3:0] sp_bcd_tens;
    bcd sp_bcd(
        .in(sp_cpu),
        .ones(sp_bcd_ones),
        .tens(sp_bcd_tens)
    );

    // -------------------
    // Seven Segment Display
    // -------------------
    ssd seg_pc_ones_inst(
        .in(pc_bcd_ones),
        .out(hex[6:0])
    );

    ssd seg_pc_tens_inst(
        .in(pc_bcd_tens),
        .out(hex[13:7])
    );

    ssd seg_sp_ones_inst(
        .in(sp_bcd_ones),
        .out(hex[20:14])
    );

    ssd seg_sp_tens_inst(
        .in(sp_bcd_tens),
        .out(hex[27:21])
    );

endmodule