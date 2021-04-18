library ieee;
use ieee.std_logic_1164.all;
use IEEE.numeric_std.all;

entity Execute is
	generic(
			reg_size : INTEGER := 32; --reg size = 2^5 addressing depth
			instr_mem_size : integer := 4096
		);
  port (
    input_X  : in std_logic_vector (31 downto 0); --alu
    input_Y  : in std_logic_vector (31 downto 0); --alu
	address : in std_logic_vector (31 downto 0); --alu
    alu_opcode : in std_logic_vector (4 downto 0); --alu
	 alu_opcode_delayed : out std_logic_vector (4 downto 0); --alu
	pc_branch : out integer range 0 to instr_mem_size-1; --alu
	branch_taken : out std_logic:= '0'; --alu
    output_Z : out std_logic_vector(31 downto 0); --alu
	 input_Y_delayed: out std_logic_vector (31 downto 0);
    immediate : in std_logic_vector (31 downto 0); -- extended immediate value --for adder
    pc_updated : in integer range 0 to instr_mem_size-1; --for adder
	 rd_address : in INTEGER RANGE 0 TO reg_size -1;
	 rd_address_delayed: out INTEGER RANGE 0 TO reg_size -1
  );
end Execute;

-- Report Notes (remvove later)
-- -- we used 64 instead of 32 for product vector size
architecture behavior of Execute is
  -- hi & lo -> from reference of MIPS used to assign remainder (rmdr) and quotient results of a division operation
  signal hi, lo, rmdr, quotient : std_logic_vector (31 downto 0);
  --signal product                     : std_logic_vector (31 downto 0);
  signal product : std_logic_vector (63 downto 0);
  signal increment : signed (31 downto 0);

begin
	input_Y_delayed <= input_Y;
	alu_opcode_delayed <= alu_opcode;
	rd_address_delayed <= rd_address;
  process (input_X, input_Y, alu_opcode)
  begin
	
    case alu_opcode is
      -- R-Types 

        -- add 
      when "00000" =>
        output_Z <= std_logic_vector(to_unsigned(to_integer(unsigned(input_X)) + to_integer(unsigned(input_Y)), output_Z'length));

      -- and
      when "00001" =>
        output_Z <= input_X and input_Y;

      -- div
      when "00010" =>
        quotient  <= std_logic_vector(to_unsigned(to_integer(unsigned(input_X)) / to_integer(unsigned(input_Y)), output_Z'length));
        rmdr <= std_logic_vector(to_unsigned(to_integer(unsigned(input_X)) mod to_integer(unsigned(input_Y)), rmdr'length));
        hi <= rmdr;
        lo <= quotient;
        output_Z <= quotient;

      -- nor
      when "00011" =>
        output_Z <= input_X nor input_Y;

      -- or
      when "00100" =>
        output_Z <= input_X or input_Y;

      -- slt
      when "00101" =>
        if (unsigned(input_X) < unsigned(input_Y)) then
          output_Z <= x"00000001"; 
        else
          output_Z <= x"00000000"; 
        end if;

      -- sub
      when "00110" =>
        output_Z <= std_logic_vector(to_unsigned(to_integer(unsigned(input_X)) - to_integer(unsigned(input_Y)), output_Z'length));
           
      -- xor
      when "00111" =>
        output_Z <= input_X xor input_Y;

      -- mult
      when "01000" =>
        product  <= std_logic_vector(to_unsigned(to_integer(unsigned(input_X)) * to_integer(unsigned(input_Y)), 64)); 
        hi <= product (63 downto 32); 
        lo <= product (31 downto 0); 
        output_Z <= std_logic_vector(to_unsigned(to_integer(unsigned(input_X)) * to_integer(unsigned(input_Y)), output_Z'length)); 

      -- mfhi
      when "01001" =>
        output_Z <= hi; 
       
      --mflo
      when "01010" =>
        output_Z <= lo; 
    
     -- sra 
     when "01011" =>
     if input_X(31) = '0' then
       output_Z <= std_logic_vector(to_unsigned(0, to_integer(unsigned(input_Y(10 downto 6))))) & input_X(31 downto (0 + to_integer(unsigned(input_Y(10 downto 6)))));
     else
       output_Z <= std_logic_vector(to_unsigned(1, to_integer(unsigned(input_Y(10 downto 6))))) & input_X(31 downto (0 + to_integer(unsigned(input_Y(10 downto 6)))));
     end if;

     -- sll 
      when "01100" =>
        output_Z <= input_X((31 - to_integer(unsigned(input_Y(10 downto 6)))) downto 0) & std_logic_vector(to_unsigned(0, to_integer(unsigned(input_Y(10 downto 6)))));

     -- srl 
      when "01101" =>
        output_Z <= std_logic_vector(to_unsigned(0, to_integer(unsigned(input_Y(10 downto 6))))) & input_X(31 downto (0 + to_integer(unsigned(input_Y(10 downto 6)))));

     -- jr 
      when "01110" =>
        output_Z <= input_X;

      -- j 
      when "01111" =>
        output_Z <= input_X(31 downto 28) & input_Y(25 downto 0) & "00";

       -- jal 
      when "10000" =>
        output_Z <= input_X(31 downto 28) & input_Y(25 downto 0) & "00";

       -- addi
      when "10001" =>
        output_Z <= std_logic_vector(to_unsigned(to_integer(unsigned(input_X)) + to_integer(unsigned(input_Y)), output_Z'length));
      
      -- andi
      when "10010" =>
        output_Z <= input_X and input_Y;

      -- ori
      when "10011" =>
        output_Z <= input_X or input_Y;

      -- xori
      when "10100" =>
        output_Z <= input_X xor input_Y;
              
      -- lw
      when "10101" =>
        output_Z <= address;

      -- lui
      when "10110" =>
        output_Z <= input_Y(15 downto 0) & std_logic_vector(to_unsigned(0, 16)); -- output mask x11110000 (keep only 16 MSB)
    
      -- sw
      when "10111" =>
        output_Z <= address;
    
      -- slti
      when "11000" =>
        if (unsigned(input_X) < unsigned(input_Y)) then
          output_Z <= x"00000001"; -- True
        else
          output_Z <= x"00000000"; -- False
        end if;

      -- beq
      when "11001" =>
        output_Z <= std_logic_vector(to_unsigned((to_integer(unsigned(input_X)) + to_integer(unsigned(input_Y)) * 4), output_Z'length));
      
      -- bne
      when "11010" =>
        output_Z <= std_logic_vector(to_unsigned((to_integer(unsigned(input_X)) + to_integer(unsigned(input_Y)) * 4), output_Z'length));
      
      -- if alu_opcode is any other format
      when others =>
        NULL;

    end case;

  end process;
  increment <= shift_left(signed(immediate),2);
  pc_branch <= pc_updated + to_integer(increment); 

end behavior;
