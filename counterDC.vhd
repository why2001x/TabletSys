LIBRARY ieee;
USE ieee.std_logic_1164.all;

USE work.Counters.all;

ENTITY counterDC IS
	PORT (
		clkI, clrKn: IN std_logic;
		qO: OUT std_logic_vector(11 downto 0)
	);
END counterDC;
ARCHITECTURE th68 OF counterDC IS
	SIGNAL temp: std_logic;
BEGIN
	u1: counterD8 PORT MAP(
		clkI => clkI,
		clrKn => clrKn,
		qO(7) => temp,
		qO(6 downto 0) => qO(6 downto 0)
	);
	qO(7) <= temp;
	u2: counterD4 PORT MAP(
		clkI => temp,
		clrKn => clrKn,
		qO => qO(11 downto 8)
	);
END th68;