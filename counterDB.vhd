LIBRARY ieee;
USE ieee.std_logic_1164.all;

USE work.Counters.all;

ENTITY counterDB IS
	PORT (
		clkI, clrKn: IN std_logic;
		qO: OUT std_logic_vector(10 downto 0)
	);
END counterDB;
ARCHITECTURE s68p3 OF counterDB IS
	SIGNAL temp: std_logic;
BEGIN
	u1: counterD8 PORT MAP(
		clkI => clkI,
		clrKn => clrKn,
		qO(7) => temp,
		qO(6 downto 0) => qO(6 downto 0)
	);
	qO(7) <= temp;
	u2: count_07 PORT MAP(
		clock => temp,
		aclr => not clrKn,
		q => qO(10 downto 8)
	);
END s68p3;