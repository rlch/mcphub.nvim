# Lualine Integration

MCP Hub provides a lualine component that can be used to show the status of the MCP Hub and the number of connected servers. Add the component to a lualine section to use it. The following example shows how to add the component to the `lualine_x` section:

```lua
require('lualine').setup {
    sections = {
        lualine_x = {
            -- Other lualine components in "x" section
            {require('mcphub.extensions.lualine')},
        },
    },
}
```

## Usage

#### When MCP Hub is connecting: 

![image](https://github.com/user-attachments/assets/f67802fe-6b0c-48a5-9275-bff9f830ce29)

#### When connected shows number of connected servers:

![image](https://github.com/user-attachments/assets/f90f7cc4-ff34-4481-9732-a0331a26502b)

#### When a tool or resource is being called, shows spinner:

![image](https://github.com/user-attachments/assets/f6bdeeec-48f7-48de-89a5-22236a52843f)

