// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../src/NftMarket.sol";
import "./MockERC20.sol";
import "./MockERC721.sol";

contract NftMarketTest is Test {
    NftMarket public market;
    MockERC20 public token;
    MockERC721 public nft;

    address public user1 = address(0x1);
    address public user2 = address(0x2);

    function setUp() public {
        token = new MockERC20(10000);
        nft = new MockERC721();
        market = new NftMarket(address(token), address(nft));

        token.transfer(user1, 1000);
        token.transfer(user2, 1000);
    }
    //测试NFT上架成功和上架事件
    function testListNFT() public {
        nft.mint(user1, 1);
        vm.startPrank(user1);
        nft.approve(address(market), 1);
        //上架事件
        vm.expectEmit(true, true, false, true);
        emit NftMarket.List(1, 100);
        market.list(1, 100);
        vm.stopPrank();
        
        uint price = market.getListing(1, user1);
        assertEq(price, 100);
    }
    //测试上架别人的NFT失败
    function testFailListNFTNotOwner() public {
        nft.mint(user1, 1);
        vm.startPrank(user2);
        nft.approve(address(market), 1);
        vm.expectRevert("You are not the owner of this NFT");
        market.list(1, 100);
        vm.stopPrank();
    }



    //测试NFT购买成功和购买事件的测试
    function testBuyNFT() public {
        nft.mint(user1, 1);
        vm.startPrank(user1);
        nft.approve(address(market), 1);
        market.list(1, 100);
        vm.stopPrank();

        vm.startPrank(user2);
        token.approve(address(market), 100);
        //购买事件
        vm.expectEmit(true, true, false, true);
        emit NftMarket.BuyNFT(100, 1);
        market.buyNFT(100, 1);
        vm.stopPrank();

        assertEq(nft.ownerOf(1), user2);
    }
    //测试购买自己的NFT
    function testFailBuyOwnNFT() public {
        nft.mint(user1, 1);
        vm.startPrank(user1);
        nft.approve(address(market), 1);
        market.list(1, 100);
        token.approve(address(market), 100);
        market.buyNFT(100, 1);
        vm.stopPrank();
    }
    //测试重复购买NFT
    function testFailDoublePurchase() public {
        nft.mint(user1, 1);
        vm.startPrank(user1);
        nft.approve(address(market), 1);
        market.list(1, 100);
        vm.stopPrank();

        vm.startPrank(user2);
        token.approve(address(market), 100);
        market.buyNFT(100, 1);
        vm.stopPrank();

        vm.startPrank(user2);
        market.buyNFT(100, 1);
        vm.stopPrank();
    }
    //测试支付过少断言错误信息
    function testFailBuyWithLessAmount() public {
        nft.mint(user1, 1);
        vm.startPrank(user1);
        nft.approve(address(market), 1);
        market.list(1, 100);
        vm.stopPrank();

        vm.startPrank(user2);
        token.approve(address(market), 99);
        vm.expectRevert("the price does not match");
        market.buyNFT(99, 1);
        vm.stopPrank();
    }
    ////测试支付过多断言错误信息
    function testFailBuyWithExcessAmount() public {
        nft.mint(user1, 1);
        vm.startPrank(user1);
        nft.approve(address(market), 1);
        market.list(1, 100);
        vm.stopPrank();

        vm.startPrank(user2);
        token.approve(address(market), 101);
        vm.expectRevert("the price does not match");
        market.buyNFT(101, 1);
        vm.stopPrank();
    }

    
    //模糊测试
    function testFuzzyListingAndBuying() public {
        for (uint i = 0; i < 100; i++) {
            address randomUser = address(uint160(uint256(keccak256(abi.encodePacked(block.timestamp, i)))));
            uint256 randomPrice = (uint256(keccak256(abi.encodePacked(block.timestamp, i))) % 1000000) + 1; // [1, 1000000]
            vm.assume(randomPrice >= 1); // 0.01 * 100 = 1
            vm.assume(randomPrice <= 1000000); // 10000 * 100 = 1000000

            nft.mint(randomUser, i);
            vm.startPrank(randomUser);
            nft.approve(address(market), i);
            market.list(i, randomPrice);
            vm.stopPrank();

            uint256 randomBuyerTokenBalance = token.balanceOf(randomUser);
            if (randomBuyerTokenBalance >= randomPrice) {
                vm.startPrank(randomUser);
                token.approve(address(market), randomPrice);
                market.buyNFT(randomPrice, i);
                vm.stopPrank();

                assertEq(nft.ownerOf(i), randomUser);
            }
        }
    }
    //不可变测试
    function testInvariantNoTokenBalanceInMarket() public view {
        uint256 marketTokenBalance = token.balanceOf(address(market));
        assertEq(marketTokenBalance, 0);
    }
}

