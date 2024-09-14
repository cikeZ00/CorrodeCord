use reqwest::Client;
use serde_json::{json, Value};
use std::error::Error;
use crate::rest::endpoints::{BASE_URL, GET_GUILDS, GET_CHANNELS, GET_MESSAGES, SEND_MESSAGE, GET_USER, GET_USER_GUILDS, GET_USER_CONNECTIONS, GET_GUILD};

pub struct RestClient {
    client: Client,
    token: String,
}

pub async fn send_request(client: &Client, token: &str, endpoint: &str) -> Result<Value, Box<dyn Error>> {
    let response = client.get(&format!("{}{}", BASE_URL, endpoint))
        .header("Authorization", token)
        .send()
        .await?
        .json::<Value>()
        .await?;

    Ok(response)
}
impl RestClient {
    pub fn new(token: String) -> Self {
        RestClient {
            client: Client::new(),
            token,
        }
    }
    
    pub async fn get_guilds(&self) -> Result<Value, Box<dyn Error>> {
        send_request(&self.client, &self.token, GET_GUILDS).await
    }
    
    pub async fn get_channels(&self, guild_id: &str) -> Result<Value, Box<dyn Error>> {
        send_request(&self.client, &self.token, &GET_CHANNELS.replace("{guild_id}", guild_id)).await
    }
    
    pub async fn get_messages(&self, channel_id: &str) -> Result<Value, Box<dyn Error>> {
        send_request(&self.client, &self.token, &GET_MESSAGES.replace("{channel_id}", channel_id)).await
    }
    
    // ({"mobile_network_type":"unknown","content":"hello","nonce":"1284283526178406400","tts":false,"flags":0})
    pub async fn send_message(&self, channel_id: &str, message: &str) -> Result<Value, Box<dyn Error>> {
        let response = self.client.post(&format!("{}{}", BASE_URL, &SEND_MESSAGE.replace("{channel_id}", channel_id)))
            .header("Authorization", &self.token)
            .json(&json!({"content": message}))
            .send()
            .await?
            .json::<Value>()
            .await?;
        
        Ok(response)
    }
}