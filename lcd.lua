do
    if(_G['i2c'] ~= nil) then        
        -- Retrieve constants
        local constants = {
	    MODULE_NAME = 'HD44780 I2C',
	    LCD_CLEARDISPLAY = 0x01,
	    LCD_RETURNHOME = 0x02,
	    LCD_ENTRYMODESET = 0x04,
	    LCD_DISPLAYCONTROL = 0x08,
	    LCD_CURSORSHIFT = 0x10,
	    LCD_FUNCTIONSET = 0x20,
	    LCD_SETCGRAMADDR = 0x40,
	    LCD_SETDDRAMADDR = 0x80,
	    
	    -- flags for display entry mode
	    LCD_ENTRYRIGHT = 0x00,
	    LCD_ENTRYLEFT = 0x02,
	    LCD_ENTRYSHIFTINCREMENT = 0x01,
	    LCD_ENTRYSHIFTDECREMENT = 0x00,
	    
	    -- flags for display on/off control
	    LCD_DISPLAYON = 0x04,
	    LCD_DISPLAYOFF = 0x00,
	    LCD_CURSORON = 0x02,
	    LCD_CURSOROFF = 0x00,
	    LCD_BLINKON = 0x01,
	    LCD_BLINKOFF = 0x00,
	    
	    -- flags for display/cursor shift
	    LCD_DISPLAYMOVE = 0x08,
	    LCD_CURSORMOVE = 0x00,
	    LCD_MOVERIGHT = 0x04,
	    LCD_MOVELEFT = 0x00,
	    
	    -- flags for function set
	    LCD_8BITMODE = 0x10,
	    LCD_4BITMODE = 0x00,
	    LCD_2LINE = 0x08,
	    LCD_1LINE = 0x00,
	    LCD_5x10DOTS = 0x04,
	    LCD_5x8DOTS = 0x00,
	    
	    -- flags for backlight control
	    LCD_BACKLIGHT = 0x08,
	    LCD_NOBACKLIGHT = 0x00,
	    
	    EN = 0x04,  -- Enable bit
	    RW = 0x02,  -- Read/Write bit
	    RS = 0x01,  -- Register select bit
	    
	    COMMAND = 0,
	    DATA = 1
	}

        print(constants.MODULE_NAME .. ': I2C here. continue.')

        -- LOCAL VARIABLES NEEDED
        -------------------
        local id
        local sda
        local scl
        local address        
        local id
        local cols
        local rows
        local backlight

        local displayFunction
        local displayControl
        local displayMode
        local numLines

        -- Write to the I2C expander.
        -- Initiates I2C connection
        local function expanderWrite(data, backlight)
            if(backlight == nil) then
                backlight = constants.LCD_BACKLIGHT
            end
            i2c.start(id)
            i2c.address(id, address ,i2c.TRANSMITTER)              
            i2c.write(id, bit.bor(data, backlight))
            i2c.stop(id)
        end

        -- According to datasheet p22, 4-bit interface data must be sent twice (high order bits first)
        -- EN bit is toggling on each sending
        local function pulseEnable(data)
            expanderWrite(bit.bor(data, constants.EN))
            tmr.delay(1)
            expanderWrite(bit.band(data, bit.bnot(constants.EN)))
            tmr.delay(50)
        end                

        -- Write 4 bits with EN toggling
        local function write4bits(value)
            expanderWrite(value)
            pulseEnable(value)
        end   

        -- Send value with 4 bit splitting
        -- First high-order bits, then low ones
        -- mode is supposed to receive 0 for commands, RS value for data
        local function send(value, mode)            
            local highNib = bit.band(value, 0xF0)
            local lowNib = bit.band(bit.lshift(value, 4), 0xF0)

            write4bits(bit.bor(highNib, mode))
            write4bits(bit.bor(lowNib, mode))
        end

        -- Wrapper to force command 
        local function command(value)
            send(value, 0)
        end

        -- Write to LCD
        local function write(value)
            send(value, constants.RS)
            return 1
        end      

        -- Compute display value and send it to LCD
        local function display()
            displayControl =  bit.bor(displayControl, constants.LCD_DISPLAYON)
            command(bit.bor(constants.LCD_DISPLAYCONTROL, displayControl))
        end

        -- Clear screen
        local function clear()
            command(constants.LCD_CLEARDISPLAY)
            tmr.delay(2000)
        end

        -- Send cursor to home
        local function home()
            command(constants.LCD_RETURNHOME)
            tmr.delay(2000)
        end

        -- Set cursor to line beginning
        -- Both col and row variables are 0-based
        local function setCursor(col, row)

            -- Add make row 1-based for lua array usage
            row = row + 1

            -- Offsets for 4 rows 
            rowOffsets = { 0x00, 0x40, 0x14, 0x54 }
                                
            command(bit.bor(constants.LCD_SETDDRAMADDR, (col + rowOffsets[row])))
        end

        local function printString(str)
            for i = 1, #str do
             local char = string.byte(string.sub(str, i, i))
             print(constants.MODULE_NAME .. ': Char "' .. string.sub(str, i, i) .. '" represented by ' .. char)
             write(char)             
            end
        end

        -- Turn the (optional) backlight off/on
        local function noBacklight()
            backlight = constants.LCD_NOBACKLIGHT
            expanderWrite(0, backlight)
        end

         -- Turn the (optional) backlight off/on
        local function setBacklight(value)
            if ((value == constants.LCD_BACKLIGHT) or (value == constants.LCD_NOBACKLIGHT)) then
                expanderWrite(0, value)
            end            
        end


        local function init(givenSda, givenScl, givenAddress, givenColsNumber, givenRowsNumber, givenId)

            -- setCursor can't handle offset up to 4 lines
            if(givenRowsNumber > 4) then
                print(constants.MODULE_NAME .. ': This library can only handle 4 rows max.')
                return false
            end
            -- Assign object var
            if givenId ~= nil then id = givenId else id = 0 end
            address = givenAddress
            sda = givenSda
            scl = givenScl

            cols = givenColsNumber
            rows = givenRowsNumber            

            displayFunction = bit.bor(constants.LCD_4BITMODE, constants.LCD_1LINE, constants.LCD_5x8DOTS)                      

            -- Activate 2-lines LCD if more than one row
            if rows > 1 then
                displayFunction = bit.bor(displayFunction, constants.LCD_2LINE)
            end
            numLines = rows
            
            -- According to p45/46 we need at least 40ms after power rises above 2.7V
            tmr.delay(40000)
            
            -- Establishing connection
            local speed = i2c.setup(id, sda, scl, i2c.SLOW)
            print(constants.MODULE_NAME .. ': I2C setup (SDA : ' .. sda .. ', SCL : ' .. scl .. ', device at 0x' .. string.format('%x', address) .. ') at ' .. speed .. ' bit/s.')
                    
            -- Sequence described p45 of datasheet
            --------------------------------------
            
            
            write4bits(bit.lshift(0x03, 4))
            tmr.delay(4500) -- wait min 4.1ms
               
            write4bits(bit.lshift(0x03, 4))
            tmr.delay(4500);  -- wait min 4.1ms
     
            write4bits(bit.lshift(0x03, 4))
            tmr.delay(150);
   
            -- finally, set to 4-bit interface
            write4bits(bit.lshift(0x02, 4))

            -- set # lines, font size, etc.
            command(bit.bor(constants.LCD_FUNCTIONSET, displayFunction))           
            displayControl = bit.bor(constants.LCD_DISPLAYON, constants.LCD_CURSOROFF, constants.LCD_BLINKOFF)

            -- Compute display
            display()
            
            -- Clear screen
            clear()

            --Initialize to default text direction (for roman languages)
            displayMode = bit.bor(constants.LCD_ENTRYLEFT, constants.LCD_ENTRYSHIFTDECREMENT)

            -- set the entry mode
            command(bit.bor(constants.LCD_ENTRYMODESET, displayMode))

            -- Cursor to home
            home()

            -- All right
            return true
        end
      
        -- Define object
        hd44780 = {
            -- Constants available when using object
            BACKLIGHT_ON = constants.LCD_BACKLIGHT,
            BACKLIGHT_OFF = constants.LCD_NOBACKLIGHT,

            -- Methods
            init = init,
            setBacklight = setBacklight,
            setCursor = setCursor,
            clear = clear,
            printString = printString            
        }
    else
        print(constants.MODULE_NAME .. ': I2C module is required to run this library. Please include it in your firmware.')
    end    
end
