LIBRARY ieee;
USE ieee.std_logic_1164.all;

LIBRARY altera;
USE altera.maxplus2.a_7474;
USE work.Constants.all;
--USE work.Counters.count_09;

ENTITY PPG IS
	PORT (
		clkI, pI: IN std_logic;
		qO: OUT std_logic
	);
END PPG;
ARCHITECTURE h74 OF PPG IS
BEGIN
	u: a_7474 PORT MAP(
		a_1prn => VCC,
		a_1clrn => VCC,
		a_1clk => clkI,
		a_1d => pI,
		a_1q => qO,
		a_1qn => OPEN,
		a_2prn => VCC,
		a_2clrn => VCC,
		a_2clk => GND,
		a_2d => VCC,
		a_2q => OPEN,
		a_2qn => OPEN
	);
END h74;
--ARCHITECTURE clk10 OF PPG IS
	--SIGNAL temp: std_logic;
--BEGIN
	--u: count_09 PORT MAP(
		--aclr => pI,
		--clk_en => not temp,
		--clock => clkI,
		--cout => temp,
		--q => OPEN
	--);
	--qO <= not temp;
--END clk10;