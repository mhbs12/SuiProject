module 0x0::twoproom {
    use sui::object::{Self, UID};
    use sui::transfer;
    use sui::tx_context::{Self, TxContext};
    use std::option::{Self, Option};


    public struct Room has key, store {
        id: UID,
        player1: address,
        player2: Option<address>,
    }

    const ERoomFull: u64 = 0;
    public entry fun create_room(ctx: &mut TxContext) {
        let sender = tx_context::sender(ctx);
        let room = Room {
            id: object::new(ctx),
            player1: sender,
            player2: option::none(),
        };
        transfer::share_object(room);
    }

    public entry fun join_room(room: &mut Room, ctx: &mut TxContext) {
        let sender = tx_context::sender(ctx);
        assert!(option::is_none(&room.player2), ERoomFull);
        room.player2 = option::some(sender);
    }

    public fun player1(room: &Room): address {
        room.player1
    }
    public fun player2(room: &Room): Option<address> {
        room.player2
    }
    public fun is_full(room: &Room): bool {
        option::is_some(&room.player2)
    }
}