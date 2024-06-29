/// Module: transferable_vesting_contract
module transferable_vesting_contract::transferable_vesting_contract {
    use sui::balance::Balance;
    use sui::coin::{Coin};
    use sui::clock::{Self, Clock};

    // @dev Thrown if the airdrop creator tries create an airdrop in the past.
    const EInvalidStartTime: u64 = 2;

    public struct TransferableVestingContract<phantom T> has key, store {
        id: UID,
        // Total amount of vesting coins
        balance: Balance<T>,
        // The beginning of the linear vesting schedule.
        start: u64,
        // The duration of the vesting schedule.
        duration: u64,
    }

    public struct AdminCap has key {
        id: UID,
    }

    fun init(ctx: &mut TxContext) {
        let admin_cap = AdminCap {
            id: object::new(ctx)
        };
        transfer::transfer(admin_cap, ctx.sender())
    }

    public fun new<T>(coin: Coin<T>, start: u64, duration: u64, c: &Clock, ctx: &mut TxContext): TransferableVestingContract<T> {
        assert!(start > c.timestamp_ms(), EInvalidStartTime);
        TransferableVestingContract {
            id: object::new(ctx),
            balance: coin.into_balance(),
            start,
            duration,
        }
    }

    // === Public View Functions ===
    public fun balance<T>(self: &TransferableVestingContract<T>): u64 {
        self.balance.value()
    }

    #[test]
    fun test_transferable_vesting_contract() {
        use sui::test_utils::assert_eq;
        use sui::test_scenario::{Self as test, next_tx, ctx};
        use sui::coin::mint_for_testing;
        use sui::sui::SUI;

        let admin = @0xAD;

        let mut scenario = test::begin(admin);
        let test = &mut scenario;

        let mut c = clock::create_for_testing(ctx(test));

        next_tx(test, admin);
        {
            let coin = mint_for_testing<SUI>(100, ctx(test));
            let start = 1000;
            let duration = 1000;
            let contract = new(coin, start, duration, &c, scenario.ctx());

            assert_eq(contract.balance(), 100);
            // assert!(contract.start() == 1000);
            // assert!(contract.duration() == 1000);

            clock::increment_for_testing(&mut c, 1);
            transfer::public_share_object(contract);
        };

        clock::destroy_for_testing(c);
        test::end(scenario);
    }
}
