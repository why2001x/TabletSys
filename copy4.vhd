LIBRARY ieee;
USE ieee.std_logic_1164.all;

ENTITY copy4 IS
	PORT (
		I: IN std_logic;
		O: OUT std_logic_vector(3 downto 0)
	);
END copy4;
ARCHITECTURE lines OF copy4 IS
BEGIN
	O <= (I, I, I, I);
END lines;