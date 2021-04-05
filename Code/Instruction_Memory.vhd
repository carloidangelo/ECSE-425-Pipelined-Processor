--Instruction_Memory.vhd

LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;
use std.textio.all;
use ieee.std_logic_textio.all;

ENTITY Instruction_Memory IS
	GENERIC(
		instr_mem_size : INTEGER := 4096;
		mem_delay : time := 1 ns;
		clock_period : time := 1 ns
	);
	PORT (
		clock: IN STD_LOGIC;
		address: IN INTEGER RANGE 0 TO instr_mem_size-1;
		memread: IN STD_LOGIC;
		readdata: OUT STD_LOGIC_VECTOR (31 DOWNTO 0);
		waitrequest: OUT STD_LOGIC
	);
END Instruction_Memory;

ARCHITECTURE behaviour OF Instruction_Memory IS
	TYPE MEM IS ARRAY(instr_mem_size-1 downto 0) OF STD_LOGIC_VECTOR(7 DOWNTO 0);
	SIGNAL ram_instr: MEM;
	SIGNAL fetch_instr: STD_LOGIC_VECTOR(31 DOWNTO 0);
	SIGNAL read_waitreq_reg: STD_LOGIC := '1';
	
BEGIN
	--This is the main section of the SRAM model
	mem_process: PROCESS (clock)
		file read_file : text;
		variable read_line : line; 				-- will be one line read from input file
		variable read_instr : std_logic_vector(31 downto 0); 	-- read one instruction from input file
		variable count : integer range 0 to instr_mem_size-1;
	BEGIN
		--This is a cheap trick to initialize the SRAM in simulation
		IF(now < 1 ps)THEN
			file_open(read_file, "program.txt", read_mode);
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

		IF (clock'event AND clock = '1') THEN
			fetch_instr(7 downto 0) <= ram_instr(address);
			fetch_instr(15 downto 8) <= ram_instr(address + 1);
			fetch_instr(23 downto 16) <= ram_instr(address + 2);
			fetch_instr(31 downto 24) <= ram_instr(address + 3);			
		END IF;
	END PROCESS;
	readdata <= fetch_instr;

	waitreq_r_proc: PROCESS (memread)
	BEGIN
		IF(memread'event AND memread = '1')THEN
			read_waitreq_reg <= '0' after mem_delay, '1' after mem_delay + clock_period;
		END IF;
	END PROCESS;
	waitrequest <= read_waitreq_reg;

END behaviour;
