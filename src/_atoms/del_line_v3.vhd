--=============================
-- Developed by KST. Ver. 3.3. 
--=============================
----------------------------------------------------------------------------------
-- Company:         Дизайн-центр
-- Engineer:        Станислав Кузнецов (KST)
--                  
-- Create Date:     14:30 12.12.2011 
-- Design Name:     
-- Module Name:     del_line_v3 - behavioral
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
--                  istb. По istb только увеличивается защитный счетчик.
--                  (Версия 2.х является самостоятельной независимой веткой.)
-- Revision 3.0 -   Введены входные и выходные стробы сопровождения. Величина
--                  задержки теперь измеряется в стробах сопровождения.
--                  Добавлен дополнительный выходной регистр XREG.
-- Revision 3.1 -   Исправлена ошибка формирования защитного счетчика
--                  s_oena_cnt при DEPTH=1.
--                  Убрано ограничение по DEPTH для "LUT".
--                  Ограничение по DEPTH для "RAM" снижено до 2.
-- Revision 3.2 -   Исправление ошибки ошибочной трактовки параметра DEPTH.
--                  В нем содержалась величина на единицу меньшая, 
--                  чем должна была. После коррекции пропала необходимость
--                  в проверке ограничений на минимальную величину DEPTH,
--                  теперь допустимы все значения больше нуля.
--                  Скорректировано начальное состояние линии задержки при
--                  реализации на базе "REG" и "LUT".
-- Revision 3.3 -   [KST: 20.10.2017] Добавлен параметр RAMINIT, позволяющий 
--                  исключать инициализацию памяти (BASE="RAM"), что является 
--                  важным, например, при использовании STYLE="M-RAM" (Altera).
--                  Данный вид памяти не поддерживает начальную инициализацию.
--                  В других случаях использование начальной инициализации
--                  делает более удобным анализ результатов симуляции.
--                  
--                  
-- Additional Comments: 
-- Величина задержки определяется параметром DEPTH.
-- Задержка измеряется в стробах istb, пришедших на вход.
--
-- Линия может быть реализована на базе триггеров (BASE = "REG"),
-- памяти (BASE = "RAM") и логики (BASE = "LUT").
-- Последнее отработано только на Xilinx.
-- 
-- Величина вносимой конвейером задержки для "REG" и "LUT" составляет 1 такт,
-- для "RAM" - 2 такта. 
-- Таким образом:
-- 1. Выходные данные линии задержки на базе "RAM" будут появлятся на такт
--    позже чем у линий на базе "REG" или "LUT".
-- 2. В случае непрерывного строба istb величина задержки будет не DEPTH 
--    тактов, а DEPTH + величина вносимой задержки
-- 
-- Чтобы линии задержки на базе "REG"/"LUT" работали аналогично
-- линии на базе "RAM", для них можно установить в единицу параметр XREG.
-- Это добавит дополнительный такт работы и их вносимая задержка станет
-- равной вносимой задержки линии на базе "RAM".
-- 
----------------------------------------------------------------------------------
    -- <метка> : entity work.del_line_v3
    -- generic map(
        -- IWIDTH => ,--Разрядность слова
        -- DEPTH  => ,--Длина линии задержки
        -- BASE   => ,--База для реализации: "REG", "RAM", "LUT"
        -- STYLE  => ,--Тип памяти для базы "RAM": "Auto", "M512", "M4K", "logic"
        -- RAMINIT=> ,--Признак начальной инициализации памяти (для BASE="RAM")
        -- XREG   => )--Дополнительный выходной регистр
    -- port map(
        -- aclr   => ,
        -- clk    => ,
        -- istb   => ,
        -- idata  => ,
        -- odata  => ,
        -- ostb   =>
    -- );
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.all;  
use IEEE.STD_LOGIC_ARITH.all;
use IEEE.STD_LOGIC_unsigned.all;

