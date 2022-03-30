LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.std_logic_unsigned.all;

ENTITY oscope is port(
      clk_12mhz_ext   : in     std_logic;
      tx_text         : buffer std_logic;
      rx_text         : in     std_logic;
      pwm_out         : out    std_logic_vector(3 downto 0);
      ch_gain         : out    std_logic_vector(3 downto 0);
      sw              : in     std_logic;
      xbus            : in     std_logic_vector(9 downto 0);
      led             : out    std_logic_vector(7 downto 0)
   );
END oscope;

ARCHITECTURE logic OF oscope IS
signal clk_50mhz              : std_logic;
signal clk_200mhz             : std_logic;
signal reset_reset_n          : std_logic;
signal sw_last                : std_logic := '0';
signal sw_state               : std_logic := '0';
signal tx_mem                 : std_logic;
signal tx_adc                 : std_logic;
signal tx_switch              : std_logic;
signal command_valid          : std_logic;
signal command_channel        : std_logic_vector(4 downto 0);
signal command_startofpacket  : std_logic;
signal command_endofpacket    : std_logic;
signal command_ready          : std_logic;
signal response_valid         : std_logic;
signal response_channel       : std_logic_vector(4 downto 0);
signal response_data          : std_logic_vector(11 downto 0);
signal response_startofpacket : std_logic;
signal response_endofpacket   : std_logic;
signal acq_rate               : std_logic_vector(15 downto 0) := x"0001";  --0x52
signal adc_control            : std_logic_vector(15 downto 0) := x"8002";  --0x51
signal osc_length             : std_logic_vector(15 downto 0) := x"07d0";  --0x50
signal trigger_offset         : std_logic_vector(15 downto 0) := x"0064";  --0x53
signal trigger                : std_logic;
signal counter                : std_logic_vector(36 downto 0);
signal testout                : std_logic_vector(7 downto 0);
signal testoutadc             : std_logic_vector(7 downto 0);
signal regaddr                : std_logic_vector(7 downto 0);
signal regdataout             : std_logic_vector(15 downto 0);
signal regdatain              : std_logic_vector(15 downto 0);
signal regstrobe              : std_logic;
signal regdata00              : std_logic_vector(15 downto 0) := x"0002";
signal regdata01              : std_logic_vector(15 downto 0) := x"0400";
signal updaterate             : std_logic_vector(15 downto 0) := x"0400";  
signal pwm_rate               : std_logic_vector(15 downto 0) := x"061a";  --0x90
signal pwm_counter            : std_logic_vector(23 downto 0) := x"000000";
signal pwm_lucnt              : std_logic_vector(19 downto 0) := x"00000";
signal pwm_cycle              : std_logic_vector(15 downto 0) := x"001f";  --0x91
signal pwm_luval              : std_logic_vector(8 downto 0);
signal pwm                    : std_logic;
signal counter_1msec          : std_logic_vector(15 downto 0);
signal strobe_1msec           : std_logic;
signal counter_1usec          : std_logic_vector(7 downto 0);
signal strobe_1usec           : std_logic;
signal timer                  : std_logic_vector(31 downto 0) := x"00000000";

component adc_qsys is
   port (
      clk_clk                : in     std_logic := 'X';
      reset_reset_n          : in     std_logic := 'X';
      command_valid          : in     std_logic := 'X';
      command_channel        : in     std_logic_vector(4 downto 0) := (others=>'X');
      command_startofpacket  : in     std_logic := 'X';
      command_endofpacket    : in     std_logic := 'X';
      command_ready          : out    std_logic; 
      response_valid         : out    std_logic;
      response_channel       : out    std_logic_vector(4 downto 0); 
      response_data          : buffer std_logic_vector(11 downto 0); 
      response_startofpacket : out    std_logic;                    
      response_endofpacket   : out    std_logic;        
      clk_50mhz_clk          : buffer std_logic;
      clk_200mhz_clk         : buffer std_logic
   );
end component adc_qsys;

