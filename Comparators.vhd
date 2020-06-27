LIBRARY ieee;
USE ieee.std_logic_1164.all;

PACKAGE Comparators IS

COMPONENT comparator4 IS
	PORT (
		aI, bI: IN std_logic_vector(3 downto 0);
		albI, agbI, aebI: IN std_logic;
		albO, agbO, aebO: OUT std_logic
	);
END COMPONENT;

COMPONENT comparator8 IS
	PORT (
		aI, bI: IN std_logic_vector(7 downto 0);
		albI, agbI, aebI: IN std_logic;
		albO, agbO, aebO: OUT std_logic
	);
END COMPONENT;

COMPONENT comparatorC IS
	PORT (
		aI, bI: IN std_logic_vector(11 downto 0);
		albI, agbI, aebI: IN std_logic;
		albO, agbO, aebO: OUT std_logic
	);
END COMPONENT;

END Comparators;