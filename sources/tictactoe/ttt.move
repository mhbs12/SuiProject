module 0x0::ttt;
use sui::sui::SUI;
use sui::coin::Coin;
use 0x0::main::Control;
use 0x0::main;


public struct Game has key {
    id: UID,
    board: vector<u8>,
    turn: u8,
    x: address,
    o: address,
}


public struct Trophy has key {
    id: UID,
    status: u8,
    board: vector<u8>,
    turn: u8,
    other: address,
}


const MARK__: u8 = 0;
const MARK_X: u8 = 1;
const MARK_O: u8 = 2;


const TROPHY_NONE: u8 = 0;
const TROPHY_DRAW: u8 = 1;
const TROPHY_WIN: u8 = 2;



#[error]
const EInvalidLocation: vector<u8> = b"Move was for a position that doesn't exist on the board.";

#[error]
const EWrongPlayer: vector<u8> = b"Game expected a move from another player";

#[error]
const EAlreadyFilled: vector<u8> = b"Attempted to place a mark on a filled slot.";

#[error]
const ENotFinished: vector<u8> = b"Game has not reached an end condition.";

#[error]
const EAlreadyFinished: vector<u8> = b"Can't place a mark on a finished game.";

#[error]
const EInvalidEndState: vector<u8> = b"Game reached an end state that wasn't expected.";

entry fun start_bttt(coin: Coin<SUI>, amount: u64, ctx: &mut TxContext){
    main::create_bet(coin, amount, ctx);
}
entry fun join_bttt(coin: Coin<SUI>, amount: u64, control: &mut Control, ctx: &mut TxContext){
    let x = main::sender1(control);
    main::join_bet(coin, amount, control, ctx);
    new(x, ctx);
}
public fun new(x: address, ctx: &mut TxContext) {
    transfer::share_object(Game {
        id: object::new(ctx),
        board: vector[MARK__, MARK__, MARK__, MARK__, MARK__, MARK__, MARK__, MARK__, MARK__],
        turn: 0,
        x,
        o: tx_context::sender(ctx),
    });
}
entry fun play(game: Game, gamer: &mut Game, control: Control, controlr: &mut Control, row: u8, col: u8, ctx: &mut TxContext){
    let x = place_mark(gamer, controlr, row, col ,ctx);
    if (x == TROPHY_WIN) {
        burn(game, control);
    } else if (x == TROPHY_DRAW) {
        burn(game, control);
    } else {
        transfer::share_object(game);
        main::share_control(control);
    }
}


public(package) fun place_mark(game: &mut Game, control: &mut Control, row: u8, col: u8, ctx: &mut TxContext): u8 {
    assert!(game.ended() == TROPHY_NONE, EAlreadyFinished);
    assert!(row < 3 && col < 3, EInvalidLocation);
  
    let (me, them, sentinel) = game.next_player();
    assert!(me == ctx.sender(), EWrongPlayer);

    if (game[row, col] != MARK__) {
        abort EAlreadyFilled
    };

    *(&mut game[row, col]) = sentinel;
    game.turn = game.turn + 1;

    
    let end = game.ended();
    if (end == TROPHY_WIN) {
        main::winner(me, control);
        main::finish_game(control, ctx);
        transfer::transfer(game.mint_trophy(end, them, ctx), me);
        
    } else if (end == TROPHY_DRAW) {
        main::draw(control, ctx);
        transfer::transfer(game.mint_trophy(end, them, ctx), me);
        transfer::transfer(game.mint_trophy(end, me, ctx), them);
        
    } else if (end != TROPHY_NONE) {
        abort EInvalidEndState
    };
    end
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


fun mint_trophy(game: &Game, status: u8, other: address, ctx: &mut TxContext): Trophy {
    Trophy {
        id: object::new(ctx),
        status,
        board: game.board,
        turn: game.turn,
        other,
    }
}

public fun burn(game: Game, control: Control) {
    assert!(game.ended() != TROPHY_NONE, ENotFinished);
    let Game { id, .. } = game;
    object::delete(id);
    main::destroy(control);
}


public fun ended(game: &Game): u8 {
    if (
        test_triple(game, 0, 1, 2) ||
            test_triple(game, 3, 4, 5) ||
            test_triple(game, 6, 7, 8) ||
            
            test_triple(game, 0, 3, 6) ||
            test_triple(game, 1, 4, 7) ||
            test_triple(game, 2, 5, 8) ||
            
            test_triple(game, 0, 4, 8) ||
            test_triple(game, 2, 4, 6)) {
        TROPHY_WIN
    } else if (game.turn == 9) {
        TROPHY_DRAW
    } else {
        TROPHY_NONE
    }
}

#[syntax(index)]
public fun mark(game: &Game, row: u8, col: u8): &u8 {
    &game.board[(row * 3 + col) as u64]
}

#[syntax(index)]
fun mark_mut(game: &mut Game, row: u8, col: u8): &mut u8 {
    &mut game.board[(row * 3 + col) as u64]
}


#[test_only]
public use fun game_board as Game.board;
#[test_only]
public use fun trophy_status as Trophy.status;
#[test_only]
public use fun trophy_board as Trophy.board;
#[test_only]
public use fun trophy_turn as Trophy.turn;
#[test_only]
public use fun trophy_other as Trophy.other;

#[test_only]
public fun game_board(game: &Game): vector<u8> {
    game.board
}

#[test_only]
public fun trophy_status(trophy: &Trophy): u8 {
    trophy.status
}

#[test_only]
public fun trophy_board(trophy: &Trophy): vector<u8> {
    trophy.board
}

#[test_only]
public fun trophy_turn(trophy: &Trophy): u8 {
    trophy.turn
}

#[test_only]
public fun trophy_other(trophy: &Trophy): address {
    trophy.other
}


