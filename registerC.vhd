LIBRARY ieee;
USE ieee.std_logic_1164.all;

USE work.Registers.register4;

ENTITY registerC IS
	PORT (
		dI: IN std_logic_vector(11 downto 0);
		clkI: IN std_logic;
		qI: OUT std_logic_vector(11 downto 0)
	);
END registerC;
ARCHITECTURE t95 OF registerC IS
BEGIN
	u1: register4 PORT MAP(
		clkI => clkI,
		d => dI(3 downto 0),
		q => qI(3 downto 0)
	);
	u2: register4 PORT MAP(
		clkI => clkI,
		d => dI(7 downto 4),
		q => qI(7 downto 4)
	);
	u3: register4 PORT MAP(
		clkI => clkI,
		d => dI(11 downto 8),
		q => qI(11 downto 8)
	);
END t95;