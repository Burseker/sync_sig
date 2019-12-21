--*****************************************************************************
--Author: Ryabkov Andrey
--Vendor: 
--Version: 1.2
--Application: 
--Filename: packer1x.vhd
--Date Last Modified: 
--Date Created: 
--
--Device: Stratix-II, Virtex-5, Spartan-6
--Design Name: Гармонь
--Purpose:    packer1x - гибкий упаковщик
--        * Разрядность входных слов может меняться
--          в процессе работы, шина i_width
--        * Разрядность выходных слов задается при
--          компиляции, параметр OWIDTH
--
--Dependencies:
--        * Поддержка OWIDTH = 32
--        * Так как блок является упаковщиком слов, то i_width
--          должна быть всегда меньше или равна OWIDTH
--        * После смены i_width блок требует сброса sclr
--        * Нельзя одновременно присылать стробы i_start и i_end,
--          иначе автомат будет работать неправильно. Между
--          этими стробами должен быть промежуток
--        * Необходимо соблюдать требование o_rdy - блок
--          готов принимать данные - стробы i_start, i_stb
--        * Если i_width меньше OWIDTH, то входное слово
--          должно быть размещено в старших разрядах i_dat
--
--Reference:
--
--Revision History:
--    Revision 0.1.0 (29/09/2011) - Первая версия
--        * Не решен вопрос необходимости параметра IMWIDTH
--    Revision 0.1.1 (29/09/2011) - Блок переименован
--        * Блок переименован flex_packer -> packer1x
--        * Обнаружена ошибка перехода в flush. Не учтено, что
--          если i_end_r = '1' and addr_hop = '1', выходное слово
--          не обязательно заполняется полностью.
--          Верно работает при i_width = 1, 2, 4, 8, 16, 32
--        * Ошибка исправлена. Для этого введен сигнал addr_align
--          блока addr_frmr. Если addr_hop = '1' and addr_align = '1',
--          выходное слово заполнилось полностью
--        * Изменено условие строба oend, процесс oend_prc
--        * Изменено условие установки сигнала fsm_flush в
--          состоянии receive
--    Revision 0.1.2 (10/10/2014) - Переименован вычислитель адреса
--        * addr_frmr -> addr_frmr_1x
--
--
--*****************************************************************************

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.pkg_packer1x.all;

entity packer1x is
  generic (
    OWIDTH  : integer := 32; -- выходная разрядность
    IMWIDTH : integer := 32  -- максимальная разрядность вх. шины данных
  );
  port (
    clk     : in  std_logic;
    sclr    : in  std_logic;
    
    i_stb   : in  std_logic;
    i_dat   : in  std_logic_vector(OWIDTH-1 downto 0);
    i_start : in  std_logic;
    i_end   : in  std_logic;
    i_width : in  std_logic_vector(log2_ceil(OWIDTH) downto 0); -- log2_ceil(32) = 5
    o_rdy   : out std_logic; -- готовность принимать данные
    
    o_stb   : out std_logic;
    o_dat   : out std_logic_vector(OWIDTH-1 downto 0);
    o_start : out std_logic;
    o_end   : out std_logic
  );
end packer1x;

