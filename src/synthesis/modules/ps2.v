module ps2 (
    input clk,
    input rst_n,
    input ps2_clk,
    input ps2_data,
    output [15:0] code
);

    reg [1:0] ps2_clk_sync;
    reg [1:0] ps2_data_sync;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            ps2_clk_sync <= 2'b11; // Initial state (idle)
            ps2_data_sync <= 2'b11; // Initial state (idle)
        end
        else begin
            ps2_clk_sync[0] <= ps2_clk;
            ps2_clk_sync[1] <= ps2_clk_sync[0];
            ps2_data_sync[0] <= ps2_data;
            ps2_data_sync[1] <= ps2_data_sync[0];
        end
    end

    wire ps2_clk_falling = (ps2_clk_sync[1] == 1'b1) && (ps2_clk_sync[0] == 1'b0); // Detect falling edge of ps2_clk

    // sample buffer for the 11 bits: index 0 = start bit, index 1-8 = d0 to d7 (data bits), index 9 = parity bit, index 10 = stop bit
    reg [10:0] sample_bits;
    reg [3:0] bit_count;

    reg [19:0] idle_counter;
    localparam IDLE_TIMEOUT = 20'd1_000_000; // Adjust this value as needed for clock frequency, 10e6 is good for 50MHz (20ms)

    wire [7:0] sampled_byte = { sample_bits[8], sample_bits[7], sample_bits[6], sample_bits[5], sample_bits[4], sample_bits[3], sample_bits[2], sample_bits[1] };
    wire parity_ok = (sample_bits[9] == ~(^sampled_byte));
    
    reg [15:0] code_reg, code_next;
    assign code = code_reg;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            bit_count <= 4'd0;
            sample_bits <= 11'd0;
            code_reg <= 16'd0;
            idle_counter <= 20'd0;
        end
        else begin
            if (ps2_clk_falling)
                idle_counter <= 20'd0;
            else if (idle_counter < IDLE_TIMEOUT)
                idle_counter <= idle_counter + 1'b1;

            if (idle_counter == IDLE_TIMEOUT)
                bit_count <= 4'd0; 

            if (ps2_clk_falling) begin
                sample_bits[bit_count] <= ps2_data_sync[1];

                if (bit_count == 4'd10) 
                    bit_count <= 4'd0; // frame complete, reset bit count
                else 
                    bit_count <= bit_count + 1'b1; 
            end

            code_reg <= code_next;
        end
    end

    always @(*) begin
        code_next = code_reg;

        if (ps2_clk_falling && bit_count == 4'd10) begin
            // frame complete, check validity
            if ((sample_bits[0] == 1'b0) && (sample_bits[10] == 1'b1) && parity_ok) begin
                code_next = { code_reg[7:0], sampled_byte }; // move previous byte to upper part and add new byte
            end
        end
    end

endmodule