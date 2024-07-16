// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
import "forge-std/Test.sol";
import "../src/MockERC20.sol";
import  "../src/tokenBankpermit.sol";
import  "../src/SigUtils.sol";

contract tokenBankTest is Test{
    MockERC20 internal token;
    SigUtils internal sigUtils;

    uint256 internal ownerPrivateKey;
    uint256 internal spenderPrivateKey;

    address internal owner;
    address internal spender;

    TokenBank internal tokenbank;
    
    function setUp()public{
        token = new MockERC20(1e18);
        sigUtils = new SigUtils(token.DOMAIN_SEPARATOR());

        ownerPrivateKey = 0xA11CE;
        spenderPrivateKey = 0xB0B;

        owner = vm.addr(ownerPrivateKey);
        spender = vm.addr(spenderPrivateKey);

        token._mint(owner, 1e18);

        tokenbank=new TokenBank(address(token));
    }

    //测试permit
    // function test_Permit() public {
    //     SigUtils.Permit memory permit = SigUtils.Permit({
    //         owner: owner,
    //         spender: spender,
    //         value: 1e18,
    //         nonce: 0,
    //         deadline: 1 days
    //     });

    //     bytes32 digest = sigUtils.getTypedDataHash(permit);

    //     (uint8 v, bytes32 r, bytes32 s) = vm.sign(ownerPrivateKey, digest);

    //     token.permit(
    //         permit.owner,
    //         permit.spender,
    //         permit.value,
    //         permit.deadline,
    //         v,
    //         r,
    //         s
    //     );

    //     assertEq(token.allowance(owner, spender), 1e18);
    //     assertEq(token.nonces(owner), 1);
    // }

    //测试permitDeposit
    function test_DepositWithLimitedPermit() public {
        SigUtils.Permit memory permit = SigUtils.Permit({
            owner: owner,
            spender: address(tokenbank),
            value: 1e18,
            nonce: token.nonces(owner),
            deadline: 1 days
        });

        bytes32 digest = sigUtils.getTypedDataHash(permit);

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(ownerPrivateKey, digest);

        tokenbank.permitDeposit(
            permit.owner,
            permit.spender,
            permit.value,
            permit.deadline,
            v,
            r,
            s
        );

        assertEq(token.balanceOf(owner), 0);
        assertEq(token.balanceOf(address(tokenbank)), 1e18);
        assertEq(token.allowance(owner, address(tokenbank)), 0);
        assertEq(token.nonces(owner), 1);

    }
}
