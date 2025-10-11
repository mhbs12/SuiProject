module 0x0::main;

use sui::sui::SUI;
use sui::coin::{Self, Coin};
use sui::balance::{Self, Balance};


public struct Control has key{
    id: UID,
    winner: Option<address>,
    balance: Balance<SUI>,
    sender1: address,
    amount1: u64,
    sender2: Option<address>,
    amount2: u64,
}

public fun create_bet(mut coin: Coin<SUI>, amount: u64, ctx: &mut TxContext) {
    assert!(amount > 0, 1);
    assert!(coin.value() >= amount, 2);
    let stake = coin::split(&mut coin, amount, ctx);
    let value = coin::into_balance(stake);        
    let c = Control { 
        id: object::new(ctx),
        winner: option::none<address>(), 
        balance: value,
        sender1: tx_context::sender(ctx),
        amount1: amount,
        sender2: option::none<address>(),
        amount2: 0,
    };
    transfer::public_transfer(coin, tx_context::sender(ctx));
    transfer::share_object(c);
    

}
public fun join_bet(mut coin: Coin<SUI>, amount: u64, control: &mut Control, ctx: &mut TxContext) {
    assert!(balance::value(&control.balance) <= amount, 2);
    let stake = coin::split(&mut coin, amount, ctx);
    let value = coin::into_balance(stake);
    control.sender2 = option::some(tx_context::sender(ctx));
    control.amount2 = amount;
    balance::join(&mut control.balance, value);
    transfer::public_transfer(coin, tx_context::sender(ctx));
}

public(package) fun winner(winner: address, control: &mut Control){
    control.winner = option::some(winner);

}
public(package) fun sender1(control: &Control): address {
        control.sender1
}
public fun draw(control: &mut Control, ctx: &mut TxContext) {
    assert!(option::is_some(&control.sender2), 5);
    let sender2_addr = option::extract(&mut control.sender2);
    let coin2_balance = balance::split(&mut control.balance, control.amount2);
    let coin2: Coin<SUI> = coin::from_balance(coin2_balance, ctx);
    transfer::public_transfer(coin2, sender2_addr);
    assert!(balance::value(&control.balance) == control.amount1, 6);
    let coin1_balance = balance::withdraw_all(&mut control.balance);
    let coin1: Coin<SUI> = coin::from_balance(coin1_balance, ctx);
    transfer::public_transfer(coin1, control.sender1);
    control.amount1 = 0;
    control.amount2 = 0;
}

public(package) fun finish_game(control: &mut Control, ctx: &mut TxContext) {
    assert!(option::is_some(&control.winner), 3);
    let winner_address = *option::borrow(&control.winner);
    let amount = control.balance.value();
    let prize = coin::take(&mut control.balance, amount, ctx);
    transfer::public_transfer(prize, winner_address);
}
public(package) fun destroy(control: Control){
    let Control {id, balance, ..} = control;
    balance::destroy_zero(balance);
    object::delete(id);
}
public(package) fun share_control(control: Control) {
        transfer::share_object(control);
}