component adcstream is
   port (
           clk_50mhz              : in     std_logic;
           rst_n                  : in     std_logic;
           tx                     : buffer std_logic;
           rx                     : in     std_logic;
           osc_length             : in     std_logic_vector(15 downto 0);
           trigger_offset         : in     std_logic_vector(15 downto 0);
           acq_rate               : in     std_logic_vector(15 downto 0) := x"0001";
           activech               : in     std_logic_vector(3 downto 0) := x"1";
           trigger                : in     std_logic;
           response_valid         : in     std_logic;
           response_channel       : in     std_logic_vector(4 downto 0);
           response_data          : in     std_logic_vector(11 downto 0);
           response_startofpacket : in     std_logic;
           response_endofpacket   : in     std_logic;
           command_valid          : buffer std_logic := '1';
           command_channel        : buffer std_logic_vector(4 DOWNTO 0);
           command_startofpacket  : buffer std_logic;
           command_endofpacket    : buffer std_logic;
           command_ready          : in     std_logic;
           updaterate             : in     std_logic_vector(15 downto 0);

           testout       : buffer std_logic_vector(7 downto 0)
    );
end component adcstream;

component textinterface is
    port (
          clk            : in     std_logic;
          tx             : buffer std_logic;
          rx             : in     std_logic;
          regaddr        : buffer std_logic_vector(7 downto 0);
          regdataout     : in     std_logic_vector(15 downto 0);
          regdatain      : buffer std_logic_vector(15 downto 0);
          regstrobe      : buffer std_logic := '0';
          testout        : buffer std_logic_vector(7 downto 0)
    );
end component textinterface;

component sinlu is
   port  (
      address   : IN  std_logic_vector (8 DOWNTO 0);
      clock      : IN  std_logic := '1';
      q         : OUT std_logic_vector (8 DOWNTO 0)
   );
end component sinlu;

begin 
u0 : component adc_qsys
      port map (
         clk_clk                => clk_12mhz_ext,              
         reset_reset_n          => reset_reset_n,     
         command_valid          => command_valid,      
         command_channel        => command_channel,     
         command_startofpacket  => command_startofpacket,
         command_endofpacket    => command_endofpacket,   
         command_ready          => command_ready,     
         response_valid         => response_valid,     
         response_channel       => response_channel,    
         response_data          => response_data,        
         response_startofpacket => response_startofpacket,
         response_endofpacket   => response_endofpacket,  
         clk_50mhz_clk          => clk_50mhz,
         clk_200mhz_clk         => clk_200mhz
    );

adcstream0: component adcstream
   port map (
           clk_50mhz              => clk_50mhz,
           rst_n                  => '1',
           tx                     => tx_adc,
           rx                     => rx_text,
           acq_rate               => acq_rate,
           osc_length             => osc_length,
           trigger_offset         => trigger_offset,
           activech               => adc_control(3 downto 0),
           trigger                => adc_control(15),
           command_valid          => command_valid,      
           command_channel        => command_channel,     
           command_startofpacket  => command_startofpacket,
           command_endofpacket    => command_endofpacket,   
           command_ready          => command_ready,     
           response_valid         => response_valid,     
           response_channel       => response_channel,    
           response_data          => response_data,        
           response_startofpacket => response_startofpacket,
           response_endofpacket   => response_endofpacket,  
           updaterate             => updaterate,
           testout                => testoutadc
    );

textinterface0: component textinterface
    port map (
           clk           => clk_50mhz,
           tx            => tx_mem,
           rx            => rx_text,
           regaddr       => regaddr,
           regdataout    => regdataout,
           regdatain     => regdatain,
           regstrobe     => regstrobe,
           testout       => testout
    );
    
sinlu0 : component sinlu 
   port map (
            address       => pwm_lucnt(18 downto 10), 
            clock         => clk_50mhz,
            q             => pwm_luval
   ); 

