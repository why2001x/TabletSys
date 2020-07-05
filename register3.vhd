LIBRARY ieee;
USE ieee.std_logic_1164.all;
LIBRARY altera;
USE altera.maxplus2.dffe;

USE work.Constants.all;

ENTITY register3 IS
	PORT (
		dI: IN std_logic_vector(2 downto 0);
		clkI, clrKn, EN: IN std_logic;
		qO: OUT std_logic_vector(2 downto 0)
	);
END register3;
ARCHITECTURE dff3 OF register3 IS
BEGIN
	u2: dffe PORT MAP(
		D => dI(2),
		CLK => clkI,
		CLRN => clrKn,
		PRN => VCC,
		ENA => EN,
		Q => qO(2)
	);
	u1: dffe PORT MAP(
		D => dI(1),
		CLK => clkI,
		CLRN => clrKn,
		PRN => VCC,
		ENA => EN,
		Q => qO(1)
	);
	u0: dffe PORT MAP(
		D => dI(0),
		CLK => clkI,
		CLRN => clrKn,
		PRN => VCC,
		ENA => EN,
		Q => qO(0)
	);
END dff3;