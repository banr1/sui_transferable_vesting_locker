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
    const Interval: u64 = 60 * 60 * 24 * 30 * 1000; // 30 days
    // const Step: u64 = 5;
    const Amount: u64 = 7;

    public struct Counter has key {
        id: UID,
        count: u64,
    }

    fun init(ctx: &mut TxContext) {
        let counter = Counter { id: object::new(ctx), count: 0 };
        transfer::share_object(counter);
    }

    public fun transfer_coin(coin: &mut Coin<SUI>, clock_object: &Clock, counter: &mut Counter, ctx: &mut TxContext) {
        assert!(Start + counter.count * Interval <= clock::timestamp_ms(clock_object), EInvalidStart);
        let sendingCoin = coin.split(Amount, ctx);
        transfer::public_transfer(sendingCoin, Receiver);
        counter.increment();
    }

    /// Internal function to increment the counter by 1.
    public fun increment(self: &mut Counter) {
        self.count = self.count + 1;
    }
}
