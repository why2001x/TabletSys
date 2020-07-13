LIBRARY ieee;
USE ieee.std_logic_1164.all;
LIBRARY altera;
USE altera.maxplus2.dffe;

USE work.Constants.all;

ENTITY register4 IS
	PORT (
		dI: IN std_logic_vector(3 downto 0);
		clkI, clrKn, EN: IN std_logic;
		qO: OUT std_logic_vector(3 downto 0)
	);
END register4;
ARCHITECTURE dff4 OF register4 IS
BEGIN
	u3: dffe PORT MAP(
		D => dI(3),
		CLK => clkI,
		CLRN => clrKn,
		PRN => VCC,
		ENA => EN,
		Q => qO(3)
	);
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
END dff4;