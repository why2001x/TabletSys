LIBRARY ieee;
USE ieee.std_logic_1164.all;
LIBRARY altera;
USE altera.maxplus2.a_7485;

ENTITY comparator4 IS
	PORT (
		aI, bI: IN std_logic_vector(3 downto 0);
		albI, agbI, aebI: IN std_logic;
		albO, agbO, aebO: OUT std_logic
	);
END comparator4;
ARCHITECTURE s85 OF comparator4 IS
BEGIN
	u: a_7485 PORT MAP(
		a => aI,
		b => bI,
		agbi => agbI,
		albi => albI,
		aebi => aebI,
		agbo => agbO,
		albo => albO,
		aebo => aebO
	);
END s85;