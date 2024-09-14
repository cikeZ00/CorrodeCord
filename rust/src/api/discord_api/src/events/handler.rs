use serde_json::Value;
use std::sync::mpsc;
use crate::events::event::Event;

pub fn handle_event(tx: mpsc::Sender<Event>, event_name: &str, data: Value) {
    match event_name {
        "READY" => {
            if let Some(data) = data.as_object().clone() {
                tx.send(Event::Ready(data.clone())).unwrap();
            }
        },
        "MESSAGE_CREATE" => {
            if let Some(content) = data.as_object() {
                tx.send(Event::MessageCreate(content.clone())).unwrap();
            }
        },
        "CHANNEL_CREATE" => {},
        "MESSAGE_REACTION_ADD" => {},
        "MESSAGE_REACTION_REMOVE" => {},
        "TYPING_START" => {
            println!("Typing: {}", data["user_id"]);
        },
        "GUILD_DELETE" => {},
        "GUILD_CREATE" => {},
        "GUILD_UPDATE" => {},
        "GUILD_EMOJIS_UPDATE" => {},
        "GUILD_MEMBER_ADD" => {},
        "GUILD_MEMBER_REMOVE" => {},
        "GUILD_MEMBER_UPDATE" => {},
        "GUILD_MEMBERS_CHUNK" => {},
        "GUILD_ROLE_CREATE" => {},
        "GUILD_ROLE_DELETE" => {},
        "GUILD_ROLE_UPDATE" => {},
        "CHANNEL_PINS_UPDATE" => {},
        "CHANNEL_RECIPIENT_ADD" => {},
        "CHANNEL_RECIPIENT_REMOVE" => {},
        "FRIEND_SUGGESTIONS" => {},
        "CHANNEL_UNREAD_UPDATE" => {},
        "CHANNEL_UPDATE" => {},
        "SESSIONS_REPLACE" => {},
        "CHANNEL_DELETE" => {},
        "MESSAGE_UPDATE" => {},
        "MESSAGE_DELETE" => {},
        "MESSAGE_ACK" => {
            println!("Message ack: {}", data["message_id"]);
        },
        "VOICE_STATE_UPDATE" => {},
        "VOICE_CHANNEL_STATUS_UPDATE" => {},
        "CONVERSATION_SUMMARY_UPDATE" => {},
        
        _ => {
            println!("Received unknown event: {}", event_name);
            if let Some(content) = data.as_str() {
                println!("Message received: {}", content);
            }
        } // Ignore other events for now
    }
}
