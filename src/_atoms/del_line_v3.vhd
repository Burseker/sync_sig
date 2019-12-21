--=============================
-- Developed by KST. Ver. 3.3. 
--=============================
----------------------------------------------------------------------------------
-- Company:         ������-�����
-- Engineer:        ��������� �������� (KST)
--                  
-- Create Date:     14:30 12.12.2011 
-- Design Name:     
-- Module Name:     del_line_v3 - behavioral
-- Project Name:    
-- Target Devices:  
-- Tool versions:   Notepad++
-- Description:     ����� ��������
--                  
--                  
-- Dependencies:    ��������� ����������� ����
--                  
-- Revision:        
-- Revision 1.0 -   �������
-- Revision 2.0 -   �������
-- Revision 2.1 -   ��� ���������� �� ���� RAM � LUT �������� ������ 
--                  ����������� ������ ���� ��� ����������� �� �������
--                  istb. �� istb ������ ������������� �������� �������.
--                  (������ 2.� �������� ��������������� ����������� ������.)
-- Revision 3.0 -   ������� ������� � �������� ������ �������������. ��������
--                  �������� ������ ���������� � ������� �������������.
--                  �������� �������������� �������� ������� XREG.
-- Revision 3.1 -   ���������� ������ ������������ ��������� ��������
--                  s_oena_cnt ��� DEPTH=1.
--                  ������ ����������� �� DEPTH ��� "LUT".
--                  ����������� �� DEPTH ��� "RAM" ������� �� 2.
-- Revision 3.2 -   ����������� ������ ��������� ��������� ��������� DEPTH.
--                  � ��� ����������� �������� �� ������� �������, 
--                  ��� ������ ����. ����� ��������� ������� �������������
--                  � �������� ����������� �� ����������� �������� DEPTH,
--                  ������ ��������� ��� �������� ������ ����.
--                  ��������������� ��������� ��������� ����� �������� ���
--                  ���������� �� ���� "REG" � "LUT".
-- Revision 3.3 -   [KST: 20.10.2017] �������� �������� RAMINIT, ����������� 
--                  ��������� ������������� ������ (BASE="RAM"), ��� �������� 
--                  ������, ��������, ��� ������������� STYLE="M-RAM" (Altera).
--                  ������ ��� ������ �� ������������ ��������� �������������.
--                  � ������ ������� ������������� ��������� �������������
--                  ������ ����� ������� ������ ����������� ���������.
--                  
--                  
-- Additional Comments: 
-- �������� �������� ������������ ���������� DEPTH.
-- �������� ���������� � ������� istb, ��������� �� ����.
--
-- ����� ����� ���� ����������� �� ���� ��������� (BASE = "REG"),
-- ������ (BASE = "RAM") � ������ (BASE = "LUT").
-- ��������� ���������� ������ �� Xilinx.
-- 
-- �������� �������� ���������� �������� ��� "REG" � "LUT" ���������� 1 ����,
-- ��� "RAM" - 2 �����. 
-- ����� �������:
-- 1. �������� ������ ����� �������� �� ���� "RAM" ����� ��������� �� ����
--    ����� ��� � ����� �� ���� "REG" ��� "LUT".
-- 2. � ������ ������������ ������ istb �������� �������� ����� �� DEPTH 
--    ������, � DEPTH + �������� �������� ��������
-- 
-- ����� ����� �������� �� ���� "REG"/"LUT" �������� ����������
-- ����� �� ���� "RAM", ��� ��� ����� ���������� � ������� �������� XREG.
-- ��� ������� �������������� ���� ������ � �� �������� �������� ������
-- ������ �������� �������� ����� �� ���� "RAM".
-- 
----------------------------------------------------------------------------------
    -- <�����> : entity work.del_line_v3
    -- generic map(
        -- IWIDTH => ,--����������� �����
        -- DEPTH  => ,--����� ����� ��������
        -- BASE   => ,--���� ��� ����������: "REG", "RAM", "LUT"
        -- STYLE  => ,--��� ������ ��� ���� "RAM": "Auto", "M512", "M4K", "logic"
        -- RAMINIT=> ,--������� ��������� ������������� ������ (��� BASE="RAM")
        -- XREG   => )--�������������� �������� �������
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
        IWIDTH : integer;         --����������� �����
        DEPTH  : integer;         --����� ����� ��������
        BASE   : string := "REG"; --���� ��� ����������:
                                  --"REG" - ��������� ������� �� ���������
                                  --"RAM" - ������
                                  --"LUT" - ��������� ������� �� LUT
        STYLE  : string := "Auto";--��� ������ ��� ���� "RAM"
                                  --Altera: "Auto", "M512", "M4K", "M-RAM", "MLAB", "M9K", "M144K", "logic"
                                  --Xilinx: "Auto"
        RAMINIT: boolean := true;--������� ��������� ������������� ������ (��� BASE="RAM")
        XREG   : integer := 0);   --�������������� �������� �������
        
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
    -- �������� ������� (���������� ����������� ��������)
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
        
        --������� ���������
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
        
        --�������� ����� ����������
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
        
        --������������� ������
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
        
        --������
        memory : process (clk)
        begin
            if rising_edge(clk) then
                s_mem_odata <= mem(s_mem_addr);
                if (istb = '1') then
                    mem(s_mem_addr) <= idata;
                end if;
            end if;
        end process;
        
        --�������� �������
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
        
        --�������� ����� ����������
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
        
        --������� ��������� ����������� �� LUT-��
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
        
        --�������� �������
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
        
        --�������� ����� ����������
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
    --�������������� �������� �������
    --==============================================
    --���. ������� �������
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
    --���. ������� ��������
    xreg_off:  if (XREG <= 0) generate
        odata <= s_odata;
        ostb  <= s_ostb;
    end generate;
    
    
end behav;
