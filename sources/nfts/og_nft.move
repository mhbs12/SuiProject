module 0x0::og_nft;

use std::string::{Self, String};
use sui::url::{Self, Url};
use sui::table::{Self, Table};
use sui::display;
use sui::package;

#[error]
const EAlreadyHave: vector<u8> = b"You already have this NFT.";

public struct OG_NFT has drop {}
public struct OgNft has key { 
    id: UID, 
    name: String, 
    description: String, 
    image_url: Url 
}

public struct MintRegistry has key { 
    id: UID, 
    registry: Table<address, bool> 
}

fun init(witness: OG_NFT, ctx: &mut TxContext) {
    transfer::share_object(MintRegistry {
        id: object::new(ctx),
        registry: table::new(ctx),
    });
    let publisher = package::claim(witness, ctx);
    let mut display = display::new_with_fields<OgNft>(
        &publisher,
        vector[
            string::utf8(b"name"),
            string::utf8(b"description"),
            string::utf8(b"image_url")
        ],
        vector[
            string::utf8(b"{name}"),
            string::utf8(b"{description}"),
            string::utf8(b"{image_url}")
        ],
        ctx
    );

    display::update_version(&mut display);
    transfer::public_freeze_object(display);
    transfer::public_freeze_object(publisher);
}

entry fun mint_og( registry: &mut MintRegistry, ctx: &mut TxContext) {
    let sender = tx_context::sender(ctx);
    assert!(!table::contains(&registry.registry, sender), EAlreadyHave);
    let og_nft = OgNft {
        id: object::new(ctx),
        name: string::utf8(b"OG"),
        description: string::utf8(b"OG confirmed member"),
        image_url: url::new_unsafe_from_bytes(b"http://aggregator.walrus-testnet.walrus.space/v1/blobs/vTlUE0IKFgQYLhugvLLhYM_jV1vJHVJfuTKDjwgcbDE"),
    };
    transfer::transfer(og_nft, sender);
    table::add(&mut registry.registry, sender, true);
}
