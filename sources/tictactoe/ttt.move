module 0x0::ttt;

use sui::sui::SUI;
use sui::coin::Coin;
use sui::clock::Clock;
use 0x0::main::Control;
use 0x0::main;
use sui::clock::timestamp_ms;
use 0x0::profile;
use 0x0::profile::PlayerRegistry;

public struct Game has key {
    id: UID,
    last_move_timestamp: u64,
    board: vector<u8>,
    turn: u8,
    x: address,
    o: address,
}

const MARK__: u8 = 0;
const MARK_X: u8 = 1;
const MARK_O: u8 = 2;

const NONE: u8 = 0;
const DRAW: u8 = 1;
const WIN: u8 = 2;

const TIMEOUT: u64 = 30_000; //30s (30s only for tests okayy!!)

#[syntax(index)]
public fun mark(game: &Game, row: u8, col: u8): &u8 {
    &game.board[(row * 3 + col) as u64]
}

#[syntax(index)]
fun mark_mut(game: &mut Game, row: u8, col: u8): &mut u8 {
    &mut game.board[(row * 3 + col) as u64]
}

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

#[error]
const EInvalidLocation: vector<u8> = b"Move was for a position that doesn't exist on the board.";

#[error]
const EWrongPlayer: vector<u8> = b"Game expected a move from another player";

#[error]
const EAlreadyFilled: vector<u8> = b"Attempted to place a mark on a filled slot.";

#[error]
const EAlreadyFinished: vector<u8> = b"Can't place a mark on a finished game.";

#[error]
const EInvalidEndState: vector<u8> = b"Game reached an end state that wasn't expected.";

#[error]
const ETimeoutNotReached: vector<u8> = b"The timeout period has not been reached yet.";

#[error]
const ESameAddress: vector<u8> = b"The address has to be different";

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

entry fun start_bttt(coin: Coin<SUI>, amount: u64, registry: &mut PlayerRegistry, ctx: &mut TxContext){
    main::create_bet(coin, amount, ctx);
    profile::get_or_create_profile(registry, ctx);
}

entry fun join_bttt(coin: Coin<SUI>, amount: u64, control: &mut Control, registry: &mut PlayerRegistry, clock: &Clock, ctx: &mut TxContext){
    let x = main::sender1(control);
    assert!(tx_context::sender(ctx) != x, ESameAddress);
    profile::get_or_create_profile(registry, ctx);
    main::join_bet(coin, amount, control, ctx);
    new(x, clock, ctx);
}

entry fun place_mark(mut game: Game, mut control: Control, registry: &mut PlayerRegistry, clock: &Clock, row: u8, col: u8, ctx: &mut TxContext){
    assert!(game.ended() == NONE, EAlreadyFinished);
    assert!(row < 3 && col < 3, EInvalidLocation);
    let (me, them, sentinel) = game.next_player();
    assert!(me == ctx.sender(), EWrongPlayer);
    if (game[row, col] != MARK__) {
        abort EAlreadyFilled
    };
    *(&mut game[row, col]) = sentinel;
    game.turn = game.turn + 1;
    game.last_move_timestamp = timestamp_ms(clock);
    let end = game.ended();
    if (end == WIN) {
        main::winner(me, &mut control);
        profile::register_win(registry, me);
        profile::register_loss(registry, them);
        main::finish_game(&mut control, ctx);
        burn(game,control);
    } else if (end == DRAW) {
        main::draw(&mut control, ctx);
        profile::register_draw(registry, me, them);
        burn(game,control);
    } else if (end == NONE) {
        transfer::share_object(game);
        main::share_control(control);
    } else {
        abort EInvalidEndState
    };
}

entry fun claim_by_timeout(game: Game, mut control: Control, registry: &mut PlayerRegistry, clock: &Clock, ctx: &mut TxContext) {
    let current_time = timestamp_ms(clock);
    let time_since_last_move = current_time - game.last_move_timestamp;
    assert!(time_since_last_move >= TIMEOUT, ETimeoutNotReached);
    let (next_player_addr, waiting_player_addr, _) = game.next_player();
    assert!(tx_context::sender(ctx) == waiting_player_addr, EWrongPlayer);
    let me = waiting_player_addr;
    let them = next_player_addr;
    main::winner(me, &mut control);
    main::finish_game(&mut control, ctx);
    profile::register_win(registry, me);
    profile::register_loss(registry, them);
    burn(game, control);
}

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

fun new(x: address, clock: &Clock, ctx: &mut TxContext) {
    transfer::share_object(Game {
        id: object::new(ctx),
        last_move_timestamp: timestamp_ms(clock),
        board: vector[MARK__, MARK__, MARK__, MARK__, MARK__, MARK__, MARK__, MARK__, MARK__],
        turn: 0,
        x,
        o: tx_context::sender(ctx),
    });
}

fun next_player(game: &Game): (address, address, u8) {
    if (game.turn % 2 == 0) {
        (game.x, game.o, MARK_X)
    } else {
        (game.o, game.x, MARK_O)
    }
}

fun test_triple(game: &Game, x: u8, y: u8, z: u8): bool {
    let x = game.board[x as u64];
    let y = game.board[y as u64];
    let z = game.board[z as u64];

    MARK__ != x && x == y && y == z
}

fun burn(game: Game, control: Control) {
    let Game { id, .. } = game;
    object::delete(id);
    main::destroy(control);
}

fun ended(game: &Game): u8 {
    if (
        test_triple(game, 0, 1, 2) ||
            test_triple(game, 3, 4, 5) ||
            test_triple(game, 6, 7, 8) ||
            
            test_triple(game, 0, 3, 6) ||
            test_triple(game, 1, 4, 7) ||
            test_triple(game, 2, 5, 8) ||
            
            test_triple(game, 0, 4, 8) ||
            test_triple(game, 2, 4, 6)) {
        WIN
    } else if (game.turn == 9) {
        DRAW
    } else {
        NONE
    }
}


