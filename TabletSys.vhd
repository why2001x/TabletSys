library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

LIBRARY altera;
USE altera.maxplus2.all;
USE work.Comparators.all;
USE work.Constants.all;
USE work.Counters.all;
USE work.Utilities.all;

--modeK切换模式，分别为：待机、设定每瓶十位、设定每瓶个位、准备就绪--
--setK：每按一次当前设定位+1（设十位/个位时）--
--startpulse:状态为就绪时，按下pulse开始--
--greenLED:正常装瓶时（startpulse启动后）亮--
--redLED：设定每瓶片数十位时，超过4时报警，固定在4不可增加（最大每瓶片数为49）/halt状态亮/装瓶结束亮
--numO1-O5：
--状态00（初始状态）：numO1显示设定瓶数十位
--状态01：numO2显示设定瓶数个位
--状态10：numO4显示每瓶十位
--状态11：numO5显示每瓶个位（同时也是就绪状态）
--开始装瓶：前2位为当前瓶内已装片数，前3位为从开始以来总共装片个数
--TODO：非法输入判断（瓶数/片数为0）


ENTITY TabletSys IS
	PORT (
		clkI, tabI: IN std_logic;	--时钟、药片脉冲，自动输入--	--时钟脉冲使用CP3(1Hz)--
		modeK, setK: IN std_logic;	--模式、设定脉冲，手动输入--
		
		numO1: OUT std_logic_vector(3 downto 0);	--持续输出5组8421，至辉光管--
		numO2: OUT std_logic_vector(3 downto 0);
		numO3: OUT std_logic_vector(3 downto 0);
		numO4: OUT std_logic_vector(3 downto 0);
		numO5: OUT std_logic_vector(3 downto 0);

		botO: OUT std_logic;	--换瓶指示，脉冲输出，至伺服电机--
		
		redLED, greenLED: OUT std_logic;--状态表示，持续输出，至LED--
		
		displaytoggle: IN std_logic;--切换显示模式--
		startPulse: IN std_logic;--开始脉冲--
		
		BottleReady: IN std_logic; --药瓶就位电平，自传感器--

		haltK, nextK: IN std_logic;	--中止开关/换瓶脉冲，手动输入，强制干涉--
		
		clkHI: IN std_logic; --高频时钟输入(CP1)--
		
		testOnly: OUT std_logic_vector(0 downto 0)
	);
END TabletSys;

architecture Sys of TabletSys is

	signal status: std_logic_vector(1 downto 0);--指示状态--
	signal num: std_logic_vector(3 downto 0);--暂存输入数--
	
	signal PillsPerBottle: BCDs(2 downto 0);--每瓶片数--
	signal PillsInBottle: BCDs(2 downto 0);--已装每瓶片数--
	signal PillsCount: BCDs(4 downto 0);--总装片数计数器---
	
	signal BottlesCount: BCDs(2 downto 0);--目前已装瓶数--
	signal BottlesLimit: BCDs(2 downto 0);--最大可装瓶数--
	
	signal started: std_logic := '0';--开始Flag--
	signal finished: std_logic := '0';--完成Flag--
	
	signal BottleFull: std_logic := '0';
	signal BottleRequest: std_logic;
	
	signal Flash: std_logic_vector(3 downto 0);
