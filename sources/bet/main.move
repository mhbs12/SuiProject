module 0x0::main;

use sui::sui::SUI;
use sui::coin::{Self, Coin};
use sui::balance::{Self, Balance};

public struct Control has key{
    id: UID,
    winner: Option<address>,
    balance: Balance<SUI>,
}


entry fun criar_aposta(mut coin: Coin<SUI>, amount: u64, ctx: &mut TxContext) {
    assert!(amount > 0, 1);
    assert!(coin.value() >= amount, 2);
    let stake = coin::split(&mut coin, amount, ctx);
    let value = coin::into_balance(stake);        
    let c = Control { 
        id: object::new(ctx),
        winner: option::none<address>(), 
        balance: value,
    };
    transfer::public_transfer(coin, tx_context::sender(ctx));
    transfer::share_object(c);
    

}
entry fun entrar_aposta(mut coin: Coin<SUI>, amount: u64, control: &mut Control, ctx: &mut TxContext) {
    assert!(balance::value(&control.balance) <= amount, 2);
    let stake = coin::split(&mut coin, amount, ctx);
    let value = coin::into_balance(stake);
    balance::join(&mut control.balance, value);
    transfer::public_transfer(coin, tx_context::sender(ctx));
}
public(package) fun winner(winner: address, control: &mut Control){
    control.winner = option::some(winner);

}

public(package) fun finish_game(control: Control, ctx: &mut TxContext) {
    let Control { id, winner, balance } = control;
    object::delete(id);
    
    let winner_address = option::destroy_some(winner);  
    let prize = coin::from_balance(balance, ctx);
    transfer::public_transfer(prize, winner_address);
}
