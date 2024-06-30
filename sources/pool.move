module transferable_vesting_contract::pool {

    use sui::balance::{Balance};
    use sui::sui::SUI;
    use sui::coin::{Coin};

    // Error codes
    const EInsufficientBalance: u64 = 0;

    /// Configuration and Pool object, managed by the house.
    public struct Pool has key {
        id: UID,
        balance: Balance<SUI>, // House's balance which also contains the acrued winnings of the house.
    }

    /// A one-time use capability to initialize the house data; created and sent
    /// to sender in the initializer.
    public struct PoolCap has key {
        id: UID
    }

    fun init(ctx: &mut TxContext) {
        // Creating and sending the PoolCap object to the sender.
        let pool_cap = PoolCap {
            id: object::new(ctx)
        };

        transfer::transfer(pool_cap, ctx.sender());
    }

    // Functions

    /// Initializer function that should only be called once and by the creator of the contract.
    /// Initializes the pool object with the balance.
    public fun initialize_pool(pool_cap: PoolCap, coin: &mut Coin<SUI>, amount: u64, ctx: &mut TxContext) {
        assert!(coin.value() > 0, EInsufficientBalance);
        assert!(amount > 0, EInsufficientBalance);
        assert!(amount <= coin.value(), EInsufficientBalance);

        let pool = Pool {
            id: object::new(ctx),
            balance: coin.split(amount, ctx).into_balance(),
        };

        let PoolCap { id } = pool_cap;
        object::delete(id);

        transfer::share_object(pool);
    }

    // --------------- Pool Mutations ---------------

    /// Returns a mutable reference to the balance of the house.
    public(package) fun borrow_balance_mut(pool: &mut Pool): &mut Balance<SUI> {
        &mut pool.balance
    }

    /// Returns a mutable reference to the house id.
    public(package) fun borrow_mut(pool: &mut Pool): &mut UID {
        &mut pool.id
    }

    // --------------- Pool Accessors ---------------

    /// Returns a reference to the house id.
    public(package) fun borrow(pool: &Pool): &UID {
        &pool.id
    }

    /// Returns the balance of the house.
    public fun balance(pool: &Pool): u64 {
        pool.balance.value()
    }
}
