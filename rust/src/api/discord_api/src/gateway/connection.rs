use tungstenite::{connect, Message, Error as WsError};
use serde_json::{json, Value};
use std::sync::{Arc, mpsc, Mutex};
use std::time::Duration;
use reqwest;
use tokio;

use crate::events::event::Event;
use crate::events::handler::handle_event;

pub async fn start_thread(tx: mpsc::Sender<Event>, token: String) {
    let gateway_url_cached = reqwest::get("https://discord.com/api/v10/gateway")
        .await.expect("Failed to fetch gateway URL")
        .text().await.expect("Failed to read response");

    let gateway_json: Value = serde_json::from_str(&gateway_url_cached).expect("Failed to parse gateway URL");
    let mut gateway_url = gateway_json["url"].as_str().expect("Invalid gateway URL").to_owned();

    loop {
        let mut hb_interval: u128 = 0;
        let (socket, _response) = match connect(gateway_url.clone() + "/?v=9&encoding=json") {
            Ok((socket, response)) => (socket, response),
            Err(error) => {
                println!("Failed to connect. Retrying...");
                println!("Error: {:?}", error);
                tokio::time::sleep(Duration::from_secs(5)).await;
                continue;
            }
        };

        let socket = Arc::new(Mutex::new(socket));

        if let Ok(msg) = socket.lock().unwrap().read() {
            if msg.is_text() {
                let payload: Value = serde_json::from_str(&msg.to_string()).expect("Unable to parse JSON");
                if payload["op"] == 10 {
                    let heartbeat_interval = payload["d"]["heartbeat_interval"].as_u64().expect("Invalid heartbeat interval");
                    hb_interval = heartbeat_interval as u128;
                }
            }
        }

        let identify_payload = json!({
            "op": 2,
            "d": {
                "token": token,
                "properties": {
                    "$os": "linux",
                    "$browser": "chrome",
                    "$device": "desktop"
                }
            }
        });
        socket.lock().unwrap().send(Message::Text(identify_payload.to_string())).expect("Error sending message");

        let mut last_heartbeat = std::time::Instant::now();
        let mut last_sequence = Value::Null;
        loop {
            if last_heartbeat.elapsed().as_millis() > hb_interval {
                let heartbeat_payload = json!({
                    "op": 1,
                    "d": last_sequence
                });
                if let Err(err) = socket.lock().unwrap().send(Message::Text(heartbeat_payload.to_string())) {
                    println!("Error sending heartbeat: {:?}", err);
                    break;
                }
                last_heartbeat = std::time::Instant::now();
            }

            match socket.lock().unwrap().read() {
                Ok(msg) => {
                    if msg.is_text() {
                        let payload: Value = serde_json::from_str(&msg.to_string()).expect("Unable to parse JSON");
                        match payload["op"].as_u64().expect("Invalid OP code") {
                            0 => {
                                let event_name = payload["t"].as_str().expect("Invalid event name");
                                handle_event(tx.clone(), event_name, payload["d"].clone());
                                let seq = payload["s"].as_u64().expect("Invalid sequence number");
                                last_sequence = Value::from(seq);
                                if event_name == "READY" {
                                    gateway_url = payload["d"]["resume_gateway_url"].as_str().expect("Invalid gateway URL").to_owned();
                                }
                            },
                            11 => { println!("Heartbeat ACK received"); },
                            7 => {
                                println!("Received reconnect request. Attempting to resume...");
                                let resume_payload = json!({
                                    "op": 6,
                                    "d": {
                                        "token": token,
                                        "session_id": payload["d"]["session_id"]
                                    }
                                });
                                socket.lock().unwrap().send(Message::Text(resume_payload.to_string())).expect("Error sending message");
                            },
                            9 => { println!("Invalid session. Reconnecting and identifying..."); },
                            1 => { println!("Heartbeat received"); },
                            _ => { println!("Received unknown payload: {:?}", payload); }
                        }
                    } else if let Message::Close(Some(close_frame)) = msg {
                        if close_frame.code == tungstenite::protocol::frame::coding::CloseCode::Library(4004) {
                            tx.send(Event::AuthFail(close_frame.reason.to_string())).expect("Failed to send AUTH_FAIL event");
                            return;
                        }
                    } else {
                        println!("Received binary message: {:?}", msg);
                    }
                },
                Err(WsError::ConnectionClosed) => {
                    println!("Connection closed. Reconnecting...");
                    break;
                },
                Err(err) => {
                    println!("Error reading message: {:?}", err);
                    break;
                }
            }
        }
        println!("Reconnecting...");
    }
}
