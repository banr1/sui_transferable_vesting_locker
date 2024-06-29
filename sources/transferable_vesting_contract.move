/// Module: transferable_vesting_contract
module transferable_vesting_contract::transferable_vesting_contract {
  // use sui::coin::{Self, Coin};

  public struct AdminCap has key {
    id: UID,
  }

  fun init(ctx: &mut TxContext) {
    let admin_cap = AdminCap {
      id: object::new(ctx)
    };
    transfer::transfer(admin_cap, ctx.sender())
  }

  #[test]
  fun test_transferable_vesting_contract() {
    use sui::test_scenario;
    let admin = @0xAD;

    let mut scenario = test_scenario::begin(admin);
    {
        init(scenario.ctx());
    };

    scenario.end();
  }
}
