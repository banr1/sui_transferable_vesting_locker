#!/bin/zsh

# Define variables
coin_object_id=0xf766d83eff18fb2936c3e45805f387d29540c8b0811120a007ee45742409b402
receiver=0x9b64f8c9ad1e042639f7fa108fa2bb803ea35012a9c8dc89a3c5a0084ea6875f
amount_per_step=7
start=1719565200000
interval=43200000 # 60 * 60 * 12 * 1000
step=2

output1=$(sui client publish --gas-budget 50000000 --skip-dependency-verification)

# Extract PackageID
package_id=$(echo "$output1" | grep "PackageID:" | awk '{print $4}')
echo "PackageID: $package_id"

# Execute new
echo "Execute new function"
output2=$(sui client ptb --move-call "${package_id}::locker::new" "<0x2::sui::SUI>" @${coin_object_id} @${receiver} ${amount_per_step} ${start} ${interval} ${step} --gas-budget 10000000)

# Extract Locker ObjectID
locker_object_id=$(echo "$output2" | grep -A 30 "Created Objects:" | grep -B 3 "Locker" | grep "ObjectID:" | head -n 1 | awk '{print $4}')
echo "Locker ObjectID: $locker_object_id"

# Execute transfer
echo "Execute transfer function (1st)"
sui client ptb --move-call "${package_id}::locker::transfer" "<0x2::sui::SUI>" @${locker_object_id} @0x6 --gas-budget 10000000

echo "Execute transfer function (2nd)"
sui client ptb --move-call "${package_id}::locker::transfer" "<0x2::sui::SUI>" @${locker_object_id} @0x6 --gas-budget 10000000

echo "Execute transfer function (3rd): This should fail"
sui client ptb --move-call "${package_id}::locker::transfer" "<0x2::sui::SUI>" @${locker_object_id} @0x6 --gas-budget 10000000

echo "PackageID: $package_id"
echo "Locker ObjectID: $locker_object_id"
