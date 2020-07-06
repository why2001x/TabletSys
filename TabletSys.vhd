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

--modeP: 切换模式，模式循环为：待机->设定(6位)->待机--
--setP: 每按一次当前设定位+1（设定时）--
	--startpulse: 状态为待机时，按下setP开始--
--gLED: 正常装瓶时（startpulse启动后）亮--
--rLED: halt状态亮/计数错误时闪烁--
--numO5-O1: 根据机器状态及显示开关共同决定显示内容--


ENTITY TabletSys IS
	PORT (
		modeP: IN std_logic;							--模式切换按钮--
		setP: IN std_logic;							--设定按钮--
		disK: IN std_logic_vector(1 downto 0);	--显示切换开关2个--
		haltK, nextK: IN std_logic;				--中止/换瓶开关，强制干涉--
		clrPn: IN std_logic;							--复位按钮--

		numO5: OUT std_logic_vector(3 downto 0);	--持续输出5组8421，至数码管--
		numO4: OUT std_logic_vector(3 downto 0);
		numO3: OUT std_logic_vector(3 downto 0);
		numO2: OUT std_logic_vector(3 downto 0);
		numO1: OUT std_logic_vector(3 downto 0);

		gLED, rLED: OUT std_logic;		--状态表示，持续输出，至LED--

		TabletReady: OUT std_logic;	--药片请求，脉冲输出，至供给端--
		botO: OUT std_logic;				--换瓶操作，电平输出，至伺服电机--
		tabI: BUFFER std_logic;				--药片脉冲，自传感器--
		BottleReady: IN std_logic;		--药瓶就位电平，自传感器--

		clkI: IN std_logic;	--时钟脉冲--	--时钟脉冲使用CP3(1Hz)--
		clkHI: IN std_logic; --中频时钟输入(CP2)--	--时钟脉冲使用CP2(100Hz)--

		REDUNDANCE: OUT std_logic_vector(4 downto 0) --冗余引脚使器件易于匹配CPLD适当调整可以在Fitter(Place & Route)阶段减单元数--
	);
END TabletSys;

architecture Sys of TabletSys is
	--signal tabI: std_logic;				--药片脉冲,由CP3分频得到--
	signal status: std_logic_vector(2 downto 0);	--指示输入状态--
	signal num: std_logic_vector(3 downto 0);		--暂存输入数--

	signal PillsPerBottle: BCDs(2 downto 0);	--每瓶片数--
	signal PillsInBottle: BCDs(2 downto 0);	--已装每瓶片数--
	signal PillsCount: BCDs(4 downto 0);		--总装片数计数器---

	signal BottlesCount: BCDs(2 downto 0);	--目前已装瓶数--
	signal BottlesLimit: BCDs(2 downto 0);	--最大可装瓶数--

	signal Code: std_logic_vector(6 downto 1);	--输入状态解码--
	signal StartPulsen: std_logic;					--开始脉冲#--
	signal ValidPill: std_logic;						--有效药片计数信号--

	signal Startn: std_logic;	--开始Flag#--
	signal Start: std_logic;	--开始Flag--
	signal Finish: std_logic;	--完成Flag--
	signal Finishn: std_logic;	--完成Flag#--

	signal TabletRequest: std_logic;	--接收就绪时向供给端请求药片--
	signal BottleRequest: std_logic;	--接收未就绪向接收端请求更新--

	signal numOAmask: std_logic_vector(3 downto 0);	--总装片数显示控制--
	signal numOBmask: std_logic_vector(3 downto 0);	--已装瓶数显示控制--
	signal numOPmask: std_logic_vector(3 downto 0);	--瓶内片数显示控制--
	signal numOBlmtM: std_logic_vector(3 downto 0);	--目标瓶数输入控制--
	signal numOPlmtM: std_logic_vector(3 downto 0);	--目标规格输入控制--
