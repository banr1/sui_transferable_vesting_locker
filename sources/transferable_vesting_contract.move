/// Module: transferable_vesting_contract
module transferable_vesting_contract::transferable_vesting_contract {
    // use sui::balance::Balance;
    use sui::coin::{Coin};
    use sui::clock::{Self, Clock};

    // Error codes
    // Thrown if the airdrop creator tries to create an airdrop with more than the maximum number of steps.
    const EStepOverflow: u64 = 0;
    // Thrown if the airdrop creator tries create an airdrop in the past.
    const EInvalidStart: u64 = 1;

    const Receiver: address = @0xACE;
    const Start: u64 = 1719565200000; // 2024-06-28 18:00:00 JST
    // const Interval: u64 = 60 * 60 * 24 * 30 * 1000; // 30 days
    // const Step: u64 = 60;
    const Interval: u64 = 60 * 60 * 12 * 1000; // 0.5 days
    const Step: u64 = 2;
    const Amount: u64 = 7;

    public struct Counter has key {
        id: UID,
        count: u64,
    }

    fun init(ctx: &mut TxContext) {
        let counter = Counter { id: object::new(ctx), count: 0 };
        transfer::share_object(counter);
    }

    // Transfer a coin to the receiver if the counter is less than the maximum number of steps.
    public fun transfer_coin<T>(coin: &mut Coin<T>, clock_object: &Clock, counter: &mut Counter, ctx: &mut TxContext) {
        assert!(Start + counter.count * Interval <= clock::timestamp_ms(clock_object), EInvalidStart);
        let sendingCoin = coin.split(Amount, ctx);
        counter.increment();
        transfer::public_transfer(sendingCoin, Receiver);
    }

    /// Internal function to increment the counter by 1.
    fun increment(self: &mut Counter) {
        self.count = self.count + 1;
        assert!(self.count <= Step, EStepOverflow);
    }
}
