library ieee;
use IEEE.std_logic_1164.all;
use ieee.numeric_std.all;

entity RegisterBlock is
	GENERIC(
			reg_size : INTEGER := 32; --reg size = 2^5 addressing depth
			mem_delay : time := 1 ns;
			clock_period : time := 1 ns
		);
  port (
	clock : in std_logic;
	reg_write: in std_logic; -- register write enable signal
	write_data: in std_logic_vector(31 downto 0);
	write_address: in INTEGER RANGE 0 TO reg_size-1;
	read_address1 : in INTEGER RANGE 0 TO reg_size -1; -- rs (src address 1)
	read_address2 : in INTEGER RANGE 0 TO reg_size -1; -- rt (src address 2)
	data_out1 : out std_logic_vector (31 downto 0); -- rs (data at src 1)
	data_out2 : out std_logic_vector (31 downto 0) -- rt (data at src 2)
    ) ;
end entity;
  
architecture behavior of RegisterBlock is
 TYPE REG IS ARRAY(reg_size-1 downto 0) OF STD_LOGIC_VECTOR(31 DOWNTO 0);
 SIGNAL reg_block: REG;
 
  begin
  --This is the main section of the SRAM model
	register_process: PROCESS (clock)
		file read_file : text;
		variable read_line : line; 				-- will be one line read from input file
		variable read_instr : std_logic_vector(31 downto 0); 	-- read one instruction from input file
		variable count : integer range 0 to instr_mem_size-1;
	BEGIN
		--This is a cheap trick to initialize the SRAM in simulation
		IF(now < 1 ps)THEN
			file_open(read_file, "register_file.txt", read_mode);
			while not endfile(read_file) loop
				readline(read_file, read_line);
				read(read_line, read_instr); 
				ram_instr(count) <= read_instr(7 downto 0);
				ram_instr(count + 1) <= read_instr(15 downto 8);
				ram_instr(count + 2) <= read_instr(23 downto 16);
				ram_instr(count + 3) <= read_instr(31 downto 24);
				count := count + 4;
			end loop;
			file_close(read_file);
		end if;

	register_process: process(clk)
	begin
	if rising_edge(clock) then
	
		if reg_write = '1' and write_address /=0 then --R0 is always zero
			reg_block(write_address) <= write_data; --write data to register location
		end if;
	end if;	
	data_out1 <= reg_block(read_address1); --read data in rs register location
	data_out2 <= reg_block(read_address2); --read data in rt register location
	end process;
end architecture;
	