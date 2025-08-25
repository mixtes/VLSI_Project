module register_syn #(
    parameter DATA_WIDTH = 16
) (
    clk, rst_n, cl, ld, in, inc, dec, sr, ir, sl, il, out
);
    
    input clk, rst_n, cl, ld, inc, dec, sr, ir, sl, il;
    input [DATA_WIDTH-1:0] in;
    output [DATA_WIDTH-1:0] out;

    reg [DATA_WIDTH-1:0] out_next, out_reg;
    assign out = out_reg;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            out_reg <= {DATA_WIDTH{1'b0}};
        else
            out_reg <= out_next;
    end

    always @(*) begin
        out_next = out_reg;
        if (cl)
            out_next = {DATA_WIDTH{1'b0}};
        else if (ld)
            out_next = in;
        else if (inc)
            out_next = out_reg + 1;
        else if (dec)
            out_next = out_reg - 1;
        else if (sr) begin
            out_next = out_reg >> 1;
            out_next[DATA_WIDTH-1] = il;
        end else if (sl) begin
            out_next = out_reg << 1;
            out_next[0] = ir;
        end
    end 

endmodule