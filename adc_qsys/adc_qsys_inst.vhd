	component adc_qsys is
		port (
			clk_clk                : in  std_logic                     := 'X';             -- clk
			clk_50mhz_clk          : out std_logic;                                        -- clk
			command_valid          : in  std_logic                     := 'X';             -- valid
			command_channel        : in  std_logic_vector(4 downto 0)  := (others => 'X'); -- channel
			command_startofpacket  : in  std_logic                     := 'X';             -- startofpacket
			command_endofpacket    : in  std_logic                     := 'X';             -- endofpacket
			command_ready          : out std_logic;                                        -- ready
			reset_reset_n          : in  std_logic                     := 'X';             -- reset_n
			response_valid         : out std_logic;                                        -- valid
			response_channel       : out std_logic_vector(4 downto 0);                     -- channel
			response_data          : out std_logic_vector(11 downto 0);                    -- data
			response_startofpacket : out std_logic;                                        -- startofpacket
			response_endofpacket   : out std_logic;                                        -- endofpacket
			clk_200mhz_clk         : out std_logic                                         -- clk
		);
	end component adc_qsys;

	u0 : component adc_qsys
		port map (
			clk_clk                => CONNECTED_TO_clk_clk,                --        clk.clk
			clk_50mhz_clk          => CONNECTED_TO_clk_50mhz_clk,          --  clk_50mhz.clk
			command_valid          => CONNECTED_TO_command_valid,          --    command.valid
			command_channel        => CONNECTED_TO_command_channel,        --           .channel
			command_startofpacket  => CONNECTED_TO_command_startofpacket,  --           .startofpacket
			command_endofpacket    => CONNECTED_TO_command_endofpacket,    --           .endofpacket
			command_ready          => CONNECTED_TO_command_ready,          --           .ready
			reset_reset_n          => CONNECTED_TO_reset_reset_n,          --      reset.reset_n
			response_valid         => CONNECTED_TO_response_valid,         --   response.valid
			response_channel       => CONNECTED_TO_response_channel,       --           .channel
			response_data          => CONNECTED_TO_response_data,          --           .data
			response_startofpacket => CONNECTED_TO_response_startofpacket, --           .startofpacket
			response_endofpacket   => CONNECTED_TO_response_endofpacket,   --           .endofpacket
			clk_200mhz_clk         => CONNECTED_TO_clk_200mhz_clk          -- clk_200mhz.clk
		);

