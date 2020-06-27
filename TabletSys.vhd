LIBRARY ieee;
USE ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
LIBRARY altera;
USE altera.maxplus2.all;

USE work.Constants.all;

ENTITY TabletSys IS
	PORT (
		clkI, tabI: IN std_logic;	--时钟、药片脉冲，自动输入--	--时钟脉冲使用CP3(1Hz)--
		modeK, setK: IN std_logic;	--模式、设定开关，手动输入--

		botO: OUT std_logic;	--换瓶指示，脉冲输出，至伺服电机--
		numO: OUT std_logic_vector(19 downto 0);	--持续输出5组8421，至辉光管--

		stat, err: OUT std_logic;	--状态表示，持续输出，至LED--
		
		haltK, nextK: IN std_logic	--中止开关/换瓶脉冲，手动输入，强制干涉--
	);
END TabletSys;

ARCHITECTURE Main OF TabletSys IS



BEGIN
	stat <= not haltK;
END Main;