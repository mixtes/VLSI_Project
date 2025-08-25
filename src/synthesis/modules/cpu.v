module cpu #(
    parameter ADDR_WIDTH = 6,
    parameter DATA_WIDTH = 16
) (
    input wire                      clk,
    input wire                      rst_n,
    input wire [DATA_WIDTH-1:0]     mem,
    input wire [DATA_WIDTH-1:0]     in,
    input wire                      btn,
    output reg                      we,
    output wire [ADDR_WIDTH-1:0]    addr,
    output wire [DATA_WIDTH-1:0]    data,
    output wire [DATA_WIDTH-1:0]    out,
    output wire [ADDR_WIDTH-1:0]    pc,
    output wire [ADDR_WIDTH-1:0]    sp
);

    reg [DATA_WIDTH-1:0] out_reg, out_next;

    // register outputs
    wire [ADDR_WIDTH-1:0] PC_out, SP_out, MAR_out;
    wire [2*DATA_WIDTH-1:0] IR_out;
    wire [DATA_WIDTH-1:0] MDR_out, A_out;

    // cpu register inputs
    reg [ADDR_WIDTH-1:0] PC_in, SP_in, MAR_in;
    reg [DATA_WIDTH-1:0] MDR_in, A_in;
    reg [2*DATA_WIDTH-1:0] IR_in;

    // control signals for registers
    reg cl_pc, cl_sp, cl_mar, cl_mdr, cl_ir, cl_a;
    reg ld_pc, ld_sp, ld_mar, ld_mdr, ld_ir, ld_a;
    reg inc_pc, inc_sp, inc_mar, inc_mdr, inc_ir, inc_a;
    reg dec_pc, dec_sp, dec_mar, dec_mdr, dec_ir, dec_a;
    reg sr_pc, sr_sp, sr_mar, sr_mdr, sr_ir, sr_a;
    reg ir_pc, ir_sp, ir_mar, ir_mdr, ir_ir, ir_a;
    reg sl_pc, sl_sp, sl_mar, sl_mdr, sl_ir, sl_a;
    reg il_pc, il_sp, il_mar, il_mdr, il_ir, il_a;

    // output connections
    assign addr = MAR_out;
    assign data = MDR_out;
    assign out = out_reg;
    assign pc = PC_out;
    assign sp = SP_out;

    // register instances
    register_syn #(.DATA_WIDTH(ADDR_WIDTH)) PC_reg (
        .clk(clk), .rst_n(rst_n), .cl(cl_pc), .ld(ld_pc), .inc(inc_pc), .dec(dec_pc),
        .sr(sr_pc), .ir(ir_pc), .sl(sl_pc), .il(il_pc),
        .in(PC_in), .out(PC_out)
    );

    register_syn #(.DATA_WIDTH(ADDR_WIDTH)) SP_reg (
        .clk(clk), .rst_n(rst_n), .cl(cl_sp), .ld(ld_sp), .inc(inc_sp), .dec(dec_sp),
        .sr(sr_sp), .ir(ir_sp), .sl(sl_sp), .il(il_sp),
        .in(SP_in), .out(SP_out)
    );

    register_syn #(.DATA_WIDTH(ADDR_WIDTH)) MAR_reg (
        .clk(clk), .rst_n(rst_n), .cl(cl_mar), .ld(ld_mar), .inc(inc_mar), .dec(dec_mar),
        .sr(sr_mar), .ir(ir_mar), .sl(sl_mar), .il(il_mar),
        .in(MAR_in), .out(MAR_out)
    );

    register_syn #(.DATA_WIDTH(DATA_WIDTH)) MDR_reg (
        .clk(clk), .rst_n(rst_n), .cl(cl_mdr), .ld(ld_mdr), .inc(inc_mdr), .dec(dec_mdr),
        .sr(sr_mdr), .ir(ir_mdr), .sl(sl_mdr), .il(il_mdr),
        .in(MDR_in), .out(MDR_out)
    );

    register_syn #(.DATA_WIDTH(2*DATA_WIDTH)) IR_reg (
        .clk(clk), .rst_n(rst_n), .cl(cl_ir), .ld(ld_ir), .inc(inc_ir), .dec(dec_ir),
        .sr(sr_ir), .ir(ir_ir), .sl(sl_ir), .il(il_ir),
        .in(IR_in), .out(IR_out)
    );

    register_syn #(.DATA_WIDTH(DATA_WIDTH)) A_reg (
        .clk(clk), .rst_n(rst_n), .cl(cl_a), .ld(ld_a), .inc(inc_a), .dec(dec_a),
        .sr(sr_a), .ir(ir_a), .sl(sl_a), .il(il_a),
        .in(A_in), .out(A_out)
    );

    localparam  ALU_ADD_INST    = 3'b000,
                ALU_SUB_INST    = 3'b001,
                ALU_MUL_INST    = 3'b010,
                ALU_DIV_INST    = 3'b011,
                ALU_NOT_INST    = 3'b100,
                ALU_XOR_INST    = 3'b101,
                ALU_OR_INST     = 3'b110,
                ALU_AND_INST    = 3'b111;   

    // ALU instance
    reg  [2:0] alu_oc;
    reg  [DATA_WIDTH-1:0] alu_a;
    reg  [DATA_WIDTH-1:0] alu_b;
    wire [DATA_WIDTH-1:0] alu_out;
    alu #(.DATA_WIDTH(DATA_WIDTH)) ALU (
        .oc(alu_oc),
        .a(alu_a),
        .b(alu_b),
        .f(alu_out)
    );

    // -----------------------
    // CPU microarchitecture
    // -----------------------
    localparam  MOV_INSTRUCTION     = 4'b0000,
                ADD_INSTRUCTION     = 4'b0001,
                SUB_INSTRUCTION     = 4'b0010,
                MUL_INSTRUCTION     = 4'b0011,
                IN_INSTRUCTION      = 4'b0111,
                OUT_INSTRUCTION     = 4'b1000,
                STOP_INSTRUCTION    = 4'b1111;

    localparam  BEQ_INSTRUCTION     = 4'b0101;

    localparam  JSR_INSTRUCTION     = 4'b0110;
    localparam  RTS_INSTRUCTION     = 4'b1110;

    localparam  S_RESET         = 0,
                S_FETCH1        = 1,                                        // MAR <= PC; PC <= PC + 1;
                S_FETCH2        = 2,                                        // MDR <= mem[MAR];
                S_FETCH3        = 3,
                S_LOAD_IR       = 4,                                        // IR[31:16] <= MDR;
                S_DECODE        = 5,
                // operand resolution states, calculate effective addresses
                S_RESOLVE_X1    = 6,
                S_RESOLVE_X2    = 7,
                S_RESOLVE_X3    = 8,
                S_RESOLVE_Y1    = 9,
                S_RESOLVE_Y2    = 10,
                S_RESOLVE_Y3    = 11,
                S_RESOLVE_Z1    = 12,
                S_RESOLVE_Z2    = 13,
                S_RESOLVE_Z3    = 14,
                // read operands
                S_READ_X1       = 41, 
                S_READ_X2       = 42,
                S_READ_X3       = 43,
                S_READ_Y1       = 15,
                S_READ_Y2       = 16, 
                S_READ_Y3       = 17,
                S_READ_Y4       = 18,
                S_READ_Z1       = 19,
                S_READ_Z2       = 20, 
                S_READ_Z3       = 21,
                // execute instructions
                S_EXEC_ALU      = 22,
                S_IN1           = 23,
                S_IN2           = 24,
                S_OUT1          = 25,
                S_OUT2          = 26,
                S_OUT3          = 27,
                S_OUT4          = 28,
                S_WRITEBACK0    = 29,
                S_WRITEBACK1    = 30,
                S_WRITEBACK2    = 31,
                S_STOP          = 32,                                       // correctly finished program
                S_HALT          = 33;                                       // interrupt or error state, CPU is halted
    // support for 2 word instructions
    localparam  S_FETCH_EXTRA1  = 34,
                S_FETCH_EXTRA2  = 35,
                S_LOAD_IR_LOW   = 36;
    // resolve effective addresses
    localparam  S_RESOLVE_X_CAPTURE = 37,
                S_RESOLVE_Y_CAPTURE = 38,
                S_RESOLVE_Z_CAPTURE = 39;
    
    localparam  S_WAIT_FOR_INPUT    = 40;
    localparam  S_CHECK_EQUALITY    = 44;
    localparam  S_WAIT              = 50;

    reg [5:0] state, next_state;

    wire [3:0] opcode = IR_out[31:28];                                      // 4-bit opcode; used when decoding the instruction
    wire [3:0] opX = IR_out[27:24];                                         // 4-bit operand X; used when decoding the instruction
    wire [3:0] opY = IR_out[23:20];                                         // 4-bit operand Y; used when decoding the instruction
    wire [3:0] opZ = IR_out[19:16];                                         // 4-bit operand Z; used when decoding the instruction
    
    wire [DATA_WIDTH-1:0] second_word = IR_out[DATA_WIDTH-1:0];

    reg [ADDR_WIDTH-1:0] EA_X, EA_Y, EA_Z;                                  // Effective Addresses

    reg halted, halted_next;

    wire is_arithmetic;
    assign is_arithmetic = (opcode == 4'b0001) || (opcode == 4'b0010) || (opcode == 4'b0011) ? 1'b1 : 1'b0;
    // two word instructions support, not yet necessary
    wire needs_second_word;
    // assign needs_second_word = (opcode == FUTURE_INSTRUCTION) || ((ocode == CURRENT_INSTRUCTION) && (SPECIAL_CASE)) ? 1'b1 : 1'b0;
    assign needs_second_word = (opcode == BEQ_INSTRUCTION) ? 1'b1 : 1'b0;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= S_RESET;
            out_reg <= {DATA_WIDTH{1'b0}};
            halted <= 1'b0;

        end else begin
            state <= next_state;
            out_reg <= out_next;
            halted <= halted_next;
        end
    end

    always @(*) begin
        // default: clear all control signals
        {cl_pc, ld_pc, inc_pc, dec_pc, sr_pc, ir_pc, sl_pc, il_pc} = 8'b0;
        {cl_sp, ld_sp, inc_sp, dec_sp, sr_sp, ir_sp, sl_sp, il_sp} = 8'b0;
        {cl_mar, ld_mar, inc_mar, dec_mar, sr_mar, ir_mar, sl_mar, il_mar} = 8'b0;
        {cl_mdr, ld_mdr, inc_mdr, dec_mdr, sr_mdr, ir_mdr, sl_mdr, il_mdr} = 8'b0;
        {cl_ir, ld_ir, inc_ir, dec_ir, sr_ir, ir_ir, sl_ir, il_ir} = 8'b0;
        {cl_a, ld_a, inc_a, dec_a, sr_a, ir_a, sl_a, il_a} = 8'b0;

        // default outputs
        we          = 1'b0;
        alu_a       = {DATA_WIDTH{1'b0}};
        alu_b       = {DATA_WIDTH{1'b0}};
        alu_oc      = 3'b000;
        
        next_state  = state;
        out_next    = out_reg;
        halted_next = halted;

        case (state)
            S_RESET: begin
                // Initial state is PC = 8, SP = last address
                ld_pc = 1'b1;
                PC_in = {{ADDR_WIDTH-4{1'b0}}, 1'b1, 3'b000};               // PC = 8
                ld_sp = 1'b1;
                SP_in = {ADDR_WIDTH{1'b1}};                                 // SP = last address
                cl_mar = 1'b1; cl_mdr = 1'b1; cl_ir = 1'b1; cl_a = 1'b1;    // Clear MAR, MDR, IR, A; just in case, so that there are no random values
                next_state = S_FETCH1;
            end
            // MAR <= PC; PC <= PC + 1;
            S_FETCH1: begin
                ld_mar = 1'b1;
                MAR_in = PC_out;
                inc_pc = 1'b1;
                next_state = S_FETCH2;
            end
            S_FETCH2: begin
                next_state = S_FETCH3;
            end
            // MDR <= mem[MAR];
            S_FETCH3: begin
                ld_mdr = 1'b1;
                MDR_in = mem;
                next_state = S_LOAD_IR;
            end
            // IR[31:16] <= MDR;
            S_LOAD_IR: begin
                ld_ir = 1'b1;
                IR_in = {MDR_out, {DATA_WIDTH{1'b0}}};
                // two word instructions support, not yet necessary
                if (needs_second_word) 
                    next_state = S_FETCH_EXTRA1;                           
                else
                    next_state = S_DECODE;
                // next_state = S_DECODE;
            end
            // two word instructions support, not yet necessary
            S_FETCH_EXTRA1: begin
                ld_mar = 1'b1;
                MAR_in = PC_out;
                inc_pc = 1'b1;
                next_state = S_FETCH_EXTRA2;
            end
            S_FETCH_EXTRA2: begin
                ld_mdr = 1'b1;
                MDR_in = mem;
                next_state = S_LOAD_IR_LOW;
            end
            S_LOAD_IR_LOW: begin
                ld_ir = 1'b1;
                IR_in = {IR_out[2*DATA_WIDTH-1:DATA_WIDTH], MDR_out};                // load the second word into the lower part of IR
                next_state = S_DECODE;
            end
            // Decode the instruction
            S_DECODE: begin                                                             
                case (opcode)
                    MOV_INSTRUCTION: begin 
                        // we first resolve Y (source) then X (destination)
                        next_state = S_RESOLVE_Y1;
                    end
                    ADD_INSTRUCTION, SUB_INSTRUCTION, MUL_INSTRUCTION: begin
                        // we first resolve Y (1st operand), then Z (2nd operand), then X (destination)
                        next_state = S_RESOLVE_Y1;
                    end
                    IN_INSTRUCTION: begin
                        // we resolve X (destination), only one operand
                        next_state = S_WAIT_FOR_INPUT;
                    end
                    OUT_INSTRUCTION: begin
                        // we resolve X (source), only one operand
                        next_state = S_RESOLVE_X1;
                    end
                    BEQ_INSTRUCTION: begin
                        next_state = S_RESOLVE_Y1;
                    end
                    STOP_INSTRUCTION: begin
                        // stop the CPU
                        next_state = S_STOP;
                    end
                    default: begin
                        // unknown instruction, halt the CPU
                        next_state = S_HALT;
                    end
                endcase
            end
            // Resolve operand Y, 1st step is to send the request to the memory
            S_RESOLVE_Y1: begin
                ld_mar = 1'b1;
                MAR_in = {3'b000, opY[2:0]};                                // has to be extended with 3 leading zeros, because addresses are 6 bits wide
                next_state = S_RESOLVE_Y2;
            end
            S_RESOLVE_Y2: begin
                next_state = S_RESOLVE_Y3;
            end
            // Resolve operand Y, 2nd step is to read the value from memory
            S_RESOLVE_Y3: begin
                ld_mdr = 1'b1;
                MDR_in = mem; 
                // wait for effective address
                next_state = S_RESOLVE_Y_CAPTURE;
            end
            S_RESOLVE_Y_CAPTURE: begin
                if (opY[3] == 1'b0) EA_Y <= {3'b000, opY[2:0]};             // direct addressing
                else EA_Y <= MDR_out[ADDR_WIDTH-1:0]; 

                if (opcode == MOV_INSTRUCTION || opcode == BEQ_INSTRUCTION) next_state = S_RESOLVE_X1;
                else next_state = S_RESOLVE_Z1; // if we are in MOV instruction, we can skip reading Z and go to resolve X
            end
            // Resolve operand Z, 1st step is to send the request to the memory
            S_RESOLVE_Z1: begin
                ld_mar = 1'b1;
                MAR_in = {3'b000, opZ[2:0]};                                // has to be extended with 3 leading zeros, because addresses are 6 bits wide
                next_state = S_RESOLVE_Z2;  
            end
            S_RESOLVE_Z2: begin
                next_state = S_RESOLVE_Z3;
            end
            // Resolve operand Z, 2nd step is to read the value from memory
            S_RESOLVE_Z3: begin
                ld_mdr = 1'b1;
                MDR_in = mem;
                // wait for effective address
                next_state = S_RESOLVE_Z_CAPTURE;
            end
            S_RESOLVE_Z_CAPTURE: begin
                if (opZ[3] == 1'b0) EA_Z <= {3'b000, opZ[2:0]};             // direct addressing
                else EA_Z <= MDR_out[ADDR_WIDTH-1:0]; 

                next_state = S_RESOLVE_X1;
            end
            // Resolve operand X, 1st step is to send the request to the memory
            S_RESOLVE_X1: begin
                ld_mar = 1'b1;
                MAR_in = {3'b000, opX[2:0]};                                // has to be extended with 3 leading zeros, because addresses are 6 bits wide
                next_state = S_RESOLVE_X2; 
            end
            // Resolve operand X, 2nd step is to read the value from memory
            S_RESOLVE_X2: begin
                next_state = S_RESOLVE_X3;
            end
            S_RESOLVE_X3: begin
                ld_mdr = 1'b1;
                MDR_in = mem;
                // wait for effective address
                next_state = S_RESOLVE_X_CAPTURE;
            end
            S_RESOLVE_X_CAPTURE: begin
                if (opX[3] == 1'b0) EA_X = {3'b000, opX[2:0]};             // direct addressing
                else EA_X = MDR_out[ADDR_WIDTH-1:0];                       // indirect addressing

                if (opcode == MOV_INSTRUCTION || opcode == BEQ_INSTRUCTION) next_state = S_READ_Y1;
                else if (is_arithmetic) next_state = S_READ_Y1;
                else if (opcode == IN_INSTRUCTION) next_state = S_IN1;
                else if (opcode == OUT_INSTRUCTION) next_state = S_OUT1;
                else next_state = S_HALT;                                   // should not happen, but just in case
            end
            // Read operand Y, 1st step is to send the request to the memory
            S_READ_Y1: begin
                ld_mar = 1'b1;
                MAR_in = EA_Y;
                next_state = S_READ_Y2;
            end
            S_READ_Y2: begin
                next_state = S_READ_Y3;
            end
            // Read operand Y, 2nd step is to read the value from memory
            S_READ_Y3: begin
                ld_mdr = 1'b1;
                MDR_in = mem;
                next_state = S_READ_Y4;
            end
            // Read operand Y, 3rd step is to load the value into A register
            S_READ_Y4: begin
                ld_a = 1'b1;
                A_in = MDR_out;

                if (opcode == MOV_INSTRUCTION) next_state = S_WRITEBACK0;     // if we are in MOV instruction, we can skip reading Z and go to WB
                else if (opcode == BEQ_INSTRUCTION) next_state = S_READ_X1;
                else next_state = S_READ_Z1;                                // otherwise, we need to read Z operand
            end
            // Read operand Z, 1st step is to send the request to the memory
            S_READ_Z1: begin
                ld_mar = 1'b1;
                MAR_in = EA_Z;
                next_state = S_READ_Z2;
            end
            S_READ_Z2: begin
                next_state = S_READ_Z3;
            end
            // Read operand Z, 2nd step is to read the value from memory
            S_READ_Z3: begin
                ld_mdr = 1'b1;
                MDR_in = mem;
                next_state = S_EXEC_ALU;
            end
            S_READ_X1: begin
                ld_mar = 1'b1;
                MAR_in = EA_X;
                next_state = S_READ_X2;
            end
            S_READ_X2: begin
                next_state = S_READ_X3;
            end
            S_READ_X3: begin
                ld_mdr = 1'b1;
                MDR_in = mem;
                next_state = S_EXEC_ALU;
            end
            // Execute ALU operation
            S_EXEC_ALU: begin
                // alu_a is wired to A_out, so we just need to set alu_b and alu_oc
                if (is_arithmetic) begin
                    alu_a = A_out;
                    alu_b = MDR_out;

                    case (opcode)
                        ADD_INSTRUCTION: alu_oc = ALU_ADD_INST;
                        SUB_INSTRUCTION: alu_oc = ALU_SUB_INST;
                        MUL_INSTRUCTION: alu_oc = ALU_MUL_INST;
                        BEQ_INSTRUCTION: alu_oc = ALU_XOR_INST;
                        default: next_state = S_HALT;
                    endcase

                    ld_a = 1'b1;
                    A_in = alu_out;                                     // get the result from ALU, available on the same cycle because alu is combinational
                end

                if (opcode == BEQ_INSTRUCTION) next_state = S_CHECK_EQUALITY;
                else next_state = S_WRITEBACK1; 
            end
            S_CHECK_EQUALITY: begin
                if (A_out == {DATA_WIDTH{1'b0}}) begin
                    ld_pc = 1'b1;
                    PC_in = second_word[5:0];
                    next_state = S_WAIT;
                end
                else next_state = S_FETCH1;
            end
            S_WRITEBACK0: begin
                next_state = S_WRITEBACK1;
            end
            S_WRITEBACK1: begin
                ld_mdr = 1'b1;
                MDR_in = A_out;
                ld_mar = 1'b1;
                MAR_in = EA_X;
                next_state = S_WRITEBACK2;
            end
            // Write back the result to memory, 2nd step is to write the data to memory
            S_WRITEBACK2: begin
                we = 1'b1;
                next_state = S_FETCH1;
            end
            S_WAIT_FOR_INPUT: begin
                if (btn) next_state = S_RESOLVE_X1;
                else next_state = S_WAIT_FOR_INPUT;
            end
            // IN instruction
            S_IN1: begin
                ld_mdr = 1'b1;
                MDR_in = in;
                ld_mar = 1'b1;
                MAR_in = EA_X;
                next_state = S_IN2;
            end
            S_IN2: begin
                we = 1'b1;
                next_state = S_FETCH1;
            end
            // OUT instruction
            S_OUT1: begin
                ld_mar = 1'b1;
                MAR_in = EA_X;
                next_state = S_OUT2;
            end
            S_OUT2: begin
                next_state = S_OUT3;
            end
            S_OUT3: begin
                ld_mdr = 1'b1;
                MDR_in = mem;
                
                next_state = S_OUT4;
            end
            S_OUT4: begin
                out_next = MDR_out;
                next_state = S_FETCH1;
            end
            S_STOP: begin
                if (opX != 4'b0000) out_next = {{(DATA_WIDTH-4){1'b0}}, opX};
                else if (opY != 4'b0000) out_next = {{(DATA_WIDTH-4){1'b0}}, opY};
                else if (opZ != 4'b0000) out_next = {{(DATA_WIDTH-4){1'b0}}, opZ};
                next_state = S_HALT;
            end
            S_HALT: begin
                halted_next = 1'b1;
                next_state = S_HALT;
            end
            S_WAIT: begin
                next_state = S_FETCH1;
            end
            default: begin
                // unknown state, halt the CPU
                next_state = S_HALT;
            end
        endcase
    end
endmodule