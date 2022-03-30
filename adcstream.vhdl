library IEEE;
use IEEE.std_logic_1164.ALL;
use ieee.std_logic_signed.all; 
use ieee.numeric_std.all;
--setup serial port with
--sudo stty -F /dev/ttyUSB0 speed 115200 -echo -echoe -echok
--sudo stty -F /dev/ttyUSB0 raw  d
--sudo stty -F /dev/ttyUSB0  -echo -echoe -echok
entity adcstream is
   port (
           clk_50mhz              : in     std_logic;
           rst_n                  : in     std_logic;
           tx                     : buffer std_logic;
           rx                     : in     std_logic; 

           acq_rate               : in     std_logic_vector(15 downto 0);
           osc_length             : in     std_logic_vector(15 downto 0);
           trigger_offset         : in     std_logic_vector(15 downto 0);
           activech               : in     std_logic_vector(3 downto 0);
           trigger                : in     std_logic;
           response_valid         : in     std_logic;       
           response_channel       : in     std_logic_vector(4 downto 0);
           response_data          : in     std_logic_vector(11 downto 0);
           response_startofpacket : in     std_logic;                   
           response_endofpacket   : in     std_logic;                  
           command_valid          : buffer std_logic;
           command_channel        : buffer std_logic_vector(4 downto 0); 
           command_startofpacket  : buffer std_logic; 
           command_endofpacket    : buffer std_logic;
           command_ready          : in     std_logic;
           updaterate             : in     std_logic_vector(15 downto 0);
           
           testout                : buffer std_logic_vector(7 downto 0)
    );
end entity adcstream;

architecture Behavioral of adcstream is   

--define internal signals
signal   update_cnt          : std_logic_vector(31 downto 0) := x"00000000";
signal   update_strobe       : std_logic := '0';
signal   acq_strobe          : std_logic := '0';
signal   dump_strobe         : std_logic := '0';
signal   acq_counter         : std_logic_vector(15 downto 0) := x"0001";
signal   halt_acq            : std_logic := '0';
signal   skip_acq            : std_logic := '0';
signal   header              : std_logic_vector(7 downto 0);
signal   txdelay             : std_logic_vector (15 downto 0);

signal   dump                : std_logic := '0';
signal   channel_cnt         : std_logic_vector(3 downto 0) := x"0";
signal   channel_cnt_last    : std_logic_vector(3 downto 0) := x"0";
signal   trigger_addr        : std_logic_vector(15 downto 0);
signal   tx_busy             : std_logic;
signal   tx_data             : std_logic_vector(7 downto 0);
signal   tx_ena              : std_logic_vector(3 downto 0) := x"0";
signal   sample_addr         : std_logic_vector (15 downto 0);
signal   sample_addr_trigoff : std_logic_vector (15 downto 0);
signal   tempaddr            : std_logic_vector (15 downto 0);
signal   adc_sram_addr       : std_logic_vector (15 downto 0);
signal   post_trigger_cnt    : std_logic_vector (15 downto 0);
signal   adc_wen             : std_logic := '0';
signal   sram_tx_data        : std_logic_vector(7 downto 0);  
signal   adc_to_ram_data     : std_logic_vector(15 downto 0) := x"1234";
signal   acq_count           : std_logic_vector(15 downto 0);
signal   triggered_addr      : std_logic_vector(11 downto 0);
signal   adc_last            : std_logic_vector(11 downto 0);
signal   ram_write_delay     : std_logic_vector(3 downto 0);
signal   response_valid_last : std_logic; 
signal   response_ch         : std_logic_vector(1 downto 0);
signal   resp_val_high       : std_logic_vector(3 downto 0);

--install components
component uart is
    port (
        clk       :   IN      std_logic;                     --system clock
        reset_n   :   IN      std_logic;                     --ascynchronous reset
        rx        :   IN      std_logic;                     --receive pin
        rx_busy   :   buffer  std_logic;                     --data reception in progress
        rx_error  :   buffer  std_logic;                     --start, parity, or stop bit error detected
        rx_data   :   buffer  std_logic_vector(7 DOWNTO 0);  --data received
        tx_ena    :   IN      std_logic;                     --initiate transmission
        tx_data   :   IN      std_logic_vector(7 DOWNTO 0);  --data to transmit
        tx_busy   :   buffer  std_logic;                     --transmission in progress
        tx        :   buffer  std_logic
    );
