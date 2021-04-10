--Write_Back.vhd

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity Write_Back is
	generic(
		instr_mem_size : integer := 4096
	);
	port (
		clock: in std_logic;
		f_waitrequest: in std_logic;
		d_waitrequest: in std_logic;
		mem_status: in std_logic;
		readdata : in std_logic_vector (31 downto 0);
		alu_result : in std_logic_vector (31 downto 0)
	);
end Write_Back;

architecture behaviour of Write_Back is

begin

	execute: process (clock)
	begin
		if (falling_edge(clock)) then
			if (f_waitrequest = '0' and d_waitrequest = '0') then
				if (mem_status = '1') then
				else 
				end if;
				
			end if;
		end if;
	end process;

end behaviour;