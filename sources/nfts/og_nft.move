module 0x0::og_nft;
use sui::tx_context::sender;
use sui::package;
use sui::display;
use std::string::{Self, String};
use sui::url::{Self, Url};
    
public struct OgNft has key, store {
    id: UID,
    name: String,
    description: String, 
    url: Url
}

public struct OG_NFT has drop {}

fun init(witness: OG_NFT, ctx: &mut TxContext) {

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
            string::utf8(b"{url}")
        ],
        ctx
    );
    display::update_version(&mut display);
    transfer::public_transfer(publisher, sender(ctx));
    transfer::public_transfer(display, sender(ctx));
}

entry fun mint(ctx: &mut TxContext) {
    let nft = OgNft {
        id: object::new(ctx),
        name: string::utf8(b"OG"),
        description: string::utf8(b"it fills you with determination"),
        url: url::new_unsafe_from_bytes(b"http://aggregator.walrus-testnet.walrus.space/v1/blobs/vTlUE0IKFgQYLhugvLLhYM_jV1vJHVJfuTKDjwgcbDE")
    };
    transfer::public_transfer(nft, sender(ctx));
}
