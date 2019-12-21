--================================================================================
-- Description: Модуль коммутации с переходом на AXISteream
-- Version:     0.1.0
-- Developer:   SVB
-- Workgroup:   IRS16
--================================================================================
-- Keywords:    DMA
-- Tools:       modelsim 10.2d
--              
-- Note:
-- 
-- Version History:
-- Ver 0.0.0 - File create
-- Ver 0.1.0 - Первая рабочая версия
-- 
----------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
--=== common lib ===
-- use work.xqpkt_pkg.all;
use work.pkg_func.all;

entity test_commutator is
    generic (
        SIM     : integer := 0
    );
    port (
        aclr            : in  std_logic;    --сброс от SDRAM
        clk             : in  std_logic;
        
        idat_ch0        : in  std_logic_vector(31 downto 0) := (others => '0');
        istb_ch0        : in  std_logic := '0';
        iend_ch0        : in  std_logic := '0';
        iten_ch0        : out std_logic := '0';
        
        mcomm0_tdata    : out std_logic_vector(31 downto 0);
        mcomm0_tvalid   : out std_logic;
        mcomm0_tlast    : out std_logic;
        mcomm0_tready   : in  std_logic := '1';
        
        mcomm1_tdata    : out std_logic_vector(31 downto 0);
        mcomm1_tvalid   : out std_logic;
        mcomm1_tlast    : out std_logic;
        mcomm1_tready   : in  std_logic := '1';
        
        mcomm2_tdata    : out std_logic_vector(31 downto 0);
        mcomm2_tvalid   : out std_logic;
        mcomm2_tlast    : out std_logic;
        mcomm2_tready   : in  std_logic := '1';
        
        mcomm3_tdata    : out std_logic_vector(31 downto 0);
        mcomm3_tvalid   : out std_logic;
        mcomm3_tlast    : out std_logic;
        mcomm3_tready   : in  std_logic := '1'
    );
end test_commutator;

architecture beh of test_commutator is

    -- type t_dsth_table is array ( 0 to 6 ) of std_logic_vector(7 downto 0);
    -- CONSTANT C_DSTH_TABLE   : t_dsth_table := (x"E0", x"E1",x"E2", x"E4",x"E5", x"E6",x"E7");
    
    
    signal s_buff0_odata    : std_logic_vector(31 downto 0) := ( others => '0' );
    signal s_buff0_oend     : std_logic := '0';
    signal s_buff0_ostb     : std_logic := '0';
    signal s_buff0_oten     : std_logic := '0';
    signal s_buff0_oempty   : std_logic := '0';
    
    signal s_buff1_odata    : std_logic_vector(31 downto 0) := ( others => '0' );
    signal s_buff1_oend     : std_logic := '0';
    signal s_buff1_ostb     : std_logic := '0';
    signal s_buff1_oten     : std_logic := '0';
    signal s_buff1_oempty   : std_logic := '0';
    
    signal s_buff2_odata    : std_logic_vector(31 downto 0) := ( others => '0' );
    signal s_buff2_oend     : std_logic := '0';
    signal s_buff2_ostb     : std_logic := '0';
    signal s_buff2_oten     : std_logic := '0';
    signal s_buff2_oempty   : std_logic := '0';
    
    signal s_buff3_odata    : std_logic_vector(31 downto 0) := ( others => '0' );
    signal s_buff3_oend     : std_logic := '0';
    signal s_buff3_ostb     : std_logic := '0';
    signal s_buff3_oten     : std_logic := '0';
    signal s_buff3_oempty   : std_logic := '0';
	
    -- -- DEBUG ===============================================
    -- attribute mark_debug : string;
    -- -- Infrastructure
    -- attribute mark_debug of s_cmdrdpkt_fifo_dat     : signal is "TRUE";

    type T_DEMUX_TRD32 is record
        p_dat      : std_logic_vector(31 downto 0);
        p_str      : std_logic;
        p_end      : std_logic;
        p_stb_a    : std_logic;
        p_ten_a    : std_logic;
        p_stb_b    : std_logic;
        p_ten_b    : std_logic;
        p_stb_c    : std_logic;
        p_ten_c    : std_logic;
        p_stb_d    : std_logic;
        p_ten_d    : std_logic;
    end record;
    
    signal s_comm_demux  : T_DEMUX_TRD32 := ( (others => '0'), '0', '0',
                                                     '0', '1',
                                                     '0', '1',
                                                     '0', '1',
                                                     '0', '1');
begin
    
