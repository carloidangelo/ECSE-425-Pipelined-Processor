LIBRARY ieee;
USE ieee.STD_LOGIC_1164.all;

ENTITY fsm_tb IS
END fsm_tb;

ARCHITECTURE behaviour OF fsm_tb IS

COMPONENT comments_fsm IS
PORT (clk : in std_logic;
      reset : in std_logic;
      input : in std_logic_vector(7 downto 0);
      output : out std_logic
  );
END COMPONENT;

--The input signals with their initial values
SIGNAL clk, s_reset, s_output: STD_LOGIC := '0';
SIGNAL s_input: std_logic_vector(7 downto 0) := (others => '0');

CONSTANT clk_period : time := 1 ns;
CONSTANT SLASH_CHARACTER : std_logic_vector(7 downto 0) := "00101111";
CONSTANT STAR_CHARACTER : std_logic_vector(7 downto 0) := "00101010";
CONSTANT NEW_LINE_CHARACTER : std_logic_vector(7 downto 0) := "00001010";

BEGIN
dut: comments_fsm
PORT MAP(clk, s_reset, s_input, s_output);

 --clock process
clk_process : PROCESS
BEGIN
	clk <= '0';
	WAIT FOR clk_period/2;
	clk <= '1';
	WAIT FOR clk_period/2;
END PROCESS;
 