entity del_line_v3 is     
    generic(
        IWIDTH : integer;         --Разрядность слова
        DEPTH  : integer;         --Длина линии задержки
        BASE   : string := "REG"; --База для реализации:
                                  --"REG" - сдвиговый регистр на триггерах
                                  --"RAM" - память
                                  --"LUT" - сдвиговый регистр на LUT
        STYLE  : string := "Auto";--Тип памяти для базы "RAM"
                                  --Altera: "Auto", "M512", "M4K", "M-RAM", "MLAB", "M9K", "M144K", "logic"
                                  --Xilinx: "Auto"
        RAMINIT: boolean := true;--Признак начальной инициализации памяти (для BASE="RAM")
        XREG   : integer := 0);   --Дополнительный выходной регистр
        
    port(
        aclr   : in  std_logic;
        clk    : in  std_logic;
        idata  : in  std_logic_vector(IWIDTH-1 downto 0);
        istb   : in  std_logic;
        odata  : out std_logic_vector(IWIDTH-1 downto 0);
        ostb   : out std_logic);
end del_line_v3;

architecture behav of del_line_v3 is      
      
    signal s_oena_cnt   : integer range 0 to DEPTH+1-1 := 0;
    signal s_oena       : std_logic := '0';
    signal s_odata      : std_logic_vector(IWIDTH-1 downto 0) := (others => '0');
    signal s_ostb       : std_logic := '0';
    
