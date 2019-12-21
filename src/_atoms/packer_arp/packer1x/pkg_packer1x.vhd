library ieee,work;
use ieee.std_logic_1164.all;

package pkg_packer1x is

	function log2_ceil(a: integer) return integer;
	
	COMPONENT packer1x
	GENERIC (
		OWIDTH : integer := 32;
		IMWIDTH : integer := 32);
	PORT(
		clk : IN std_logic;
		sclr : IN std_logic;
		i_stb : IN std_logic;
		i_dat : IN std_logic_vector(OWIDTH-1 downto 0);
		i_start : IN std_logic;
		i_end : IN std_logic;
		i_width : IN std_logic_vector(log2_ceil(OWIDTH) downto 0);          
		o_rdy : OUT std_logic;
		o_stb : OUT std_logic;
		o_dat : OUT std_logic_vector(OWIDTH-1 downto 0);
		o_start : OUT std_logic;
		o_end : OUT std_logic);
	END COMPONENT;
	
	COMPONENT addr_dc
	GENERIC (
		OWIDTH : integer := 32);
	PORT(
		clk : IN std_logic;
		i_stb : IN std_logic;
		i_ena : IN std_logic;
		i_addr : IN std_logic_vector(log2_ceil(OWIDTH) downto 0);
		o_high : OUT std_logic;
		o_addr : OUT std_logic_vector(OWIDTH-1 downto 0));
	END COMPONENT;
	
	COMPONENT dc_5x32_r
	GENERIC (
		OREG : boolean := false);
	PORT(
		clk : IN std_logic;
		input : IN std_logic_vector(4 downto 0);          
		output : OUT std_logic_vector(31 downto 0));
	END COMPONENT;
	
	COMPONENT addr_cd
	GENERIC (
		OWIDTH : integer := 32);
	PORT(
		clk : IN std_logic;
		i_stb : IN std_logic;
		i_high : IN std_logic_vector(OWIDTH-1 downto 0);          
		i_addr : IN std_logic_vector(OWIDTH-1 downto 0);          
		o_stb : OUT std_logic;
		o_high : OUT std_logic;
		o_addr : OUT std_logic_vector(log2_ceil(OWIDTH)-1 downto 0));
	END COMPONENT;
	
	COMPONENT cd_32x5_r
	PORT(
		clk : IN std_logic;
		input : IN std_logic_vector(31 downto 0);          
		output : OUT std_logic_vector(4 downto 0));
	END COMPONENT;
	
	COMPONENT addr_frmr_1x
	GENERIC (
		OPWIDTH : integer := 6;
		OWIDTH  : integer := 32;
		INIT    : integer := 0);
	PORT(
		clk : IN std_logic;
		sclr : IN std_logic;
		i_ena : IN std_logic;
		i_width : IN std_logic_vector(OPWIDTH-1 downto 0);          
		o_hop : OUT std_logic;
		o_align : OUT std_logic;
		o_addr : OUT std_logic_vector(OPWIDTH-1 downto 0));
	END COMPONENT;
	
	COMPONENT mux32_1_r
	PORT(
		clk : IN std_logic;
		addr : IN std_logic_vector(4 downto 0);
		input : IN std_logic_vector(31 downto 0);          
		output : OUT std_logic);
	END COMPONENT;
	
	COMPONENT dmux1_2_r
	PORT(
		clk : IN std_logic;
		i_stb : IN std_logic;
		i_addr : IN std_logic;
		i_dat : IN std_logic;          
		o_stb : OUT std_logic_vector(1 downto 0);
		o_dat : OUT std_logic_vector(1 downto 0));
	END COMPONENT;

end pkg_packer1x;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package body pkg_packer1x is

	function log2_ceil(a : integer) return integer is
		variable temp : integer;
	begin
		temp := 0;
		for i in 0 to 30 loop
			if (a > (2**i)) then
				temp := i+1;
			end if;
		end loop;
		return(temp);
	end log2_ceil;
	
end pkg_packer1x;