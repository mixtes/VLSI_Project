module top_mem;

    reg clk, rst_n;
    reg [3:0] addr;
    reg [7:0] data;
    wire [7:0] out;
    reg we;

    mem_sim mem_instance(.clk(clk), .rst_n(rst_n), .we(we), .addr(addr), .data(data), .out(out));

    
    initial begin
        rst_n = 1'b0; 
        clk = 1'b0;
        we = 1'b0;
        addr = 4'h0;
        data = 8'h00;

        #2 rst_n = 1'b1;

        repeat (1000) begin
            we = {$random} % 2;
            addr = {$random} % 16;
            data = {$random} % 256;
            #10;
        end
        #10 $finish;
    end

    always @(out)
        $strobe("Time = %4d, Address = %b, Data = %8b, we = %1b, Out = %8b", $time, addr, data, we, out);

    always 
        #5 clk = ~clk;    
endmodule