reset_reset_n <= '1';
--sq_out <= counter_1msec(9);
tx_text <= tx_mem when sw_state = '1' else tx_adc;      
ch_gain <= adc_control(7 downto 4);
led(7) <= sw_state;
led(6) <= pwm;
led(5 downto 0) <= testoutadc(7 downto 2);
pwm_out(0) <= pwm;
pwm_out(1) <= pwm;
pwm_out(2) <= '1' when timer(7 downto 0) = x"00" else '0';
pwm_out(3) <= not pwm;
 
regdataout <= regdata00             when regaddr = x"00" else
              regdata01             when regaddr = x"01" else
              updaterate            when regaddr = x"30" else
              osc_length            when regaddr = x"50" else
              adc_control           when regaddr = x"51" else
              acq_rate              when regaddr = x"52" else
              trigger_offset        when regaddr = x"53" else
              pwm_rate              when regaddr = x"90" else
              pwm_cycle             when regaddr = x"91" else
              timer(31 downto 16)   when regaddr = x"e0" else
              timer(15 downto 0)    when regaddr = x"e1" else
              x"dead";

process(clk_50mhz)
begin
   if clk_50mhz'event and clk_50mhz='1' then
      if regstrobe = '1' then
         if regaddr = x"00" then regdata00      <= regdatain; end if;
         if regaddr = x"01" then regdata01      <= regdatain; end if;
         if regaddr = x"30" then updaterate     <= regdatain; end if;
         if regaddr = x"50" then osc_length     <= regdatain; end if;
         if regaddr = x"51" then adc_control    <= regdatain; end if;
         if regaddr = x"52" then acq_rate       <= regdatain; end if;
         if regaddr = x"53" then trigger_offset <= regdatain; end if;
         if regaddr = x"90" then pwm_rate       <= regdatain; end if;
         if regaddr = x"91" then pwm_cycle      <= regdatain; end if;
      end if;
   end if;
end process;

process(clk_50mhz)
begin
   if clk_50mhz'event and clk_50mhz='1' then
      if counter_1usec = x"32" then
         strobe_1usec <= '1';
         counter_1usec <= x"00";
      else
         strobe_1usec <= '0';
         counter_1usec <= counter_1usec + '1';
      end if;
   end if;
end process;

process(clk_50mhz)
begin
   if clk_50mhz'event and clk_50mhz='1' then
      if counter_1msec = x"c34f" then
         counter_1msec <= x"0000";
         strobe_1msec <= '1';
      else
         strobe_1msec <= '0';
         counter_1msec <= counter_1msec + '1';
      end if;
   end if;
end process;

process (clk_200mhz)
begin
   if clk_200mhz'event and clk_200mhz = '1' then
      if pwm_rate(15) = '0' then
         if pwm_counter(23 downto 7) > pwm_rate then pwm_counter <= x"000000"; 
            else pwm_counter <= pwm_counter + '1'; end if;
         if pwm_cycle > pwm_counter(23 downto 7) then pwm <= '1'; else pwm <= '0'; end if;
      end if;
      if pwm_rate(15) = '1' then
         pwm_counter <= pwm_counter + '1';
         if pwm_counter > x"0000ff" then 
            pwm_lucnt <= pwm_lucnt + pwm_rate(14 downto 0);
            pwm_counter <= x"000000"; 
            else pwm_counter <= pwm_counter + '1'; end if;
         --if  pwm_luval(8 downto 1) > pwm_counter then pwm <= '1'; else pwm <= '0'; end if;   
         if  pwm_luval(8 downto 2) > pwm_counter then pwm <= '1'; else pwm <= '0'; end if;   
      end if;
      
   end if;
end process;

process (clk_50mhz)
begin
   if clk_50mhz'event and clk_50mhz = '1' then
      if strobe_1msec = '1' then timer <= timer + '1'; end if;
   end if;
end process;

process (clk_50mhz)
begin
   if clk_50mhz'event and clk_50mhz = '1' then
      sw_last <= sw;
      if (sw_last = '1' and sw = '0') then sw_state <= not sw_state; end if;
   end if;
end process;
END logic;