--	signal numOSAmsk: std_logic_vector(1 downto 0);	--总装片数辅助控制--
--	signal numOSBmsk: std_logic_vector(1 downto 0);	--瓶数相关辅助控制--
--	signal numOSPmsk: std_logic_vector(1 downto 0);	--片数相关辅助控制--
	
	signal Flash4: std_logic_vector(3 downto 0);	--4号数码管闪烁控制--
	signal Flash3: std_logic_vector(3 downto 0);	--3号数码管闪烁控制--
	signal Flash2: std_logic_vector(3 downto 0);	--2号数码管闪烁控制--

	signal Error: std_logic;	--显著错误信号--
	signal Equal: std_logic;	--比较相等信号--
	signal Equalw: std_logic_vector(3 downto 0);	--Equal	4位信号--
	signal Equalnw: std_logic_vector(3 downto 0);	--Equal#	4位信号--
begin

--分频控制,对1Hz信号2分频至2Hz模拟药片--
	Process(clkI)
		variable temp:std_logic :='0';
	begin
		if(rising_edge(clkI)) then
			if(temp='0') then
				temp:='1';
				tabI<='1';
			else 
				temp:='0';
				tabI<='0';
			end if;
		end if;
	end process;
------------------------------------
		
--状态控制--
------------------------------------------------------------
------------------------------------------------------------

--运行--
----------------------------------------
	StartPulsen <= status(0) or status(1) or status(2) or not setP;	--status状态为00时setP即为开始脉冲--
	Online: dff PORT MAP(	--系统输入/工作状态控制--
		PRN => StartPulsen,	--开始脉冲#, 配合触发器--
		CLRN => clrPn,			--全局复位--
		CLK => GND,				--SR锁存器--
		D => GND,				--SR锁存器--
		Q => Start				--开始Flag--
	);
	Startn <= not Start;		--开始Flag#--
------------------------------------------------------------
------------------------------------------------------------


--输入--
------------------------------------------------------------
------------------------------------------------------------

--位选--
----------------------------------------
	stat: count_06 PORT MAP(	--00为初态，01-06状态对应不同数位，00-06循环--
		aclr => not clrPn,		--全局复位--
		clk_en => Startn,			--仅输入阶段改变状态--
		clock => modeP,			--modeP上升沿改变状态--
		q => status					--状态输出--
	);
----------------------------------------
	Decoder: a_74138 PORT MAP(
		g1 => Startn,		--输入阶段有效--
		g2an => GND,
		g2bn => GND,
		c => status(2),	--状态输入--
		b => status(1),
		a => status(0),
		y0n => OPEN,		--00无对应数位--
		y1n => Code(1),	--01-瓶数百位	0/1--
		y2n => Code(2),	--01-瓶数十位	0-9--
		y3n => Code(3),	--01-瓶数个位	0-9--
		y4n => Code(4),	--01-瓶数百位	0-7--
		y5n => Code(5),	--01-瓶数百位	0-9--
		y6n => Code(6),	--01-瓶数百位	0-9--
		y7n => OPEN			--无07状态--
	);
----------------------------------------

--输入计数器--
----------------------------------------
	numCounter: count_09 PORT MAP(						--输入计数器 0-9循环--
		clock => setP,											--setP上升沿计数加--
		clk_en => VCC,											--全时使能--
		cout => OPEN,											--进位暂不使用--
		aclr => (num(1) and not Code(1))					--瓶数限制(<=100)--
				or(BottlesLimit(2)(0) and not Code(2))	--瓶数首位连带限制--
				or(BottlesLimit(2)(0) and not Code(3))	--瓶数首位连带限制--
				or(num(3) and not Code(4))					--片数百位限制0-7--
				or modeP,										--位间切换复位--
				--or Finishn,
		q => num													--8421码输出--
	);
----------------------------------------

