awesome-battmon
===============

A simple battery monitor for awesome WM.

Screenshots
-----------

![2 batteries and one is critical](https://github.com/rhenium/awesome-battmon/raw/images/critical.png)
![2 batteries and one is charging](https://github.com/rhenium/awesome-battmon/raw/images/charging.png)

Installation
------------

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
      update_interval = 10 -- 10 seconds
    })
    right_layout:add(bat0)
    ```

Copyright
---------

Copyright (c) 2015-2017 Kazuki Yamaguchi <k@rhe.jp>

awesome-battmon is free software; you can redistribute it and/or modify it under
the terms of the MIT license. See COPYING for details.