end component uart;

component ram16kb IS
    port (
        clock       : in      std_logic  := '1';
        data        : in      std_logic_VECTOR (15 downto 0);
        rdaddress   : in      std_logic_VECTOR (14 downto 0);
        wraddress   : in      std_logic_VECTOR (13 downto 0);
        wren        : in      std_logic  := '0';
        q           : buffer  std_logic_VECTOR (7 downto 0)
    );
end component ram16kb;

begin
--connect components
uart0: component uart 
    port map (
          clk       => clk_50mhz,
          reset_n   => '1',
          rx        => '1',
          rx_busy   => open,
          rx_error  => open,
          rx_data   => open,

          tx_ena    => tx_ena(3),
          tx_data   => tx_data,
          tx_busy   => tx_busy,
          tx        => tx
    );

sram0: component ram16kb
    port map (
        clock          => clk_50mhz,
        data           => adc_to_ram_data,
        rdaddress      => sample_addr_trigoff(14 downto 0),
        wraddress      => adc_sram_addr(13 downto 0),
        wren           => ram_write_delay(3),
        q              => sram_tx_data
    );
command_valid <= '1';
command_startofpacket <= '1';
testout(7 downto 0) <= post_trigger_cnt(7 downto 0);

--transmit state machine
header <= x"20";
process(clk_50mhz)
begin
   if clk_50mhz'event and clk_50mhz='1' then
      if dump_strobe = '1' then 
         dump <= '1'; 
         tx_ena <= x"0"; 
         txdelay <= x"0000"; 
         sample_addr <= x"0000";
      end if;
      if dump = '1' then
         if tx_ena >= x"1" then tx_ena <= tx_ena + '1'; end if;
         if tx_ena = "1000" then tx_ena <= x"0"; end if;
         if txdelay < x"00cc" then --was cc on both places
            if tx_busy = '0' then txdelay <= txdelay + '1'; end if;
         elsif txdelay = x"00cc" then 
            txdelay <= x"0000";   
            if sample_addr < header then          -- header
               if sample_addr = x"0000" then tx_data <= x"0a"; end if;
               if sample_addr = x"0001" then tx_data <= x"0d"; end if;            
               if sample_addr = x"0002" then tx_data <= x"6f"; end if;
               if sample_addr = x"0003" then tx_data <= x"73"; end if;
               if sample_addr = x"0004" then tx_data <= x"63"; end if;
               if sample_addr = x"0005" then tx_data <= x"6f"; end if;
               if sample_addr = x"0006" then tx_data <= x"70"; end if;
               if sample_addr = x"0007" then tx_data <= x"65"; end if;
               if sample_addr = x"0008" then tx_data <= trigger & "000" & activech; end if;
               if sample_addr = x"0009" then tx_data <= osc_length(15 downto 8); end if;
               if sample_addr = x"000a" then tx_data <= osc_length(7 downto 0); end if;
               if sample_addr = x"000b" then tx_data <= acq_rate(15 downto 8); end if;
               if sample_addr = x"000c" then tx_data <= acq_rate(7 downto 0); end if;
               if sample_addr = x"000d" then tx_data <= trigger_addr(15 downto 8); end if;
               if sample_addr = x"000e" then tx_data <= trigger_addr(7 downto 0); end if;
               if sample_addr = x"000f" then tx_data <= x"ff"; end if;
               if sample_addr = x"001c" then tx_data <= x"00"; end if;
               if sample_addr = x"001d" then tx_data <= x"00"; end if;
               if sample_addr = x"001e" then tx_data <= x"ff"; end if;
               if sample_addr = x"001f" then tx_data <= x"ff"; end if;
               tx_ena <= x"1";
               sample_addr <= sample_addr + '1';
            elsif sample_addr < osc_length + header + x"1" then  -- data portion of packet
               tx_ena <= x"1";
               tx_data <= sram_tx_data;   
               sample_addr <= sample_addr + '1';
            elsif sample_addr >= osc_length + header then  -- end of packet
               dump <= '0';
               sample_addr <= x"0000";               
            end if;
         end if;
      end if;
   end if;
end process;

