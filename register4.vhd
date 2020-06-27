LIBRARY ieee;
USE ieee.std_logic_1164.all;
LIBRARY altera;
USE altera.maxplus2.a_7495;

USE work.Constants.all;

ENTITY register4 IS
	PORT (
		dI: IN std_logic_vector(3 downto 0);
		clkI: IN std_logic;
		qI: OUT std_logic_vector(3 downto 0)
	);
END register4;
ARCHITECTURE s95 OF register4 IS
BEGIN
	u: a_7495 PORT MAP(
		mode => VCC,
		clkl => clkI,
		clkr => VCC,
		ser => GND,
		d => dI,
		q => qI
	);
END s95;