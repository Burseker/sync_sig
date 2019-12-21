--*****************************************************************************
--Author: Ryabkov Andrey
--Vendor: 
--Version: 1.2
--Application: 
--Filename: addr_frmr_1x.vhd
--Date Last Modified: 
--Date Created: 
--
--Device: Stratix-II, Virtex-5
--Design Name: Гармонь
--Purpose:    addr_frmr_1x - блок вычисления адреса для flex_packer
--        Суммирует число i_width по модулю OWIDTH с накоплением
--        * Формула: mux = (mux + i_width) % OWIDTH
--
--Dependencies:
--
--Reference:
--    * На основе addr_frmr распаковщика flex_unpacker
--
--Revision History:
--    Revision 0.1.0 (20/09/2011) - Первая версия
--    Revision 0.1.1 (29/09/2011) - o_align
--        + Добавлен порт o_align - сигнал, что на следующий такт
--          адрес будет указывать на начало регистра
--    Revision 0.1.2 (10/10/2014) - Блок переименован addr_frmr_1x
--
--
--*****************************************************************************

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity addr_frmr_1x is
  generic (
    OPWIDTH : integer := 6;  -- разрядность операндов
    OWIDTH  : integer := 32; -- выходная разрядность flex_packer
    INIT    : integer := 0   -- начальное значение выходного регистра
  );
  port (
    clk     : in  std_logic;
    sclr    : in  std_logic;
    
    i_ena   : in  std_logic; -- выдать адрес
    i_width : in  std_logic_vector(OPWIDTH-1 downto 0); -- входная разрядность flex_packer
    o_hop   : out std_logic;
    o_align : out std_logic;
    o_addr  : out std_logic_vector(OPWIDTH-1 downto 0)  -- адрес на выход
  );
end addr_frmr_1x;

architecture syn of addr_frmr_1x is

  constant c_zeros : std_logic_vector(OPWIDTH-2 downto 0) := (others=>'0');

  signal sum       : std_logic_vector(OPWIDTH-1 downto 0) := (others=>'0');
  signal sub       : std_logic_vector(OPWIDTH-1 downto 0) := (others=>'0');
  signal mux       : std_logic_vector(OPWIDTH-2 downto 0) := std_logic_vector(to_unsigned(INIT, OPWIDTH-1));
  
  signal sign_sub  : std_logic := '0';
  signal rgnum     : std_logic := '0';
  
begin

  --==================================================
  -- Сумматор-накопитель
  sum_prc: process(i_width, mux)
    variable v_mux : std_logic_vector(OPWIDTH-1 downto 0) := (others=>'0');
  begin
    v_mux := '0' & mux;
    sum   <= std_logic_vector(unsigned(i_width) + unsigned(v_mux));
  end process;
  
  
  --==================================================
  -- Вычитатель
  sub_prc: process(sum)
  begin
    sub <= std_logic_vector(unsigned(sum) - to_unsigned(OWIDTH, OPWIDTH));
  end process;
  
  sign_sub <= sub(sub'length-1); -- знаковый разряд sub
  
  
  --==================================================
  -- Мультиплексор
  mux_prc: process(clk)
  begin
    if(rising_edge(clk))then
        if(sclr = '1')then
            mux <= std_logic_vector(to_unsigned(INIT, OPWIDTH-1));
        elsif(i_ena = '1')then
            if(sign_sub = '1')then -- если sub отрицательное
                mux <= sum(OPWIDTH-2 downto 0);
            else
                mux <= sub(OPWIDTH-2 downto 0);
            end if;
        end if;
    end if;
  end process;
  
  
  --==================================================
  -- Самый старший разряд адреса -
  -- выбор одного из двух регистров
  rgnum_prc: process(clk)
  begin
    if(rising_edge(clk))then
        if(sclr = '1')then
            rgnum <= '0';
        elsif(i_ena = '1' and sign_sub = '0')then
            rgnum <= not rgnum;
        end if;
    end if;
  end process;
  
  o_addr <= rgnum & mux;
  
  
  --==================================================
  -- Сигнал o_hop - в следующий строб i_ena будет 
  -- прыжок адреса на другой регистр
  o_hop <= not sign_sub;
  
  
  --==================================================
  -- Сигнал o_align - в следующий строб i_ena адрес
  -- будет указывать на начало регистра, выравнен
  o_align <= '1' when (sub(OPWIDTH-2 downto 0) = c_zeros) else '0';
  
  
end syn;
