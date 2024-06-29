/// Module: transferable_vesting_contract
module transferable_vesting_contract::transferable_vesting_contract {
    // use sui::balance::Balance;
    use sui::coin::{Coin};
    use sui::clock::{Self, Clock};
    use sui::sui::{SUI};

    // @dev Thrown if the airdrop creator tries create an airdrop in the past.
    const EInvalidStart: u64 = 2;

    // The beginning of the linear vesting schedule.
    const Receiver: address = @0xACE;
    const Start: u64 = 1719565200000; // 2024-06-28 18:00:00 JST
    // const Duration: u64 = 1000;
    // const Step: u64 = 5;
    const Amount: u64 = 7;

    public fun transfer_coin(coin: &mut Coin<SUI>, c: &Clock, ctx: &mut TxContext) {
        assert!(Start <= clock::timestamp_ms(c), EInvalidStart);
        let sendingCoin = coin.split(Amount, ctx);
        transfer::public_transfer(sendingCoin, Receiver);
    }
}
