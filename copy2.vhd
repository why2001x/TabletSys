LIBRARY ieee;
USE ieee.std_logic_1164.all;

ENTITY copy2 IS
	PORT (
		I: IN std_logic;
		O: OUT std_logic_vector(1 downto 0)
	);
END copy2;
ARCHITECTURE lines OF copy2 IS
BEGIN
	O <= (I, I);
END lines;