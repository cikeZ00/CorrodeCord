use std::collections::HashMap;
use discord_api::events::event::Event;
use discord_api::gateway::connection::start_thread;
use std::sync::{mpsc, Arc, Mutex};
use flutter_rust_bridge::for_generated::futures::{SinkExt, StreamExt};
use crate::frb_generated::{StreamSink, FLUTTER_RUST_BRIDGE_HANDLER};
use tokio::runtime::Runtime;
use serde_json::json;

pub async fn gateway_connection(token: String, sink: StreamSink<String>) {
    let handle = flutter_rust_bridge::spawn_blocking_with(
        move || {
            // Data channels for comms between threads
            let (tx, rx) = mpsc::channel(); // From gateway to main thread
            let (tx_sub, rx_sub) = mpsc::channel(); // From main thread to gateway


            // Create a new tokio runtime to run the async task
            let rt = Runtime::new().unwrap();
            rt.block_on(async {
                tokio::spawn(start_thread(tx, rx_sub, token));

                loop {
                    match rx.recv() {
                        Ok(Event::Ready(data)) => {
                            let mut filtered_data = HashMap::new();
                            for (key, value) in data.iter() {
                                match key.as_str() {
                                    "user" => {
                                        filtered_data.insert("user".to_string(), value.clone());
                                    },
                                    "session_id" => {
                                        filtered_data.insert("session_id".to_string(), value.clone());
                                    },
                                    "guilds" => {
                                        filtered_data.insert("guilds".to_string(), value.clone());
                                    },
                                    _ => {}
                                }
                            }
                            // Encode filtered data to JSON string
                            let event_data_json = serde_json::to_string(&filtered_data).expect("Failed to encode READY event");

                            let event_wrapper = json!({
                                "event_type": "READY",
                                "data": event_data_json
                            }).to_string();

                            sink.add(event_wrapper).expect("Failed to send READY event"); // Send data to Flutter
                        },
                        Ok(Event::MessageCreate(message)) => {
                            let author = message["author"]["username"].to_string();
                            let content = message["content"].to_string();
                            let timestamp = message["timestamp"].to_string();
                            let channel_id = message["channel_id"].to_string();
                            let server_id = message["guild_id"].to_string();

                            // Send data to Flutter
                            let mut message_data = HashMap::new();
                            message_data.insert("author".to_string(), author);
                            message_data.insert("content".to_string(), content);
                            message_data.insert("timestamp".to_string(), timestamp);
                            message_data.insert("channel_id".to_string(), channel_id);
                            message_data.insert("server_id".to_string(), server_id);

                            let event_data_json = serde_json::to_string(&message_data).expect("Failed to encode MESSAGE_CREATE event");

                            let event_wrapper = json!({
                                "event_type": "MESSAGE",
                                "data": event_data_json
                            }).to_string();

                            sink.add(event_wrapper).expect("Failed to send MESSAGE event");
                        },
                        Ok(Event::AuthFail(reason)) => {
                            let mut event_data_map = HashMap::new();
                            event_data_map.insert("reason".to_string(), reason);
                            let event_data_json = serde_json::to_string(&event_data_map).expect("Failed to encode AUTH_FAIL event");

                            let event_wrapper = json!({
                                "event_type": "AUTH_FAIL",
                                "data": event_data_json
                            }).to_string();

                            sink.add(event_wrapper).expect("Failed to send AUTH_FAIL event");
                        },
                        // Handle receiving on a closed channel
                        Err(_) => {
                            break;
                        },
                        _ => {
                            println!("Unknown event received");
                        }
                    }
                }
            })
        },
        FLUTTER_RUST_BRIDGE_HANDLER.thread_pool(),
    );
    handle.await.unwrap()
}