--=============================================
-- TYPICAL PROCESS
--=============================================
    -- process(aclr, iclk)
    -- begin
        -- if(aclr = '1')then
        -- elsif(rising_edge(iclk))then
        -- end if;
    -- end process;
    
    
    qpkt_demux: entity work.qpkt_demux
    generic map(
        WIDTH   => 32,
        addr0   => x"E1",
        addr1   => x"E2",
        addr2   => x"E3"
    )
    port map(	
        aclr    => aclr,
        clk     => clk,
        
        idat    => idat_ch0,
        istb    => istb_ch0,
        iend    => iend_ch0,
        iten    => iten_ch0,
        
        odat    => s_comm_demux.p_dat,
        oend    => s_comm_demux.p_end,
        ostr    => s_comm_demux.p_str,
        
        ostb0   => s_comm_demux.p_stb_a,
        oten0   => s_comm_demux.p_ten_a,
        
        ostb1   => s_comm_demux.p_stb_b,
        oten1   => s_comm_demux.p_ten_b,
        
        ostb2   => s_comm_demux.p_stb_c,
        oten2   => s_comm_demux.p_ten_c,
        
        ostb3   => s_comm_demux.p_stb_d,
        oten3   => s_comm_demux.p_ten_d
    );
    
    
    qpkt_scfifo_ch0: entity work.qpkt_scfifo
    generic map(
        WIDTH    => 32,
        DEPTH    => 64,
        AFULL_TR => 48
    )
	port map(
		aclr    => aclr,
		clk     => clk,
        
		idat    => s_comm_demux.p_dat,
        -- istr    : in  std_logic;
        iend    => s_comm_demux.p_end,
        istb    => s_comm_demux.p_stb_a,
		iten    => s_comm_demux.p_ten_a,
        
		odat    => s_buff0_odata,
		-- ostr    : out std_logic;
		oend    => s_buff0_oend,
		ostb    => s_buff0_ostb,
		oten    => s_buff0_oten,
		oempty  => s_buff0_oempty
	);
    
    
    qpkt_scfifo_ch1: entity work.qpkt_scfifo
    generic map(
        WIDTH    => 32,
        DEPTH    => 64,
        AFULL_TR => 48
    )
	port map(
		aclr    => aclr,
		clk     => clk,
        
		idat    => s_comm_demux.p_dat,
        -- istr    : in  std_logic;
        iend    => s_comm_demux.p_end,
        istb    => s_comm_demux.p_stb_b,
		iten    => s_comm_demux.p_ten_b,
        
		odat    => s_buff1_odata,
		-- ostr    : out std_logic;
		oend    => s_buff1_oend,
		ostb    => s_buff1_ostb,
		oten    => s_buff1_oten,
		oempty  => s_buff1_oempty
	);
    
    
    qpkt_scfifo_ch2: entity work.qpkt_scfifo
    generic map(
        WIDTH    => 32,
        DEPTH    => 64,
        AFULL_TR => 48
    )
	port map(
		aclr    => aclr,
		clk     => clk,
        
		idat    => s_comm_demux.p_dat,
        -- istr    : in  std_logic;
        iend    => s_comm_demux.p_end,
        istb    => s_comm_demux.p_stb_c,
		iten    => s_comm_demux.p_ten_c,
        
		odat    => s_buff2_odata,
		-- ostr    : out std_logic;
		oend    => s_buff2_oend,
		ostb    => s_buff2_ostb,
		oten    => s_buff2_oten,
		oempty  => s_buff2_oempty
	);
    
    
    qpkt_scfifo_ch3: entity work.qpkt_scfifo
    generic map(
        WIDTH    => 32,
        DEPTH    => 64,
        AFULL_TR => 48
    )
	port map(
		aclr    => aclr,
		clk     => clk,
        
		idat    => s_comm_demux.p_dat,
        -- istr    : in  std_logic;
        iend    => s_comm_demux.p_end,
        istb    => s_comm_demux.p_stb_d,
		iten    => s_comm_demux.p_ten_d,
        
		odat    => s_buff3_odata,
		-- ostr    : out std_logic;
		oend    => s_buff3_oend,
		ostb    => s_buff3_ostb,
		oten    => s_buff3_oten,
		oempty  => s_buff3_oempty
	);
    
    
--=============================================
--          SIGNALS ASSYGMENTS
--=============================================
    mcomm0_tdata  <= s_buff0_odata;
    mcomm0_tlast  <= s_buff0_oend;
    mcomm0_tvalid <= not s_buff0_oempty;
    s_buff0_oten <= mcomm0_tready;
    
    mcomm1_tdata  <= s_buff1_odata;
    mcomm1_tlast  <= s_buff1_oend;
    mcomm1_tvalid <= not s_buff1_oempty;
    s_buff1_oten <= mcomm1_tready;
    
    mcomm2_tdata  <= s_buff2_odata;
    mcomm2_tlast  <= s_buff2_oend;
    mcomm2_tvalid <= not s_buff2_oempty;
    s_buff2_oten <= mcomm2_tready;
    
    mcomm3_tdata  <= s_buff3_odata;
    mcomm3_tlast  <= s_buff3_oend;
    mcomm3_tvalid <= not s_buff3_oempty;
    s_buff3_oten <= mcomm3_tready;

    
end beh;
