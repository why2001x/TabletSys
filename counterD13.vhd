LIBRARY ieee;
USE ieee.std_logic_1164.all;

USE work.Counters.all;

ENTITY counterD13 IS
	PORT (
		clkI, clrKn: IN std_logic;
		qO: OUT std_logic_vector(18 downto 0)
	);
END counterD13;
ARCHITECTURE d68p1 OF counterD13 IS
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
	u3: count_07 PORT MAP(
		clock => not Secnd,
		aclr => not clrKn,
		q => qO(18 downto 16)
	);
END d68p1;