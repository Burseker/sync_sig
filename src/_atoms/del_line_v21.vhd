--=============================
-- Developed by KST. Ver. 2.1. 
--=============================
----------------------------------------------------------------------------------
-- Company:         Дизайн-центр
-- Engineer:        Станислав Кузнецов
--                  
-- Create Date:     14:30 12.12.2011 
-- Design Name:     
-- Module Name:     del_line_v21 - behavioral
-- Project Name:    
-- Target Devices:  
-- Tool versions:   Notepad++
-- Description:     Линия задержки
--                  
--                  
-- Dependencies:    Полностью независимый блок
--                  
-- Revision:        
-- Revision 1.0 -   утеряно
-- Revision 2.0 -   утеряно
-- Revision 2.1 -   При реализации на базе RAM и LUT выходной сигнал 
--                  формируется каждый такт вне зависимости от сигнала
--                  enable. По enable только увеличивается защитный счетчик.
--                  
-- Additional Comments: 
-- Линия задержки. Время задержки в тактах задается параметром depth.
-- Линия может быть реализована в виде сдвиговых регистров на базе триггеров
-- (base = "REG"), на базе памяти (base = "RAM") и в виде сдвиговых регистров 
-- на базе LUTов (base = "LUT"). Последнее отработано только на Xilinx.
-- 
-- 
----------------------------------------------------------------------------------
--	<метка> : entity work.del_line_v21
--	generic map(
--		iwidth => ,
--		depth  => ,
--		base   => ,--"REG", "RAM", "LUT"
--		style  => )--"Auto", "M512", "M4K", "M-RAM", "MLAB", "M9K", "M144K", "logic"
--	port map(
--		aclr   => ,
--		clk    => ,
--		enable => ,
--		din    => ,
--		dout   => 
--	);
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.all;  
use IEEE.STD_LOGIC_ARITH.all;
use IEEE.STD_LOGIC_unsigned.all;

entity del_line_v21 is	 
	generic(
        iwidth	: integer;         --Разрядность слова
        depth	: integer;         --Длина линии задержки
        base	: string := "REG"; --База для реализации:
                                   --"REG" - сдвиговый регистр на триггерах
                                   --"RAM" - память
                                   --"LUT" - сдвиговый регистр на LUT
        style   : string := "Auto" --Тип памяти для базы "RAM"
                                   --Altera: "Auto", "M512", "M4K", "M-RAM", "MLAB", "M9K", "M144K", "logic"
                                   --Xilinx: "Auto"
            );
	port(
		aclr	: in 	std_logic;
		clk		: in 	std_logic;
		enable	: in 	std_logic;
		din		: in 	std_logic_vector(iwidth-1 downto 0);	   
		dout	: out 	std_logic_vector(iwidth-1 downto 0));
end del_line_v21;

architecture behav of del_line_v21 is	  
	
