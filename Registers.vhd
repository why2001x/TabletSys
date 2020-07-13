LIBRARY ieee;
USE ieee.std_logic_1164.all;

PACKAGE Registers IS

COMPONENT register1 IS
	PORT (
		dI: IN std_logic_vector(0 downto 0);
		clkI, clrKn, EN: IN std_logic;
		qO: OUT std_logic_vector(0 downto 0)
	);
END COMPONENT;

COMPONENT register2 IS
	PORT (
		dI: IN std_logic_vector(1 downto 0);
		clkI, clrKn, EN: IN std_logic;
		qO: OUT std_logic_vector(1 downto 0)
	);
END COMPONENT;

COMPONENT register4 IS
	PORT (
		dI: IN std_logic_vector(3 downto 0);
		clkI, clrKn, EN: IN std_logic;
		qO: OUT std_logic_vector(3 downto 0)
	);
END COMPONENT;

END Registers;