--瓶数限制--
----------------------------------------
	BottlesLimit(2)(3 downto 1) <= (GND, GND, GND);	--目标瓶数百位高3位恒0--
	bottleLimit2: register1 PORT MAP(					--目标瓶数百位存储--
		dI => num(0 downto 0),								--输入数据--
		clkI => Code(1) or not setP,						--选中时setP#下降沿更新--
		clrKn => clrPn,										--全局复位--
		EN => Startn,											--输入阶段使能--
		qO => BottlesLimit(2)(0 downto 0)				--目标瓶数百位输出--
	);
	bottleLimit1: register4 PORT MAP(					--目标瓶数十位存储--
		dI => num,												--输入数据--
		clkI => Code(2) or not setP,						--选中时setP#下降沿更新--
		clrKn => clrPn,										--全局复位--
		EN => Startn,											--输入阶段使能--
		qO => BottlesLimit(1)								--目标瓶数十位输出--
	);
	bottleLimit0: register4 PORT MAP(					--目标瓶数个位存储--
		dI => num,												--输入数据--
		clkI => Code(3) or not setP,						--选中时setP#下降沿更新--
		clrKn => clrPn,										--全局复位--
		EN => Startn,											--输入阶段使能--
		qO => BottlesLimit(0)								--目标瓶数个位输出--
	);
----------------------------------------

--片数限制--
----------------------------------------
	PillsPerBottle(2)(3) <= GND;				--目标片数百位高1位恒0--
	PillsPerBottle2: register3 PORT MAP(	--目标片数百位存储--
		dI => num(2 downto 0),					--输入数据--
		clkI => Code(4) or not setP,			--选中时setP#下降沿更新--
		clrKn => clrPn,							--全局复位--
		EN => Startn,								--输入阶段使能--
		qO => PillsPerBottle(2)(2 downto 0)	--目标片数百位输出--
	);
	PillsPerBottle1: register4 PORT MAP(	--目标片数十位存储--
		dI => num,									--输入数据--
		clkI => Code(5) or not setP,			--选中时setP#下降沿更新--
		clrKn => clrPn,							--全局复位--
		EN => Startn,								--输入阶段使能--
		qO => PillsPerBottle(1)					--目标片数十位输出--
	);
	PillsPerBottle0: register4 PORT MAP(	--目标片数个位存储--
		dI => num,									--输入数据--
		clkI => Code(6) or not setP,			--选中时setP#下降沿更新--
		clrKn => clrPn,							--全局复位--
		EN => Startn,								--输入阶段使能--
		qO => PillsPerBottle(0)					--目标片数个位输出--
	);
----------------------------------------
------------------------------------------------------------
------------------------------------------------------------


--计数--
------------------------------------------------------------
------------------------------------------------------------

--已有瓶数--
----------------------------------------
	BottlesCount(2)(3 downto 1) <= (GND, GND, GND);					--将完成瓶数百位高3位恒0--
	BottleCounter: counterD9 PORT MAP(									--将完成瓶数计数--
		clkI => Equal or nextK or Startn,								--满瓶/强制换瓶计数--	--开始Flag#用于赋初值--
		clrKn => Start,														--输入阶段异步复位--
		qO(8 downto 8) => BottlesCount(2)(0 downto 0),				--将完成瓶数百位输出--
		qO(7 downto 4) => BottlesCount(1),								--将完成瓶数十位输出--
		qO(3 downto 0) => BottlesCount(0)								--将完成瓶数个位输出--
	);
----------------------------------------

--当前片数--
----------------------------------------
	ValidPill <= tabI and BottleReady and not nextK;		--有效药片落下时，应当药瓶就绪，且不在被强制移动--
	PillsInBottle(2)(3) <= GND;									--瓶内片数百位高1位恒0--
	PillsInBottleCounter: counterDB PORT MAP(					--瓶内片数计数--
		clkI => ValidPill,											--有效药片计数--
		clrKn => Start and not(Equal or nextK),				--输入阶段/满瓶/强制换瓶计数复位--
		qO(10 downto 8) => PillsInBottle(2)(2 downto 0),	--瓶内片数百位输出--
		qO(7 downto 4) => PillsInBottle(1),						--瓶内片数十位输出--
		qO(3 downto 0) => PillsInBottle(0)						--瓶内片数个位输出--
	);
	PillsCounter: counterD14 PORT MAP(							--总药片数计数--
		clkI => ValidPill,											--有效药片计数--
		clrKn => Start,												--输入阶段异步复位--
		qO(19 downto 16) => PillsCount(4),						--总药片数万位输出--
		qO(15 downto 12) => PillsCount(3),						--总药片数千位输出--
		qO(11 downto 8) => PillsCount(2),						--总药片数百位输出--
		qO(7 downto 4) => PillsCount(1),							--总药片数十位输出--
		qO(3 downto 0) => PillsCount(0)							--总药片数个位输出--
	);
