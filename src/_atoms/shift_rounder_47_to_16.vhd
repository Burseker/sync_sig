--================================================================================
-- Description: Сдвиговый регистр с округлением
-- Version:     0.1.0
-- Developer:   SVB
-- Workgroup:   IRS16
--================================================================================
-- Keywords:    
-- Tools:       modelsim 10.2d
--              
-- Note: 
-- 
-- Version History:
-- Ver 0.0.0 - File create
-- Ver 0.1.0 - Первая рабочая версия
----------------------------------------------------------------------------------

--=== basic lib ===
library ieee;                                               
use ieee.std_logic_1164.all;

--=== std logic lib ===
-- USE IEEE.STD_LOGIC_ARITH.ALL;
-- USE IEEE.STD_LOGIC_UNSIGNED.ALL;

--=== numeric std lib ===
use ieee.numeric_std.all;

--=== common lib ===
-- use work.qpkt_pkg.all;
use work.pkg_func.all;


entity shift_rounder_47_to_16 is
port (
    aclr    : in  std_logic;
    clk     : in  std_logic;
    
    shift   : in std_logic_vector(4 downto 0);
    idat    : in std_logic_vector(46 downto 0);
    istb    : in std_logic;    
    odat    : out std_logic_vector(15 downto 0) := (others => '0');
    ostb    : out std_logic    
  );
end shift_rounder_47_to_16;

architecture beh of shift_rounder_47_to_16 is

    
    
    -- type    t_slv42_arr8    is array (0 to 7) of std_logic_vector(41 downto 0);
    -- signal s_arr_dat_i  : t_slv42_arr8 := (others => (others => '0'));
    -- signal s_arr_dat_q  : t_slv42_arr8 := (others => (others => '0'));
    
    -- signal s_odat_i     : std_logic_vector(41 downto 0) := (others => '0');
    -- signal s_odat_q     : std_logic_vector(41 downto 0) := (others => '0');
    -- signal s_ostb       : std_logic := '0';
    
    
    --Stage 1
    signal s_st1_shift  : std_logic_vector(1  downto 0) := (others => '0');
    signal s_st1_mux    : std_logic_vector(18 downto 0) := (others => '0');
    signal s_st1_hext   : std_logic_vector(27 downto 0) := (others => '0');
    signal s_st1_lext   : std_logic_vector(27 downto 0) := (others => '0');
    signal s_st1_stb    : std_logic := '0';
    
    --Stage 2
    signal s_st2_mux    : std_logic_vector(17 downto 0) := (others => '0');
    signal s_st2_summ   : std_logic := '0';
    signal s_st2_sign   : std_logic := '0';
    signal s_st2_ovf    : std_logic := '0';
    signal s_st2_ovfa   : std_logic := '0';
    signal s_st2_stb    : std_logic := '0';
    
    signal s_odat       : std_logic_vector(15 downto 0) := (others => '0');
    signal s_ostb       : std_logic := '0';
