module 0x0::main;

use sui::sui::SUI;
use sui::coin::{Self, Coin};
use sui::balance::{Self, Balance};
use sui::tx_context::{Self, TxContext};
use sui::transfer;
use sui::object::{Self, UID};
use std::option::{Self, Option};

public struct Control has key{
    id: UID,
    winner: Option<address>,
    balance: Balance<SUI>,
}


entry fun criar_aposta(mut coin: Coin<SUI>, amount: u64, ctx: &mut TxContext) {
    assert!(amount > 0, EInvalidAmount);
    assert!(coin.value() >= amount, EInsufficientBalance);
    let stake = coin::split(&mut coin, amount, ctx);
    let value = coin::into_balance(stake);        
    let c = Control { 
        id: object::new(ctx),
        winner: option::none<address>, 
        balance: value,
    };
    transfer::public_transfer(coin, tx_context::sender(ctx));
    transfer::share_object(c);
    

}
entry fun entrar_aposta(mut coin: Coin<SUI>, amount: u64, control: &mut Control, ctx: &mut TxContext) {
    assert!(balance::value(&control.balance) <= amount, EInsufficientBalance);
    let stake = coin::split(&mut coin, amount, ctx);
    let value = coin::into_balance(stake);
    balance::join(&mut control.balance, value);
    transfer::public_transfer(coin, tx_context::sender(ctx));
}

entry fun finish_game(winner: address, treasury: Treasury, ctx: &mut TxContext) {
    assert!(tx_context::sender(ctx) == winner, 10);
    let Treasury {id,balance} = treasury;
    object::delete(id);
    let prize = coin::from_balance(balance, ctx);
    transfer::public_transfer(prize, winner);
}
