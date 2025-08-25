module register_sim (
    clk,
    rst_n,
    cl,
    ld,
    in,
    inc,
    dec,
    sr,
    ir,
    sl,
    il,
    out
);

    input clk, rst_n, cl, ld, inc, dec, sr, ir, sl, il;
    input [3:0] in;
    output [3:0] out;

    reg [3:0] out_next, out_reg;
    assign out = out_reg;

    always @(posedge clk, negedge rst_n) begin
        if (!rst_n) 
            out_reg <= 4'b0000;
        else 
            out_reg <= out_next;
    end

    always @(*) begin
        out_next = out_reg;
        if (cl) 
            out_next = 4'b0000;
        else if (ld) 
            out_next = in;
        else if (inc) 
            out_next = out_reg + 1;
        else if (dec) 
            out_next = out_reg - 1;
        else if (sr) begin
            out_next = out_reg >> 1;
            out_next[3] = il;
        end
        else if (sl) begin
            out_next = out_reg << 1;
            out_next[0] = ir;
        end
    end
    
endmodule