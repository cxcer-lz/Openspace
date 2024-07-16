// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/nftmarketpermit.sol";
import "../src/MockERC20.sol";
import "../src/MockERC721.sol";

contract NftMarketTest is Test {
    NftMarket public market;
    MockERC20 public token;
    MockERC721 public nft;
    address owner;
    address buyer;
    uint256 tokenId;
    uint256 price;
    uint256 deadline;
    uint256 ownerPrivateKey;
    uint256 buyerPrivateKey;

    function setUp() public {
        token = new MockERC20(100000);
        nft = new MockERC721();
        ownerPrivateKey = 0xA11CE;
        buyerPrivateKey = 0xB0B;

        owner = vm.addr(ownerPrivateKey);
        buyer = vm.addr(buyerPrivateKey);
        tokenId = 1;
        price = 100 * 10**18;
        deadline = block.timestamp + 1 days;

        vm.startPrank(address(this));
        token.transfer(owner, 1000 * 10**18);
        token.transfer(buyer, 1000 * 10**18);
        vm.stopPrank();

        vm.startPrank(owner);
        market = new NftMarket(address(token), address(nft));
        nft.mint(owner, tokenId);
        nft.approve(address(market), tokenId);
        market.addToWhitelist(buyer);
        market.list(tokenId, price);
        vm.stopPrank();
    }

    function testPermitBuy() public {

        // 生成 permitBuy 的消息哈希和签名哈希
        bytes32 messageHash = keccak256(abi.encodePacked(owner, tokenId));
        bytes32 ethSignedMessageHash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", messageHash));
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(ownerPrivateKey, ethSignedMessageHash);
        

        // 生成 permit 数据哈希和签名哈希
        bytes32 permitDataHash = keccak256(abi.encodePacked(buyer, address(market), price, deadline));
        bytes32 ethSignedPermitHash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", permitDataHash));
        (uint8 permitV, bytes32 permitR, bytes32 permitS) = vm.sign(buyerPrivateKey, ethSignedPermitHash);

        assertEq(token.allowance(buyer, address(market)), 0);
        
        //测试购买
        vm.startPrank(buyer);
        token.approve(address(market), price);
        market.buyNFT(price, 1);
        vm.stopPrank();
        assertEq(nft.ownerOf(1), buyer);
        assertEq(token.balanceOf(owner), price+token.balanceOf(buyer)+price);

    }
}
