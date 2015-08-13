# awesome-battmon
A simple battery monitor for awesome WM.  
バッテリーの残量を視覚的に表示する awesome WM のシンプルなウィジェットです。  

## Screenshots
![2 batteries and one is critical](https://github.com/rhenium/awesome-battmon/raw/master/images/critical.png)  
![2 batteries and one is charging](https://github.com/rhenium/awesome-battmon/raw/master/images/charging.png)  

## Installation
1. Clone this repository:

    ```sh
    git clone https://github.com/rhenium/awesome-battmon.git ~/.config/awesome/plugins/battmon
    ```

2. Require battmon in your `rc.lua`:

    ```lua
    local battmon = require("plugins/battmon")
    ```

3. Insert battmon widget:

    ```lua
    for key, batt in pairs(battmon.all()) do
      right_layout:add(batt)
    end
    ```

    or manually

    ```lua
    local bat0 = battmon({
      battery = "BAT0",
      ac_adapter = "AC",
      width = 48, -- 48px
      warning = 30, -- 30%
      critical = 15, -- 15%
      normal_color = "#ffffff",
      charging_color = "#00ff00",
      warning_color = "#ffff00",
      critical_color = "#ff0000",
      update_interval = 1
    })
    right_layout:add(bat0)
    ```
