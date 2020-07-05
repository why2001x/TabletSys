library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

LIBRARY altera;
USE altera.maxplus2.all;
USE work.Comparators.all;
USE work.Constants.all;
USE work.Counters.all;
USE work.Registers.all;
USE work.Utilities.all;

--modeP切换模式，分别为：待机、设定每瓶十位、设定每瓶个位、准备就绪--
--setP：每按一次当前设定位+1（设十位/个位时）--
--startpulse:状态为就绪时，按下pulse开始--
--gLED:正常装瓶时（startpulse启动后）亮--
--rLED：设定每瓶片数十位时，超过4时报警，固定在4不可增加（最大每瓶片数为49）/halt状态亮/装瓶结束亮
--numO1-O5：
--状态00（初始状态）：numO1显示设定瓶数十位
--状态01：numO2显示设定瓶数个位
--状态10：numO4显示每瓶十位
--状态11：numO5显示每瓶个位（同时也是就绪状态）
--开始装瓶：前2位为当前瓶内已装片数，前3位为从开始以来总共装片个数
--TODO：非法输入判断（瓶数/片数为0）


ENTITY TabletSys IS
	PORT (
		modeP: IN std_logic;	--模式切换按钮--
		setP: IN std_logic;	--设定按钮--
		disK: IN std_logic_vector(1 downto 0);	--显示切换开关--

		haltK, nextK: IN std_logic;	--中止/换瓶开关，强制干涉--
		clrPn: IN std_logic;	--复位按钮--

		numO5: OUT std_logic_vector(3 downto 0);	--持续输出5组8421，至数码管--
		numO4: OUT std_logic_vector(3 downto 0);
		numO3: OUT std_logic_vector(3 downto 0);
		numO2: OUT std_logic_vector(3 downto 0);
		numO1: OUT std_logic_vector(3 downto 0);

		gLED, rLED: OUT std_logic;--状态表示，持续输出，至LED--

		tabO: OUT std_logic; --药片请求，脉冲输出，至供给端--
		botO: OUT std_logic;	--换瓶操作，电平输出，至伺服电机--

		tabI: IN std_logic;	--药片脉冲，自传感器--
		BottleReady: IN std_logic; --药瓶就位电平，自传感器--

		clkI: IN std_logic;	--时钟脉冲-- --时钟脉冲使用CP3(1Hz)--
		clkHI: IN std_logic; --高频时钟输入(CP2)-- --时钟脉冲使用CP2(100Hz)--

		testOnly: OUT std_logic_vector(3 downto 0)
	);
END TabletSys;

architecture Sys of TabletSys is

	signal status: std_logic_vector(2 downto 0);--指示状态--
	signal num: std_logic_vector(3 downto 0);--暂存输入数--

	signal PillsPerBottle: BCDs(2 downto 0);--每瓶片数--
	signal PillsInBottle: BCDs(2 downto 0);--已装每瓶片数--
	signal PillsCount: BCDs(4 downto 0);--总装片数计数器---

	signal BottlesCount: BCDs(2 downto 0);--目前已装瓶数--
	signal BottlesLimit: BCDs(2 downto 0);--最大可装瓶数--

	signal Code: std_logic_vector(7 downto 0);
	signal Run: std_logic;

	signal Startn: std_logic;
	signal Start: std_logic;	--开始Flag--
	signal Finish: std_logic;	--完成Flag--
	signal Finishn: std_logic;
	signal Finishw: std_logic_vector(3 downto 0);
	signal Finishnw: std_logic_vector(3 downto 0);

	signal TabletRequest: std_logic;
	signal BottleRequest: std_logic;

	signal numOAmask: std_logic_vector(3 downto 0);
	signal numOBmask: std_logic_vector(3 downto 0);
	signal numOPmask: std_logic_vector(3 downto 0);
	signal numOBlmtM: std_logic_vector(3 downto 0);
	signal numOPlmtM: std_logic_vector(3 downto 0);
--	signal numOSAmsk: std_logic_vector(1 downto 0);
--	signal numOSBmsk: std_logic_vector(1 downto 0);
--	signal numOSPmsk: std_logic_vector(1 downto 0);
	
	signal Flash4: std_logic_vector(3 downto 0);
	signal Flash3: std_logic_vector(3 downto 0);
	signal Flash2: std_logic_vector(3 downto 0);

	signal Error: std_logic := GND;
	signal Equal: std_logic;
begin

--状态控制--
------------------------------------------------------------
------------------------------------------------------------

--运行--
----------------------------------------
	Online: dff PORT MAP(
		PRN => status(0) or status(1) or status(2) or not setP,
		CLRN => clrPn,
		CLK => GND,
		D => GND,
		Q => Start
	);
	Startn <= not Start;
