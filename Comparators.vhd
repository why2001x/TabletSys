LIBRARY ieee;
USE ieee.std_logic_1164.all;

PACKAGE Comparators IS

COMPONENT comparatorA IS
	PORT (
		dataa, datab: IN std_logic_vector(11 downto 0);
		aeb, aneb, agb: OUT std_logic
	);
END COMPONENT;

COMPONENT comparatorC IS
	PORT (
		clock: IN std_logic;
		dataa, datab: IN std_logic_vector(11 downto 0);
		aeb, aneb, agb: OUT std_logic
	);
END COMPONENT;

END Comparators;