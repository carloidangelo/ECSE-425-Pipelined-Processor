library ieee;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity adder is
	generic(
		instr_mem_size : integer := 4096
	);
port(
	extended_immediate : in std_logic_vector (31 downto 0);  
	 pc_updated : in integer range 0 to instr_mem_size-1;
	 result : out integer range 0 to instr_mem_size-1
	 );
end adder;

architecture adder_arch of adder is

signal increment : signed (31 downto 0);

begin
	increment <= shift_left(signed(extended_immediate),2);
	result <= pc_updated + to_integer(increment); 
end adder_arch;