library ieee;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity adder is
port(
	 increment : in integer;
	 PC : in std_logic_vector(31 downto 0);
	 result : out std_logic_vector(31 downto 0)
	 );
end adder;

architecture adder_arch of adder is

signal add : integer;

begin
	add <= to_integer(unsigned(PC)) + increment; 
	result <= std_logic_vector(to_unsigned(add, result'length));
end adder_arch;