------------------------------------------------------------
------------------------------------------------------------


--输入--
------------------------------------------------------------
------------------------------------------------------------

--位选--
----------------------------------------
	stat: count_06 PORT MAP(
		aclr => not clrPn,
		clk_en => Startn,
		clock => modeP,
		q => status
	);
----------------------------------------
	Decoder: a_74138 PORT MAP(
		g1 => Startn,
		g2an => GND,
		g2bn => GND,
		c => status(2),
		b => status(1),
		a => status(0),
		y0n => OPEN,
		y1n => Code(1),
		y2n => Code(2),
		y3n => Code(3),
		y4n => Code(4),
		y5n => Code(5),
		y6n => Code(6),
		y7n => OPEN
	);
----------------------------------------

--输入计数器--
----------------------------------------
	numCounter: count_09 PORT MAP(
		clock => setP,
		clk_en => VCC,
		cout => OPEN,
		aclr => (num(1) and not Code(1))
				or(BottlesLimit(2)(0) and not Code(2))
				or(BottlesLimit(2)(0) and not Code(3))
				or(num(3) and not Code(4))
				or modeP,
		q => num
	);
----------------------------------------

--瓶数限制--
----------------------------------------
	BottlesLimit(2)(3 downto 1) <= (GND, GND, GND);
	bottleLimit2: register1 PORT MAP(
		dI => num(0 downto 0),
		clkI => Code(1) or not setP,
		clrKn => clrPn,
		EN => Startn,
		qO => BottlesLimit(2)(0 downto 0)
	);
	bottleLimit1: register4 PORT MAP(
		dI => num,
		clkI => Code(2) or not setP,
		clrKn => clrPn,
		EN => Startn,
		qO => BottlesLimit(1)
	);
	bottleLimit0: register4 PORT MAP(
		dI => num,
		clkI => Code(3) or not setP,
		clrKn => clrPn,
		EN => Startn,
		qO => BottlesLimit(0)
	);
----------------------------------------

--片数限制--
----------------------------------------
	PillsPerBottle(2)(3) <= GND;
	PillsPerBottle2: register3 PORT MAP(
		dI => num(2 downto 0),
		clkI => Code(4) or not setP,
		clrKn => clrPn,
		EN => Startn,
		qO => PillsPerBottle(2)(2 downto 0)
	);
	PillsPerBottle1: register4 PORT MAP(
		dI => num,
		clkI => Code(5) or not setP,
		clrKn => clrPn,
		EN => Startn,
		qO => PillsPerBottle(1)
	);
	PillsPerBottle0: register4 PORT MAP(
		dI => num,
		clkI => Code(6) or not setP,
		clrKn => clrPn,
		EN => Startn,
		qO => PillsPerBottle(0)
	);
----------------------------------------
------------------------------------------------------------
------------------------------------------------------------


--计数--
------------------------------------------------------------
------------------------------------------------------------

--已有瓶数--
----------------------------------------
	BottlesCount(2)(3 downto 1) <= (GND, GND, GND);
	BottleCounter: counterD9 PORT MAP(
		clkI => Equal and BottleReady and not(nextK or haltK),
		clrKn => Start,
		qO(8 downto 8) => BottlesCount(2)(0 downto 0),
		qO(7 downto 4) => BottlesCount(1),
		qO(3 downto 0) => BottlesCount(0)
	);
----------------------------------------

--当前瓶片数--
----------------------------------------
	PillsInBottle(2)(3) <= GND;
	PillsInBottleCounter: counterDB PORT MAP(
		clkI => tabI and BottleReady and not(Finish or nextK or haltK),
		clrKn => Start and not(Equal or nextK),
		qO(10 downto 8) => PillsInBottle(2)(2 downto 0),
		qO(7 downto 4) => PillsInBottle(1),
		qO(3 downto 0) => PillsInBottle(0)
	);
----------------------------------------

--当前总计--
----------------------------------------
	PillsCounter: counterD14 PORT MAP(
		clkI => tabI and not(Finish or nextK or haltK),
		clrKn => Start,
		qO(19 downto 16) => PillsCount(4),
		qO(15 downto 12) => PillsCount(3),
		qO(11 downto 8) => PillsCount(2),
		qO(7 downto 4) => PillsCount(1),
		qO(3 downto 0) => PillsCount(0)
	);
----------------------------------------
------------------------------------------------------------
------------------------------------------------------------

