module mem_sim (
    input clk,
    input rst_n,
    input we,
    input [3:0] addr,
    input [7:0] data,
    output [7:0] out
);

    localparam CAPACITY = 2**4;

    reg [7:0] out_reg, out_next;
    assign out = out_reg;

    reg [7:0] mem_reg [CAPACITY-1:0], mem_next [CAPACITY-1:0];

    integer i;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            out_reg <= 8'h00;
            for (i = 0; i < CAPACITY; i = i + 1) begin
                mem_reg[i] <= 8'h00;
            end
        end
        else begin
            out_reg = out_next;
            for (i = 0; i < CAPACITY; i = i + 1) begin
                mem_reg[i] <= mem_next[i];
            end
        end
    end

    always @(*) begin
        out_next = out_reg;
        for (i = 0; i < CAPACITY; i = i + 1) begin
            mem_next[i] = mem_reg[i];
        end

        if (we == 1'b0) begin
            out_next = mem_reg[addr];
        end
        else begin
            mem_next[addr] = data;
        end
    end

endmodule