tempaddr(15 downto 1) <= trigger_addr(14 downto 0) - trigger_offset(14 downto 0) when trigger = '1' else x"0000";
tempaddr(0) <= '0';
sample_addr_trigoff <= (sample_addr - header) + tempaddr;
--sample_addr_trigoff <= (sample_addr - header) when trigger = '0' else 
--                       (sample_addr - header) + tempaddr;

process(clk_50mhz)
begin
   if clk_50mhz'event and clk_50mhz='1' then
      if update_cnt(31 downto 16) > updaterate then
         update_strobe <= '1';
         update_cnt <= x"00000000";
      else
         update_strobe <= '0';
         update_cnt <= update_cnt + '1';
      end if;
   end if;
end process;

response_ch <= "00" when response_channel = "01000" else
               "01" when response_channel = "00010" else
               "10" when response_channel = "00101" else
               "11" when response_channel = "00001";
               
--adc acquire state machine-list of channels in two places
process(clk_50mhz)
begin
   if clk_50mhz'event and clk_50mhz='1' then
      if dump_strobe = '1' then dump_strobe <= '0'; end if;
      if acq_counter < acq_rate and response_valid = '1' then 
         acq_counter <= acq_counter + '1';
      end if;
      --if command_valid = '1' then command_valid <= '0'; end if;
      if adc_wen = '1' then adc_wen <= '0'; ram_write_delay <= x"1"; end if;
      if ram_write_delay <= "0111" then ram_write_delay <= ram_write_delay + '1'; end if; 
      if ram_write_delay(3) = '1' then ram_write_delay <= x"0"; end if;
      --reset everything
      if update_strobe = '1' then 
         adc_sram_addr <= x"0000";
         trigger_addr <= x"0000";    
         post_trigger_cnt <= x"0000";
         halt_acq <= '0'; 
			resp_val_high <= "1111";
      end if;
      response_valid_last <= response_valid;
      if response_valid = '1' and response_valid_last = '0' and halt_acq = '0' and acq_counter >= acq_rate then
         --if response_valid = '1' then command_valid <= '1'; end if;      
         acq_counter <= x"0001";
         if channel_cnt < activech - '1' then
            channel_cnt <= channel_cnt + '1';
         else channel_cnt <= x"0";   
         end if;
         channel_cnt_last <= channel_cnt;
         --list of channels in two places
         if channel_cnt(3 downto 0) = x"0" then command_channel <= '0'&x"8"; end if;
         if channel_cnt(3 downto 0) = x"1" then command_channel <= '0'&x"2"; end if;
         if channel_cnt(3 downto 0) = x"2" then command_channel <= '0'&x"5"; end if;
         if channel_cnt(3 downto 0) = x"3" then command_channel <= '0'&x"1"; end if;  
         --we read out data in bytes breaking up this ways makes sync easy   
         adc_to_ram_data(15)           <= '0'; 
         adc_to_ram_data(14 downto 13) <= response_ch;
         adc_to_ram_data(12 downto 8)  <= response_data(11 downto 7);
         adc_to_ram_data(7)            <= '1';
         adc_to_ram_data(6 downto 0)   <= response_data(6 downto 0);
         adc_wen <= '1';
         if adc_sram_addr = x"3fff" then
            adc_sram_addr <= x"0000";
         else
            adc_sram_addr <= adc_sram_addr + '1';
         end if;
         if trigger = '0' or trigger_addr > x"0000" then post_trigger_cnt <= post_trigger_cnt + '1'; end if;
         if post_trigger_cnt > osc_length then dump_strobe <= '1'; halt_acq <= '1'; end if;
         if (channel_cnt_last = x"0" or activech = x"1") then adc_last <= response_data; end if;
			-- store last 4 logic levels
			if response_ch = "00" then
	         if '0'&response_data > '0'&x"400" then resp_val_high <= resp_val_high(2 downto 0) & '1'; 
				   else resp_val_high <= resp_val_high(2 downto 0) & '0'; end if;
			end if;
         -- if trigger set and first time thru and trif offset padded and adc meas goes <1v to >= 1v
         if trigger = '1' and trigger_addr = x"0000"          --trigger active and not set
                          and adc_sram_addr > trigger_offset  --dont trigger unless previuos data buffered
                          and resp_val_high = "0011"
								  and response_ch = "00" then         -- and channel 0
                                   trigger_addr <= adc_sram_addr;    
         end if;
      end if;
   end if;
end process;

end Behavioral;
