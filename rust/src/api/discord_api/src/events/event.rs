use serde_json::{Map, Value};

pub enum Event {
    Ready(Map<String, Value>),
    MessageCreate(Map<String, Value>),
    ChannelCreate,
    MessageReactionAdd,
    MessageReactionRemove,
    TypingStart,
    GuildDelete,
    GuildCreate,
    AuthFail(String),
    Unknown(String),
}
