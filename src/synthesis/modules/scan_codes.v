module scan_codes (
    input clk,
    input rst_n,
    input [15:0] code,
    input status,
    output reg control,
    output reg [3:0] num
);

    wire byte_high_is_f0 = (code[15:8] == 8'hF0);
    wire byte_low_is_f0 = (code[7:0] == 8'hF0);

    wire [7:0] sc = byte_high_is_f0 ? code[7:0] : byte_low_is_f0 ? code[15:8] : 8'h00;

    wire break_detected = (byte_high_is_f0 ^ byte_low_is_f0);

    function [3:0] sc_to_digit;
        input [7:0] code_in;
        begin
            case (code_in)
                // Set1
                8'h02: sc_to_digit = 4'd1;
                8'h03: sc_to_digit = 4'd2;
                8'h04: sc_to_digit = 4'd3;
                8'h05: sc_to_digit = 4'd4;
                8'h06: sc_to_digit = 4'd5;
                8'h07: sc_to_digit = 4'd6;
                8'h08: sc_to_digit = 4'd7;
                8'h09: sc_to_digit = 4'd8;
                8'h0A: sc_to_digit = 4'd9;
                8'h0B: sc_to_digit = 4'd0;
                // Set2
                8'h16: sc_to_digit = 4'd1;
                8'h1E: sc_to_digit = 4'd2;
                8'h26: sc_to_digit = 4'd3;
                8'h25: sc_to_digit = 4'd4;
                8'h2E: sc_to_digit = 4'd5;
                8'h36: sc_to_digit = 4'd6;
                8'h3D: sc_to_digit = 4'd7;
                8'h3E: sc_to_digit = 4'd8;
                8'h46: sc_to_digit = 4'd9;
                8'h45: sc_to_digit = 4'd0;
                default: sc_to_digit = 4'hF; // Invalid code
            endcase 
        end
    endfunction

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            control <= 1'b0;
            num <= 4'd0;
        end
        else begin
            if (!status) begin
                control <= 1'b0;

            end
            else begin
                if (!control) begin
                    if (break_detected) begin
                        if (sc_to_digit(sc) != 4'hF) begin
                            num <= sc_to_digit(sc);
                            control <= 1'b1; 
                        end
                        // else its not a valid digit, do nothing
                    end
                end
                // wait for status to become low again
            end
        end
    end
    
endmodule