----------------------------------------
------------------------------------------------------------
------------------------------------------------------------

--判别/请求--
------------------------------------------------------------
------------------------------------------------------------

	aeb: copy4 PORT MAP(		--Equal 一分四--
		I => Equal,
		O => Equalw
	);
	aebn: copy4 PORT MAP(	--Equal#一分四--
		I => not Equal,
		O => Equalnw
	);
	Judge: comparatorC PORT MAP(	--瓶内未满时判断瓶内片数关系-- or --瓶内满时判断已装瓶数关系--
		dataa(11 downto 8) => (PillsInBottle(2)  and Equalnw) or (BottlesCount(2) and Equalw),	--代码左侧信号相等时--
		dataa(7 downto 4)  => (PillsInBottle(1)  and Equalnw) or (BottlesCount(1) and Equalw),	--经由同类型逻辑电路变换--
		dataa(3 downto 0)  => (PillsInBottle(0)  and Equalnw) or (BottlesCount(0) and Equalw),	--其状态不影响右侧信号关系--
		datab(11 downto 8) => (PillsPerBottle(2) and Equalnw) or (BottlesLimit(2) and Equalw),	--又下一次左侧信号变化远落后于延迟--
		datab(7 downto 4)  => (PillsPerBottle(1) and Equalnw) or (BottlesLimit(1) and Equalw),	--故借助信号延迟可完成元件复用--
		datab(3 downto 0)  => (PillsPerBottle(0) and Equalnw) or (BottlesLimit(0) and Equalw),	--注：该器件无法进行功能仿真--
		aeb => Equal,
		agb => Error
	);
	Finish <= Equal;						--结束Flag--
	Finishn <= Start and not Finish;	--未结束Flag--
------------------------------------------------------------
------------------------------------------------------------
	TabletRequest <= BottleReady;	--药瓶就绪->接受药片请求--
	bottlePrepare: dff PORT MAP(	--向传送带电机输出电平，顺向转动直至下一个药瓶在就绪位置--
		PRN => VCC,						--无预置--
		CLRN => VCC,					--无预置--
		CLK => clkHI,					--中频时钟，峰峰时差相对药瓶移动应可忽略--
		D => not BottleReady,		--高电平直至有药瓶就绪--
		Q => BottleRequest			--药瓶请求--
	);	
	TabletReady <= (Start and Finishn) and TabletRequest and not(haltK or nextK);	--工作状态&药片请求&无强制干涉->可接受药片--				
	botO <= (Equal and Start) or (BottleRequest or nextK);	--(满瓶&工作状态)|(药瓶请求|强制干涉)->要求药瓶就绪--

------------------------------------------------------------
------------------------------------------------------------

--输出--
------------------------------------------------------------
------------------------------------------------------------

--LED--
----------------------------------------
   Process(haltK,Error,clkI)
	begin
		if(Error='1' and clkI='1') then --受干涉/错误(闪烁)状态--
			rLED<='1';
			gLED<='0';
		elsif(haltK='1') then
			rLED<='1';
			gLED<='1';
		elsif(Start='1' and Finishn='1') then --工作状态--
			rLED<='0';
			gLED<='1';
		else 
			rLED<='0';
			gLED<='0';
		end if;
	end process;
	--rLED <= haltK or (Error and clkI);		--受干涉/错误(闪烁)状态--
	--gLED <= Start and Finishn; --> BUG(绝了)	--工作状态--
---------------------------------------	-

