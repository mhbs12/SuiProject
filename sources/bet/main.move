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

#[error]
const EInvalidAmount: vector<u8> = b"The amount must be greater than 0.";

#[error]
const ENotEnoughBalance: vector<u8> = b"You don't have enough balance.";

#[error]
const EPlayerTwoNotJoined: vector<u8> = b"Cannot declare a draw because player two has not joined the bet.";

#[error]
const EBalanceInconsistencyOnDraw: vector<u8> = b"Balance inconsistency when processing a draw. The remaining amount does not match player one's stake.";

#[error]
const ENoWinnerDeclared: vector<u8> = b"Cannot finish the bet because no winner has been declared.";

#[error]
const EYouAreNotTheCreator: vector<u8> = b"This is illegal (ㆆ _ ㆆ)";

public(package) fun create_bet(mut coin: Coin<SUI>, amount: u64, ctx: &mut TxContext) {
    assert!(amount > 0, EInvalidAmount);
    assert!(coin.value() >= amount, ENotEnoughBalance);
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
    transfer::public_transfer(coin, tx_context::sender(ctx)); //i will CHANGE this!!!
    transfer::share_object(c);
}

public(package) fun join_bet(mut coin: Coin<SUI>, amount: u64, control: &mut Control, ctx: &mut TxContext) {
    assert!(balance::value(&control.balance) <= amount, ENotEnoughBalance);
    let stake = coin::split(&mut coin, amount, ctx);
    let value = coin::into_balance(stake);
    control.sender2 = option::some(tx_context::sender(ctx));
    control.amount2 = amount;
    balance::join(&mut control.balance, value);
    transfer::public_transfer(coin, tx_context::sender(ctx)); //i will CHANGE this!!!
}

public(package) fun winner(winner: address, control: &mut Control){
    control.winner = option::some(winner);

}

public(package) fun sender1(control: &Control): address {
        control.sender1
}

public(package) fun draw(control: &mut Control, ctx: &mut TxContext) {
    assert!(option::is_some(&control.sender2), EPlayerTwoNotJoined);
    let sender2_addr = option::extract(&mut control.sender2);
    let coin2_balance = balance::split(&mut control.balance, control.amount2);
    let coin2: Coin<SUI> = coin::from_balance(coin2_balance, ctx);
    transfer::public_transfer(coin2, sender2_addr);
    assert!(balance::value(&control.balance) == control.amount1, EBalanceInconsistencyOnDraw);
    let coin1_balance = balance::withdraw_all(&mut control.balance);
    let coin1: Coin<SUI> = coin::from_balance(coin1_balance, ctx);
    transfer::public_transfer(coin1, control.sender1);
    control.amount1 = 0;
    control.amount2 = 0;
}

public(package) fun finish_game(control: &mut Control, ctx: &mut TxContext) {
    assert!(option::is_some(&control.winner), ENoWinnerDeclared);
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

entry fun delete_and_claim(control: Control, ctx: &mut TxContext) {
    let sender = tx_context::sender(ctx);
    let Control { id, balance, sender1, sender2, .. } = control;
    assert!(option::is_none(&sender2), EPlayerTwoNotJoined);
    assert!(sender1 == sender, EYouAreNotTheCreator);
    assert!(balance::value(&balance) > 0, EInvalidAmount);
    let coin: Coin<SUI> = coin::from_balance(balance, ctx);
    transfer::public_transfer(coin, sender);
    object::delete(id);
}