architecture syn of packer1x is

  -- КОНСТАНТЫ
  -- Разрядность адреса, формируемого addr_frmr (+1, т.к. выходной регистр двойной)
  constant c_addr_w     : integer := log2_ceil(OWIDTH)+1; -- log2_ceil(32) + 1 = 6
  -- Разрядность адреса, формируемого addr_dc
  constant c_dc_oaddr_w : integer := OWIDTH;
  -- Разрядность адреса, формируемого addr_cd
  constant c_cd_oaddr_w : integer := c_addr_w-1;
  
  -- СИГНАЛЫ
  -- Внутренний синхронный сброс
  signal reset          : std_logic := '0';
  
  -- Управляющий автомат
  type st_type is (idle, start, receive, flush);
  signal state          : st_type := idle;
  signal fsm_reset      : std_logic := '0';
  signal fsm_ostart     : std_logic := '0';
  signal fsm_flush      : std_logic := '0';
  signal fsm_flush_r    : std_logic := '0';
  signal fsm_rdy        : std_logic := '0';

  -- Задержка данных и стробов
  signal i_dat_r        : std_logic_vector(OWIDTH-1 downto 0) := (others=>'0');
  signal i_dat_r1       : std_logic_vector(OWIDTH-1 downto 0) := (others=>'0');
  signal i_dat_r2       : std_logic_vector(OWIDTH-1 downto 0) := (others=>'0');
  signal i_dat_inv      : std_logic_vector(OWIDTH-1 downto 0) := (others=>'0');
  signal istrobe        : std_logic := '0';
  signal i_end_r        : std_logic := '0';
  
  -- Блок вычисления адреса
  type t_addr_arr is array (natural range <>) of std_logic_vector(c_addr_w-1 downto 0);
  signal addr           : t_addr_arr(0 to OWIDTH-1) := (others=>(others=>'0'));
  signal addr_align     : std_logic := '0';
  signal addr_hop       : std_logic := '0';
  signal addr_hop_r     : std_logic := '0';
  signal addr_hop_r1    : std_logic := '0';
  signal addr_hop_r2    : std_logic := '0';
  signal addr_hop_r3    : std_logic := '0';
  signal addr_hop_r4    : std_logic := '0';
  signal addr_hop_r5    : std_logic := '0';
  
  -- Дешифраторы
  type t_dcaddr_arr is array (natural range <>) of std_logic_vector(c_dc_oaddr_w-1 downto 0);
  signal dc_oaddr       : t_dcaddr_arr(0 to OWIDTH-1) := (others=>(others=>'0'));
  signal s_iwidth       : integer range 0 to OWIDTH := 0;
  signal dc_ena         : std_logic_vector(OWIDTH-1 downto 0) := (others=>'0');
  signal dc_ohigh       : std_logic_vector(OWIDTH-1 downto 0) := (others=>'0');
  
  -- Шифраторы
  type t_cdaddr_arr is array (natural range <>) of std_logic_vector(c_cd_oaddr_w-1 downto 0);
  signal cd_oaddr       : t_cdaddr_arr(0 to OWIDTH-1) := (others=>(others=>'0'));
  signal cd_iaddr       : t_dcaddr_arr(0 to OWIDTH-1) := (others=>(others=>'0'));
  signal cd_istb        : std_logic := '0';
  signal cd_ostb        : std_logic_vector(OWIDTH-1 downto 0) := (others=>'0');
  signal cd_ohigh       : std_logic_vector(OWIDTH-1 downto 0) := (others=>'0');
  
  -- Мультиплексоры
  signal mx_idat        : std_logic_vector(OWIDTH-1 downto 0) := (others=>'0');
  signal mx_odat        : std_logic_vector(OWIDTH-1 downto 0) := (others=>'0');
  signal mx_ostb        : std_logic_vector(OWIDTH-1 downto 0) := (others=>'0');
  signal mx_ohigh       : std_logic_vector(OWIDTH-1 downto 0) := (others=>'0');
  
  -- Демультиплексоры
  type t_stb_arr is array (natural range <>) of std_logic_vector(1 downto 0);
  type t_dat_arr is array (natural range <>) of std_logic_vector(1 downto 0);
  signal dmxostb        : t_stb_arr(0 to OWIDTH-1) := (others=>(others=>'0'));
  signal dmxodat        : t_dat_arr(0 to OWIDTH-1) := (others=>(others=>'0'));
  signal dmx_ostb       : std_logic_vector(2*OWIDTH-1 downto 0) := (others=>'0');
  signal dmx_odat       : std_logic_vector(2*OWIDTH-1 downto 0) := (others=>'0');
  
  -- Выходной двойной регистр
  signal oreg           : std_logic_vector(2*OWIDTH-1 downto 0) := (others=>'0');
  signal oreg_inv       : std_logic_vector(2*OWIDTH-1 downto 0) := (others=>'0');
  signal reg_sel        : std_logic := '0';
  
  -- Выход
  signal ostb           : std_logic := '0';
  signal oend           : std_logic := '0';
  signal oend_r         : std_logic := '0';
  signal oend_r1        : std_logic := '0';
  signal oend_r2        : std_logic := '0';
  signal oend_r3        : std_logic := '0';
  signal oend_r4        : std_logic := '0';
  signal oend_r5        : std_logic := '0';
  signal odat           : std_logic_vector(OWIDTH-1 downto 0) := (others=>'0');

