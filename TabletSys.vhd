library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

LIBRARY altera;
USE altera.maxplus2.all;
USE work.Comparators.all;
USE work.Constants.all;
USE work.Counters.all;

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
		modeK, setK: IN std_logic;	--模式、设定开关，手动输入--

		botO: OUT std_logic;	--换瓶指示，脉冲输出，至伺服电机--
		numO1: OUT std_logic_vector(3 downto 0);	--持续输出5组8421，至辉光管--
		numO2: OUT std_logic_vector(3 downto 0);
		numO3: OUT std_logic_vector(3 downto 0);
		numO4: OUT std_logic_vector(3 downto 0);
		numO5: OUT std_logic_vector(3 downto 0);
		
		--stat, err: OUT std_logic;	--状态表示，持续输出，至LED--
		
		redLED, greenLED: OUT std_logic;
		
		displaytoggle: IN std_logic;--切换显示模式--
		--PillsPerBottleL: buffer std_logic_vector(3 downto 0);--每瓶片数，2个BCD--
		--BottleReady: buffer std_logic := '1';
		--BottleFull: buffer std_logic :='0';
		--BottlesLimitL: BUFFER std_logic_vector(3 downto 0);--最大可装瓶数--
		startPulse: IN std_logic;--开始脉冲--

		haltK, nextK: IN std_logic	--中止开关/换瓶脉冲，手动输入，强制干涉--
	);
END TabletSys;

architecture Sys of TabletSys is

	signal status: std_logic_vector(1 downto 0);--指示状态--
	signal num: std_logic_vector(3 downto 0);--暂存输入数--
	signal PillsPerBottleH: std_logic_vector(3 downto 0);--每瓶片数，2个BCD--
	signal PillsPerBottleL: std_logic_vector(3 downto 0);--每瓶片数，2个BCD--
	signal PillsInBottleH: std_logic_vector(3 downto 0);--已装每瓶片数，2个BCD--
	signal PillsInBottleL: std_logic_vector(3 downto 0);--已装每瓶片数，2个BCD--
	signal started: std_logic := '0';--开始Flag--
	signal PillsCountH: std_logic_vector(3 downto 0);--总装片数计数器---
	signal PillsCountM: std_logic_vector(3 downto 0);--总装片数计数器---
	signal PillsCountL: std_logic_vector(3 downto 0);--总装片数计数器---
	signal BottlesCountH: std_logic_vector(3 downto 0);--目前已装瓶数--
	signal BottlesCountL: std_logic_vector(3 downto 0);--目前已装瓶数--
	signal BottlesLimitH: std_logic_vector(3 downto 0);--最大可装瓶数--
	signal BottlesLimitL: std_logic_vector(3 downto 0);--最大可装瓶数--
	signal finished: std_logic :='0';--完成Flag--
	signal BottleReady: std_logic := '1';
	signal BottleFull: std_logic :='0';
