local M = {}

M.EventTypes = {
    HEARTBEAT = "heartbeat",
    HUB_STATE = "hub_state",
    LOG = "log",
    SUBSCRIPTION_EVENT = "subscription_event",
}

M.SubscriptionTypes = {
    TOOL_LIST_CHANGED = "tool_list_changed",
    RESOURCE_LIST_CHANGED = "resource_list_changed",
    PROMPT_LIST_CHANGED = "prompt_list_changed",

    CONFIG_CHANGED = "config_changed",
    SERVERS_UPDATING = "servers_updating",
    SERVERS_UPDATED = "servers_updated",
}

M.HubState = {
    STARTING = "starting",
    READY = "ready",
    CONFIGURING = "configuring",
    ERROR = "error",
    RESTARTING = "restarting",
    RESTARTED = "restarted",
    STOPPED = "stopped",
    STOPPING = "stopping",
}

return M
