#!/bin/zsh

csv_file="input.csv"

output1=$(sui client publish --gas-budget 50000000 --skip-dependency-verification)

# Extract PackageID
package_id=$(echo "$output1" | grep "PackageID:" | awk '{print $4}')
echo "PackageID: $package_id"

# Define common variables
coin_object_id=0xf766d83eff18fb2936c3e45805f387d29540c8b0811120a007ee45742409b402
start=1719565200000 # Fri Jun 28 2024 18:00:00 GMT+0900
interval=86400000 # 60 * 60 * 24 * 1000 (1 day)
step=2
# interval=2592000000 # 60 * 60 * 24 * 30 * 1000 (1 month)
# step=60

# Read CSV file and execute new and transfer functions
while IFS=',' read -r receiver amount_per_step
do
    # Skip the first line
    if $is_first_line; then
        is_first_line=false
        continue
    fi

    echo "Processing: Receiver=$receiver, Amount=$amount_per_step"

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

    echo "----------------------------------------"
done < "$csv_file"
