--==============================
-- Developed by SVB. Ver. 1.2.0 
--==============================
----------------------------------------------------------------------------------
-- Company:         Дизайн-центр
-- Engineer:        Сергей Бураков
--                  
-- Create Date:     10:00 12.11.2013
-- Design Name:     
-- Module Name:     var_reciver - beh
-- Project Name:    
-- Target Devices:  
-- Tool versions:   Notepad++
-- Description:     
--                  
--                  
-- Dependencies:    
--                  
-- Revision:        
-- Revision 1.0.0 - Создание файла
-- Revision 1.1.0 - переименование портов и сигналов                
--                  iena -> iten, s_iena -> s_iten 				 
--                  idata -> idat
-- Revision 1.2.0 - переименование внутренних сигналов
--                  исключены лишние сигналы
--                  
--                  
-- Additional Comments: 
-- 
-- 
-- 
-- 
-- 
-- 
----------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
--=========================
use work.qpkt_pkg.all;
use work.pkg_func.all;
--use work.im_cmd_pkg.all;
--=========================

entity var_reciver is
	generic(
		RAND_STB	: natural := 0;	--вероятность пропуска строба в процентах
        WIDTH       : natural := 32
	);
    port  (
		--частоты синхронизации
		aclr    : in  std_logic;
		clk_rx  : in  std_logic;
		
		idat    : in  std_logic_vector(WIDTH-1 downto 0);--Шина данных с выхода LINK-порта
        istb    : in  std_logic;--Строб сопровождения данных на шине idat
        istr    : in  std_logic;--Признак начала пакета (признак последнего слова в пакете)
        iend    : in  std_logic;--Признак конца пакета (признак последнего слова в пакете)
        iendq   : in  std_logic;--Признак последнего квадрослова пакета
        iten    : out std_logic --Сигнал готовности входного буфера
	);
end var_reciver;

architecture beh of var_reciver is

--SIGNALS
	-- signal s_data	: std_logic_vector(WIDTH-1 downto 0) := (others => '0');
	-- signal s_str	: std_logic := '0';
	-- signal s_end	: std_logic := '0';
	-- signal s_endq	: std_logic := '0';
	-- signal s_stb	: std_logic := '0';
    
	signal s_iten       : std_logic := '1';
	--lnkpkt_parser signals
    signal s_hdr_set    : T_QHDR_SET := C_QHDR_SET_INIT;
	signal s_hdr_stb    : std_logic := '0';
	signal s_hdr_vld    : std_logic := '0';
	signal s_dat_vld    : std_logic := '0';
    
    
	signal s_crc_rst	: std_logic := '0';
	signal s_crc        : std_logic_vector(15 downto 0) := (others => '0');
begin
	-- --=============================================
    -- -- PACKET STROBER lpclk_rx
    -- --=============================================
	-- strober : entity work.pkt_strober
    -- port map(
		-- aclr	=> aclr,
		-- clk		=> clk_rx,
		
		-- idat(31 downto 0)	=> s_lp_data,
		-- idat(32)			=> s_lp_endq,
		-- istb	=> s_lp_stb,
		
		-- odata	=> s_strbr_data,
		-- ostb	=> s_strbr_stb,
		-- ostr	=> s_strbr_str,
		-- oend	=> s_strbr_end,
		-- oendq	=> s_strbr_endq,
		-- opkt    => open,
        -- oqstr   => open
	-- );
	
    -- s_strbr_data <= idat;
	-- s_strbr_stb <= istb;
    -- s_strbr_str <= istr;
	-- s_strbr_end <= iend;
	-- s_strbr_endq <= iendq;
	iten <= s_iten;
    
    --=============================================
    -- Блок анализа заголовка пакета lpclk_tx_div4
    --=============================================
    process(aclr, clk_rx)
    begin
        if(aclr = '1')then
            s_iten <= '0';
        elsif(rising_edge(clk_rx))then
            if(random_value_gen(1, 100) > RAND_STB) then
                s_iten <= '1';
            else
                s_iten <= '0';
            end if;
        end if;
    end process;
    
	--=============================================
    -- Блок анализа заголовка пакета lpclk_tx_div4
    --=============================================
	hdrparser: entity work.qpkt_parser 
    generic map(WIDTH => WIDTH)
    port map(
		aclr    => aclr,
        clk     => clk_rx,
        idata   => idat,
        istb    => istb,
        iend    => iend,
        hdr_set => s_hdr_set,
        hdr_stb => s_hdr_stb,
        hdr_vld => s_hdr_vld,
        dat_vld => s_dat_vld
	);
	
    --s_crc_rst <= s_dat_vld or s_hdr_stb or iend;
    s_crc_rst <= iend and istb;
--=============================================
-- Рассчет CRC для ядра 32
--=============================================
    crc16_iw32_gen: if(WIDTH = 32) generate
        crc: entity work.crc16_iw32
        generic map(
            INIT    => x"FFFF",
            IBIT_REV   => false,
            IBYTE_REV  => true
        )
        port map(
            clk     => clk_rx,
            rst     => s_crc_rst,
            ena     => istb,
            
            idat => idat,
            
            odateven=> open,--s_crceven,
            odatodd => s_crc
        );
    end generate crc16_iw32_gen;
    
end beh;