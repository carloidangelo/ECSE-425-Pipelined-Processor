LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;

ENTITY Execute_tb IS
END Execute_tb;

ARCHITECTURE behaviour OF Execute_tb IS

--Declare the component that you are testing:
    COMPONENT Execute IS
        GENERIC(
		reg_size : INTEGER := 32; --reg size = 2^5 addressing depth
		instr_mem_size : integer := 4096
        );
        PORT (
 		clock : in std_logic;
    		input_X  : in std_logic_vector (31 downto 0); --alu
    		input_Y  : in std_logic_vector (31 downto 0); --alu
		address : in std_logic_vector (31 downto 0); --alu
    		alu_opcode : in std_logic_vector (4 downto 0); --alu
		alu_opcode_delayed : out std_logic_vector (4 downto 0); --alu
		pc_branch : out integer range 0 to instr_mem_size-1; --alu
		branch_taken : out std_logic; --alu
    		output_Z : out std_logic_vector(31 downto 0); --alu
		input_Y_delayed: out std_logic_vector (31 downto 0);
    		immediate : in std_logic_vector (31 downto 0); -- extended immediate value --for adder
    		pc_updated : in integer range 0 to instr_mem_size-1; --for adder
		rd_address : in INTEGER RANGE 0 TO reg_size -1;
		rd_address_delayed: out INTEGER RANGE 0 TO reg_size -1
        );
    END COMPONENT;

    --all the input signals with initial values
    signal clk : std_logic := '0';
    constant clk_period : time := 1 ns;
    signal input_X  : std_logic_vector (31 downto 0); --alu
    signal input_Y  : std_logic_vector (31 downto 0); --alu
    signal address : std_logic_vector (31 downto 0); --alu
    signal alu_opcode : std_logic_vector (4 downto 0); --alu
    signal alu_opcode_delayed : std_logic_vector (4 downto 0); --alu
    signal pc_branch : integer; --alu
    signal branch_taken : std_logic; --alu
    signal output_Z : std_logic_vector(31 downto 0); --alu
    signal input_Y_delayed: std_logic_vector (31 downto 0);
    signal immediate : std_logic_vector (31 downto 0); -- extended immediate value --for adder
    signal pc_updated : integer range 0 to 4096-1; --for adder
    signal rd_address : INTEGER RANGE 0 TO 32-1;
    signal rd_address_delayed: INTEGER RANGE 0 TO 32-1;


BEGIN

    dut: Execute 
    PORT MAP(
	clock => clk,
        input_X => input_X,
        input_Y => input_Y,
        alu_opcode => alu_opcode,
        output_Z => output_Z,
    	address => address,
    	alu_opcode_delayed => alu_opcode_delayed,
    	pc_branch => pc_branch,
    	branch_taken => branch_taken,
    	input_Y_delayed => input_Y_delayed,
    	immediate => immediate,
    	pc_updated => pc_updated,
    	rd_address => rd_address,
    	rd_address_delayed => rd_address_delayed
    );

    clk_process : process
    BEGIN
        clk <= '0';
        wait for clk_period/2;
        clk <= '1';
        wait for clk_period/2;
    end process;

    test_process : process
    BEGIN
        wait for clk_period;
        
        -- Test case 1: add = 00000
        report "Test case 1";
        input_X <= "00000000000000000000000000000000";
        input_Y <= "00000000000000000000000000000001"; 
        alu_opcode <= "00000";
        wait for clk_period;
        assert output_Z = "00000000000000000000000000000001" report "alu error" severity error;

        -- Test case 2: sub = 00110
        report "Test case 2";
        input_X <= "00000000000000000000000000000011";
        input_Y <= "00000000000000000000000000000001"; 
        alu_opcode <= "00110";
        wait for clk_period;
        assert output_Z = "00000000000000000000000000000010" report "alu error" severity error;

    
        -- Test case 3: xor = 00111
        report "Test case 3";
        input_X <= "00000000000000000000000000100001";
        input_Y <= "00000000000000000000011000001001"; 
        alu_opcode <= "00111";
        wait for clk_period;
        assert output_Z = "00000000000000000000011000101000" report "alu error" severity error;
     
        
        -- Test case 4: or = 00100
        report "Test case 4";
        input_X <= "00000000000000000000110010010001";
        input_Y <= "00000000000000000000010010000001"; 
        alu_opcode <= "00100";
        wait for clk_period;
        assert output_Z = "00000000000000000000110010010001" report "alu error" severity error;
        
        
        -- Test case 5: nor = 00011
        report "Test case 5";
        input_X <= "00000000000000000000000010010000";
        input_Y <= "00000000000000000000010001011001"; 
        alu_opcode <= "00011";
        wait for clk_period;
        assert output_Z =  "11111111111111111111101100100110" report "alu error" severity error;
        
        
        -- Test case 6: jr = 01110
        report "Test case 6";
        input_X <= "00000000000000000000110000011000";
        input_Y <= "00000000000000000000011000011001"; 
        alu_opcode <= "01110";
        wait for clk_period;
        assert output_Z = "00000000000000000000110000011000" report "alu error" severity error;
        
         -- Test case 7: sw = 10111
         report "Test case 7";
         address <= "00000000000000000000110000011000";
         alu_opcode <= "10111";
         wait for clk_period;
         assert output_Z = "00000000000000000000110000011000" report "alu error" severity error;

    wait; 
    END PROCESS;
END behaviour;