begin
    
    
    assert (BASE = "REG" or  BASE = "RAM" or BASE = "LUT")
    report "DEL_LINE_V3: Wrong value of parameter 'BASE'. Only three values are allowed: 'REG', 'RAM' and 'LUT'!"
    severity FAILURE;
    assert (DEPTH > 0)
    report "DEL_LINE_V3: DEPTH must be positive!"
    severity FAILURE;
    
    
    --=====================================================
    -- ЗАЩИТНЫЙ СЧЕТЧИК (ИСКЛЮЧЕНИЕ ПЕРЕХОДНОГО ПРОЦЕССА)
    --=====================================================
    oecnt : process(aclr,clk)
    begin
        if(aclr = '1')then
            s_oena_cnt  <= 0;
            s_oena      <= '0';
        elsif(rising_edge(clk)) then
            if(istb = '1')then
                if(s_oena = '0')then
                    s_oena_cnt <= s_oena_cnt + 1;
                end if;
                if(s_oena_cnt = DEPTH-1)then
                    s_oena <= '1';
                end if;
            end if;
        end if;
    end process;
    
    
    --==============================================
    --REGISTER BASE DELAY LINE
    --==============================================
    regbased:  if (BASE = "REG") generate
        type   reg_array    is array (0 to DEPTH+1) of std_logic_vector(IWIDTH-1 downto 0);
        signal reg_chain      : reg_array := (others => (others => '0'));
    begin
        
        reg_chain(0) <= idata;
        
        --ЦЕПОЧКА РЕГИСТРОВ
        regchain: for i in 1 to DEPTH+1 generate
            process(aclr,clk)
            begin
                if (aclr = '1') then 
                    reg_chain(i) <= (others=>'0');
                elsif(rising_edge(clk))then
                    if(istb = '1')then
                        reg_chain(i) <= reg_chain(i-1);    
                    end if;
                end if;
            end process;
        end generate;
         s_odata <= reg_chain(DEPTH+1);
        
        --ВЫХОДНОЙ СТРОБ ГОТОВНОСТИ
        os : process(aclr,clk)
        begin
            if(aclr = '1')then
                s_ostb    <= '0';
            elsif(rising_edge(clk)) then
                if(s_oena = '1')then
                    s_ostb <= istb;
                end if;
            end if;
        end process;
        
    end generate;
    --END OF REGISTER BASE DELAY LINE
    
    
    --==============================================
    --RAM BASE DELAY LINE
    --==============================================
    rambased:    if (BASE = "RAM") generate
        type   t_memory is array (0 to DEPTH-1) of std_logic_vector (IWIDTH-1 downto 0);
        
        function mem_init(init: boolean) return t_memory is
        begin
            if (init) then
                return (others => (others => '0'));
            else
                return (others => (others => 'U'));
            end if;
        end mem_init;-----------------------------------------------
       
        signal mem          : t_memory :=  mem_init(RAMINIT);
        attribute ramstyle  : string;
        attribute ramstyle of mem : signal is STYLE;
        
        signal s_mem_addr   : integer range 0 to DEPTH-1;
        signal s_mem_odata  : std_logic_vector(IWIDTH-1 downto 0) := (others => '0');
        signal s_org_data   : std_logic_vector(IWIDTH-1 downto 0) := (others => '0');
        signal s_stb        : std_logic := '0';
    begin
        
        --ФОРМИРОВАТЕЛЬ АДРЕСА
        addrfrm : process(aclr,clk)
        begin
            if (aclr = '1') then 
                s_mem_addr <= 0;
            elsif(rising_edge(clk))then
                if(istb = '1')then
                    if (s_mem_addr = DEPTH-1) then
                        s_mem_addr <= 0;
                    else
                        s_mem_addr <= s_mem_addr + 1;
                    end if;
                end if;
            end if;
        end process;
        
        --ПАМЯТЬ
        memory : process (clk)
        begin
            if rising_edge(clk) then
                s_mem_odata <= mem(s_mem_addr);
                if (istb = '1') then
                    mem(s_mem_addr) <= idata;
                end if;
            end if;
        end process;
        
        --ВЫХОДНОЙ РЕГИСТР
        org : process(aclr,clk)
        begin
            if(aclr = '1')then
                s_org_data    <= (others => '0');
            elsif(rising_edge(clk)) then
                if(s_oena = '1')then
                    s_org_data <= s_mem_odata;
                end if;
            end if;
        end process;
        s_odata <= s_org_data;
        
        --ВЫХОДНОЙ СТРОБ ГОТОВНОСТИ
        os : process(aclr,clk)
        begin
            if(aclr = '1')then
                s_stb     <= '0';
                s_ostb    <= '0';
            elsif(rising_edge(clk)) then
                if(s_oena = '1')then
                    s_stb  <= istb;
                    s_ostb <= s_stb;
                end if;
            end if;
        end process;
        
    end generate;
    --END OF RAM BASE DELAY LINE
    
    
    --==============================================
    --LUT (SRL primitive) BASE DELAY LINE
    --==============================================
    lutbased:  if (BASE = "LUT") generate
        type   lut_array    is array (0 to DEPTH) of std_logic_vector(IWIDTH-1 downto 0);
        signal lut_chain    : lut_array := (others => (others => '0'));
        signal s_org_data   : std_logic_vector(IWIDTH-1 downto 0) := (others => '0');
    begin
        
        lut_chain(0) <= idata;
        
        --Цепочка регистров реализуемых на LUT-ах
        lutchain : for i in 1 to DEPTH generate
            process(clk)
            begin
                if(rising_edge(clk))then
                    if(istb='1')then
                        lut_chain(i) <= lut_chain(i-1);    
                    end if;
                end if;
            end process;
        end generate;
        
        --выходной регистр
        org : process(aclr,clk)
        begin
            if(aclr = '1')then
                s_org_data    <= (others => '0');
            elsif(rising_edge(clk)) then
                if(s_oena = '1')then
                    s_org_data <= lut_chain(DEPTH);
                end if;
            end if;
        end process;
        s_odata <= s_org_data;
        
        --ВЫХОДНОЙ СТРОБ ГОТОВНОСТИ
        os : process(aclr,clk)
        begin
            if(aclr = '1')then
                s_ostb    <= '0';
            elsif(rising_edge(clk)) then
                if(s_oena = '1')then
                    s_ostb <= istb;
                end if;
            end if;
        end process;
        
    end generate;
    --END OF LUT BASE DELAY LINE
    
    
    --==============================================
    --ДОПОЛНИТЕЛЬНЫЙ ВЫХОДНОЙ РЕГИСТР
    --==============================================
    --ДОП. РЕГИСТР ВКЛЮЧЕН
    xreg_on:  if (XREG > 0) generate
        signal s_xreg_data   : std_logic_vector(IWIDTH-1 downto 0) := (others => '0');
        signal s_xreg_stb    : std_logic := '0';
    begin
        xrg : process(aclr,clk)
        begin
            if(aclr = '1')then
                s_xreg_data <= (others => '0');
                s_xreg_stb  <= '0';
            elsif(rising_edge(clk)) then
                s_xreg_data <= s_odata;
                s_xreg_stb  <= s_ostb;
            end if;
        end process;
        odata <= s_xreg_data;
        ostb  <= s_xreg_stb;
    end generate;
    --ДОП. РЕГИСТР ВЫКЛЮЧЕН
    xreg_off:  if (XREG <= 0) generate
        odata <= s_odata;
        ostb  <= s_ostb;
    end generate;
    
    
end behav;
