module top_sim;

    reg [2:0] oc;
    reg [3:0] a, b;
    wire [3:0] f;
    
    reg clk, rst_n, cl, ld, inc, dec, sr, ir, sl, il;
    reg [3:0] in;
    wire [3:0] out;

    alu_sim alu_instance(
        .oc(oc),
        .a(a),
        .b(b),
        .f(f)
    );

    register_sim register_intance(
        .clk(clk),
        .rst_n(rst_n),
        .cl(cl),
        .ld(ld),
        .in(in),
        .inc(inc),
        .dec(dec),
        .sr(sr),
        .ir(ir),
        .sl(sl),
        .il(il),
        .out(out)
    );

    integer i;

    initial begin
        clk = 1'b0;
        rst_n = 1'b0;

        for (i = 0; i < 2**11; i = i + 1) begin
            {oc, a, b} = i;
            #5;
            $display("time = %5d, oc = %b, a = %b, b = %b, f = %b", $time, oc, a, b, f);
        end
        $stop;

        cl = 1'b0;
        ld = 1'b0;
        in = 4'b0000;
        inc = 1'b0;
        dec = 1'b0;
        sr = 1'b0;
        ir = 1'b0;
        sl = 1'b0;
        il = 1'b0;

        #2 rst_n = 1'b1;
        repeat (1000) begin
            #5; 
            cl = $urandom % 2;
            ld = $urandom % 2;
            in = $urandom % 16;
            inc = $urandom % 2;
            dec = $urandom % 2;
            sr = $urandom % 2;
            ir = $urandom % 2;
            sl = $urandom % 2;
            il = $urandom % 2;
        end
        $finish;
    end

    always @(out) begin
        $display(
            "time = %5d, cl = %b, ld = %b, in = %b, inc = %b, dec = %b, sr = %b, ir = %b, sl = %b, il = %b, out = %b",
            $time, cl, ld, in, inc, dec, sr, ir, sl, il, out
        );
    end

    always
        #5 clk = ~clk;

endmodule