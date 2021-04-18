library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity Decode_tb is
end Decode_tb;

architecture behavior of Decode_tb is


component Decode is
generic(
		reg_size : INTEGER := 32; --reg size = 2^5 addressing depth
		instr_mem_size : integer := 4096
	);
	port( 
		clock: in std_logic;
		f_waitrequest: in std_logic;
		d_waitrequest: in std_logic;
		instruction: in std_logic_vector (31 downto 0);
		pc_updated : in integer range 0 to instr_mem_size-1;
		pc_updated_delay : out integer range 0 to instr_mem_size-1;
		read_data1 : out std_logic_vector(31 downto 0); 
		read_data2 : out std_logic_vector(31 downto 0); 
		extended_immediate : out std_logic_vector (31 downto 0); -- extended immediate value
		alu_opcode : out std_logic_vector (4 downto 0); -- operation code for ALU
		address : out std_logic_vector (31 downto 0);
		rd_address: out INTEGER RANGE 0 TO reg_size -1; -- destination register address	
		-- data hazard detections
		delay: out std_logic := '0'
		
		);
end component;

------------------------ BEGIN test signals-----------------------------------
		signal clock: std_logic := '0';
		constant clock_period : time := 1 ns;
		signal status_sync: std_logic := '1';
		signal f_waitrequest: std_logic:= '1';
		signal d_waitrequest: std_logic:= '1';
		signal instruction: std_logic_vector (31 downto 0);
		signal pc_updated : integer range 0 to 4096-1;
		---Output Signals
		signal pc_updated_delay : integer range 0 to 4096-1;
		signal read_data1 : std_logic_vector(31 downto 0); 
		signal read_data2 : std_logic_vector(31 downto 0); 
		signal extended_immediate : std_logic_vector (31 downto 0); -- extended immediate value
		signal alu_opcode : std_logic_vector (4 downto 0); -- operation code for ALU
		signal address : std_logic_vector (31 downto 0);
		signal rd_address: INTEGER RANGE 0 TO 32 -1; -- destination register address	
		-- data hazard detections
		signal delay: std_logic := '0';
		
---------------- END test signals ---------------------------------------------

begin

dec_test: Decode
port map(
		clock => clock,
		f_waitrequest => f_waitrequest,
		d_waitrequest => d_waitrequest,
		instruction => instruction,
		pc_updated => pc_updated,
		pc_updated_delay => pc_updated_delay,
		read_data1 => read_data1, 
		read_data2 => read_data2, 
		extended_immediate => extended_immediate, -- extended immediate value
		alu_opcode => alu_opcode, -- operation code for ALU
		address => address,
		rd_address => rd_address,-- destination register address	
		-- data hazard detections
		delay => delay

);

clock_process: process
begin
	clock <= '1';
	wait for clock_period/2;
	clock <= '0';
	wait for clock_period/2;
end process;


test_process: process

begin

REPORT "TEST 1: I-type instruction (addi $30, $0, 4)";

instruction <= "001000" & "11110" & "00000" & "0000000000000100";
f_waitrequest <= '0';
   
wait for clock_period;
f_waitrequest <= '1';
wait for clock_period;

assert (alu_opcode = "10001") report "FAILURE ALU opcode was not 10001" severity error;
assert (read_data1 = std_logic_vector(to_unsigned(0,32))) report "Read data not 0";
assert (extended_immediate = std_logic_vector(to_unsigned(4,32))) report "FAILURE immediate was not 4" severity error;


wait;

end process;



end behavior;