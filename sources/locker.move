module transferable_vesting_locker::locker {
    use std::string::String;
    use sui::balance::{Balance};
    use sui::clock::{Self, Clock};
    use sui::coin::{Self, Coin};
    use sui::vec_set::{Self, VecSet};

    // Error codes
    // Thrown when the current step count exceeds the total number of steps
    const EStepOverflow: u64 = 0;
    // Thrown when the current time is less than the each step time
    const EInvalidTiming: u64 = 1;
    // Thrown when the start time is invalid
    const EInvalidStartTime: u64 = 2;
    // Thrown when the balance is insufficient
    const EInvalidBalance: u64 = 3;
    // Thrown when the category is invalid
    const EInvalidCategory: u64 = 4;

    // Locker cap struct
    public struct LockerCap has key {
        id: UID,
    }

    // Category registry struct
    public struct CategoryRegistry has key {
        id: UID,
        categories: VecSet<String>,
    }

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
        steps: u64,
        // Amount of coin to transfer per step
        amount_per_step: u64,
        // Original balance of the locker
        // This is the total amount of coin that will be transferred to the receiver
        original_balance: u64,
        // Category of the locker
        category: String,
        // Current step count
        // This is the number of steps that have been transferred to the receiver
        current_steps_count: u64,
        // Current balance of the locker
        // This is the remaining balance of the locker
        current_balance: Balance<T>,
    }

    // Initializes the locker
    fun init(ctx: &mut TxContext) {
        let locker_cap = LockerCap { id: object::new(ctx) };
        let registry = CategoryRegistry {
            id: object::new(ctx),
            categories: vec_set::empty(),
        };
        transfer::share_object(registry);
        transfer::transfer(locker_cap, ctx.sender());
    }

    // Registers a new category
    // This is called by the owner of the locker cap
    public fun register_category(_: &LockerCap, registry: &mut CategoryRegistry, name: String) {
        assert!(name.length() > 0, EInvalidCategory);
        assert!(!registry.categories.contains(&name), EInvalidCategory);
        registry.categories.insert(name);
    }

    // Creates a new locker
    // Deposits and locks an existing coin for a specified duration
    public fun new<T>(
        _: &LockerCap,
        coin: Coin<T>,
        registry: &CategoryRegistry,
        receiver: address,
        amount_per_step: u64,
        start: u64,
        interval: u64,
        steps: u64,
        category: String,
        clock_object: &Clock,
        ctx: &mut TxContext
    ) {
        let original_balance = amount_per_step * steps;
        assert!(original_balance == coin.value(), EInvalidBalance);
        assert!(registry.categories.contains(&category), EInvalidCategory);
        assert!(clock::timestamp_ms(clock_object) <= start, EInvalidStartTime);

        transfer::share_object(Locker {
            id: object::new(ctx),
            receiver,
            start,
            interval,
            steps,
            amount_per_step,
            original_balance,
            category,
            current_steps_count: 0,
            current_balance: coin.into_balance(),
        });
    }

    // Transfers the next step of the locked coin to the receiver
    // The transfer is only allowed if the current time is greater than or equal to the start time of the locker
    // and the current step count is less than the total number of steps
    public fun transfer<T>(locker: &mut Locker<T>, clock_object: &Clock, ctx: &mut TxContext) {
        assert!(locker.start + locker.current_steps_count * locker.interval <= clock::timestamp_ms(clock_object), EInvalidTiming);
        locker.current_steps_count = locker.current_steps_count + 1;
        assert!(locker.current_steps_count <= locker.steps, EStepOverflow);

        transfer::public_transfer(coin::take(&mut locker.current_balance, locker.amount_per_step, ctx), locker.receiver)
    }
}
