LIBRARY ieee;
USE ieee.std_logic_1164.all;
LIBRARY altera;
USE altera.maxplus2.a_7468;

USE work.Constants.all;

ENTITY counterD4 IS
	PORT (
		clkI, clrKn: IN std_logic;
		qO: OUT std_logic_vector(3 downto 0)
	);
END counterD4;
ARCHITECTURE sh68 OF counterD4 IS
BEGIN
	u: a_7468 PORT MAP(
		a_2clk => clkI,
		a_2clrn => clrKn,
		a_2qd => qO(3),
		a_2qc => qO(2),
		a_2qb => qO(1),
		a_2qa => qO(0),
		
		a_1clk1 => GND,
		a_1clk2 => GND,
		a_1clrn => GND
	);
END sh68;