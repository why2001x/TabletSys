LIBRARY ieee;
USE ieee.std_logic_1164.all;

USE work.Comparators.all;

ENTITY comparatorC IS
	PORT (
		aI, bI: IN std_logic_vector(11 downto 0);
		albI, agbI, aebI: IN std_logic;
		albO, agbO, aebO: OUT std_logic
	);
END comparatorC;
ARCHITECTURE t85 OF comparatorC IS
	SIGNAL albT0, agbT0, aebT0: std_logic;
BEGIN
	u0: comparator8 PORT MAP(
		aI => aI(7 downto 0),
		bI => bI(7 downto 0),
		agbI => agbI,
		albI => albI,
		aebI => aebI,
		agbO => agbT0,
		albO => albT0,
		aebO => aebT0
	);
	u1: comparator4 PORT MAP(
		aI => aI(11 downto 8),
		bI => bI(11 downto 8),
		agbI => agbT0,
		albI => albT0,
		aebI => aebT0,
		agbO => agbO,
		albO => albO,
		aebO => aebO
	);
END t85;