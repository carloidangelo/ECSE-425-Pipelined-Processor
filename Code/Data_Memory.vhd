LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;
use std.textio.all;
use ieee.std_logic_textio.all;

ENTITY Data_Memory IS
	GENERIC(
		ram_size : INTEGER := 32768;
		mem_delay : time := 1 ns;
		clock_period : time := 1 ns
	);
	PORT (
		clock: IN STD_LOGIC;
		writedata: IN STD_LOGIC_VECTOR (31 DOWNTO 0);
		address: IN INTEGER RANGE 0 TO ram_size-1;
		memwrite: IN STD_LOGIC;
		memread: IN STD_LOGIC;
		readdata: OUT STD_LOGIC_VECTOR (31 DOWNTO 0);
		waitrequest: OUT STD_LOGIC
	);
END Data_Memory;

ARCHITECTURE rtl OF Data_Memory IS
	TYPE MEM IS ARRAY(ram_size-1 downto 0) OF STD_LOGIC_VECTOR(7 DOWNTO 0);
	SIGNAL ram_block: MEM;
	SIGNAL read_address_reg: INTEGER RANGE 0 to ram_size-1;
	SIGNAL write_waitreq_reg: STD_LOGIC := '1';
	SIGNAL read_waitreq_reg: STD_LOGIC := '1';
	SIGNAL fetch_instr: STD_LOGIC_VECTOR(31 DOWNTO 0);
BEGIN
	--This is the main section of the SRAM model
	mem_process: PROCESS (clock)
	BEGIN
		--This is a cheap trick to initialize the SRAM in simulation
		IF(now < 1 ps)THEN
			For i in 0 to ram_size-1 LOOP
				--initialize the data memory to all zeros
				ram_block(i) <= std_logic_vector(to_unsigned(0,8));
			END LOOP;
		end if;

		IF (clock'event AND clock = '1') THEN
			IF (memread = '1') THEN
				fetch_instr(7 downto 0) <= ram_block(address);
				fetch_instr(15 downto 8) <= ram_block(address + 1);
				fetch_instr(23 downto 16) <= ram_block(address + 2);
				fetch_instr(31 downto 24) <= ram_block(address + 3);
			
			ELSIF (memwrite = '1') THEN
				ram_block(address) <= writedata(7 DOWNTO 0);
				ram_block(address+1) <= writedata(15 downto 8);
				ram_block(address+2) <= writedata(23 downto 16);
				ram_block(address+3) <= writedata(31 downto 24);
			END IF;
		END IF;

	END PROCESS;
	readdata <= fetch_instr;



	--The waitrequest signal is used to vary response time in simulation
	--Read and write should never happen at the same time.
	waitreq_w_proc: PROCESS (memwrite)
	BEGIN
		IF(memwrite'event AND memwrite = '1')THEN
			write_waitreq_reg <= '0' after mem_delay, '1' after mem_delay + clock_period;

		END IF;
	END PROCESS;

	waitreq_r_proc: PROCESS (memread)
	BEGIN
		IF(memread'event AND memread = '1')THEN
			read_waitreq_reg <= '0' after mem_delay, '1' after mem_delay + clock_period;
		END IF;
	END PROCESS;
	waitrequest <= write_waitreq_reg and read_waitreq_reg;


END rtl;