--数码管--
----------------------------------------
	numOAM: copy4 PORT MAP(
		I => Startn or not disK(1),				--非输入状态高优先显示开关开启->显示当前总片数--
		O => numOAmask
	);
	numOBM: copy4 PORT MAP(
		I => Startn or disK(1) or not disK(0),	--非输入状态仅低优先显示开关开启->显示当前装填瓶序数--
		O => numOBmask
	);
	numOPM: copy4 PORT MAP(
		I => Startn or disK(1) or disK(0),		--非输入状态无显示开关开启->显示当前瓶内药片数--
		O => numOPmask
	);
	
	numOBLM: copy4 PORT MAP(
		I => Start or status(2),					--输入瓶数状态->显示目标瓶数--
		O => numOBlmtM
	);
	numOPLM: copy4 PORT MAP(
		I => Start or not status(2),				--输入规格状态->显示目标规格--
		O => numOPlmtM
	);
	
--------------------
	numO5 <= (numOAmask or PillsCount(4));						--显示当前总片数万位--
--------------------
	numO4 <= (numOAmask or PillsCount(3))						--显示当前总片数千位--
			and(numOBmask or BottlesCount(2))					--显示当前装填瓶序数百位--
			and(numOPmask or PillsInBottle(2))					--显示当前瓶内药片数百位--
			and(numOBlmtM or BottlesLimit(2) or Flash4)		--显示目标瓶数百位--
			and(numOPlmtM or PillsPerBottle(2) or Flash4);	--显示目标规格百位--
	clk4: copy4 PORT MAP(
		I => clkI and not(Code(1) and Code(4)),				--选定位闪烁--
		O => Flash4
	);
--------------------
	numO3 <= (numOAmask or PillsCount(2))						--显示当前总片数百位--
			and(numOBmask or BottlesCount(1))					--显示当前装填瓶序数十位--
			and(numOPmask or PillsInBottle(1))					--显示当前瓶内药片数十位--
			and(numOBlmtM or BottlesLimit(1) or Flash3)		--显示目标瓶数十位--
			and(numOPlmtM or PillsPerBottle(1) or Flash3);	--显示目标规格十位--
	clk3: copy4 PORT MAP(
		I => clkI and not(Code(2) and Code(5)),				--选定位闪烁--
		O => Flash3
	);
--------------------
	numO2 <= (numOAmask or PillsCount(1))						--显示当前总片数十位--
			and(numOBmask or BottlesCount(0))					--显示当前装填瓶序数个位--
			and(numOPmask or PillsInBottle(0))					--显示当前瓶内药片数个位--
			and(numOBlmtM or BottlesLimit(0) or Flash2)		--显示目标瓶数个位--
			and(numOPlmtM or PillsPerBottle(0) or Flash2);	--显示目标规格个位--
	clk2: copy4 PORT MAP(
		I => clkI and not(Code(3) and Code(6)),				--选定位闪烁--
		O => Flash2
	);
--------------------
	numO1 <= (numOAmask or PillsCount(0));						--显示当前总片数个位--
--------------------
----------------------------------------

--模式指示--
----------------------------------------
--	numOSAM: copy2 PORT MAP(	--总装片数辅助控制--
--		I => Start and disK(1),
--		O => numOSAmsk
--	);
--	numOSBM: copy2 PORT MAP(	--瓶数相关辅助控制--
--		I => (Start and not disK(1) and disK(0)) or (Startn and not status(2)),
--		O => numOSBmsk
--	);
--	numOSPM: copy2 PORT MAP(	--片数相关辅助控制--
--		I => (Start and not disK(1) and not disK(0)) or (Startn and status(2)),
--		O => numOSPmsk
--	);
--
--	numOS(7 downto 4) <= (VCC, VCC, VCC, VCC);	--e,f,g及小数点常亮--
--	numOS(3 downto 2) <= (numOSAmsk and S_Ap)		--总装片数提示c,d--
--							or (numOSBmsk and S_Bp)		--瓶数相关提示c,d--
--							or (numOSPmsk and S_Pp);	--片数相关提示c,d--
--	numOS(1 downto 0) <= (VCC, VCC);					--a,b常亮--
----------------------------------------
------------------------------------------------------------
------------------------------------------------------------	

end architecture;


		