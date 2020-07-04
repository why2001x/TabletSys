LIBRARY ieee;
USE ieee.std_logic_1164.all;

PACKAGE Utilities IS

COMPONENT PPG IS
	PORT (
		clkI, pI: IN std_logic;
		qO: OUT std_logic
	);
END COMPONENT;

END Utilities;