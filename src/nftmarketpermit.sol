// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";


interface IERC20Permit {
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
}

contract NftMarket is Ownable {
    using ECDSA for bytes32;

    IERC20Permit public token; // EIP-2612 token 
    IERC721 public nft; // ERC721 token 

    struct Listing {
        address seller;
        uint256 price;
        bool active;
    }

    mapping(uint256 => Listing) public listings;

    bytes32 public constant PERMIT_TYPEHASH = keccak256("Permit(address buyer,uint256 tokenId,uint256 price,uint256 deadline)");
    bytes32 public DOMAIN_SEPARATOR;

    constructor(IERC20Permit _token, IERC721 _nft) {
        token = _token;
        nft = _nft;

        uint256 chainId;
        assembly {
            chainId := chainid()
        }
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                keccak256(bytes("NftMarket")),
                keccak256(bytes("1")),
                chainId,
                address(this)
            )
        );
    }

    function listNFT(uint256 tokenId, uint256 price) external {
        require(nft.ownerOf(tokenId) == msg.sender, "Not the owner");
        nft.transferFrom(msg.sender, address(this), tokenId);
        listings[tokenId] = Listing(msg.sender, price, true);
    }

    function permitBuy(
        uint256 tokenId,
        uint256 price,
        uint256 deadline,
        bytes calldata signatureForWL,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        require(block.timestamp <= deadline, "Permit expired");
        require(listings[tokenId].active, "NFT not listed");
        require(listings[tokenId].price == price, "Incorrect price");

        bytes32 structHash = keccak256(
            abi.encode(
                PERMIT_TYPEHASH,
                msg.sender, // Buyer's address
                tokenId,
                price,
                deadline
            )
        );
        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                DOMAIN_SEPARATOR,
                structHash
            )
        );
        address signer = digest.recover(signatureForWL);
        require(signer == owner(), "Invalid signature");

        Listing memory listing = listings[tokenId];
        listings[tokenId].active = false;

  
        token.permit(msg.sender, address(this), price, deadline, v, r, s);

        
        require(token.transferFrom(msg.sender, listing.seller, listing.price), "Token transfer failed");

        
        nft.transferFrom(address(this), msg.sender, tokenId);
    }
}