begin
    

    
 -- --============================================= 
 -- -- Стадия 1
 -- --=============================================
    -- process(aclr, clk)
    -- begin
        -- if(aclr = '1')then
            -- s_st1_hz <= (others => '0');
            -- s_st1_ho <= (others => '0');
            -- s_st1_lz <= (others => '0');
            -- s_st1_lo <= (others => '0');
        -- elsif(rising_edge(clk))then
            -- for i in 0 to 6 loop
                -- s_st1_hz(i) <= and_bus( idat(i*4+22 downto i*4+19) );
                -- s_st1_ho(i) <= or_bus( idat(i*4+22 downto i*4+19) );
                
                -- s_st1_lz(i) <= and_bus( idat(i*4+3 downto i*4) );
                -- s_st1_lo(i) <= or_bus( idat(i*4+3 downto i*4) );
            -- end loop;
        -- end if;
    -- end process; 

    
 --============================================= 
 -- Стадия 1
 --=============================================
    process(aclr, clk)
    begin
        if(aclr = '1')then
            s_st1_mux    <= (others => '0');
            s_st1_shift  <= (others => '0');
            s_st1_hext   <= (others => '0');
            s_st1_lext   <= (others => '0');
            s_st1_stb    <= '0';
        elsif(rising_edge(clk))then
            case shift(4 downto 2) is
                when b"000" => s_st1_mux  <= idat(18 downto 0);
                               s_st1_hext <= idat(46 downto 19);
                               s_st1_lext <= (others => '0');
                when b"001" => s_st1_mux  <= idat(22 downto 4);
                               s_st1_hext(27 downto  4) <= idat(46 downto 23);
                               s_st1_hext(3  downto  0) <= (others => idat(23));
                               s_st1_lext(27 downto 24) <= idat(3 downto 0);
                               s_st1_lext(23 downto  0) <= (others => '0');
                when b"010" => s_st1_mux <= idat(26 downto 8);
                               s_st1_hext(27 downto  8) <= idat(46 downto 27);
                               s_st1_hext(7  downto  0) <= (others => idat(27));
                               s_st1_lext(27 downto 20) <= idat(7 downto 0);
                               s_st1_lext(19 downto  0) <= (others => '0');
                when b"011" => s_st1_mux <= idat(30 downto 12);
                               s_st1_hext(27 downto 12) <= idat(46 downto 31);
                               s_st1_hext(11 downto  0) <= (others => idat(31));
                               s_st1_lext(27 downto 16) <= idat(11 downto 0);
                               s_st1_lext(15 downto  0) <= (others => '0');
                when b"100" => s_st1_mux <= idat(34 downto 16);
                               s_st1_hext(27 downto 16) <= idat(46 downto 35);
                               s_st1_hext(15 downto  0) <= (others => idat(35));
                               s_st1_lext(27 downto 12) <= idat(15 downto 0);
                               s_st1_lext(11 downto  0) <= (others => '0');
                when b"101" => s_st1_mux <= idat(38 downto 20);
                               s_st1_hext(27 downto 20) <= idat(46 downto 39);
                               s_st1_hext(19 downto  0) <= (others => idat(39));
                               s_st1_lext(27 downto 8) <= idat(19 downto 0);
                               s_st1_lext(7 downto  0) <= (others => '0');
                when b"110" => s_st1_mux <= idat(42 downto 24);
                               s_st1_hext(27 downto 24) <= idat(46 downto 43);
                               s_st1_hext(23 downto  0) <= (others => idat(41));
                               s_st1_lext(27 downto 4) <= idat(23 downto 0);
                               s_st1_lext(3 downto  0) <= (others => '0');
                when b"111" => s_st1_mux <= idat(46 downto 28);
                               s_st1_hext <= (others => idat(46));
                               s_st1_lext <= idat(27 downto 0);
                when others => NULL;
            end case;
            
            s_st1_shift <= shift(1 downto 0);
            s_st1_stb   <= istb;
        end if;
    end process;
    
    
 --============================================= 
 -- Стадия 2
 --=============================================
    process(aclr, clk)
    begin
        if(aclr = '1')then
            s_st2_mux  <= (others => '0');
            s_st2_summ <= '0';
            s_st2_sign <= '0';
            s_st2_ovf  <= '0';
            s_st2_ovfa <= '0';
            s_st2_stb  <= '0';
        elsif(rising_edge(clk))then
            s_st2_sign <= s_st1_hext(27);
            s_st2_stb <= s_st1_stb;
            if( s_st1_hext = x"000_0000" or s_st1_hext = x"FFF_FFFF" )then
                s_st2_ovf <= '0';
            else
                s_st2_ovf <= '1';
            end if;
            
            case s_st1_shift is
                when b"00" =>   
                                --настройка сумматора
                                if( s_st1_hext(27) = '0' )then
                                    s_st2_summ <= '1';
                                else
                                    if( s_st1_lext = x"800_0000" )then
                                        s_st2_summ <= '0';
                                    else
                                        s_st2_summ <= '1';
                                    end if;
                                end if;
                                --насторойка результата округления
                                s_st2_mux <= s_st1_mux(16 downto 0) & s_st1_lext(27);
                                --проверка переполнения
                                if( s_st1_mux(18 downto 15) = s_st1_hext(27 downto 24) )then
                                    s_st2_ovfa <= '0';
                                else
                                    s_st2_ovfa <= '1';
                                end if;
                                
                when b"01" =>
                                --настройка сумматора
                                if( s_st1_hext(27) = '0' )then
                                    s_st2_summ <= '1';
                                else
                                    if( s_st1_mux(0) = '1' and s_st1_lext = x"000_0000" )then
                                        s_st2_summ <= '0';
                                    else
                                        s_st2_summ <= '1';
                                    end if;
                                end if;
                                --насторойка результата округления
                                s_st2_mux <= s_st1_mux(17 downto 0);
                                --проверка переполнения
                                if( s_st1_mux(18 downto 16) = s_st1_hext(27 downto 25) )then
                                    s_st2_ovfa <= '0';
                                else
                                    s_st2_ovfa <= '1';
                                end if;
                when b"10" =>   
                                --настройка сумматора
                                if( s_st1_hext(27) = '0' )then
                                    s_st2_summ <= '1';
                                else
                                    if( s_st1_mux(1 downto 0) = b"10" and s_st1_lext = x"000_0000" )then
                                        s_st2_summ <= '0';
                                    else
                                        s_st2_summ <= '1';
                                    end if;
                                end if;
                                --насторойка результата округления
                                s_st2_mux <= s_st1_mux(18 downto 1);
                                --проверка переполнения
                                if( s_st1_mux(18 downto 17) = s_st1_hext(27 downto 26) )then
                                    s_st2_ovfa <= '0';
                                else
                                    s_st2_ovfa <= '1';
                                end if;
                when b"11" => 
                                --настройка сумматора
                                if( s_st1_hext(27) = '0' )then
                                    s_st2_summ <= '1';
                                else
                                    if( s_st1_mux(2 downto 0) = b"100" and s_st1_lext = x"000_0000" )then
                                        s_st2_summ <= '0';
                                    else
                                        s_st2_summ <= '1';
                                    end if;
                                end if;
                                --насторойка результата округления
                                s_st2_mux <= s_st1_hext(0) & s_st1_mux(18 downto 2);
                                --проверка переполнения
                                if( s_st1_mux(18) = s_st1_hext(27) )then
                                    s_st2_ovfa <= '0';
                                else
                                    s_st2_ovfa <= '1';
                                end if;
                                
                when others => NULL;
            end case;
            
        end if;
    end process;
    
    
 --============================================= 
 -- Стадия 3
 --=============================================
    process(aclr, clk)
    variable v_tdat : signed(17 downto 0);
    begin
        if(aclr = '1')then
            s_odat <= (others => '0');
            s_ostb <= '0';
        elsif(rising_edge(clk))then
            v_tdat := signed(s_st2_mux);
            if( s_st2_summ = '1' )then v_tdat := v_tdat + 1;
            else v_tdat := v_tdat; end if;
            
            if( s_st2_ovf = '1' or s_st2_ovfa = '1' )then
                s_odat <= s_st2_sign & (14 downto 0 => (not s_st2_sign));
            elsif( v_tdat(17) = v_tdat(16) )then
                s_odat <= std_logic_vector(v_tdat(16 downto 1));
            else 
                s_odat <= not std_logic_vector(v_tdat(16 downto 1));
            end if;
            s_ostb <= s_st1_stb;
        end if;
    end process; 
    
    
 --============================================= 
 -- Назначение выходных сигналов
 --=============================================
    odat <= s_odat;
    ostb <= s_ostb;
    
end beh;