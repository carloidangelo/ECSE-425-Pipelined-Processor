library ieee;
use IEEE.std_logic_1164.all;
use ieee.numeric_std.all;
use std.textio.all;
use ieee.std_logic_textio.all;

entity RegisterBlock is
	GENERIC(
			reg_size : INTEGER := 32 --reg size = 2^5 addressing depth
		);
  port (
	clock : in std_logic;
	f_waitrequest: in std_logic;
	d_waitrequest: in std_logic;
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
 FILE write_file : TEXT;
  begin
  --This is the main section of the SRAM model
	register_process: PROCESS (clock)
		variable write_line : line; -- variable to holds data memory
		variable write_data : std_logic_vector(31 downto 0); 	-- get data from RAM block
	
	begin
	IF(now > 9999999 ps)THEN
			file_open(write_file, "register_file.txt", write_mode);
			For i in 0 to reg_size-1 LOOP
				write_data := reg_block(i);
				write(write_line, write_data);
				writeline(write_file, write_line);
			END LOOP;
			file_close(write_file);
		end if;
	if falling_edge(clock) then
	
		if reg_write = '1' and f_waitrequest = '0' and d_waitrequest = '0' and write_address /=0 then --R0 is always zero
			reg_block(write_address) <= write_data; --write data to register location
		end if;
	end if;	
	data_out1 <= reg_block(read_address1); --read data in rs register location
	data_out2 <= reg_block(read_address2); --read data in rt register location
	end process;
end architecture;
	