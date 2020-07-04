LIBRARY ieee;
USE ieee.std_logic_1164.all;

USE work.Constants.all;
USE work.Counters.count_09;

ENTITY PPG IS
	PORT (
		clkI, pI: IN std_logic;
		qO: OUT std_logic
	);
END PPG;
ARCHITECTURE clk10 OF PPG IS
	SIGNAL temp: std_logic;
BEGIN
	u: count_09 PORT MAP(
		aclr => pI,
		clk_en => not temp,
		clock => clkI,
		cout => temp,
		q => OPEN
	);
	qO <= not temp;
END clk10;