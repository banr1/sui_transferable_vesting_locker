#!/bin/zsh

# 変数定義
coin_object_id=0xeab0d58fbc3ae2d24c24c5960c24ab7ed04b6c7f72dc7f7ec24a5a0afe270b00

# コマンドの出力を変数に格納
output1=$(sui client publish --gas-budget 50000000 --skip-dependency-verification)

# PackageIDを抽出
package_id=$(echo "$output1" | grep "PackageID:" | awk '{print $4}')

# PoolCapのObjectIDを抽出
pool_cap_object_id=$(echo "$output1" | grep -A 30 "Created Objects:" | grep -B 3 "PoolCap" | grep "ObjectID:" | head -n 1 | awk '{print $4}')

echo "PackageID: $package_id"
echo "PoolCap ObjectID: $pool_cap_object_id"

# initialize_poolを実行
echo "initialize_poolを実行します"
sui client ptb --move-call "${package_id}::pool::initialize_pool" @${pool_cap_object_id} @${coin_object_id} 11 --gas-budget 10000000

echo "PackageID: $package_id"
echo "PoolCap ObjectID: $pool_cap_object_id"
