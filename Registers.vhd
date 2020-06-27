LIBRARY ieee;
USE ieee.std_logic_1164.all;

PACKAGE Registers IS

COMPONENT register4 IS
	PORT (
		dI: IN std_logic_vector(3 downto 0);
		clkI: IN std_logic;
		qI: OUT std_logic_vector(3 downto 0)
	);
END COMPONENT;

COMPONENT register8 IS
	PORT (
		dI: IN std_logic_vector(7 downto 0);
		clkI: IN std_logic;
		qI: OUT std_logic_vector(7 downto 0)
	);
END COMPONENT;

COMPONENT registerC IS
	PORT (
		dI: IN std_logic_vector(11 downto 0);
		clkI: IN std_logic;
		qI: OUT std_logic_vector(11 downto 0)
	);
END COMPONENT;

END Registers;