LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;

ENTITY alu_tb IS
END alu_tb;

ARCHITECTURE behaviour OF alu_tb IS

--Declare the component that you are testing:
    COMPONENT ALU IS
        GENERIC(
            instr_mem_size : INTEGER := 4096;
            mem_delay : time := 1 ns;
            clock_period : time := 1 ns
        );
        PORT (
            input_X : in STD_LOGIC_VECTOR (31 downto 0);
			input_Y : in STD_LOGIC_VECTOR (31 downto 0);
			alu_opcode : in STD_LOGIC_VECTOR (4 downto 0);
			output_Z : out STD_LOGIC_VECTOR(31 downto 0)
        );
    END COMPONENT;

    --all the input signals with initial values
    signal clk : std_logic := '0';
    constant clk_period : time := 1 ns;
	signal input_X : STD_LOGIC_VECTOR(31 downto 0);
	signal input_Y : STD_LOGIC_VECTOR(31 downto 0);
	signal alu_opcode : STD_LOGIC_VECTOR(4 downto 0);
	signal output_Z : STD_LOGIC_VECTOR (31 downto 0);


BEGIN

    dut: ALU 
    PORT MAP(
	    clock => clk,
        input_X => input_X,
        input_Y => input_Y,
        alu_opcode => alu_opcode,
        output_Z => output_Z
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
        alu_opcode <= "00000"
        wait for clk_period;
        assert output_Z = "00000000000000000000000000000001" report "alu error" severity error;

        -- Test case 2: sub = 00110
        report "Test case 2";
        input_X <= "00000000000000000000000000000011";
        input_Y <= "00000000000000000000000000000001"; 
        alu_opcode <= "00110"
        wait for clk_period;
        assert output_Z = "00000000000000000000000000000010" report "alu error" severity error;

    
        -- Test case 3: xor = 00111
        report "Test case 3";
        input_X <= "00000000000000000000000000100001";
        input_Y <= "00000000000000000000011000001001"; 
        alu_opcode <= "00111"
        wait for clk_period;
        assert output_Z = "00000000000000000000011000101000" report "alu error" severity error;
     
        
        -- Test case 4: or = 00100
        report "Test case 4";
        input_X <= "00000000000000000000110010010001";
        input_Y <= "00000000000000000000010010000001"; 
        alu_opcode <= "00100"
        wait for clk_period;
        assert output_Z = "00000000000000000000110010010001" report "alu error" severity error;
        
        
        -- Test case 5: nor = 00011
        report "Test case 5";
        input_X <= "00000000000000000000000010010000";
        input_Y <= "00000000000000000000010001011001"; 
        alu_opcode <= "00000"
        wait for clk_period;
        assert output_Z =  "11111111111111111111101100100110" report "alu error" severity error;
        
        
        -- Test case 6: jr = 01110
        report "Test case 6";
        input_X <= "00000000000000000000110000011000";
        input_Y <= "00000000000000000000011000011001"; 
        alu_opcode <= "01110"
        wait for clk_period;
        assert output_Z = "00000000000000000000110000011000" report "alu error" severity error;
        
    wait; 
    END PROCESS;
END behaviour;