begin
	
	assert (base = "REG" or  base = "RAM" or base = "LUT")
	report "Wrong value of parameter 'base'. Only three values are allowed: 'REG', 'RAM' and 'LUT'!" 
	severity ERROR;
	assert not (base = "RAM" and depth < 3)
	report "For base = 'RAM' depth must be greater then 2."
	severity FAILURE;
	assert not (base = "LUT" and depth < 3)
	report "For base = 'LUT' depth must be greater then 2."
	severity FAILURE;	
	
	
	--==============================================
	--REGISTER BASE DELAY LINE
	--==============================================
	regbased:	if (base = "REG") generate
		type	reg_array	is array (0 to depth) of std_logic_vector(iwidth-1 downto 0);
		signal	reg_out		: reg_array;
		begin
		
		reg_out(0) <= din;
		
		--цепочка регистров
		reg_chain: for i in 1 to depth generate
			process(aclr,clk)
			begin
				if (aclr = '1') then 
					reg_out(i) <= (others=>'0');
				elsif(rising_edge(clk))then
                    if(enable = '1')then
                        reg_out(i) <= reg_out(i-1);	
                    end if;
				end if;
			end process;
		end generate;
		
		dout <= reg_out(depth);
		
	end generate;
	--END OF REGISTER BASE DELAY LINE
	
	
	--==============================================
	--RAM BASE DELAY LINE
	--==============================================
	rambased:	if (base = "RAM" and depth > 2) generate
		type 	memory 		is array (0 to depth-1) of std_logic_vector (iwidth-1 downto 0);
		signal	mem 		: memory := (others => (others => '0'));
        attribute ramstyle : string; 
        attribute ramstyle of mem : signal is STYLE;
        
		signal	s_mem_addr	: integer range 0 to depth-2-1;
		signal	memout 		: std_logic_vector(iwidth-1 downto 0) := (others => '0');
		signal	memdout_ena_cnt: integer range 0 to depth-1 := 0;
		signal	memdout		: std_logic_vector(iwidth-1 downto 0) := (others => '0');	
		begin
		
		--формирователь адреса
		addrfrmr_prc : process(aclr,clk)
		begin
			if (aclr = '1') then 
				s_mem_addr <= 0;
			elsif(rising_edge(clk))then
				if(enable = '1')then
                    if (s_mem_addr = depth-2-1) then
                        s_mem_addr <= 0;
                    else
                        s_mem_addr <= s_mem_addr + 1;
                    end if;
                end if;
			end if;
		end process;
		
		--память
		memory_prc : process (clk)
		begin
			if rising_edge(clk) then
				memout <= mem(s_mem_addr);
				if (enable = '1') then
					mem(s_mem_addr) <= din;
				end if;
			end if;
		end process;
		
		--выходной регистр
		outrg_prc : process(aclr,clk)
		begin
			if(aclr = '1')then
				memdout	<= (others => '0');
				memdout_ena_cnt <= 0;
			elsif(rising_edge(clk)) then
				if(memdout_ena_cnt = depth-1)then
					memdout <= memout;
				end if;
				if(enable = '1')then
					if(memdout_ena_cnt < depth-1)then
						memdout_ena_cnt <= memdout_ena_cnt + 1;
					end if;
				end if;
			end if;
		end process;
		
		dout <= memdout;
		
	end generate;
	--END OF RAM BASE DELAY LINE
	
	
	--==============================================
	--LUT (SRL primitive) BASE DELAY LINE
	--==============================================
	lutbased:	if (base = "LUT" and depth > 1) generate
		type	lut_array	is array (0 to depth-1) of std_logic_vector(iwidth-1 downto 0);
		signal	lut_chain	: lut_array;
		signal	lutdout_ena_cnt: integer range 0 to depth-1 := 0;
		signal	lutdout		: std_logic_vector(iwidth-1 downto 0) := (others => '0');		
		begin
		
		lut_chain(0) <= din;
		
		--Цепочка регистров реализуемых на LUT-ах
		lutchain : for i in 1 to depth-1 generate
			process(clk)
			begin
				if(rising_edge(clk))then
                    if(enable='1')then
                        lut_chain(i) <= lut_chain(i-1);	
                    end if;
				end if;
			end process;
		end generate;
		
		--выходной регистр
		outrg_prc : process(aclr,clk)
		begin
			if(aclr = '1')then
				lutdout	<= (others => '0');
				lutdout_ena_cnt <= 0;
			elsif(rising_edge(clk)) then
				if(lutdout_ena_cnt = depth-1)then
					lutdout <= lut_chain(depth-1);
			    end if;
				if(enable='1')then
					if(lutdout_ena_cnt < depth-1)then
						lutdout_ena_cnt <= lutdout_ena_cnt + 1;
					end if;
				end if;
			end if;
		end process;
		
		dout <= lutdout;
		
	end generate;
	--END OF LUT BASE DELAY LINE
	
	
end behav;
