module discordv

import sync
import time
import discordv.eventbus
import discordv.gateway
import discordv.rest
import discordv.types

// Config struct
pub struct Config {
pub mut:
	token string
	intents types.Intent = guilds | guild_messages
}

// Client represents a connection to the Discord API
pub struct Client {
	token string
	intents types.Intent
pub:
	shard_count int
mut:
	events &eventbus.EventBus
	shards []&gateway.Connection
	rest &rest.REST
}

// Creates a new Discord client and create shards if it provided as second argument
pub fn new(config Config, shard_count ...int) ?&Client {
	mut count := 1
	if shard_count.len >= 1 {
		count = shard_count[0]
	}
	client := new_with_shards(config, count)?
	return client
}

// Creates a new Discord client with specified number of shards
fn new_with_shards(config Config, shard_count int) ?&Client{
	mut client := &Client{
		token: config.token
		intents: config.intents
		shard_count: shard_count
		events: eventbus.new()
		rest: rest.new(config.token)
	}

	for i in 0..shard_count {
		mut conn := gateway.new_connection(config.token, config.intents, i, shard_count)?
		conn.set_reciever(client)
		conn.on_hello(on_hello)
		conn.on_dispatch(on_dispatch)
		client.shards << conn
	}

	return client
}

// Creates a websocket connection to Discord
pub fn (mut client Client) open() ? {
	for i in 0..client.shards.len {
		go client.shards[i].open()?
		time.sleep(5)
	}

	mut wg := sync.new_waitgroup()
	wg.add(1)
	wg.wait()
}