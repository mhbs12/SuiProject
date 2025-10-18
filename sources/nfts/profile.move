module 0x0::profile;

use sui::package;
use sui::table::{Self, Table};
use sui::dynamic_field as df;


public struct PROFILE has drop {}

public struct PlayerRegistry has key {
    id: UID,
    profiles: Table<address, ID>,
}

public struct PlayerProfile has key, store {
    id: UID, 
    ttt_wins: u64,
    ttt_losses: u64,
    ttt_draws: u64,
}

fun init(otw: PROFILE, ctx: &mut TxContext) {
    let registry = PlayerRegistry {
        id: object::new(ctx),
        profiles: table::new(ctx),
    };
    transfer::share_object(registry);
    let publisher = package::claim(otw, ctx);
    transfer::public_transfer(publisher, tx_context::sender(ctx));
}

public(package) fun get_or_create_profile(registry: &mut PlayerRegistry, ctx: &mut TxContext): ID {
    let player_address = tx_context::sender(ctx);
    if (table::contains(&registry.profiles, player_address)) {
        *table::borrow(&registry.profiles, player_address)
    } else {
        let profile = PlayerProfile {
            id: object::new(ctx),
            ttt_wins: 0,
            ttt_losses: 0,
            ttt_draws: 0,
        };
        df::add(&mut registry.id, player_address, profile);
        let profile_ref = df::borrow<address, PlayerProfile>(&registry.id, player_address);
        let profile_id = object::id(profile_ref);
        table::add(&mut registry.profiles, player_address, profile_id);
        profile_id
    }
}

public(package) fun register_win(registry: &mut PlayerRegistry, player: address) {
    let profile: &mut PlayerProfile = df::borrow_mut(&mut registry.id, player);
    win(profile);
}

public(package) fun register_draw(registry: &mut PlayerRegistry, player1: address, player2: address) {
    let profile1: &mut PlayerProfile = df::borrow_mut(&mut registry.id, player1);
    draw(profile1);
    let profile2: &mut PlayerProfile = df::borrow_mut(&mut registry.id, player2);
    draw(profile2);
}

public(package) fun register_loss(registry: &mut PlayerRegistry, player: address) {
    let profile: &mut PlayerProfile = df::borrow_mut(&mut registry.id, player);
    loss(profile);
}

public(package) fun get_profile_id(registry: &PlayerRegistry, player: address): ID {
    *table::borrow(&registry.profiles, player)
}

fun win(profile: &mut PlayerProfile) {
    profile.ttt_wins = profile.ttt_wins + 1;
}

fun draw(profile: &mut PlayerProfile) {
    profile.ttt_draws = profile.ttt_draws + 1;
}

fun loss(profile: &mut PlayerProfile) {
    profile.ttt_losses = profile.ttt_losses + 1;
}