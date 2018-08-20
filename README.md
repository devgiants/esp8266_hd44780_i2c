# HD44780 I2C Lua driver
This is a library intended to be used with [ESP8266 NodeMCU](https://nodemcu.readthedocs.io/en/master/) in order to interface easily with any HD44780 LCD with I2C backpack.
## Example
```lua
-- Get library
dofile('lcd.lua')
-- Init device communication.
-- In this example, pin 3 -> SDA, pin 4 -> SCL, 0x27 is the device I2C address, 20 columns, 4 rows (4x20 LCD display)
if(hd44780.init(3,4,0x27,20,4)) then
    -- Set backlight on
    hd44780.setBacklight(hd44780.BACKLIGHT_ON)
    -- Set cursor 5th columns 1st line
    hd44780.setCursor(5,0)
    -- Print text
    hd44780.printString('first line')
    hd44780.setCursor(1,1)
    hd44780.printString('second line')
    hd44780.setCursor(6,2)
    hd44780.printString('third line')
    hd44780.setCursor(0,3)
    hd44780.printString('fourth line')

    tmr.delay(1000000)
    -- Clear screen
    hd44780.clear()
    tmr.delay(1000000)
    hd44780.setBacklight(hd44780.BACKLIGHT_OFF)
    tmr.delay(1000000)
    hd44780.setCursor(5,0)
    hd44780.printString('first line')
    hd44780.setCursor(1,1)
    hd44780.printString('second line')
    hd44780.setCursor(6,2)
    hd44780.printString('third line')
    hd44780.setCursor(0,3)
    hd44780.printString('fourth line')
    hd44780.printString('V1.0')
end
```
