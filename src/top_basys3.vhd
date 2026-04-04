library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;


-- Lab 4
entity top_basys3 is
    port(
        -- inputs
        clk     :   in std_logic; -- native 100MHz FPGA clock
        sw      :   in std_logic_vector(15 downto 0);
        btnU    :   in std_logic; -- master_reset
        btnL    :   in std_logic; -- clk_reset
        btnR    :   in std_logic; -- fsm_reset
        
        -- outputs
        led :   out std_logic_vector(15 downto 0);
        -- 7-segment display segments (active-low cathodes)
        seg :   out std_logic_vector(6 downto 0);
        -- 7-segment display active-low enables (anodes)
        an  :   out std_logic_vector(3 downto 0)
    );
end top_basys3;

architecture top_basys3_arch of top_basys3 is

    -- signal declarations
    
	-- component declarations
    component sevenseg_decoder is
        port (
            i_Hex : in STD_LOGIC_VECTOR (3 downto 0);
            o_seg_n : out STD_LOGIC_VECTOR (6 downto 0)
        );
    end component sevenseg_decoder;
    
    component elevator_controller_fsm is
		Port (
            i_clk        : in  STD_LOGIC;
            i_reset      : in  STD_LOGIC;
            is_stopped   : in  STD_LOGIC;
            go_up_down   : in  STD_LOGIC;
            o_floor : out STD_LOGIC_VECTOR (3 downto 0)		   
		 );
	end component elevator_controller_fsm;
	
	component TDM4 is
		generic ( constant k_WIDTH : natural  := 4); -- bits in input and output
        Port ( i_clk		: in  STD_LOGIC;
           i_reset		: in  STD_LOGIC; -- asynchronous
           i_D3 		: in  STD_LOGIC_VECTOR (k_WIDTH - 1 downto 0);
		   i_D2 		: in  STD_LOGIC_VECTOR (k_WIDTH - 1 downto 0);
		   i_D1 		: in  STD_LOGIC_VECTOR (k_WIDTH - 1 downto 0);
		   i_D0 		: in  STD_LOGIC_VECTOR (k_WIDTH - 1 downto 0);
		   o_data		: out STD_LOGIC_VECTOR (k_WIDTH - 1 downto 0);
		   o_sel		: out STD_LOGIC_VECTOR (3 downto 0)	-- selected data line (one-cold)
	   );
    end component TDM4;
     
	component clock_divider is
        generic ( constant k_DIV : natural := 2	); -- How many clk cycles until slow clock toggles
                                                   -- Effectively, you divide the clk double this 
                                                   -- number (e.g., k_DIV := 2 --> clock divider of 4)
        port ( 	i_clk    : in std_logic;
                i_reset  : in std_logic;		   -- asynchronous
                o_clk    : out std_logic		   -- divided (slow) clock
        );
    end component clock_divider;
	
	signal w_clk : std_logic;
	signal w_clk2 : std_logic;
	signal w_clk_reset : std_logic;
	signal w_elev_reset : std_logic;
	signal w_floor : std_logic_vector(3 downto 0); 
	signal w_tens :std_logic_vector(3 downto 0);
	signal w_ones :std_logic_vector(3 downto 0);
	signal w_data : std_logic_vector(3 downto 0);
	
begin
	-- PORT MAPS ----------------------------------------	
	
    elevator_controller_fsm_instance: elevator_controller_fsm port map(
        i_clk => w_clk_reset,
        i_reset => w_elev_reset,
        is_stopped => sw(0),
        go_up_down => sw(1),     
        o_floor => w_floor   
        );	
    elevator_controller_fsm_instance2: elevator_controller_fsm port map(
        i_clk => w_clk_reset,
        i_reset => w_elev_reset,
        is_stopped => sw(15),
        go_up_down => sw(14),
        o_floor => w_floor     
        );	
	
	clock_divider_instance: clock_divider 
	   generic map( k_DIV => 25000000) --look here to figure out the clock testing thing
	   port map(
	       i_clk => clk,
	       i_reset => btnL,
	       o_clk => w_clk
        );
	clock_divider_instance2: clock_divider 
	   generic map( k_DIV => 25000000) --look here to figure out the clock testing thing
	   port map(
	       i_clk => clk,
	       i_reset => btnL,
	       o_clk => w_clk2
        );
        
    TDM4_instance: TDM4
    generic map(k_WIDTH => 4) 
        Port map( i_clk => w_clk2,		
           i_reset=> w_clk_reset,		
           i_D3 => 	w_tens,
		   i_D2 => w_ones,
		   i_D1 => "0000",		
		   i_D0 => "0000",		
		   o_data => w_data,
		   o_sel => an	
		   
	   );
    
    --sevenseg decoder
	
	-- CONCURRENT STATEMENTS ----------------------------
	   w_clk_reset <= btnU OR btnL;
	   w_elev_reset <= btnU OR btnR;
	   
	   w_tens <= "0001" when w_floor = "1010" else
	           "0001" when w_floor = "1011" else
	           "0001" when w_floor = "1100" else
	           "0001" when w_floor = "1110" else
	           "0001" when w_floor = "1111" else
	           "0001" when w_floor = "0000" else
	           "0000";
	           
	   w_ones <= "0001" when w_floor = "0001" else
	           "0010" when w_floor = "0010" else
	           "0011" when w_floor = "0011" else
	           "0100" when w_floor = "0100" else
	           "0101" when w_floor = "0101" else
	           "0110" when w_floor = "0111" else
	           "1000" when w_floor = "1000" else
	           "1001" when w_floor = "1001" else --only goes floors 1-4 so most should be unnecessary
	           "0000";
	   
	-- LED 15 gets the FSM slow clock signal. The rest are grounded.
	   
	   led(13 downto 2) <= (others => '0');
	-- leave unused switches UNCONNECTED. Ignore any warnings this causes.
	
	-- reset signals
	
end top_basys3_arch;
