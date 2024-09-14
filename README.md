# Corrode
A re-implementation of the discord client in Rust/Flutter

## Why?
I wanted to do a bigger-ish project in Rust to learn the ins and outs of the language.
I've also been looking for an alternative discord Android client for a while now with no avail.
Thus the next logical step was to try and write one myself, so here we are lol 

## TODO
- [x] Fetch Guilds/channels
- [x] Fetch messages
- [ ] Send messages
- [ ] Fetch channel message history
- [ ] Private Messages
- [ ] ....and more


## Building

```bash
cargo install flutter_rust_bridge_codegen cargo-expand

flutter pub get

flutter_rust_bridge_codegen generate

flutter build apk
```

## Disclaimer
This is a personal project of mine and is in no way affiliated with Discord