module vga (
    input clk,
    input rst_n,
    input [23:0] code,
    output reg hsync,
    output reg vsync,
    output reg [3:0] red,
    output reg [3:0] green,
    output reg [3:0] blue
);

    localparam H_VISIBLE    = 640;
    localparam H_FRONT      = 16;
    localparam H_SYNC       = 96;
    localparam H_BACK       = 48;
    localparam H_TOTAL      = H_VISIBLE + H_FRONT + H_SYNC + H_BACK;

    localparam V_VISIBLE    = 480;
    localparam V_FRONT      = 10;
    localparam V_SYNC       = 2;
    localparam V_BACK       = 33;
    localparam V_TOTAL      = V_VISIBLE + V_FRONT + V_SYNC + V_BACK;

    reg [9:0] h_count; // up to 800 fits in 10 bits
    reg [9:0] v_count; // up to 525 fits in 10 bits

    wire h_visible = (h_count < H_VISIBLE);
    wire v_visible = (v_count < V_VISIBLE);
    wire visible   = h_visible && v_visible;

    wire [3:0] left_r = code[23:20];
    wire [3:0] left_g = code[19:16];
    wire [3:0] left_b = code[15:12];

    wire [3:0] right_r = code[11:8];
    wire [3:0] right_g = code[7:4];
    wire [3:0] right_b = code[3:0];

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            h_count <= 10'd0;
            v_count <= 10'd0;
        end
        else begin
            if (h_count < H_TOTAL - 1) begin
                h_count <= 10'd0;
                if (v_count == V_TOTAL - 1)
                    v_count <= 10'd0;
                else 
                    v_count <= v_count + 1'b1;
            end
            else begin
                h_count <= h_count + 1'b1;
            end
        end
    end

    always @(*) begin
        hsync = 1'b1;
        vsync = 1'b1;

        if ((h_count >= (H_VISIBLE + H_FRONT)) && (h_count < (H_VISIBLE + H_FRONT + H_SYNC)))
            hsync = 1'b0; // active low during sync pulse

        if ((v_count >= (V_VISIBLE + V_FRONT)) && (v_count < (V_VISIBLE + V_FRONT + V_SYNC)))
            vsync = 1'b0; // active low during sync pulse 
    end

    always @(*) begin
        if (visible) begin
            if (h_count < H_VISIBLE / 2) begin
                red   = left_r;
                green = left_g;
                blue  = left_b;
            end
            else begin
                red   = right_r;
                green = right_g;
                blue  = right_b;
            end
        end
        else begin
            red   = 4'b0000;
            green = 4'b0000;
            blue  = 4'b0000;
        end
    end

endmodule