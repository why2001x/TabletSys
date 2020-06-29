library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

--modeK切换模式，分别为：待机、设定每瓶十位、设定每瓶个位、准备就绪--
--setK：每按一次当前设定位+1（设十位/个位时）--
--startpulse:状态为就绪时，按下pulse开始--
--greenLED:正常装瓶时（startpulse启动后）亮--
--redLED：设定每瓶片数十位时，超过4时报警，固定在4不可增加（最大每瓶片数为49）/halt状态亮/装瓶结束亮
--numO1-O5：
--待机模式:没定
--设定每瓶十位模式：numO1显示十位
--设定每瓶个位模式：numO1显示十位，numO2显示个位
--准备就绪：全0
--开始装瓶：前2位为当前瓶内已装片数，前3位为从开始以来总共装片个数
--TODO：来瓶脉冲控制/halt、停机时闪烁（LED？)
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

		--PillsPerBottleL: buffer std_logic_vector(3 downto 0);--每瓶片数，2个BCD--
		--BottleReady: buffer std_logic := '1';
		--BottleFull: buffer std_logic :='0';
		
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
	signal finished: std_logic :='0';--完成Flag--
	signal BottleReady: std_logic := '1';
	signal haltStatus: std_logic :='0';
	signal BottleFull: std_logic :='0';
		
begin


    process(modeK)--切换模式--
    begin 
     if(modeK'event and modeK='1') then --切换输入状态
      case status is 
        when "00"=>status<="01"; --等待有效输入--
        when "01"=>status<="10"; --每瓶十位--
        when "10"=>status<="11"; --每瓶个位--
        when "11"=>status<="00"; --准备就绪--
      end case;
     end if;
	end process;
	
	

    process(setK,modeK,status)--输入数值--
	begin
		--case modeK is
		--	when '1'=>
		--		if(status = "10" or status = "01") then--防止被切换到就绪状态时清零
		--		num<="0000";--切换模式时置0（异步）--
		--		end if;
		--	when '0'=>
				if(setK'event and setK='1') then 
           			if(num="1001") then --超过9时回0--
					num<="0000";
					else
             		num<=num+1;    
					end if;
				end if;
		--	when others=>NULL;
	--	end case;
	end process;


	process(num)--将暂存数放入每瓶片数寄存器--
    begin
        case status is
			when "01"=>--输入十位状态--
				if(num <= "0100") then--十位为5以上时不接受，最大片数49----不加底下兜底时，为甚么0101会被赋进去？？
					PillsPerBottleH<=num;--暂存数打入每瓶片数寄存器高位--
				else 
					PillsPerBottleH<="0100";--兜下来，不允许增加
				end if;
            when "10"=>PillsPerBottleL<=num;--暂存数打入每瓶片数寄存器低位--
            when others=>NULL;--其他情况不改变
    end case;
	end process;
	
	
	process(haltK) --急停状态管理--
	begin
		if(haltK'event and haltK='1') then
			case haltStatus is
				when '0'=>haltStatus<='1';
				when '1'=>haltStatus<='0';
			end case;
		end if;
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
		if(finished='1' or (num>"0100" and status="01") or haltStatus='1' ) then
			redLED<='1';
			greenLED<='0';
		elsif(started='1' and status="11" and finished='0' ) then
			redLED<='0';
			greenLED<='1';
		else 
			redLED<='0';
			greenLED<='0';
		end if;
	end process;

    --装片过程处理--
	process(tabI,nextK)
	variable BottlesCount: integer range 0 to 19 :=0 ;--瓶数计数器，达到上限停止，上限19瓶--
	begin
		if(haltStatus='0') then--急停管理
			if(BottlesCount = 19 ) then --总瓶数到达停止--
				finished<='1';
			else --装瓶进行--
				finished<='0';
				if(tabI'event and tabI = '1') then --开始装瓶--
					if(started='1' and status="11") then
					--装片进行中--
						--if(BottleReady='1') then
						if(not(PillsInBottleL = PillsPerBottleL and PillsInBottleH = PillsPerBottleH and BottlesCount = 18)) then--非最后一瓶最后一片情况--
							--总计数器--
							if(PillsCountL = "1001" and PillsCountM < "1001") then --总计数个位为9时,且十位不为9时--
								PillsCountM<=PillsCountM+1;--十位进位--
								PillsCountL<="0000";--个位置0--
							elsif(PillsCountL = "1001" and PillsCountM = "1001") then --总计数个位为9且十位也为9时--
								PillsCountL<="0000";--个位置0--
								PillsCountM<="0000";--十位置0--
								PillsCountH<=PillsCountH+1;--百位进位--
							else --其他情况，个位+1--
								PillsCountL<=PillsCountL+1;
							end if;
							--总计数器--
						else 
								--finished<='1';
						end if;

							--单瓶计数器--
						if(PillsInBottleH < PillsPerBottleH ) then --未满时装瓶,比十位--
							if(PillsInBottleL = "1001") then--瓶中计数个位为9时--
								PillsInBottleH<=PillsInBottleH+1;--十位进位--
								PillsInBottleL<="0000";--个位置0--
							else --正常时--
								PillsInBottleL<=PillsInBottleL+1;--个位加一--
							end if;
							BottleFull<='0';--瓶未满--
						else
							if( PillsInBottleL < PillsPerBottleL ) then
								BottleFull<='0';--瓶未满--
								PillsInBottleL<=PillsInBottleL+1;--个位+1
							else --瓶满状态--
								if(BottlesCount /= 18) then
									PillsInBottleH<="0000";
									PillsInBottleL<="0001";--kenengyaogai !!--
								end if;
									BottlesCount:=BottlesCount+1;--已装瓶计数+1
									--BUG:最后会装到总数多一片--
									--BottleFull<='1';--瓶满--
							end if;
						end if;
							--单瓶计数器--
						--end if;
					end if;	
				end if;
			end if;
		end if;
		
	end process;


	
	--异步输出--
	Process(status,PillsPerBottleH,PillsPerBottleL,PillsInBottleL,PillsCountL,num)
	begin
		case status is
			--when "00"=>numO<="11111111111111111111"; --等待有效输入--
			when "01"=>numO1<=PillsPerBottleH; --输入每瓶片数十位，超出时亮红灯并按最大十位存入，但此时仍可见--
			when "10"=>numO2<=PillsPerBottleL; --输入每瓶片数个位--
			when "11"=>--前2个是已装每瓶片数计数，后3个是总装片数计数--
				numO1<=PillsInBottleH;
				numO2<=PillsInBottleL;
				numO3<=PillsCountH;
				numO4<=PillsCountM;
				numO5<=PillsCountL;
			when others=>null;
		end case;
	end process;

end architecture;


		