#!/bin/zsh

# PackageIDを取得
PACKAGE_ID=$(sui client publish --gas-budget 50000000 --skip-dependency-verification | grep PackageID | grep -o 'PackageID: [^ ]*' | cut -d' ' -f2)
echo "取得したPackageID: $PACKAGE_ID"

# transfer_coinを実行
echo "transfer_coinを実行します"
sui client ptb --move-call "${PACKAGE_ID}::transferable_vesting_contract::transfer_coin" @0xf1fe3f1380e7801e95ad6a6b8ff42a65c24be5bbf13e58a63f26319313eb9e48 @0x6 --gas-budget 10000000
