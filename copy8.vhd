LIBRARY ieee;
USE ieee.std_logic_1164.all;

ENTITY copy8 IS
	PORT (
		I: IN std_logic;
		O: OUT std_logic_vector(7 downto 0)
	);
END copy8;
ARCHITECTURE lines OF copy8 IS
BEGIN
	O <= (I, I, I, I, I, I, I, I);
END lines;