begin

	testOnly(0) <= BottleRequest;

	process(modeK)--切换模式--
	begin 
	 if (rising_edge(modeK)) then --切换输入状态
	  case status is 
		when "00"=>status<="01"; --每瓶十位--
		when "01"=>status<="10"; --每瓶个位--
		when "10"=>status<="11"; --瓶数个位--
		when "11"=>status<="00"; --瓶数个位+就绪--
	  end case;
	 end if;
	end process;
	
	numCounter: counterD4 PORT MAP(
		clkI => not setK,
		clrKn => not modeK,
		qO => num
	);

	bottlePrepare: PPG PORT MAP(
		clkI => clkHI,
		pI => not BottleReady,
		qO => BottleRequest
	);
	process(setK)--将暂存数放入每瓶片数寄存器--
	begin
		case status is
			when "00"=>
				if(num <= "0001") then--十位为1以上时不接受，最大瓶数19--
					BottlesLimit(1)<=num;--暂存数打入每瓶片数寄存器高位--
				else 
					BottlesLimit(1)<="0001";--兜下来，不允许增加
				end if;
			when "01"=>
				BottlesLimit(0)<=num;
			when "10"=>--输入每瓶十位状态--
				if(num <= "0100") then--十位为5以上时不接受，最大片数49----不加底下兜底时，0101会被赋进去
					PillsPerBottle(1)<=num;--暂存数打入每瓶片数寄存器高位--
				else 
					PillsPerBottle(1)<="0100";--兜下来，不允许增加
				end if;
			when "11"=>
				PillsPerBottle(0)<=num;--暂存数打入每瓶片数寄存器低位--
			when others=>NULL;--其他情况不改变
	end case;
	end process;

	--开始信号将状态置为开始--
	Process(startPulse)
	begin
		if (rising_edge(startPulse)) then--开始脉冲给出，进入运行状态——-
			started <= '1';
		end if;
	end process;


	Process(finished,num,status,started)--红/绿灯控制
	begin
		redLED<='0';
		greenLED<='0';	
		if(finished='1' or (num>"0001" and status="00") or (num>"0100" and status="10") or (haltK = VCC)) then
			redLED<='1';
		end if;
		if(started='1' and status="11" and finished='0' ) then
			greenLED<='1';
		end if;
	end process;

	BottleCounter: counterD8 PORT MAP(
		clkI => BottleFull and started and BottleReady and not(finished or nextK or haltK),
		clrKn => started,
		qO(7 downto 4) => BottlesCount(1),
		qO(3 downto 0) => BottlesCount(0)
	);
	
	PillsInBottleCounter: counterD8 PORT MAP(
		clkI => tabI and started and BottleReady and not(finished or nextK or haltK),
		clrKn => started and not(BottleFull or nextK),
		qO(7 downto 4) => PillsInBottle(1),
		qO(3 downto 0) => PillsInBottle(0)
	);
	
	NextBottleJudge: comparator8 PORT MAP(
		dataa(7 downto 4) => PillsInBottle(1),
		dataa(3 downto 0) => PillsInBottle(0),
		datab(7 downto 4) => PillsPerBottle(1),
		datab(3 downto 0) => PillsPerBottle(0),
		aeb => BottleFull
	);
	
	FinishedJudge: comparator8 PORT MAP(
		dataa(7 downto 4) => BottlesCount(1),
		dataa(3 downto 0) => BottlesCount(0),
		datab(7 downto 4) => BottlesLimit(1),
		datab(3 downto 0) => BottlesLimit(0),
		aeb => finished
	);
	
	PillsCounter: counterDC PORT MAP(
		clkI => tabI and started and not(finished or nextK or haltK),
		clrKn => started,
		qO(11 downto 8) => PillsCount(2),
		qO(7 downto 4) => PillsCount(1),
		qO(3 downto 0) => PillsCount(0)
	);
	
	botO <= (started and BottleFull) or nextK or BottleRequest;

	--装片过程处理--
	
	
	--输出--
	Flash <= (clkI, clkI, clkI, clkI);
	Process(status,PillsPerBottle(1),BottlesCount(0),PillsInBottle(0),PillsCount(0),started)
	begin
		case status is
			when "00"=>--输入瓶数十位--
				numO1<=BottlesLimit(1) or Flash;
				numO2<=OFF;
				numO3<=OFF;
				numO4<=OFF;
				numO5<=OFF;
			when "01"=> --输入瓶数个位--
				numO2<=BottlesLimit(0) or Flash;
			when "10"=>
				numO4<=PillsPerBottle(1) or Flash; --输入每瓶片数十位--
			when "11"=>--前2个是已装每瓶片数计数，后3个是总装片数计数--
				if(started='0') then
					numO5<=PillsPerBottle(0) or Flash;
				else
					if(Displaytoggle='0') then
						numO1<=BottlesCount(1);
						numO2<=BottlesCount(0);
						numO3<=OFF;
						numO4<=PillsInBottle(1);
						numO5<=PillsInBottle(0);
					else
						numO1<=PillsCount(4);
						numO2<=PillsCount(3);
						numO3<=PillsCount(2);
						numO4<=PillsCount(1);
						numO5<=PillsCount(0);
					end if;
				end if;
			when others=>null;
		end case;
	end process;

end architecture;


		