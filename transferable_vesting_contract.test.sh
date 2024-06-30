#!/bin/zsh

# 変数定義
coin_object_id=0xeab0d58fbc3ae2d24c24c5960c24ab7ed04b6c7f72dc7f7ec24a5a0afe270b00

# コマンドの出力を変数に格納
output1=$(sui client publish --gas-budget 50000000 --skip-dependency-verification)

# PackageIDを抽出
package_id=$(echo "$output1" | grep "PackageID:" | awk '{print $4}')

# CounterのObjectIDを抽出
counter_object_id=$(echo "$output1" | grep -A 30 "Created Objects:" | grep -B 3 "Counter" | grep "ObjectID:" | head -n 1 | awk '{print $4}')

echo "PackageID: $package_id"
echo "Counter ObjectID: $counter_object_id"

# transfer_coinを実行
echo "transfer_coinを実行します"
sui client ptb --move-call "${package_id}::transferable_vesting_contract::transfer_coin" "<0x2::sui::SUI>" @${coin_object_id} @0x6 @${counter_object_id} --gas-budget 10000000
sui client ptb --move-call "${package_id}::transferable_vesting_contract::transfer_coin" "<0x2::sui::SUI>" @${coin_object_id} @0x6 @${counter_object_id} --gas-budget 10000000

echo "PackageID: $package_id"
echo "Counter ObjectID: $counter_object_id"
