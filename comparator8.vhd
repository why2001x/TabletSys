LIBRARY ieee;
USE ieee.std_logic_1164.all;

USE work.Comparators.comparator4;

ENTITY comparator8 IS
	PORT (
		aI, bI: IN std_logic_vector(7 downto 0);
		albI, agbI, aebI: IN std_logic;
		albO, agbO, aebO: OUT std_logic
	);
END comparator8;
ARCHITECTURE d85 OF comparator8 IS
	SIGNAL albT0, agbT0, aebT0: std_logic;
BEGIN
	u0: comparator4 PORT MAP(
		aI => aI(3 downto 0),
		bI => bI(3 downto 0),
		agbI => agbI,
		albI => albI,
		aebI => aebI,
		agbO => agbT0,
		albO => albT0,
		aebO => aebT0
	);
	u1: comparator4 PORT MAP(
		aI => aI(7 downto 4),
		bI => bI(7 downto 4),
		agbI => agbT0,
		albI => albT0,
		aebI => aebT0,
		agbO => agbO,
		albO => albO,
		aebO => aebO
	);
END d85;