do
    if(_G['i2c'] ~= nil) then
        print('HD44780 : I2C here. continue.')
        
        -- commands
        local LCD_CLEARDISPLAY = 0x01
        local LCD_RETURNHOME = 0x02
        local LCD_ENTRYMODESET = 0x04
        local LCD_DISPLAYCONTROL = 0x08
        local LCD_CURSORSHIFT = 0x10
        local LCD_FUNCTIONSET = 0x20
        local LCD_SETCGRAMADDR = 0x40
        local LCD_SETDDRAMADDR = 0x80
        
        -- flags for display entry mode
        local LCD_ENTRYRIGHT = 0x00
        local LCD_ENTRYLEFT = 0x02
        local LCD_ENTRYSHIFTINCREMENT = 0x01
        local LCD_ENTRYSHIFTDECREMENT = 0x00
        
        -- flags for display on/off control
        local LCD_DISPLAYON = 0x04
        local LCD_DISPLAYOFF = 0x00
        local LCD_CURSORON = 0x02
        local LCD_CURSOROFF = 0x00
        local LCD_BLINKON = 0x01
        local LCD_BLINKOFF = 0x00
        
        -- flags for display/cursor shift
        local LCD_DISPLAYMOVE = 0x08
        local LCD_CURSORMOVE = 0x00
        local LCD_MOVERIGHT = 0x04
        local LCD_MOVELEFT = 0x00
        
        -- flags for function set
        local LCD_8BITMODE = 0x10
        local LCD_4BITMODE = 0x00
        local LCD_2LINE = 0x08
        local LCD_1LINE = 0x00
        local LCD_5x10DOTS = 0x04
        local LCD_5x8DOTS = 0x00
        
        -- flags for backlight control
        local LCD_BACKLIGHT = 0x08
        local LCD_NOBACKLIGHT = 0x00
        
        local EN = 0x04  -- Enable bit
        local RW = 0x02  -- Read/Write bit
        local RS = 0x01  -- Register select bit

        local COMMAND = 0
        local DATA = 1

        local id
        local sda
        local scl
        local address        
        local id
        local cols
        local rows
        local backlight = LCD_NOBACKLIGHT

        local displayFunction
        local displayControl
        local displayMode;
        local numLines;

        local function expanderWrite(data)
            i2c.start(id)
            i2c.address(id, address ,i2c.TRANSMITTER)
            i2c.write(id, bit.bor(data, backlight))
            i2c.stop(id)
        end

        -- write either command or data
        local function send(value, mode)
            local highNib = bit.band(value, 0xF0)
            local lowNib = bit.band(bit.lshift(value, 4), 0xF0)

            write4bits(bit.bor(highNib, mode))
            write4bits(bit.bor(lowNib, mode))
        end

        local function command(value)
            send(value, 0)
        end

        local function write(value) {
            send(value, RS);
            return 1
        end

        local function write4bits(value)
            expanderWrite(value);
            pulseEnable(value);
        end


        local function pulseEnable(data)
            expanderWrite(bit.bor(data, EN))
            tmr.delay(1)

            expanderWrite(bit.band(data, bit.bnot(EN)))
            tmr.delay(50)
        end

        local function display()
            displayControl =  bit.bor(displayControl, LCD_DISPLAYON)
            command(bit.bor(LCD_DISPLAYCONTROL, displaycontrol)
        end

        local function clear()
            command(LCD_CLEARDISPLAY)
            delayMicroseconds(2000)
        end

        local function home()
            command(LCD_RETURNHOME)
            delayMicroseconds(2000)
        end


        local function init(givenSda, givenScl, givenAddress, givenColsNumber, givenRowsNumber, givenId)

            -- Assign object var
            if givenId ~= nil then id = givenId else id = 0 end
            address = givenAddress
            sda = givenSda
            scl = givenScl

            cols = givenColssNumber
            rows = givenRowsNumber            

            displayFunction = bit.bor(LCD_4BITMODE, LCD_1LINE, LCD_5x8DOTS)
           

            if rows > 1 then
                displayFunction = bit.bor(displayFunction, LCD_2LINE)
            end
            numLines = rows
            
            -- According to p45/46 we need at least 40ms after power rises above 2.7V
            tmr.delay(40000)
            
            -- Establishing connection
            local speed = i2c.setup(id, sda, scl, i2c.SLOW)
            print('HD44780 : I2C setup (SDA : ' .. sda .. ', SCL : ' .. scl .. ', device at 0x' .. string.format('%x', address) .. ') at ' .. speed .. ' bit/s.')

            expanderWrite(backlight)

            -- What to do with that
            tmr.delay(1000000)
            
            -- we start in 8bit mode, try to set 4 bit mode
            write4bits(bit.lshift(0x03, 4))
            tmr.delay(4500) -- wait min 4.1ms
   
            -- second try
            write4bits(bit.lshift(0x03, 4))
            tmr.delay(4500);  -- wait min 4.1ms
   
            -- third go!
            write4bits(bit.lshift(0x03, 4))
            tmr.delay(150);
   
            -- finally, set to 4-bit interface
            write4bits(bit.lsihft(0x02, 4) 


            -- set # lines, font size, etc.
            command(bit.bor(LCD_FUNCTIONSET, displayfunction))
            

            displayControl = bit.bor(LCD_DISPLAYON, LCD_CURSOROFF, LCD_BLINKOFF)
            
            display()

            clear()

            --Initialize to default text direction (for roman languages)
            displayMode = bit.bor(LCD_ENTRYLEFT, LCD_ENTRYSHIFTDECREMENT)

            -- set the entry mode
            command(bit.bor(LCD_ENTRYMODESET, displayMode)

            home()
            
        end
      
        -- Define object
        hd44780 = {
            init=init            
        }
    else
        print('HD44780 : I2C module is required to run this library. Please include it in your firmware.')
    end    
end
