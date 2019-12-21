--=============================
-- Developed by SVB. Ver. 1.2.0 
--=============================
----------------------------------------------------------------------------------
-- Company:        Design-center
-- Engineer:       Burakov 
-- 
-- Create Date:    16:40:19 17/10/2013 
-- Design Name: 
-- Module Name:    bidir - Behavioral 
-- Project Name: 
-- Target Devices: 
-- Tool versions: 
-- Description: 
--
-- Dependencies: 
--
-- Revision:        
-- Revision 1.0.0 - Создание файла
-- Revision 1.1.0 - возможность включать fast_output_enable_reg
--                  fast_output_reg не поддерфивается в этой версии
--                  регистр всегда включен
-- Revision 1.2.0 - outp и inp поменяны местами
-- Revision 1.3.0 - Добавлен параметр SIM, симулирует схему подключения
--                  двунаправленного вывода с открытым коллектором(открытый сток).
--                  Подтяжка к единице
--
--
-- Additional Comments: 
--
----------------------------------------------------------------------------------
-- inst: entity work.bidir
-- generic map( oenarg => )
-- port map(
    -- clk     => ,
    -- bidir   => ,
    -- oena    => ,   
    -- inp     => ,
    -- outp    => 
-- );


library ieee;
use ieee.std_logic_1164.all;
-- use ieee.std_logic_arith.all;
-- use ieee.std_logic_unsigned.all;

entity bidir is
    generic(
        SIM : natural := 0
    );
    port(
        clk     : in  std_logic;
        bidir   : inout std_logic;
        oena    : in  std_logic; 
        outp    : in  std_logic;     
        inp     : out std_logic
	);
    attribute useioff : boolean;
    -- attribute useioff of bidir  : signal is oenrg;
    -- attribute useioff of oena  : signal is oenrg;
    attribute useioff of bidir  : signal is true;
    -- attribute useioff of oena  : signal is true;
end bidir;

architecture beh of bidir is
    signal  a  : std_logic := '0';  -- dff that stores 
                                    -- value from input.
    signal  b  : std_logic := '0';  -- dff that stores 
                                    -- feedback value.
    signal  s_inp  : std_logic := '0';
    signal  s_inps : std_logic := '0';
    
    signal  s_oena  : std_logic := '0';
begin 


    -- no_onea_gen: if ( oenrg = false ) generate
        -- s_oena <= oena;
    -- end generate;
    
    -- onea_gen: if ( oenrg = true ) generate
    -- begin
        -- process(clk)
        -- begin
            -- if(rising_edge(clk))then  -- creates the flipflops
                -- s_oena <= oena;                  
            -- end if;
        -- end process; 
    -- end generate;
    
    process(clk)
    begin
        if(rising_edge(clk))then  -- creates the flipflops
            s_oena <= oena;                  
        end if;
    end process; 
        
    process(clk)
    begin
        if(rising_edge(clk))then  -- creates the flipflops
            a       <= outp;                    
            s_inp   <= b;                  
        end if;
    end process;   
    
    process (s_oena, bidir, a)    -- behavioral representation 
    begin                       -- of tri-states.
        if( s_oena = '0') then
            bidir <= 'Z';
            b <= bidir;
        else
            bidir <= a; 
            b <= bidir;
        end if;
    end process;
    
    
    no_sim_gen: if ( SIM = 0 ) generate
        s_inps <= s_inp;
    end generate;
    
    sim_gen: if ( SIM = 1 ) generate
        s_inps <= '1' when s_inp = 'Z' else s_inp;
    end generate;
    
    inp <= s_inps;
    
end beh;
