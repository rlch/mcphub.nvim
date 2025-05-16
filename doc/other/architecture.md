# How It Works

MCPHub.nvim uses an Express server to manage MCP servers and handle client requests:

1. When `setup()` is called:

   - Checks for mcp-hub command installation
   - Verifies version compatibility
   - Checks if server is already running (multi-instance support)
   - If not running, starts mcp-hub with config file watching enabled
   - Creates Express server at `http://localhost:[config.port]` or at `config.server_url`

2. After successful setup:

   - Calls `on_ready` callback with hub instance
   - Hub instance provides REST API interface 
   - Real-time UI updates via `:MCPHub` command
   - Configuration changes auto-sync across instances

3. Express Server Features:
   - Real-time config file watching and syncing
   - Manages MCP server configurations
   - Handles tool execution requests
   - Provides resource access
   - Multi-instance support with shared state
   - Automatic cleanup

4. When Neovim instances close:
   - Unregister as clients
   - Last client triggers shutdown timer
   - Timer cancels if new client connects

This architecture ensures:

- Consistent server management
- Real-time status monitoring
- Efficient resource usage
- Clean process handling
- Multiple client support

## Architecture Flows

### Server Lifecycle

```mermaid
sequenceDiagram
participant N1 as First Neovim
participant N2 as Other Neovims
participant S as MCP Hub Server

Note over N1,S: First Client Connection
N1->>S: Check if Running
activate S
S-->>N1: Not Running
N1->>S: start_hub()
Note over S: Server Start
S-->>N1: Ready Signal
N1->>S: Register Client
S-->>N1: Registration OK

Note over N2,S: Other Clients
N2->>S: Check if Running
S-->>N2: Running
N2->>S: Register Client
S-->>N2: Registration OK

Note over N1,S: Server stays active

Note over N2,S: Client Disconnection
N2->>S: Unregister Client
S-->>N2: OK
Note over S: Keep Running

Note over N1,S: Last Client Exit
N1->>S: Unregister Client
S-->>N1: OK
Note over S: Grace Period
Note over S: Auto Shutdown
deactivate S
```

### Request flow

```mermaid
sequenceDiagram
participant N as Neovim
participant P as Plugin
participant S as MCP Hub Server
N->>P: start_hub()
P->>S: Health Check
alt Server Not Running
P->>S: Start Server
S-->>P: Ready Signal
end
P->>S: Register Client
S-->>P: Registration OK
N->>P: :MCPHub
P->>S: Get Status
S-->>P: Server Status
P->>N: Display UI
```

### Cleanup flow

```mermaid
flowchart LR
A[VimLeavePre] -->|Trigger| B[Stop Hub]
B -->|If Ready| C[Unregister Client]
C -->|Last Client| D[Server Auto-shutdown]
C -->|Other Clients| E[Server Continues]
B --> F[Clear State]
F --> G[Ready = false]
F --> H[Owner = false]
```

### API Flow

```mermaid
sequenceDiagram
participant C as Chat Plugin
participant H as Hub Instance
participant S as MCP Server
C->>H: call_tool()
H->>H: Check Ready
alt Not Ready
H-->>C: Error: Not Ready
end
H->>S: POST /tools
S-->>H: Tool Result
H-->>C: Return Result
Note over C,S: Similar flow for resources

C->>H: access_resource()
H->>H: Check Ready
H->>S: POST /resources
S-->>H: Resource Data
H-->>C: Return Data
```
