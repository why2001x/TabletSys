LIBRARY ieee;
USE ieee.std_logic_1164.all;

PACKAGE Counters IS

COMPONENT counterD4 IS
	PORT (
		clkI, clrKn: IN std_logic;
		qO: OUT std_logic_vector(3 downto 0)
	);
END COMPONENT;

COMPONENT counterD8 IS
	PORT (
		clkI, clrKn: IN std_logic;
		qO: OUT std_logic_vector(7 downto 0)
	);
END COMPONENT;

COMPONENT counterDC IS
	PORT (
		clkI, clrKn: IN std_logic;
		qO: OUT std_logic_vector(11 downto 0)
	);
END COMPONENT;

END Counters;