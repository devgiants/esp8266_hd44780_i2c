do
    if(_G['i2c'] ~= nil) then        
        local constants = dofile('constants.lua')

        print(constants.MODULE_NAME .. ': I2C here. continue.')
        -- commands
        

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

        local function expanderWrite(data, backlight)
            if(backlight == nil) then
                backlight = constants.LCD_BACKLIGHT
            end
            i2c.start(id)
            i2c.address(id, address ,i2c.TRANSMITTER)  
            -- Force backlight on write so far         
            i2c.write(id, bit.bor(data, backlight))
            i2c.stop(id)
        end

        local function pulseEnable(data)
            expanderWrite(bit.bor(data, constants.EN))
            tmr.delay(1)
            expanderWrite(bit.band(data, bit.bnot(constants.EN)))
            tmr.delay(50)
        end                

        local function write4bits(value)
            expanderWrite(value)
            pulseEnable(value)
        end   

        -- write either command or data on 4 bits mode
        local function send(value, mode)
            print(value)
            local highNib = bit.band(value, 0xF0)
            local lowNib = bit.band(bit.lshift(value, 4), 0xF0)

            write4bits(bit.bor(highNib, mode))
            write4bits(bit.bor(lowNib, mode))
        end

        local function command(value)
            send(value, 0)
        end

        local function write(value)
            send(value, constants.RS)
            return 1
        end      

        local function display()
            displayControl =  bit.bor(displayControl, constants.LCD_DISPLAYON)
            command(bit.bor(constants.LCD_DISPLAYCONTROL, displayControl))
        end

        local function clear()
            command(constants.LCD_CLEARDISPLAY)
            tmr.delay(2000)
        end

        local function home()
            command(constants.LCD_RETURNHOME)
            tmr.delay(2000)
        end

        local function setCursor(col, row)
            rowOffsets = { 0x00, 0x40, 0x14, 0x54 }

            print(row .. ' ' .. col .. ' ' .. rows)
            print(rowOffsets[row])                      
            
            command(bit.bor(constants.LCD_SETDDRAMADDR, (col + rowOffsets[row])))
        end

        local function printString(str)
            for i = 1, #str do
             local char = string.byte(string.sub(str, i, i))
             print(char)
             write(char)
             --send ({ bit.clear(char,0,1,2,3),bit.lshift(bit.clear(char,4,5,6,7),4)})
            end
        end

        -- Turn the (optional) backlight off/on
        local function noBacklight()
            backlight = constants.LCD_NOBACKLIGHT
            expanderWrite(0, backlight)
        end

         -- Turn the (optional) backlight off/on
        local function backlight()
            backlight = constants.LCD_BACKLIGHT
            expanderWrite(0, backlight)
        end


        local function init(givenSda, givenScl, givenAddress, givenColsNumber, givenRowsNumber, givenId)

            -- Assign object var
            if givenId ~= nil then id = givenId else id = 0 end
            address = givenAddress
            sda = givenSda
            scl = givenScl

            cols = givenColssNumber
            rows = givenRowsNumber            

            displayFunction = bit.bor(constants.LCD_4BITMODE, constants.LCD_1LINE, constants.LCD_5x8DOTS)           
            --print(constants.MODULE_NAME .. ': displayFunction value ' .. displayFunction)

            if rows > 1 then
                displayFunction = bit.bor(displayFunction, constants.LCD_2LINE)
            end
            numLines = rows
            
            -- According to p45/46 we need at least 40ms after power rises above 2.7V
            tmr.delay(40000)
            
            -- Establishing connection
            local speed = i2c.setup(id, sda, scl, i2c.SLOW)
            print(constants.MODULE_NAME .. ': I2C setup (SDA : ' .. sda .. ', SCL : ' .. scl .. ', device at 0x' .. string.format('%x', address) .. ') at ' .. speed .. ' bit/s.')

            backlight = constants.LCD_NOBACKLIGHT
            print(backlight)
           -- expanderWrite(backlight)

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
            write4bits(bit.lshift(0x02, 4))


            -- set # lines, font size, etc.
            command(bit.bor(constants.LCD_FUNCTIONSET, displayFunction))
            

            displayControl = bit.bor(constants.LCD_DISPLAYON, constants.LCD_CURSOROFF, constants.LCD_BLINKOFF)
            
            display()

            clear()

            --Initialize to default text direction (for roman languages)
            displayMode = bit.bor(constants.LCD_ENTRYLEFT, constants.LCD_ENTRYSHIFTDECREMENT)

            -- set the entry mode
            command(bit.bor(constants.LCD_ENTRYMODESET, displayMode))

            home()
            
        end
      
        -- Define object
        hd44780 = {
            init=init,
            noBacklight=noBacklight,          
            backlight=backlight,
            setCursor=setCursor,
            printString=printString
        }
    else
        print(constants.MODULE_NAME .. ': I2C module is required to run this library. Please include it in your firmware.')
    end    
end
