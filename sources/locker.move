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
        // Unique identifier of the locker
        id: UID,
        // Address of the receiver
        receiver: address,
        // Start time of the locker
        start: u64,
        // Interval between each step
        // e.g. 60 * 60 * 24 * 1000 (1 day)
        interval: u64,
        // Total number of steps
        step: u64,
        // Amount of coin to transfer per step
        amount_per_step: u64,
        // Original balance of the locker
        // This is the total amount of coin that will be transferred to the receiver
        original_balance: u64,
        // Current step count
        // This is the number of steps that have been transferred to the receiver
        current_step_count: u64,
        // Current balance of the locker
        // This is the remaining balance of the locker
        current_balance: Balance<T>
    }

    // Transfers the next step of the locked coin to the receiver
    // The transfer is only allowed if the current time is greater than or equal to the start time of the locker
    // and the current step count is less than the total number of steps
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
