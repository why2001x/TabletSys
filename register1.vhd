LIBRARY ieee;
USE ieee.std_logic_1164.all;
LIBRARY altera;
USE altera.maxplus2.dffe;

USE work.Constants.all;

ENTITY register1 IS
	PORT (
		dI: IN std_logic_vector(0 downto 0);
		clkI, clrKn, EN: IN std_logic;
		qO: OUT std_logic_vector(0 downto 0)
	);
END register1;
ARCHITECTURE dff1 OF register1 IS
BEGIN
	u0: dffe PORT MAP(
		D => dI(0),
		CLK => clkI,
		CLRN => clrKn,
		PRN => VCC,
		ENA => EN,
		Q => qO(0)
	);
END dff1;