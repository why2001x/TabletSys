LIBRARY ieee;
USE ieee.std_logic_1164.all;

USE work.Counters.all;

ENTITY counterDA IS
	PORT (
		clkI, clrKn: IN std_logic;
		qO: OUT std_logic_vector(9 downto 0)
	);
END counterDA;
ARCHITECTURE s68p3 OF counterDA IS
	SIGNAL temp: std_logic;
BEGIN
	u1: counterD8 PORT MAP(
		clkI => clkI,
		clrKn => clrKn,
		qO(7) => temp,
		qO(6 downto 0) => qO(6 downto 0)
	);
	qO(7) <= temp;
	u2: count_03 PORT MAP(
		clock => temp,
		aclr => not clrKn,
		q => qO(9 downto 8)
	);
END s68p3;