--TODO: Thoroughly test your FSM
stim_process: PROCESS
BEGIN   
	REPORT "Initialization (setting current state to S0)";
	s_reset <= '1';
	WAIT FOR 1 * clk_period;
	s_reset <= '0';
	WAIT FOR 1 * clk_period;
	
	-- Test case 1: X
	REPORT "Example case, reading a meaningless character";
	-- Input: X
	s_input <= "01011000";
	WAIT FOR 1 * clk_period;
	ASSERT (s_output = '0') REPORT "When reading a meaningless character, the output should be '0'" SEVERITY ERROR;
	
	-- Test case 2: //AS\nD
	REPORT "Example case, reading a '//' comment";
	-- Input: /
	s_input <= SLASH_CHARACTER;
	WAIT FOR 1 * clk_period;
	ASSERT (s_output = '0') REPORT "When reading the first slash of a '//' comment, the output should be '0'" SEVERITY ERROR;
	-- Input: /
	s_input <= SLASH_CHARACTER;
	WAIT FOR 1 * clk_period;
	ASSERT (s_output = '0') REPORT "When reading the second slash of a '//' comment, the output should be '0'" SEVERITY ERROR;
	-- Input: A
	s_input <= "01000001";
	WAIT FOR 1 * clk_period;
	ASSERT (s_output = '1') REPORT "When reading the first character after the opening sequence, the output should be '1'" SEVERITY ERROR;
	-- Input: S
	s_input <= "01010011";
	WAIT FOR 1 * clk_period;
	ASSERT (s_output = '1') REPORT "When reading the second character after the opening sequence, the output should be '1'" SEVERITY ERROR;
	-- Input: \n
	s_input <= NEW_LINE_CHARACTER;
	WAIT FOR 1 * clk_period;
	ASSERT (s_output = '1') REPORT "When reading the exit sequence, the output should be '1'" SEVERITY ERROR;
	-- Input: D
	s_input <= "01000100";
	WAIT FOR 1 * clk_period;
	ASSERT (s_output = '0') REPORT "When reading the first character after the exit sequence, the output should be '0'" SEVERITY ERROR;

	-- Test case 3: /*A\nS*/D
	REPORT "Example case, reading a '/**/' comment";
	-- Input: /
	s_input <= SLASH_CHARACTER;
	WAIT FOR 1 * clk_period;
	ASSERT (s_output = '0') REPORT "When reading the slash of a '/*' comment, the output should be '0'" SEVERITY ERROR;
	-- Input: *
	s_input <= STAR_CHARACTER;
	WAIT FOR 1 * clk_period;
	ASSERT (s_output = '0') REPORT "When reading the star of a '/*' comment, the output should be '0'" SEVERITY ERROR;
	-- Input: A
	s_input <= "01000001";
	WAIT FOR 1 * clk_period;
	ASSERT (s_output = '1') REPORT "When reading the first character after the opening sequence, the output should be '1'" SEVERITY ERROR;
	-- Input: \n
	s_input <= NEW_LINE_CHARACTER;
	WAIT FOR 1 * clk_period;
	ASSERT (s_output = '1') REPORT "When reading the exit sequence within the comment, the output should be '1'" SEVERITY ERROR;
	-- Input: S
	s_input <= "01010011";
	WAIT FOR 1 * clk_period;
	ASSERT (s_output = '1') REPORT "When reading the third character after the opening sequence, the output should be '1'" SEVERITY ERROR;
	-- Input: *
	s_input <= STAR_CHARACTER;
	WAIT FOR 1 * clk_period;
	ASSERT (s_output = '1') REPORT "When reading the star of a '*/' comment, the output should be '1'" SEVERITY ERROR;
	-- Input: /
	s_input <= SLASH_CHARACTER;
	WAIT FOR 1 * clk_period;
	ASSERT (s_output = '1') REPORT "When reading the slash of a '*/' comment, the output should be '1'" SEVERITY ERROR;
	-- Input: D
	s_input <= "01000100";
	WAIT FOR 1 * clk_period;
	ASSERT (s_output = '0') REPORT "When reading the first character after the exit sequence, the output should be '0'" SEVERITY ERROR;

	-- Test case 4: //A(RESET)S
	REPORT "Example case, testing reset for a '//' comment";
	-- Input: /
	s_input <= SLASH_CHARACTER;
	WAIT FOR 1 * clk_period;
	ASSERT (s_output = '0') REPORT "When reading the first slash of a '//' comment, the output should be '0'" SEVERITY ERROR;
	-- Input: /
	s_input <= SLASH_CHARACTER;
	WAIT FOR 1 * clk_period;
	ASSERT (s_output = '0') REPORT "When reading the second slash of a '//' comment, the output should be '0'" SEVERITY ERROR;
	-- Input: A
	s_input <= "01000001";
	WAIT FOR 1 * clk_period;
	ASSERT (s_output = '1') REPORT "When reading the first character after the opening sequence, the output should be '1'" SEVERITY ERROR;
	-- RESET
	s_reset <= '1';
	WAIT FOR 1 * clk_period;
	ASSERT (s_output = 'X') REPORT "When resetting, the output should be 'X'" SEVERITY ERROR;
	-- Input: S
	s_reset <= '0';
	s_input <= "01010011";
	WAIT FOR 1 * clk_period;
	ASSERT (s_output = '0') REPORT "When reading the character after the RESET, the output should be '0'" SEVERITY ERROR;

	-- Test case 5: /*A(RESET)S
	REPORT "Example case, resetting within a '/**/' comment";
	-- Input: /
	s_input <= SLASH_CHARACTER;
	WAIT FOR 1 * clk_period;
	ASSERT (s_output = '0') REPORT "When reading the slash of a '/*' comment, the output should be '0'" SEVERITY ERROR;
	-- Input: *
	s_input <= STAR_CHARACTER;
	WAIT FOR 1 * clk_period;
	ASSERT (s_output = '0') REPORT "When reading the star of a '/*' comment, the output should be '0'" SEVERITY ERROR;
	-- Input: A
	s_input <= "01000001";
	WAIT FOR 1 * clk_period;
	ASSERT (s_output = '1') REPORT "When reading the first character after the opening sequence, the output should be '1'" SEVERITY ERROR;
	-- RESET
	s_reset <= '1';
	WAIT FOR 1 * clk_period;
	ASSERT (s_output = 'X') REPORT "When resetting, the output should be 'X'" SEVERITY ERROR;
	-- Input: S
	s_reset <= '0';
	s_input <= "01010011";
	WAIT FOR 1 * clk_period;
	ASSERT (s_output = '0') REPORT "When reading the character after the RESET, the output should be '0'" SEVERITY ERROR;


    
	WAIT;
END PROCESS stim_process;
END;
