LIBRARY ieee;
USE ieee.std_logic_1164.all;
LIBRARY altera;
USE altera.maxplus2.dffe;

USE work.Constants.all;

ENTITY register2 IS
	PORT (
		dI: IN std_logic_vector(1 downto 0);
		clkI, clrKn, EN: IN std_logic;
		qO: OUT std_logic_vector(1 downto 0)
	);
END register2;
ARCHITECTURE dff2 OF register2 IS
BEGIN
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
END dff2;