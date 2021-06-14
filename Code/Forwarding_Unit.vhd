library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity Forwarding_Unit is
	generic(
		reg_size : INTEGER := 32 --reg size = 2^5 addressing depth
	);
    port
        ( 
		  clock: in std_logic;
		  rs : in INTEGER RANGE 0 TO reg_size -1; --source 1 register from decode
		  rt: in INTEGER RANGE 0 TO reg_size -1; -- source 2 register from decode
		  reg_ex_mem: in INTEGER RANGE 0 TO reg_size -1; -- destination register from execute memory latch
		  reg_mem_wb: in INTEGER RANGE 0 TO reg_size -1; -- destination register from memory write back
		  forwarded_inputX: out std_logic_vector(31 downto 0); --forwared inputs when forward conditions met
		  forwarded_inputY: out std_logic_vector(31 downto 0)
        );

end Forwarding_Unit;

architecture Behavioral of Forwarding_Unit is

--Internal signals, as the values are being read.
signal data_forward_inputX : std_logic_vector(31 downto 0);
signal data_forward_inputY : std_logic_vector(31 downto 0);

begin
--Data forwarding was not completed. We decided we would implement a forwarding unit as a component attached in 
--the Execute stage. As inputs to the forwarding unit, we would have a destination register from the EX/MEM phase, 
--the destination register from the MEM/WB phase, the rs (src1 register),rt (src2 register) from decode phase and 
--outputs from the forwarding unit would be signals "forwarded\_inputX" and "forwarded\_inputY" as forwarded outputs 
--to the ALU. The idea was that if EX/MEM destination register is equal to either rs or rt then forwarding will be
--required. We would then use the value that the ALU just produced in the last cycle as the input to the ALU in 
--the current cycle. Alternatively if the MEM/WB destination register equal to rs or rt to the forwarding unit,
--we would use the value from the MUX in the WB phase as one input to the ALU.

--------------------------------------------------------------
-- BRIEF PSEUDOCODE
--------------------------------------------------------------

--EX hazard
--if (EX/MEM.RegisterRd = ID/EX.RegisterRt)
	--	forwareded_inputX = data at Rd
--if (EX/MEM.RegisterRd = ID/EX RegisterRs)
	--	forwarded_inputY = data at Rd

---MEM hazard
--if(MEM/WB.RegisterRd = ID/EX.RegisterRs)
--	forwarded_inputX = data at Rd

--if (MEM/WB.RegisterRd = ID/EX.RegisterRt)
--	forwarded_inputY = data at Rd



end Behavioral;