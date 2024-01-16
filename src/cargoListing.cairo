use starknet::ContractAddress;

// this is the Cargo struct that will be stored in the contract
#[derive(Drop, Serde, Copy, starknet::Store)]
struct Cargo {
    id: u32,
    weight: felt256,
    size: felt256,
    origin: location,
    destination: location,
    owner: ContractAddress,
    status: CargoStatus,
    }

// this is the location struct that will be used in the contract
#[derive(Drop, Serde, Copy, starknet::Store)]
struct location {
    latitude: felt256,
    longitude: felt256,
}

enum CargoStatus {
        Available,
        Matched,
        InTransit,
        Unavailable,
        Delivered,
    }

// this is the interface that will be used in the contract
#[starknet::interface]
trait ICargoListing<TContractState> {
    fn get_cargo(self : @TContractState, listing_id: u32) -> Cargo;
    fn add_cargo(ref self : TContractState, weight: u32, size: u32, destination: u64);
    fn update_cargo(ref self : TContractState, listing_id: u32, weight: u32, size: u3, destination: u64);
    fn remove_cargo(ref self : TContractState, listing_id: u32);
}

// this is the implementation of the interface
#[starknet::contract]
mod CargoListing {
    use starknet::ContractAddress;
    use starknet::get_caller_address;
    use super::Cargo;

    #[storage]
    struct Storage {
        next_cargo_id: u32,
        cargo_listing: LegacyMap::<u32, Cargo>,
    }

    #[constructor]
    fn constructor(ref self : ContractState) {
        self.next_cargo_id.write(1);
    }

    #[abi(embed_v0)]
    impl CargoListingImpl of super::ICargoListing<ContractState>{       
        
        // this function will get the cargo from the list
        fn get_cargo(self : @ContractState, listing_id: u32) -> Cargo {
           return self.cargo_listing.read(listing_id);
        }

        // this function will add a new cargo to the list
        fn add_cargo(ref self : ContractState, weight: u32, size: u32, destination: u64) {
            let caller = get_caller_address();
            let id = self.next_cargo_id.read();
            let cargo = Cargo {
                id: id,
                weight: weight,
                size: size,
                destination: destination,
                owner: caller,
            };
            self.cargo_listing.write(cargo.id, cargo);
            self.next_cargo_id.write(id + 1);
        }

        // this function will update the cargo in the list
        fn update_cargo(ref self : ContractState, listing_id: u32, weight: u32, size: u3, destination: u64) {
            let caller = get_caller_address();
            let cargo = self.cargo_listing.read(listing_id);
            if cargo.owner!= caller {
                return;
            }
            let cargo = Cargo {
                id: cargo.id,
                weight: weight,
                size: size,
                destination: destination,
                owner: caller,
                };
            self.cargo_listing.write(cargo.id, cargo);
        }

        // this function will remove the cargo from the list


    }
}