--判别/请求--
------------------------------------------------------------
------------------------------------------------------------

	Fin: copy4 PORT MAP(
		I => Finish,
		O => Finishw
	);
	Finn: copy4 PORT MAP(
		I => Finishn,
		O => Finishnw
	);
	Judge: comparatorC PORT MAP(
		dataa(11 downto 8) => (PillsInBottle(2) and Finishnw) or (BottlesCount(2) and Finishw),
		dataa(7 downto 4) => (PillsInBottle(1) and Finishnw) or (BottlesCount(1) and Finishw),
		dataa(3 downto 0) => (PillsInBottle(0) and Finishnw) or (BottlesCount(0) and Finishw),
		datab(11 downto 8) => (PillsPerBottle(2) and Finishnw) or (BottlesLimit(2) and Finishw),
		datab(7 downto 4) => (PillsPerBottle(1) and Finishnw) or (BottlesLimit(1) and Finishw),
		datab(3 downto 0) => (PillsPerBottle(0) and Finishnw) or (BottlesLimit(0) and Finishw),
		aeb => Equal,
		agb => Error
	);
	Finish <= Equal;
	Finishn <= not Finish;
------------------------------------------------------------
------------------------------------------------------------
	tabletRequest <= Start;
	bottlePrepare: dff PORT MAP(
		PRN => VCC,
		CLRN => VCC,
		CLK => clkHI,
		D => not BottleReady,
		Q => BottleRequest
	);	
	tabO <= TabletRequest;
	botO <= Equal or nextK or (BottleRequest and Start);

------------------------------------------------------------
------------------------------------------------------------

--输出--
------------------------------------------------------------
------------------------------------------------------------

--LED--
----------------------------------------
	rLED <= haltK or (Error and clkI);
	gLED <= Start; --and Finishn --> BUG
----------------------------------------

--数码管--
----------------------------------------
	numOAM: copy4 PORT MAP(
		I => Startn or not disK(1),
		O => numOAmask
	);
	numOBM: copy4 PORT MAP(
		I => Startn or disK(1) or not disK(0),
		O => numOBmask
	);
	numOPM: copy4 PORT MAP(
		I => Startn or disK(1) or disK(0),
		O => numOPmask
	);
	
	numOBLM: copy4 PORT MAP(
		I => Start or status(2),
		O => numOBlmtM
	);
	numOPLM: copy4 PORT MAP(
		I => Start or not status(2),
		O => numOPlmtM
	);
	
--------------------
	numO5 <= (numOAmask or PillsCount(4));
--------------------
	numO4 <= (numOAmask or PillsCount(3))
			and(numOBmask or BottlesCount(2))
			and(numOPmask or PillsInBottle(2))
			and(numOBlmtM or BottlesLimit(2) or Flash4)
			and(numOPlmtM or PillsPerBottle(2) or Flash4);
	clk4: copy4 PORT MAP(
		I => clkI and not(Code(1) and Code(4)),
		O => Flash4
	);
--------------------
	numO3 <= (numOAmask or PillsCount(2))
			and(numOBmask or BottlesCount(1))
			and(numOPmask or PillsInBottle(1))
			and(numOBlmtM or BottlesLimit(1) or Flash3)
			and(numOPlmtM or PillsPerBottle(1) or Flash3);
	clk3: copy4 PORT MAP(
		I => clkI and not(Code(2) and Code(5)),
		O => Flash3
	);
--------------------
	numO2 <= (numOAmask or PillsCount(1))
			and(numOBmask or BottlesCount(0))
			and(numOPmask or PillsInBottle(0))
			and(numOBlmtM or BottlesLimit(0) or Flash2)
			and(numOPlmtM or PillsPerBottle(0) or Flash2);
	clk2: copy4 PORT MAP(
		I => clkI and not(Code(3) and Code(6)),
		O => Flash2
	);
--------------------
	numO1 <= (numOAmask or PillsCount(0));
--------------------
----------------------------------------

--模式指示--
----------------------------------------
--	numOSAM: copy2 PORT MAP(
--		I => Start and disK(1),
--		O => numOSAmsk
--	);
--	numOSBM: copy2 PORT MAP(
--		I => (Start and not disK(1) and disK(0)) or (Startn and not status(2)),
--		O => numOSBmsk
--	);
--	numOSPM: copy2 PORT MAP(
--		I => (Start and not disK(1) and not disK(0)) or (Startn and status(2)),
--		O => numOSPmsk
--	);
--
--	numOS(7 downto 4) <= (VCC, VCC, VCC, VCC);
--	numOS(3 downto 2) <= (numOSAmsk and S_Ap)
--							or (numOSBmsk and S_Bp)
--							or (numOSPmsk and S_Pp);
--	numOS(1 downto 0) <= (VCC, VCC);
----------------------------------------
------------------------------------------------------------
------------------------------------------------------------	

end architecture;


		