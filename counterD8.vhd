LIBRARY ieee;
USE ieee.std_logic_1164.all;
LIBRARY altera;
USE altera.maxplus2.a_7468;

ENTITY counterD8 IS
	PORT (
		clkI, clrKn: IN std_logic;
		qO: OUT std_logic_vector(7 downto 0)
	);
END counterD8;
ARCHITECTURE s68 OF counterD8 IS
	SIGNAL first, temp: std_logic;
BEGIN
	u: a_7468 PORT MAP(
		a_1clk1 => first,
		a_1clk2 => temp,
		a_1clrn => clrKn,
		a_1qd => qO(7),
		a_1qc => qO(6),
		a_1qb => qO(5),
		a_1qa => temp,
		
		a_2clk => clkI,
		a_2clrn => clrKn,
		a_2qd => first,
		a_2qc => qO(2),
		a_2qb => qO(1),
		a_2qa => qO(0)
	);
	qO(4) <= temp;
	qO(3) <= first;
END s68;