LIBRARY ieee;
USE ieee.std_logic_1164.all;

USE work.Counters.all;

ENTITY counterD14 IS
	PORT (
		clkI, clrKn: IN std_logic;
		qO: OUT std_logic_vector(19 downto 0)
	);
END counterD14;
ARCHITECTURE ph68 OF counterD14 IS
	SIGNAL First: std_logic;
	SIGNAL Secnd: std_logic;
BEGIN
	u1: counterD8 PORT MAP(
		clkI => clkI,
		clrKn => clrKn,
		qO(7) => First,
		qO(6 downto 0) => qO(6 downto 0)
	);
	qO(7) <= First;
	u2: counterD8 PORT MAP(
		clkI => First,
		clrKn => clrKn,
		qO(7) => Secnd,
		qO(6 downto 0) => qO(14 downto 8)
	);
	qO(15) <= Secnd;
	u3: counterD4 PORT MAP(
		clkI => Secnd,
		clrKn => clrKn,
		qO => qO(19 downto 16)
	);
END ph68;