module 0x0::profile;

use sui::package;
use sui::table::{Self, Table};
use sui::dynamic_field as df;
use sui::display;
use std::string;

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

public struct ProfileCard has key, store {
    id: UID,
    profile_id: ID,
    player_address: address,
}

fun init(otw: PROFILE, ctx: &mut TxContext) {
    let registry = PlayerRegistry {
        id: object::new(ctx),
        profiles: table::new(ctx),
    };
    transfer::share_object(registry);
    let publisher = package::claim(otw, ctx);
    let mut display = display::new_with_fields<ProfileCard>(
        &publisher,
        vector[
            string::utf8(b"name"),
            string::utf8(b"description"),
            string::utf8(b"image_url"), 
            string::utf8(b"profile_id"),
            string::utf8(b"player")
        ],
        vector[
            string::utf8(b"Player Card"),
            string::utf8(b"This card proves your registration. Your stats are stored on-chain, linked to the profile_id attribute."),
            string::utf8(b"data:image/svg+xml;base64,PHN2ZyB3aWR0aD0iMjAwIiBoZWlnaHQ9IjIwMCIgdmlld0JveD0iMCAwIDIwMCAyMDAiIHhtbG5zPSJodHRwOi8vd3d3LnczLm9yZy8yMDAwL3N2ZyI+PGcgZmlsbD0ibm9uZSIgc3Ryb2tlPSJ3aGl0ZSIgc3Ryb2tlLXdpZHRoPSIxMCI+PHBhdGggZD0iTTY2LjYgMCB2IDIwMCIvPjxwYXRoIGQ9Ik0xMzMuMyAwIHYgMjAwIi8+PHBhdGggZD0iTTAgNjYuNiBoIDIwMCIvPjxwYXRoIGQ9Ik0wIDEzMy4zIGggMjAwIi8+PC9nPjwvc3ZnPg=="), // <- NOVA IMAGEM
            string::utf8(b"{profile_id}"),
            string::utf8(b"{player_address}")
        ],
        ctx
    );
    display::update_version(&mut display);
    transfer::public_freeze_object(display);
    
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
        let profile_id = object::id(&profile);
        
        table::add(&mut registry.profiles, player_address, profile_id);
        df::add(&mut registry.id, player_address, profile);

        let card = ProfileCard {
            id: object::new(ctx),
            profile_id: profile_id,
            player_address: player_address,
        };
        transfer::public_transfer(card, player_address);

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