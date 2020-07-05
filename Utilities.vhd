LIBRARY ieee;
USE ieee.std_logic_1164.all;

PACKAGE Utilities IS

COMPONENT copy2 IS
	PORT (
		I: IN std_logic;
		O: OUT std_logic_vector(1 downto 0)
	);
END COMPONENT;

COMPONENT copy4 IS
	PORT (
		I: IN std_logic;
		O: OUT std_logic_vector(3 downto 0)
	);
END COMPONENT;

END Utilities;