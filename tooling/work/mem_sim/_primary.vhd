library verilog;
use verilog.vl_types.all;
entity mem_sim is
    port(
        clk             : in     vl_logic;
        rst_n           : in     vl_logic;
        we              : in     vl_logic;
        addr            : in     vl_logic_vector(3 downto 0);
        data            : in     vl_logic_vector(7 downto 0);
        \out\           : out    vl_logic_vector(7 downto 0)
    );
end mem_sim;
