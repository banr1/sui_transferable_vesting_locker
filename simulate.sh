#!/bin/zsh

# コマンドの出力を変数に格納
output1=$(sui client publish --gas-budget 50000000 --skip-dependency-verification)

# PackageIDを抽出
package_id=$(echo "$output1" | grep "PackageID:" | awk '{print $4}')

# ObjectIDを抽出
counter_object_id=$(echo "$output1" | grep -m 2 "ObjectID:" | sed -n '2p' | awk '{print $4}')

echo "PackageID: $package_id"
echo "ObjectID (Counter): $counter_object_id"

# transfer_coinを実行
echo "transfer_coinを実行します"
sui client ptb --move-call "${package_id}::transferable_vesting_contract::transfer_coin" @0xf1fe3f1380e7801e95ad6a6b8ff42a65c24be5bbf13e58a63f26319313eb9e48 @0x6 @${counter_object_id} --gas-budget 10000000
