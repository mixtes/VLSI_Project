module bcd (
    in, ones, tens
);
    input [5:0] in;
    output reg [3:0] ones;
    output reg [3:0] tens;

    always @(*) begin
        ones = in % 10;
        tens = (in / 10) % 10;
    end

endmodule