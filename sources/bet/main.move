module 0x0::main;

use sui::sui::SUI;
use sui::coin::{Self, Coin};
use sui::balance::{Self, Balance};
use sui::tx_context::{Self, TxContext};
use sui::transfer;
use sui::object::{Self, UID};

public struct Treasury has key{
    id: UID,
    balance: Balance<SUI>,
}

public entry fun criar_aposta(mut coin: Coin<SUI>, amount: u64, ctx: &mut TxContext) {
    let stake = coin::split(&mut coin, amount, ctx);
    let value = coin::into_balance(stake);        
    let t = Treasury { 
        id: object::new(ctx), 
        balance: value 
    };
    transfer::public_transfer(coin, tx_context::sender(ctx));
    transfer::share_object(t);
}

public entry fun entrar_aposta(treasury: &mut Treasury, mut coin: Coin<SUI>, amount: u64, ctx: &mut TxContext) {
    assert!(balance::value(&treasury.balance) <= amount, 1);
    let stake = coin::split(&mut coin, amount, ctx);
    let value = coin::into_balance(stake);
    balance::join(&mut treasury.balance, value);
    transfer::public_transfer(coin, tx_context::sender(ctx));
}

public entry fun finish_game(winner: address, treasury: Treasury, ctx: &mut TxContext) {
    let Treasury { id, balance: total_balance } = treasury;
    object::delete(id);
    let prize = coin::from_balance(total_balance, ctx);
    transfer::public_transfer(prize, winner);
}