begin


	process(modeK)--切换模式--
	begin 
	 if(modeK'event and modeK='1') then --切换输入状态
	  case status is 
		when "00"=>status<="01"; --每瓶十位--
		when "01"=>status<="10"; --每瓶个位--
		when "10"=>status<="11"; --瓶数个位--
		when "11"=>status<="00"; --瓶数个位+就绪--
	  end case;
	 end if;
	end process;
	
	

	process(setK,modeK,status)--输入数值--
	begin
		case modeK is
			when '1'=>
					num<="0000";--切换模式时置0（异步）--
				--end if;
			when '0'=>
				if(setK'event and setK='1') then 
		   			if(num="1001") then --超过9时回0--
					num<="0000";
					else
			 		num<=num+1;
					end if;
				end if;
			when others=>NULL;
		end case;
	end process;


	process(setK)--将暂存数放入每瓶片数寄存器--
	begin
		case status is
			when "00"=>
				if(num <= "0001") then--十位为1以上时不接受，最大瓶数19----
					BottlesLimitH<=num;--暂存数打入每瓶片数寄存器高位--
				else 
					BottlesLimitH<="0001";--兜下来，不允许增加
				end if;
			when "01"=>BottlesLimitL<=num;
			when "10"=>--输入每瓶十位状态--
				if(num <= "0100") then--十位为5以上时不接受，最大片数49----不加底下兜底时，0101会被赋进去
					PillsPerBottleH<=num;--暂存数打入每瓶片数寄存器高位--
				else 
					PillsPerBottleH<="0100";--兜下来，不允许增加
				end if;
			when "11"=>PillsPerBottleL<=num;--暂存数打入每瓶片数寄存器低位--
			
			when others=>NULL;--其他情况不改变
	end case;
	end process;
	
	

	--process(nextK,BottleReady,BottleFull)--换瓶状态管理--
	--begin
	--	if(BottleReady='1') then
		--	when '1'=>
	--			if(BottleFull = '1') then--瓶满情况
	--				BottleReady<='0';
	--			end if;
		--	when '0'=>
	--	else
	--			if(nextK'event and nextK='1') then
	--				BottleReady<='0';
	--			end if;
	--	end if;
	--end process;
		

	--开始信号将状态置为开始--
	Process(startPulse)
	begin
		if(startPulse'event and startPulse='1') then--开始脉冲给出，进入运行状态——-
			started<='1';
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
		clkI => BottleFull and started and not(finished or nextK or haltK),
		clrKn => started,
		qO(7 downto 4) => BottlesCountH,
		qO(3 downto 0) => BottlesCountL
	);
	
	PillsInBottleCounter: counterD8 PORT MAP(
		clkI => tabI and started and not(finished or nextK or haltK),
		clrKn => started and not(BottleFull or nextK),
		qO(7 downto 4) => PillsInBottleH,
		qO(3 downto 0) => PillsInBottleL
	);
	
	NextBottleJudge: comparator8 PORT MAP(
		dataa(7 downto 4) => PillsInBottleH,
		dataa(3 downto 0) => PillsInBottleL,
		datab(7 downto 4) => PillsPerBottleH,
		datab(3 downto 0) => PillsPerBottleL,
		aeb => BottleFull
	);
	
	FinishedJudge: comparator8 PORT MAP(
		dataa(7 downto 4) => BottlesCountH,
		dataa(3 downto 0) => BottlesCountL,
		datab(7 downto 4) => BottlesLimitH,
		datab(3 downto 0) => BottlesLimitL,
		aeb => finished
	);
	
	PillsCounter: counterDC PORT MAP(
		clkI => tabI and started and not(finished or nextK or haltK),
		clrKn => started,
		qO(11 downto 8) => PillsCountH,
		qO(7 downto 4) => PillsCountM,
		qO(3 downto 0) => PillsCountL
	);
	
	botO <= started and (BottleFull or nextK);

	--装片过程处理--
	
	
	--异步输出--
	Process(status,PillsPerBottleH,BottlesCountL,PillsInBottleL,PillsCountL,started)
	begin
		case status is
			when "00"=>--输入瓶数十位--
				numO1<=BottlesLimitH;
				numO2<="1111";
				numO3<="1111";
				numO4<="1111";
				numO5<="1111";
			when "01"=> --输入瓶数个位--
				numO2<=BottlesLimitL;
			when "10"=>numO4<=PillsPerBottleH; --输入每瓶片数十位--
			when "11"=>--前2个是已装每瓶片数计数，后3个是总装片数计数--
				if(started='0') then
					numO5<=PillsPerBottleL;
				else
					if(Displaytoggle='0') then
						numO1<=BottlesCountH;
						numO2<=BottlesCountL;
						numO3<="1111";
						numO4<=PillsInBottleH;
						numO5<=PillsInBottleL;
					else
						numO1<="1111";
						numO2<="1111";
						numO3<=PillsCountH;
						numO4<=PillsCountM;
						numO5<=PillsCountL;
					end if;
				end if;
			when others=>null;
		end case;
	end process;

end architecture;


		