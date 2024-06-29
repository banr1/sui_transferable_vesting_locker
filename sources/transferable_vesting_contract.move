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
}
