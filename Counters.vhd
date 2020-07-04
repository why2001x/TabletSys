LIBRARY ieee;
USE ieee.std_logic_1164.all;

PACKAGE Counters IS

COMPONENT counterD1 IS
	PORT (
		clkI, clrKn: IN std_logic;
		qO: OUT std_logic_vector(0 downto 0)
	);
END COMPONENT;

COMPONENT counterD3 IS
	PORT (
		clkI, clrKn: IN std_logic;
		qO: OUT std_logic_vector(2 downto 0)
	);
END COMPONENT;

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

COMPONENT count_09 IS
	PORT (
		aclr, clk_en, clock: IN std_logic;
		cout: OUT std_logic;
		q: OUT std_logic_vector (3 downto 0)
	);
END COMPONENT;

END Counters;