begin
  
  --==================================================
  -- ВНУТРЕННИЙ СИНХРОННЫЙ СБРОС
  --==================================================
  reset_prc: process(clk)
  begin
    if(rising_edge(clk))then
        reset <= sclr or fsm_reset;
    end if;
  end process;
  
  
  --==================================================
  -- УПРАВЛЯЮЩИЙ АВТОМАТ
  --==================================================
  fsm_prc: process(clk)
  begin
    if(rising_edge(clk))then
        if(sclr = '1')then
            state <= idle;
            fsm_reset  <= '1';
            fsm_ostart <= '0';
            fsm_flush  <= '0';
            fsm_rdy    <= '0';
        else
            case state is
                when idle => -- Исходное состояние
                    if(i_start = '1')then
                        state <= start;
                    end if;
                    fsm_reset <= '0';
                    fsm_rdy   <= '1';
                    
                --==================================================
                when start => -- Отправка строба o_start
                    if(addr_hop_r5 = '1')then
                        state <= receive;
                        fsm_ostart <= '1';
                    end if;
                    
                --==================================================
                -- NOTE: Если i_end_r = '1' and addr_hop = '1' and addr_align = '1',
                -- то выходное слово заполнилось полностью. Иначе поступивших
                -- данных недостаточно для выходного слова, нужна дозагрузка (fsm_flush)
                when receive => -- Прием и упаковка
                    if(i_end_r = '1')then
                        state <= flush;
                        if(addr_hop = '1' and addr_align = '1')then
                            fsm_flush <= '0'; -- выгружать регистр не нужно
                        else
                            fsm_flush <= '1'; -- иначе нужно выгрузить регистр
                        end if;
                    end if;
                    if(i_end = '1')then
                        fsm_rdy <= '0';
                    end if;
                    fsm_ostart <= '0';
                    
                --==================================================
                when flush => -- Выгрузить выходной регистр
                    if(oend_r4 = '1')then
                        state <= idle;
                        fsm_reset <= '1';
                    end if;
                    if(addr_hop = '1')then
                        fsm_flush <= '0';
                    end if;
                    
                --==================================================
                when others => NULL;
            end case;
        end if;
    end if;
  end process;


  --==================================================
  -- ЗАДЕРЖКА ДАННЫХ И СТРОБОВ
  --==================================================
  -- Инверсия разрядов входного слова для удобной адресации
  reg_inv: for i in 0 to OWIDTH-1 generate
    i_dat_inv(i) <= i_dat(OWIDTH-1-i);
  end generate;
  
  del_prc: process(clk)
  begin
    if(rising_edge(clk))then
        -- Главный строб
        istrobe  <= i_stb or fsm_flush;
        -- Строб на дешифраторы
        cd_istb  <= istrobe;
        -- Задержанные данные на мультиплексор
        i_dat_r  <= i_dat_inv;
        i_dat_r1 <= i_dat_r;
        i_dat_r2 <= i_dat_r1;
        mx_idat  <= i_dat_r2;
        -- Разрядность входных слов
        s_iwidth <= to_integer(unsigned(i_width));
    end if;
  end process;

  --==================================================
  -- Строб o_end
  oend_prc: process(clk)
  begin
    if(rising_edge(clk))then
        -- Задержка строба i_end на 1 такт
        i_end_r <= i_end;
        -- Строб oend
        -- if(addr_hop = '1' and (i_end_r = '1' or fsm_flush = '1'))then
        -- if(addr_hop = '1' and (i_end_r = '1' or (istrobe = '1' and state = flush)))then
        fsm_flush_r <= fsm_flush;
        -- if(addr_hop = '1' and (i_end_r = '1' or fsm_flush_r = '1'))then
        if(addr_hop = '1' and ((i_end_r = '1' and addr_align = '1') or fsm_flush_r = '1'))then
            oend <= '1';
        else
            oend <= '0';
        end if;
        -- Задержка строба oend
        oend_r  <= oend;
        oend_r1 <= oend_r;
        oend_r2 <= oend_r1;
        oend_r3 <= oend_r2;
        oend_r4 <= oend_r3;
        oend_r5 <= oend_r4;
    end if;
  end process;
  

  --==================================================
  -- БЛОК ВЫЧИСЛЕНИЯ АДРЕСА
  -- Определяет разряды выходного регистра, в которые
  -- нужно записать поступившее входное слово
  --==================================================
  -- Нулевой addr_frmr
  -- NOTE: addr_hop берется с выхода нулевого addr_frmr
  u_addrfrmr: addr_frmr_1x
  GENERIC MAP(
    OPWIDTH => c_addr_w,
    OWIDTH  => OWIDTH,
    INIT    => 0)
  PORT MAP(
    clk     => clk,
    sclr    => reset,
    i_ena   => istrobe,
    i_width => i_width,
    o_hop   => addr_hop,
    o_align => addr_align,
    o_addr  => addr(0));
  
  -- Остальные addr_frmr
  addr_gen: for i in 1 to OWIDTH-1 generate
    u_addrfrmr: addr_frmr_1x
    GENERIC MAP(
        OPWIDTH => c_addr_w,
        OWIDTH  => OWIDTH,
        INIT    => i)
    PORT MAP(
        clk     => clk,
        sclr    => reset,
        i_ena   => istrobe,
        i_width => i_width,
        o_hop   => open,
        o_align => open,
        o_addr  => addr(i));
  end generate;
  
  -- Строб - прыжок в следующий выходной регистр
  ohop_prc: process(clk)
  begin
    if(rising_edge(clk))then
        if(istrobe = '1')then
            addr_hop_r <= addr_hop;
        else
            addr_hop_r <= '0';
        end if;
        addr_hop_r1 <= addr_hop_r;
        addr_hop_r2 <= addr_hop_r1;
        addr_hop_r3 <= addr_hop_r2;
        addr_hop_r4 <= addr_hop_r3;
        addr_hop_r5 <= addr_hop_r4;
    end if;
  end process;
  
  
  --==================================================
  -- ВЫБОР РАБОЧИХ ДЕШИФРАТОРОВ
  --==================================================
  dcena_gen: for i in 0 to OWIDTH-1 generate
    dcena_prc: process(clk)
    begin
        if(rising_edge(clk))then
            if(s_iwidth > i)then
                dc_ena(i) <= '1';
            else
                dc_ena(i) <= '0';
            end if;
        end if;
    end process;
  end generate;
  
  
  --==================================================
  -- ДЕШИФРАТОРЫ
  -- Старший разряд не берется. Выбор выходного двойного
  -- регистра осуществляется на следующей ступени (o_high)
  --==================================================
  dc_gen: for i in 0 to OWIDTH-1 generate
    u_addrdc: addr_dc
    GENERIC MAP(
        OWIDTH => OWIDTH)
    PORT MAP(
        clk    => clk,
        i_stb  => istrobe,
        i_ena  => dc_ena(i),
        i_addr => addr(i),
        o_high => dc_ohigh(i),
        o_addr => dc_oaddr(i));
  end generate;
  
  
  --==================================================
  -- ШИФРАТОРЫ
  --==================================================
  -- Входной адрес на шифраторы
  cd_iaddr_gen_i: for i in 0 to OWIDTH-1 generate
    cd_iaddr_gen_j: for j in 0 to OWIDTH-1 generate
        cd_iaddr(j)(i) <= dc_oaddr(i)(j);
    end generate;
  end generate;

  -- Шифраторы
  cd_gen: for i in 0 to OWIDTH-1 generate
    u_addrcd: addr_cd
    GENERIC MAP(
        OWIDTH => OWIDTH)
    PORT MAP(
        clk    => clk,
        i_stb  => cd_istb,
        i_high => dc_ohigh,
        i_addr => cd_iaddr(i),
        o_stb  => cd_ostb(i),
        o_high => cd_ohigh(i),
        o_addr => cd_oaddr(i));
  end generate;


  --==================================================
  -- МУЛЬТИПЛЕКСОРЫ
  --==================================================
  mx_gen: for i in 0 to OWIDTH-1 generate
    ow32_gen: if (OWIDTH = 32) generate
        u_mux32_1: mux32_1_r
        PORT MAP(
            clk    => clk,
            addr   => cd_oaddr(i),
            input  => mx_idat,
            output => mx_odat(i));
    end generate;
  end generate;
  
  mxout_prc: process(clk)
  begin
    if(rising_edge(clk))then
        mx_ohigh <= cd_ohigh;
        mx_ostb  <= cd_ostb;
    end if;
  end process;
  
  
  --==================================================
  -- ДЕМУЛЬТИПЛЕКСОРЫ
  --==================================================
  dmux_gen: for i in 0 to OWIDTH-1 generate
    u_dmux1_2: dmux1_2_r
    PORT MAP(
        clk    => clk,
        i_stb  => mx_ostb(i),
        i_addr => mx_ohigh(i),
        i_dat  => mx_odat(i),
        o_stb  => dmxostb(i),
        o_dat  => dmxodat(i));
  end generate;
  
  dmxout_gen: for i in 0 to OWIDTH-1 generate
    dmx_ostb(i)        <= dmxostb(i)(0);
    dmx_ostb(i+OWIDTH) <= dmxostb(i)(1);
    dmx_odat(i)        <= dmxodat(i)(0);
    dmx_odat(i+OWIDTH) <= dmxodat(i)(1);
  end generate;
  
  
  --==================================================
  -- ВЫХОДНОЙ ДВОЙНОЙ РЕГИСТР
  -- Двойной регистр нужен для непрерывности
  -- процесса упаковки входных слов
  --==================================================
  -- Выходной регистр
  oreg_i_gen: for i in 0 to 2*OWIDTH-1 generate
    oreg_i_prc: process(clk)
    begin
        if(rising_edge(clk))then
            if(dmx_ostb(i) = '1')then
                oreg(i) <= dmx_odat(i);
            end if;
        end if;
    end process;
  end generate;
  
  -- Инверсия разрядов
  oreg_inv_gen: for i in 0 to 2*OWIDTH-1 generate
    oreg_inv(i) <= oreg(2*OWIDTH-1-i);
  end generate;
  
  -- Выбор регистра для выдачи
  regsel_prc: process(clk)
  begin
    if(rising_edge(clk))then
        if(reset = '1')then
            reg_sel <= '0';
        elsif(addr_hop_r4 = '1')then
            reg_sel <= not reg_sel;
        end if;
    end if;
  end process;
  
  -- Строб
  oreg_prc: process(clk)
  begin
    if(rising_edge(clk))then
        if(addr_hop_r5 = '1')then
            ostb <= '1';
        else
            ostb <= '0';
        end if;
    end if;
  end process;
  
  -- Выходной мультиплексор
  odat_prc: process(clk)
  begin
    if(rising_edge(clk))then
        if(reg_sel = '0')then
            odat <= oreg_inv(OWIDTH-1 downto 0);
        else
            odat <= oreg_inv(2*OWIDTH-1 downto OWIDTH);
        end if;
    end if;
  end process;
  
  
  --==================================================
  -- ВЫХОД
  --==================================================
  o_rdy   <= fsm_rdy and not i_end;
  o_stb   <= ostb;
  o_dat   <= odat;
  o_start <= fsm_ostart;
  o_end   <= oend_r5;


end syn;
