module clk_div #(
    parameter DIVISOR = 50_000_000
) (
    clk, rst_n, out
);

    input clk;
    input rst_n;
    output out;
    
    reg out_next, out_reg;
    
    assign out = out_reg;

    integer counter_next, counter_reg; // potentially not compatible with synthesis tools, possible fix: reg [$clog2(DIVISOR)-1:0] counter_next, counter_reg;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            counter_reg <= 0;
            out_reg <= 1'b0;
        end
        else begin
            counter_reg <= counter_next;
            out_reg <= out_next;
        end
    end

    always @(*) begin
        counter_next = counter_reg;
        out_next = out_reg;
        if (counter_reg == DIVISOR - 1) begin
            out_next = ~out_reg;
            counter_next = 0;
        end
        else begin
            counter_next = counter_reg + 1'b1;
        end
    end
    
endmodule
