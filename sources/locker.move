module transferable_vesting_locker::locker {
    use sui::coin::{Self, Coin};
    use sui::balance::{Balance};
    use sui::clock::{Self, Clock};

    // Error codes
    // Thrown if the airdrop creator tries to create an airdrop with more than the maximum number of steps.
    const EStepOverflow: u64 = 0;
    // Thrown if the airdrop creator tries create an airdrop in the past.
    const EInvalidStart: u64 = 1;
    // Thrown if the airdrop creator tries to create an airdrop with more than the maximum number of steps.
    const EInsufficientBalance: u64 = 2;

    // Locker struct
    public struct Locker<phantom T> has key {
        id: UID,
        receiver: address,
        start: u64,
        interval: u64,
        step: u64,
        amount_per_step: u64,
        original_balance: u64,
        current_step_count: u64,
        current_balance: Balance<T>
    }

    // Transfers the next step of the locked coin to the receiver
    public fun transfer<T>(locker: &mut Locker<T>, clock_object: &Clock, ctx: &mut TxContext) {
        assert!(locker.start + locker.current_step_count * locker.interval <= clock::timestamp_ms(clock_object), EInvalidStart);
        locker.current_step_count = locker.current_step_count + 1;
        assert!(locker.current_step_count <= locker.step, EStepOverflow);
        transfer::public_transfer(coin::take(&mut locker.current_balance, locker.amount_per_step, ctx), locker.receiver)
    }

    // Creates a new locker
    // Deposits and locks an existing coin for a specified duration
    public fun new<T>(coin: &mut Coin<T>, receiver: address, amount_per_step: u64, start: u64, interval: u64, step: u64, ctx: &mut TxContext) {
        let original_balance = amount_per_step * step;
        assert!(original_balance <= coin.value(), EInsufficientBalance);

        transfer::share_object(Locker {
            id: object::new(ctx),
            receiver,
            start,
            interval,
            step,
            amount_per_step,
            original_balance,
            current_step_count: 0,
            current_balance: coin.split(original_balance, ctx).into_balance()
        });
    }
}
