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
		numO1: OUT std_logic_vector(3 downto 0);	--持续输出5组8421，至辉光管--
		numO2: OUT std_logic_vector(3 downto 0);
		numO3: OUT std_logic_vector(3 downto 0);
		numO4: OUT std_logic_vector(3 downto 0);
		numO5: OUT std_logic_vector(3 downto 0);
		
		stat, err: OUT std_logic;	--状态表示，持续输出，至LED--
		
		redLED, greenLED: OUT std_logic;

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
	signal finished: std_logic;--完成Flag--
	signal BottlesCount: integer range 0 to 19;--瓶数计数器，达到上限停止，上限19瓶--
	signal increase: std_logic;
	signal BottleReady: std_logic := '1';

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
	

    process(setK)--输入数值--
    begin
        if(setK'event and setK='1') then 
            if(num="1001") then 
                num<="0000";
            else
                num<=num+1;    
            end if;
        end if;
	end process;
	
    process(num)--将暂存数放入每瓶片数寄存器--
    begin
        case status is
			when "01"=>--输入十位状态--
				if(num > "0100") then--十位为5以上时不接受，最大片数49--
					--redLED<='1';--拒绝，输入无效
					--TODO:怎么关红灯啊啊啊啊--
				else
					--redLED<='0';	
					PillsPerBottleH<=num;--暂存数打入每瓶片数寄存器高位--
				end if;
            when "10"=>PillsPerBottleL<=num;--暂存数打入每瓶片数寄存器低位--
            when others=>NULL;--其他情况不改变
    end case;
    end process;

    --错误输入情况下判断--


	--开始信号将状态置为开始--
	Process(startPulse)
	begin
		if(startPulse'event and startPulse='1') then--开始脉冲给出，进入运行状态——-
			started<='1';
		end if;
	end process;


    --装片过程处理--
    process(tabI,nextK)
	begin
		if(BottlesCount = 19) then --总瓶数到达停止--
			redLED<='1';
			greenLED<='0';
			finished<='1';
		else --装瓶进行--
			if(tabI'event and tabI = '1' and finished='0') then --开始装瓶--
				if(started='1' and status="11") then
					--greenLED<='1';--装片进行中--

					
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

					--单瓶计数器--
					if(PillsInBottleH < PillsPerBottleH ) then --未满时装瓶!!比十位--
						if(PillsInBottleL = "1001") then--瓶中计数个位为9时--
							PillsInBottleH<=PillsInBottleH+1;--十位进位--
							PillsInBottleL<="0000";--个位置0--
						else --正常时--
							PillsInBottleL<=PillsInBottleL+1;--个位加一--
						end if;
						
					else
						if( PillsInBottleL < PillsPerBottleL ) then
							PillsInBottleL<=PillsInBottleL+1;--个位+1
						else --瓶满状态--
							BottlesCount<=BottlesCount+1;--已装瓶计数+1
							--if (nextK='1' and nextK'last_value='0') then--来瓶了--
							--	BottleReady<='1';
								--来瓶后瓶内计数器清零,暂时无法实现来瓶脉冲，自动给新瓶装一片-- 
								--BUG:最后会装到总数多一片--
								PillsInBottleH<="0000";
								PillsInBottleL<="0001";
							--else 
								--BottleReady<='0';--等待新瓶--
							--end if;	
						end if;
					end if;
					--单瓶计数器--
				end if;	
			end if;
		end if;
	end process;


	
	--异步输出--
	Process(status,PillsPerBottleH,PillsPerBottleL,PillsInBottleL,PillsCountL)
	begin
		case status is
			--when "00"=>numO<="11111111111111111111"; --等待有效输入--
			when "01"=>numO1<=PillsPerBottleH; --输入每瓶片数十位--
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
