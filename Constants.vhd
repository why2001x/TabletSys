LIBRARY ieee;
USE ieee.std_logic_1164.all;

PACKAGE Constants IS
	CONSTANT GND: std_logic := '0';
	CONSTANT VCC: std_logic := '1';
	CONSTANT OFF: std_logic_vector(3 downto 0) := X"F";
	TYPE BCDs IS ARRAY(NATURAL RANGE<>) OF std_logic_vector(3 downto 0);
END Constants;